#############################################################################
# Dicop::Data -- contains all the jobs (with chunks) and clients
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data;
use vars qw/$VERSION/;
$VERSION = '2.08';	# Current version of this package

use base Dicop::Handler;
use strict;
use vars qw($AUTOLOAD $BUILD);

use Dicop::Base qw/write_file read_list read_file random decode encode ago a2h 
		   h2a replace_templates/;
use Dicop qw/ ISSUED FAILED DONE SOLVED TOBEDONE SUSPENDED TIMEOUT BAD VERIFY/;
$BUILD = $Dicop::BUILD;

sub version { $Dicop::VERSION; }
sub build { $BUILD; }
    
use Dicop::Data::Charset;
use Dicop::Data::Charset::Dictionary;
use Dicop::Data::Charset::Extract;
use Dicop::Data::Job;
use Dicop::Data::Case;
use Dicop::Data::Client;
use Dicop::Data::Proxy;
use Dicop::Data::Result;
use Dicop::Data::Chunk;
use Dicop::Data::Group;
use Dicop::Data::User;
use Dicop::Data::Jobtype;
use Dicop::Data::Testcase;
use Dicop::Item qw/from_string/;
use Dicop::Config;
use Dicop::Server::Config;
use Dicop::Client;
use Dicop::Files;
use Dicop::Connect qw/_load_connector _connect_server/;
use Dicop::Security;
use Mail::Sendmail;
use Time::HiRes;
use File::Spec;

use Dicop::Event qw/give_up crumble msg/;

#############################################################################
# private, initialize self 

## All the parts that are handled/read/flushed/known in the particular order
## that they are read in. For all other purposes, the order does not matter.

my @MY_OBJECTS = (qw/
  charsets jobtypes groups clients cases results jobs proxies testcases users
  /);

sub _after_config_read
  { 
  my ($self,$cfg,$cfgdir,$cfgfile) = @_;

  
  ###########################################################################
  # check version of Math::BigInt::GMP if loaded

  my $c = Math::BigInt->config();

  if ($c->{lib} eq 'Math::BigInt::GMP' && ($c->{lib_version} < 1.17))
    {
    die ("Need at least Math::BigInt::GMP v1.17, but got only $c->{lib_version}");
    }

  ###########################################################################
  # set some default config values

  Dicop::Base::cfg_default( $self, 
    msg_dir => 'msg', 
    def_dir => 'def', 
    tpl_dir => 'tpl',
    target_dir => 'target',
    scripts_dir => 'scripts',
    data_dir => 'data',
    max_requests => 128,
    msg_file => 'messages.txt',
    patterns_file => 'request.def',
    objects_def_file => 'objects.def',
    log_dir => 'logs',
    error_log => 'error.log',
    server_log => 'server.log',
    file_server => 'http://127.0.01/',
    mail_server => 'none',
    max_request_time => 5,
    eventtxt_dir => 'event',
    mailtxt_dir => 'mail',
    min_chunk_size => 5,
    max_chunk_size => 120,
    client_architectures => 'linux,os/2,mswin32,armv4l,darwin,solaris', 
    chroot => '',
    resend_test => '360',
    minimum_rank_percent => 90,
    case_url_format => '',
    debug_level => 1,
    log_level => 1,
    );

  # check Dicop::Base min version
  my $ver = Dicop->base_version();

  die ("Need at least Dicop::Base $Dicop::BASE_MIN_VER, but got only $ver") unless
    $ver >= $Dicop::BASE_MIN_VER;

  # debug and leak testing enabled?
  if ($cfg->{debug_level} > 1)
    {
    eval { require Devel::Leak; };
    if ($@)
      {
      warn ("Could not load Devel::Leak, leak reports disabled.");
      $cfg->{debug_level} = 1;
      $self->{_debug} = undef;
      }
    else
      {
      $self->{_debug} = {};
      }
    }
  
  $self;
  }

sub _after_load
  {
  my ($self,$args) = @_;
  my $cfg = $self->{config};

  $self->_check_mail_templates($args->{_warn});
  $self->_check_event_templates($args->{_warn});

  # if no users defined, die (to force running ./adduser.pl first)
  give_up ("No users found, please run  ./adduser.pl  before first server startup")
    if scalar keys %{$self->{users}} == 0;
  
  $self->adjust_job_priorities();		# in case DB on disk was changed 

  $self->{resend_test} = abs($cfg->{resend_test} || 360);
  # at max 30 days
  $self->{resend_test} = 43200 if $self->{resend_test} > 43200;
  $self->{allowed_archs} = $cfg->{client_architectures} 
    || give_up ('Need a list of allowed client architectures');
  $self->{allowed_archs} = [ split(/\s*,\s*/, $self->{allowed_archs}) ];

  $self->{last_check} = 0;				# clients offline check
  $self->{target_hash} = {};			# for additional target files
  $self->{dict_hash} = {};			# for dictionaries
  $self->{worker_hash} = {};			# for workers
  
  # Make sure that the charset definitions file exists
  $self->write_charsets_def();

  # load our connector and create user-agent if we need to send events
  if ($cfg->{send_event_url_format})
    {
    $self->_load_connector($cfg, $args);
    }
  
  #$self->check();				# basic self-check

  $self;
  }

sub _load_data
  {
  # load data at startup from disk
  my ($self,$args) = @_;
  my $cfg = $self->{config};

  # basic check for keys/values/types
  my $allowed_keys = Dicop::Server::Config::allowed_keys();
  my $check = $cfg->check($allowed_keys);

  give_up($check) if defined $check;

  $self->_construct_file_names($args, $cfg, @MY_OBJECTS);
 
  my $dir = $self->{dir};

  my ($item,$chunk);
  # order in which items get done is important, first charsets, etc
  foreach my $what (@MY_OBJECTS) 
    {
    my $file = File::Spec->catfile($dir,$self->{filenames}->{$what});
    if (!-f $file)
      {
      crumble("Cannot read '$file': $!");
      print STDERR
       " Make sure you set the correct filename in the config file.\n";
      print STDERR " If you haven't changed their name, run\n  ./touch_files\n to create all the files.";
      print STDERR " Otherwise: 'touch $file' to create it.\n";
      die();
      }
    my @list = from_string(read_file($file));
    foreach $item (@list)
      {
      my $args = {};		# default empty
      $item->{_parent} = $self;
      # insert job first so that _construct in chunk can find it
      $self->{$what}->{$item->{id}} = $item;	
      if (ref($item) eq 'Dicop::Data::Job')
        {
        # load it's chunks from disk
        my $loadfile = File::Spec->catfile($dir,$item->{id},'chunks.lst');
        $args->{chunks} = [ from_string(read_file($loadfile)) ];
        $self->_construct_item($item,$args);	# and pass to job
        foreach $chunk (@{$item->{_chunks}})
          {
          $chunk->{_parent} = $self;
	  $chunk->{job} = $item;
          $self->_construct_item($chunk);
          }
        # load it's checklist from disk
        $loadfile = File::Spec->catfile($dir,$item->{id},'check.lst');
        if (-f $loadfile)
          {
          my $checklist = [ from_string( read_file($loadfile)) ];
          foreach $chunk (@$checklist)
            {
            $chunk->{_parent} = $self;
	    $chunk->{job} = $item;
            $self->_construct_item($chunk);
            $item->{_checklist}->{$chunk->{id}} = $chunk;
            }
          }
        }
      else
        {
	# delay construction for results and charsets
        $self->_construct_item($item,$args)
         if $what !~ /^(results|charsets)$/;
        }
      $item->set_id($item->{id});	# keep record of highest id
      }
    if ($what eq 'charsets')
      {
      # finish charsets (first simple, then grouped, then dictionary)
      foreach my $type (qw/simple grouped dictionary/)
	{
	foreach my $id (keys %{$self->{charsets}})
	  {
	  my $item = $self->{charsets}->{$id};
	  next if $item->{type} ne $type;

	  # In case of dictionary set, try to find from the already existing
	  # dictionary set one with the same dictionary file. If found, make
	  # a copy of the charset object, this saves memory.
	  my $other = undef;
	  if ($type eq 'dictionary')
	    {
	    foreach my $id_d (keys %{$self->{charsets}})
	      {
	      my $i = $self->{charsets}->{$id_d};
	      # take only dictionary charsets that are already constructed
	      next if $i->{type} ne 'dictionary';
	      next if ref($i->{_charset}) !~ /^Math::String::Charset::/;
	      $other = $i, last if $i->{_charset}->{_file} eq $item->{file};
	      }
	    }
	  $self->_construct_item($item,$other);
	  }
	}
      } # endif what eq 'charsets' 

    # check that at least one object of the following exists:
    for my $w (qw/cases groups clients jobtypes/)
      {
      if ($what eq $w && $self->$w() == 0)
	{
	# if not loaded any objects of this type, we got an old data-set
	# and create a default one
        warn ("Warning: You have no $what. Creating a default one.\n")
          unless $args->{_warn};		# testsuite disables warnings

	my $wname = $w; $wname =~ s/s\z//;	# Cases => Case
	my $class = 'Dicop::Data::' . ucfirst($wname);
	my $name = "Default $wname"; $name = 'test' if $w eq 'jobtype';
	my $item = $class->new( id => 1, name => $name, description => "Default $w", referee => 'dicop', owner => 'dicop' );
        $item->{_parent} = $self;
        $self->_construct_item($item);
        $self->{$what}->{$item->{id}} = $item;
	}
      }

    if ($what eq 'charsets' && $self->charsets() == 0)
      {
      # if not loaded any charsets, create a default one
      warn ("Warning: You have no charsets. Creating a default one.\n")
        unless $args->{_warn};		# testsuite disables warnings
      my $item = Dicop::Data::Charset->new( id => 1, name => 'Default charset', set => join('', '30' .. '39'), description => 'digits (0-9)', owner => 'dicop', );
      $item->{_parent} = $self;
      $self->_construct_item($item);
      $self->{$what}->{$item->{id}} = $item;
      } # endif what eq 'charsets' 
    }

  # finish results
  foreach my $id (keys %{$self->{results}})
    {
    $self->_construct_item($self->{results}->{$id});
    }
  
  # fix clients jobspeeds and return $self
  $self->_fix_client_jobspeeds(undef);
  }

sub _fix_client_jobspeeds
  {
  # fix all clients jobspeeds
  my ($self,$jobtype) = @_;

  foreach my $id (keys %{$self->{clients}})
    {
    $self->{clients}->{$id}->_fix_job_speeds($jobtype);
    }
  $self;
  }

sub _check_mail_templates
  {
  my ($self,$warn) = @_;

  if ($self->_check_templates( 'mail', $warn, 
   qw/verify_error bad_result closed newjob offline result stopped/))
    {
    warn
     ("Check config entry 'mailtxt_dir' and maybe rename sample files.\n")
     unless $warn;	# testsuite disables warnings
    die ("Too many errors, aborting.");
    }
  }

sub _check_event_templates
  {
  my ($self,$warn) = @_;

  if ($self->_check_templates( 'event', $warn, qw/job_failed found_result new_job/))
    {
    warn
     ("Check config entry 'eventtxt_dir' and maybe rename sample files.\n")
     unless $warn;	# testsuite disables warnings
    die ("Too many errors, aborting.");
    }
  }

sub check
  {
  # provide self-consistency checks on startup
  my $self = shift;

  my $rc;
  foreach my $j (keys %{$self->{jobs}})
    {
    $rc = $self->{jobs}->{$j}->check(); 
    crumble ($rc) if $rc;
    }

  return;				# no error
  }

sub get_random_job
  {
  # get one of the jobs at random
  my $self = shift;
  
  my @jobs; my $count = 0;
  foreach (keys %{$self->{jobs}})
    {
    push @jobs,$self->{jobs}->{$_} if $self->{jobs}->{$_}->is_running();
    $count++;
    }
  return if $count == 0;		# no running jobs
  return $jobs[0] if $count == 1;	# only one
  my $r = int(rand(scalar @jobs)); 
  $jobs[ $r ];
  }

##############################################################################

{
  sub _method_get_ok
    {
    my ($self,$method) = @_;
    $method =~ /^get_(case|charset|client|group|job|jobtype|proxy|result|testcase|user)/
      ? 1 : 0;
    }
  sub _method_ok
    {
    my ($self,$method) = @_;
    $method =~ /^(case|charset|client|group|job|jobtype|proxie|result|testcase|user)s/
      ? 1 : 0;
    }
}

sub AUTOLOAD
  { 
  # set the right class for access to _method_foo()
  $Dicop::Handler::AUTOLOAD = $AUTOLOAD;
  Dicop::Handler::AUTOLOAD(@_);
  }

###############################################################################

sub reference_speed
  {
  # calculate the entire cluster speed base on the reference client
  my $self = shift;
  my $time = shift || 3600*6;

  my $id = $self->{config}->{reference_client_id};
  my $rc = $self->{clients}->{$id};
  return 'unknown number' if !ref($rc);				# not found?
  my $speed = 0;
  foreach $id (keys %{$self->{clients}})
    {
    my $client = $self->{clients}->{$id};
    next unless $client->is_online($time);			# not online?
    $speed += $client->get('speed');				# sum up
    }
  return 'unknown number' if $rc->get('speed') == 0;
  $speed = int($speed / $rc->get('speed'));
  return "$speed x ".($rc->{cpuinfo}->[1]||0)." Mhz ".($rc->{cpuinfo}->[0]||'');
  }

sub speed
  {
  # calculate the speed of the cluster for a particulary job in keys/s
  # in list context returns (speed, avrg_speed_per_client)
  # Considers only the clients that were active in the timeframe given
  # Skip clients that failed to often, or never worked on a chunk
  # Speed is "corrected" by percent of job
  my $self = shift;
  my $jid = shift;
  my $time = shift || 3600*6;

  my $job = $jid;				# id or ref
  $job = $self->get_job($jid) if !ref($jid);
  $jid = $job->{id};

  return 0 unless $job->is_running();		# job not active
  my $speed = 0; my $cnt = 0;
  foreach my $id (keys %{$self->{clients}})
    {
    my $client = $self->{clients}->{$id};
    next unless $client->is_online($time);
    my $cjs = $client->{job_speed}->{$jid};
    next unless defined $cjs;
    next unless $cjs > 0;			# never worked on that job yet
    next unless $client->failures($job->{jobtype}->{id}) < 3; # too many?
    $speed += $cjs; $cnt++;
    }
  $speed = int($speed*($job->{priority}||0)/100);
  if (wantarray)
    {
    return (0,0) if $cnt == 0;			# no client active
    return ($speed,$speed/$cnt);
    }
  $speed;					# in keys/second
  }

sub get_object
  { 
  # general case of get_xxx
  my ($self,$item,$noerror) = @_;

  my $type = $self->name_from_type($item->{type});

  my $id = $item->{id};

  if ($type eq 'chunks')
    {
    my $jid = $item->{job} || 0;
    # get job first

    my $job = $self->{jobs}->{$jid};
    if (defined $job)
      {
      my $chunk = $job->get_chunk($id);
      return $chunk if defined $chunk;
      return $self->log_msg(402,$id,$jid);
      }
    return $self->log_msg(401,$jid);
    }

  return $self->{$type}->{$id} if exists $self->{$type}->{$id};
  $self->log_msg(430,$type,'id',$id) unless $noerror;
  }

sub adjust_job_priorities
  {
  # for all running jobs calculate their job priority and store it, return
  # a job that matches a minimum priority
  my $self = shift;
  my $priority = shift;

  return if $self->jobs() == 0;
  
  ###########################################################################
  # first adjust priorities of jobs

  # count running ones and find min rank in one go
  my ($min,		# hash with job(s) with minimum rank
      @running);	# list of all running jobs
  foreach my $job (keys %{$self->{jobs}})
    {
    my $j = $self->{jobs}->{$job};
    $j->{priority} = 0; 
    if ($j->is_running())
      {
      push @running,$j;
      # replace if greater or not yet defined
      $min = { job => { $j->{id} => 1 }, rank => $j->{rank} }
       if (!defined $min) || ($j->{rank} < $min->{rank});
      # add this job if equal ranks are equal
      # (meaning if two jobs get the same rank, choose randomly
      #  between them)
      $min->{job}->{$j->{id}} = 1 if $min->{rank} == $j->{rank};
      }
    }
  return if @running == 0;

  my $mp = $self->{config}->{minimum_rank_percent} || 0;
  $mp = 100 if @running == 1;			# only one job?
  my $rp = (100-$mp);
  # divide by number of jobs with same rank (usually one)
  $mp = int(100*$mp / scalar keys %{$min->{job}})/100;
  # number of "other" jobs, e.g. jobs not having the minimum priority
  my $others = scalar @running - scalar keys %{$min->{job}};
  foreach my $job (@running)
    {
    if (exists $min->{job}->{$job->{id}})
      {
      $job->{priority} = $mp;
      }
    else
      {
      $job->{priority} = int((100*$rp) / $others)/100;
      }
    }
  # Now each running job's priority is a value between 0..100, and their sum
  # is exactly 100.

  return if !defined $priority;		# caller does not care about result

  ###########################################################################
  # select job to hand to client based on a random priority value (0 .. 1.0)

  $priority *= 100;				# 0..1 => 0..100
  # sort jobs by priority
  @running = sort { $a->{priority} <=> $b->{priority} } @running;
  my $cur = 0;
  foreach my $job (@running)
    {
    return $job if $priority <= $cur+$job->{priority};
    $cur += $job->{priority};
    }
  # should not come to here
  $running[0];
  }

sub get_highest_priority
  {
  # get job with highest priority
  my $self = shift;

  my $max = 0; my $job = ''; my $rank = '';
  foreach my $id (keys %{$self->{jobs}})
    {
    my $j = $self->{jobs}->{$id};
    next if !$j->is_running();
    ($job,$max,$rank) = ($j->{id},$j->{priority},$j->{rank}) 
     if $j->{priority} > $max;
    }
  return { job => $job, rank => $rank, };
  }

sub other_request
  {
  # return type of "other" requests (non-auth,form,report,info)  

  my ($self,$re) = @_;
  my $t = 'work'; $t = 'test' if ($re->{job}||'') =~ /^test/;
  ('report', $t);
  }

sub finish_html_request
  {
  my ($self,$res) = @_;

  my $lowest = $self->get_highest_priority();
  if (ref($lowest->{job}))
    {
    my $lj = join (', ',@{$lowest->{job}});
    $$res =~ s/##lowestjob##/$lj/g;
    $$res =~ s/##lowestrank##/$lowest->{rank}/g;
    }
  else
    {
    $$res =~ s/##lowestjob##/Unknown/g;
    $$res =~ s/##lowestrank##/Unknown/g;
    }
  $$res =~ s/##minimum_rank_percent##/$self->{config}->{minimum_rank_percent}/g;
  
  # fix up CSS for these odd browsers
  $self->{user_agent} ||= '';
  $$res =~ s/<!-- autoremovethisline.*//g if $self->{user_agent} =~ /(Konqueror| MSIE )/i;
  $$res =~ s/<!-- autoremovethisline.*?-->//g;

  $res;
  }

sub finish_connect
  {
  my ($self, $res) = @_;

  $self->check_clients(); 	# check whether client's went offline

  $res;
  }
 
sub check_clients
  {
  # check whether client's went offline
  my $self = shift;
  my $mail = shift || 0;

  my $check_time = $self->{config}->{client_check_time}||0;
  
  # not defined or 0 => no check
  return if $check_time == 0;

  my $time = Dicop::Base::time();
  # only every now and then
  return if ($time - $self->{last_check} < $check_time*3600);
 
  $self->{last_check} = $time;
  $check_time = abs(int($self->{config}->{client_offline_time}||0))||1;
  $check_time *= 3600;

  my ($id,$client,$hash);
  foreach $id (keys %{$self->{clients}})
    {
    # 1 - online, 0 - offline, -1 - just went from online to offline
    $client = $self->{clients}->{$id};
    next if $client->is_online($check_time);		# is online
    next unless $client->went_offline();		# mail already sent?
    # this should send only one mail, not dozends, which can tie up the
    #	server and machine, and clog the receivers mailbox
    $hash->{$id} = 1;					# remember (for tests)
    $self->email('offline',undef, undef,undef,$client)		# so send email
     if $mail == 0;					# not for testsuite
    }
  $hash;
  }

sub class_from_type
  {
  my ($self,$type) = @_;

  # the four different charset types
  return 'Dicop::Data::Charset' if $type =~ /^(simplecharset)\z/;
  return ref($self) . '::Charset::' . ucfirst($1) 
    if $type =~ /^(extract|dictionary|grouped)charset\z/;

  $self->SUPER::class_from_type($type);
  }

#############################################################################
# deletion checks

sub _del_user
  {
  # check if we can delete this user
  my ($self,$userid) = @_;

  # need at least one user!
  return $self->log_msg(433,$userid) if $self->users() == 1;
  return;		# okay, can be deleted
  }

sub _del_charset
  {
  # check if we can delete this charset
  my ($self,$charsetid) = @_;

  # when a job needs a charset, a job needs a charset

  foreach my $jobid (keys %{$self->{jobs}})
    {
    my $job = $self->{jobs}->{$jobid};
    if ($job->{charset}->{id} eq $charsetid)
      {
      return $self->log_msg(432,'charset',$charsetid,'job',$jobid);
      }
    }
  return;		# okay, can be deleted
  }

sub _del_group
  {
  # check if we can delete this group
  my ($self,$groupid) = @_;

  # clients and proxies might still need that group

  foreach my $clientid (keys %{$self->{clients}})
    {
    my $client = $self->{clients}->{$clientid};
    if ($client->{group}->{id} eq $groupid)
      {
      return $self->log_msg(432,'group',$groupid,'client',$clientid);
      }
    }
  foreach my $proxyid (keys %{$self->{proxies}})
    {
    my $proxy = $self->{proxies}->{$proxyid};
    if ($proxy->{group}->{id} eq $groupid)
      {
      return $self->log_msg(432,'group',$groupid,'proxy',$proxyid);
      }
    }
  return;		# okay, can be deleted
  }

sub _del_case
  {
  # check if we can delete this case
  my ($self,$caseid) = @_;

  # jobs might still need that case

  foreach my $jobid (keys %{$self->{jobs}})
    {
    my $job = $self->{jobs}->{$jobid};
    if ($job->{case}->{id} eq $caseid)
      {
      return $self->log_msg(432,'case',$caseid,'job',$jobid);
      }
    }
  return;		# okay, can be deleted
  }

sub _del_client
  {
  # clear off all instances where a client is used. Return undef for ok,
  # otherwise error message (for instance if client cannot be deleted)
  my ($self,$clientid) = @_;

  # if used in a result, cannot delete client
  #foreach my $resid (keys %{$self->{results}})
  #  {
  #  my $res = $self->{results}->{$resid};
  #  if ($res->{client}->{id} eq $clientid)
  #    {
  #    return $self->log_msg(432,'client',$clientid,'result',$resid);
  #    }
  #  }

  my $client = $self->get_client($clientid,'no_error');

  # retry as proxy not nec. since proxies never have chunks
  return unless defined $client; 

  # clear any chunks that contain the client as issued-to, or verifier
  foreach my $jobid (keys %{$self->{jobs}})
    {
    my $job = $self->{jobs}->{$jobid};
    foreach my $chunk (@{$job->{_chunks}})
      {
      if (defined $chunk->{client} && ref($chunk->{client}) &&
          $chunk->{client}->{id} eq $clientid)
        {
	$chunk->{client} = '';
        my $status = $chunk->{status};
	# reclaim chunk
	if ($status != DONE)
	  {
	  $chunk->status(TOBEDONE);
	  $chunk->clear_verifiers();
	  }
        }
      else
	{
	$chunk->del_verifier($client) if $chunk->verified_by($client);
	}
      } 
    }

  return;		# okay, can be deleted
  }

sub _del_job
  {
  # clear off all instances where a job is used. Return undef for ok,
  # otherwise error message (for instance if job cannot be deleted)
  my ($self,$jobid) = @_;

  my $job = $self->get_job($jobid);

  # TODO: don't allow delete if a result "uses" a job?

  # clear any client's jobspeed table entries
  foreach my $clientid (keys %{$self->{clients}})
    {
    my $client = $self->{clients}->{$clientid};
    $client->discard_job($jobid);
    }

  return;		# okay, can be deleted
  }

sub del_item
  {
  # del item from server's in-memory database
  my ($self,$item) = @_;
 
  my $res = $self->get_object($item);
  return $res unless ref $res;		# error
 
  # ok, it exists
  my $type = $item->{type}; 
  my $id = $item->{id};

  my $rc;
  # clean any instances where the item in question is used
  # XXX TODO: that could be more general
  $rc = $self->_del_client($id) if $type =~ /^(client|proxy)$/;
  $rc = $self->_del_charset($id) if $type eq 'charset';
  $rc = $self->_del_user($id) if $type eq 'user';
  $rc = $self->_del_group($id) if $type eq 'group';
  $rc = $self->_del_job($id) if $type eq 'job';
  $rc = $self->_del_case($id) if $type eq 'case';

  return $rc if defined $rc;		# error

  $type = $self->name_from_type($type);

  # no error, so go ahead and purge it
  delete $self->{$type}->{$id};

  $self->write_charsets_def() if $type eq 'charsets';
  $self->adjust_job_priorities() if $type eq 'jobs';

  $self->modified(1);
  $self;
  }

#############################################################################

sub change
  {
  # change an object
  my $self = shift;
  my ($req,$info) = @_;

  my $type = $req->{type};
  my $item;
  if ($type eq 'chunk')
    {
    my $job = $self->get_job($req->{job});
    return $job unless ref $job;		# error
    $item = $job->get_chunk($req->{id});
    }     
  else   
    {
    $item = $self->get_object($req);
    }
  return $item unless ref $item;		# error
  # ok, item exists

  my ($txt,$tpl) = $self->read_table_template("changed.txt");

  $type = $self->name_from_type($type);
  my $id = $item->{id};

  my $trial = $item->copy();

  my @inc = (keys %$req);

  foreach my $key (@inc)
    {
    next if $key =~ /^_/;				# ignore these
    next if $key =~ /^(cmd|type|id|dirty|style|job)$/;	# ignore these
    if ($trial->can_change($key))			# possible to change?
      {
      my $val = decode($req->{$key});			# decode from browser

      $trial->put($key,$val);				# so change it
      # XXX TODO
      #return $self->log_msg(435, $key,$trial->{type},$item->{id},$val);
      }
    else
      {
      # cannot change field
      return $self->log_msg(434, $key,$trial->{type},$item->{id}); 
      }
    }
  my $check = $trial->check();			# let the obj check itself
  return $self->log_msg(437, $check) if $check;

  # if the change did work completely, copy the new values into $item
  foreach my $key (@inc)
    {
    next if $key =~ /^_/;				# ignore these
    next if $key =~ /^(cmd|type|id|dirty|style|job)$/;	# ignore these

    my $val = decode($req->{$key});			# decode from browser
    $item->put($key,$val);				# so change it
    }
  $item->{_parent} = $self;
  $item->modified(1);				# flag the item as modified
  $item->_construct();				# finish up changes
  $self->insert_object($txt,$item);		# show changes to client

  $$txt =~ s/##type##/$req->{type}/g;   	# what was changed?

  if ($req->{type} eq 'job')
    {
    # job was changed, so adjust priorities
    # XXX should this send an email to the admin?
    $self->adjust_job_priorities();
    }

  if ($req->{type} eq 'jobtype')
    {
    # jobtype was changed, so adjust client speeds
    $self->_fix_client_jobspeeds( $item->{id} );
    }

  $self->modified(1);
  $txt;
  }
  
#############################################################################

sub _add_case
  {
  # if it doesn't already exist with that name, add a case
  # (The case name is a ident number and supposed to be unique)
  my ($self, $params) = @_;

  # if already exists, return it
  foreach my $id (keys %{$self->{cases}})
    {
    return $id if $self->{cases}->{$id}->{name} eq $params->{name};
    }

  # prepare data
  my $r  = 'cmd_add;type_case';
  foreach my $k (keys %$params)
    {
    my $def = ''; $def = 'no value set' unless $k eq 'url';
    $r .= ";$k" . '_' . encode($params->{$k} || $def);
    }

  my $req = Dicop::Request->new ( id => 'req0001',
    data => $r, patterns => $self->{request_patterns} );

  # and now add case
  my $case = $self->add( $req, undef, undef, 'no_template' );

  # if case couldn't be added for some reason, use the default case
  $case = 1 unless defined $case;	# should really not happen

  # return the ID of the (new) case
  $case;
  }

sub add_result
  {
  # add a result to our result-list
  my ($self,$job,$client,$req) = @_;

  my $res = $self->{results};
  foreach my $i (keys %$res) 
     {
     my $r = $res->{$i};
     if (($r->{job} eq $job->{id}) && ($r->{result_hex} eq $req->{result}))
       {
       return ('Not added, already exists',undef);
       }
     }
  my $result = Dicop::Data::Result->new( { 
    type => $job->{jobtype}->{id}, job => $job->{id}, 
    job_description => $job->{description},
    type_description => $job->{jobtype}->{description},
    client => $client->{id}, client_name => $client->{name},
    result_hex => $req->{result},
    } );
  return ($self->add_item('result',$result),$result);
  }

sub add_clients
  {
  # mass-add clients
  my ($self,$req,$client,$info) = @_;

  my $r = $req->copy();
  delete $r->{count};
  $r->{type} = 'client';
  my $name = $req->{name};
  my $clients = $self->clients();

  my $tpl = $self->read_template("added_clients.txt");

  my $error = '';
  my $done = 0;
  
  my @IP = split (/\./, $req->{ip} || '');
  my $id = $req->{id} || $name;
  my $count = abs($req->{count} || 1);
  $count = 1024 if $count > 1024;
  for (my $i = 0; $i < $req->{count}; $i++)
    {
    $r->{name} = $name;
    $r->{id} = $id;
    $r->{ip} = '';
    $r->{ip} = join ('.', @IP) if $req->{ip} ne '';

    my $txt = $self->add($r,$client,$info);
    # check that the client got added
    if ($self->clients() == $clients)
      {
      # error, client not added
      $tpl = $self->read_template("massadd_failed.txt");
      return if !defined $tpl;
      $error = "Could not add client: '$txt'\n";
      last;
      }
    $IP[3]++; $id++; $name++;		# magical inrement (foo => fop etc)
    $done++;
    }
  my $stype = $req->{type} || ''; 	# what was added?
  $stype =~ s/^(grouped|dictionary)//;	# simple type
  $$tpl =~ s/##type##/clients/g; 	# what was added?
  $$tpl =~ s/##count##/$done/g; 	# how many did we?
  $$tpl =~ s/##count##/$req->{count}/g; # how many should we?
  $$tpl =~ s/##simpletype##/$stype/g; 	# what was added?
  $$tpl =~ s/##error##/$error/g; 	# possible error
  $tpl;
  }

sub add_item
  {
  # add an item to server's in-memory database
  my ($self,$type,$item) = @_;
  my $ot = $type;

  return crumble ("Can't add non-ref: $item") unless ref $item;

  $type = 'charset' if $type =~ /^(simple|grouped|dictionary)charset$/;
  $type = $self->name_from_type($type);

  # the ID is optional:

  my $id = $item->{id} || 0;

  return $self->log_msg (436,"Illegal item type '$type'") if $type !~
    /^(cases|charsets|proxies|jobs|jobtypes|clients|testcases|groups|results|users)$/;

  return "$ot $id already exists" if (exists $self->{$type}->{$id});
  return "ID $id illegal for item type $type $item" if $id !~ /^[a-zA-Z0-9]+\d*\z/;

  # check whether charset already exists, but compare only simple w/ simple ones
  if (($type eq 'charsets') && ($item->type() eq 'simple'))
    {
    foreach my $set (keys %{$self->{charsets}})
      {
      next if $self->{charsets}->{$set}->{type} ne 'simple';
      if ($self->{charsets}->{$set}->{set} eq $item->{set})
        {
        return $self->log_msg(431,$item->{set},$self->{charsets}->{$set}->{id});
        }
      }
    }
  $item->{_parent} = $self;
  $item->_construct();			# post init of item
  $item->modified(1);			# mark new items as modified
  my $check = $item->check();		# let the item check itself
  return $self->log_msg(436, $check) if $check;
  
  $self->{$type}->{$id} = $item;
  $self->_construct();
  $self->modified(1);			# mark ourself as modified
  '';					# no error
  }

#############################################################################

sub confirm
  {
  # ask for confirmation of deletion of some object
  my ($self,$req) = @_;

  my $item = $self->get_object($req);
  return $item unless ref $item;
 
  my $txt = $self->{tpl};
  
  $self->insert_object($txt,$item, 
    {
      description => 1, 
      job_description => 1, 
      ip => 1, 
      result => 1, 
      name => 1,
      id => 1,
      arch => 1,
      version => 1,
    }
    );
  $$txt =~ s/##type##/$req->{type}/g; 	# fields of the object
  $txt;
  }

#############################################################################
# generation routines, e.g. return HTML from template file

sub search
  {
  # show the search results
  my ($self,$req) = @_;

  my $type = $req->{type};
  my ($txt,$tpl) = ($self->{tpl},$self->{tplrow});

  my $results = $self->_search($req,$type);

  if (keys %$results == 0)
    {
    $$txt =~ s/<!-- search output(.|\n)*search output -->/<p>No results were found. Please try again:<\/p>/;
    }
  else
    {
    # display results

    $self->_gen_table($txt, $tpl, 0, [ { ids => $results, type => $type } ], $self->_status_sort($req));

    # some items don't have all the fields, so remove them afterwards
    $$txt =~ s/##(job_description|description|name|ip|delete)##//g;
  
    }
  $$txt =~ s/##object_group##/$type/g;

  $txt;
  }

sub _search
  {
  my ($self, $req, $type) = @_;

  my $results = { };
  foreach my $id (keys %{$self->{$type}})
    {
    my $item = $self->{$type}->{$id};
    my $match = 0;					# default: no match
    foreach my $crit_name (qw/name id ip description/)
      {
      my $criteria = $crit_name;
      # for results, search in job_description rather than in description
      $criteria = 'job_description'
       if $crit_name eq 'description' && ref($item) eq 'Dicop::Data::Result';

      # 'jobs', etc have no IP, so always match
      $match++, next unless exists $item->{$criteria};
      # criteria ANY means always match
      $match++, next if $req->{$crit_name} eq 'ANY';
      # else check for a match
      my $check = quotemeta($req->{$crit_name});
      $check = lc($check) if $req->{case} == 0;		# insensitive
      my $against = $item->{$criteria};
      $against = lc($against) if $req->{case} == 0;	# insensitive

      if ($against =~ /$check/)
        {
        $match++;					# matched
        }
      }
    $results->{$id} = $self->{$type}->{$id} if $match == 4;      # 4 criteria
    }
  $results;
  }

sub del
  {
  # really delete an object after confirmation
  my ($self,$req) = @_;

  my $res = $self->del_item($req);
  return $res unless ref $res;

  my $txt = $self->read_template("deleted.txt");
  $$txt =~ s/##type##/$req->{type}/g; 	# what was deleted?
  $$txt =~ s/##id##/$req->{id}/g;
  $txt;
  }

sub add
  {
  # add something to the database
  my ($self,$req, $client, $info, $no_template) = @_;
  
  my $type = $req->{type} || '';
  my $error = $req->error() || '';

  # mass-add clients
  return $self->add_clients ($req, $client, $info) 
   if $type eq 'client' && (abs($req->{count} || 1)) != 1;
 
  my ($item,$txt);
  my $class = "Dicop::Data::".ucfirst($type);
  $class =~ s/(Grouped|Simple)charset/Charset/;
  $class =~ s/Dictionarycharset/Charset::Dictionary/;
  my $params = {};

  # always set the owner for the item from the admin who entered the request
  $params->{owner} = $info->{user} || 'no user';
  foreach my $key (keys %$req)
    {
    next if $key =~ /^_/;				# skip internals
    next if $key =~ /^(cmd|submit|type|style)$/;	# and these
    my $val = decode($req->{$key});
    # if user had to enter a password and a passwordrepeat, try to mach them
    if ($key eq 'pwdrepeat') 
      {
      if ($req->{pwd} ne $req->{pwdrepeat})
        {
        $error = "Passwords do not match. Please try again.";
        last;
        }
      next;
      }
    if ($key eq 'pwd')
      {
      # don't store passwords directly, but hash them and add a salt
      $params->{salt} = a2h(random(16*8));
      $params->{pwdhash} = Dicop::Security::hash_pwd("$params->{salt}$val\n");
      next;
      }
    $params->{$key} = $val;
    }
  if ($error eq '')
    {
    $item = $class->new ( $params );
    if (defined $item)
      {
      $error = $self->add_item ($req->{type},$item);
      }
    else
      {
      $error = "Could not construct object from request data.";
      }
    }
  
  if ($error eq "")
    {
    # update the file with the charset definitions for the workers
    $self->write_charsets_def() if $req->{type} =~ /charset$/;
    if ($type eq 'job')
      {
      $self->adjust_job_priorities();
      $self->email('newjob',undef, $item);	# send mail
      $self->_send_event('new_job', $item);	# create event if necc.
      }
    }

  return $item->{id} if defined $no_template;

  # prepare template to return
  if ($error ne "")
    {
    $txt = $self->read_template("add_failed.txt");
    return if !defined $txt;
    if (exists $item->{script_output} && defined $item->{script_output})
      {
      $$txt =~ s/##output##/$item->{script_output}/g; 	# script output for jobs
      }
    else
      {
      $$txt =~ s/##output##/None./g;
      }
    }
  else
    {
    $txt = $self->read_template("added.txt");
    return if !defined $txt;
    if (exists $item->{script_output} && defined $item->{script_output})
      {
      $$txt =~ s/##output##/$item->{script_output}/g; 	# script output for jobs
      }
    else
      {
      $$txt =~ s/##output##/None./g;
      }
    delete $item->{script_output};
    $self->insert_object($txt,$item);
    }
  my $stype = $req->{type} || ''; 	# what was added?
  $stype =~ s/^(grouped|dictionary)//;	# simple type
  $$txt =~ s/##type##/$type/g; 		# what was added?
  $$txt =~ s/##simpletype##/$stype/g; 	# what was added?
  $$txt =~ s/##error##/$error/g; 	# possible error

  $txt;
  }

sub insert_object
  {
  # insert an object with all it's parameters into an HTML form
  # XXX TODO: that should be in base (and use some sort of
  # templating)
  my ($self,$txt,$item,$keys) = @_;

  $$txt =~ s/##id##/$item->{id}/g;  		# its ID
  
  my $add = "";
  foreach my $key (sort keys %$item)
    {
    next if $key =~ /^_/;				# skip internals
    next if $key =~ /^(cmd|dirty|pwdhash|salt)/;	# skip these
    next if ref($keys) && !exists $keys->{$key};

    my $text = $item->get_as_hex($key);
    next if defined $text && $text eq '';		# skip empty elements

    if (ref($text) eq 'ARRAY')
      {
      $text = join(", ", @$text);
      } 
    if (ref($text) =~ /^Dicop::Data/)
      {
      $text = ref($text) . ' id #' . $text->{id};
      } 

    $add .= "<tr><td>$key</td>";
    $add .= "<td>$text&nbsp;</td></tr>\n";
    }
  $$txt =~ s/##params##/$add/;  # anything as table

  $self;
  }

#############################################################################
# FOO_list () routines

sub job_list
  {
  # create a table of all jobs belonging to a case (used by cmd_status;type_case)
  my ($self,$case,$req) = @_;

  my %hash;
  # for counting
  foreach (qw/done suspended running tobedone failed/) { $hash{$_} = 0; }

  my $ids = {}; my $case_id = $case->{id};
  # find all jobs belonging to this case
  my $jobs = $self->{jobs};
  # gather all IDs of the jobs to be included (e.g. not filtered away)
  foreach my $id (keys %$jobs)
    {
    $ids->{$id} = $jobs->{$id} if $jobs->{$id}->{case}->{id} eq $case_id;
    }

  if (scalar keys %$ids == 0)
    {
    my $t = $self->read_template("no_jobs.inc");
    return $$t;
    }

  # now generate a joblist and return it
  $self->sorted_job_list($req, \%hash, $ids);
  }

sub result_list
  {
  # create a table of all results (all, or only the ones belonging to a
  # certain case/job)
  my ($self, $item, $req) = @_;

  my ($txt,$tpl) = $self->read_table_template("result.tpl");
  return if !defined $txt;
   
  my $ids = {}; 
  my $id = $item->{id} || 0;
  my $type = 'case';
  $type = 'job' if ref($item) =~ /Job/;

  # find:
  # all results ($item undef)
  # all results from all jobs belonging to this case ($type == 'case')
  # all results from all jobs belonging to this job ($type == 'job')

  my $results = $self->{results};
  foreach my $rid (keys %$results)
    {
    my $job = $self->{jobs}->{$results->{$rid}->{job}};
    if ( ($id == 0) ||					# add all to the list
         ($type eq 'case' && defined $job && $job->{case}->{id} eq $id) ||
         ($type eq 'job' && defined $job && $job->{id} eq $id) )
      {
      $ids->{$rid} = $results->{$rid};
      }
    }

  if (scalar keys %$ids == 0)
    {
    my $t = $self->read_template("no_results.inc");
    return $$t;
    }

  my $t = $self->_gen_table( $txt, $tpl, 0, 
    [ { ids => $ids, type => 'results' } ],
    $self->_status_sort($req) ); 
  $$t;
  }

sub chunk_list
  {
  # create a table of all chunks of one job (used by cmd_status;type_job)
  my ($self,$job) = @_;

  my ($txt,$tpl) = $self->read_table_template("chunk.tpl");
  return if !defined $txt;

  my $list = ""; my $line; my $bg;
  foreach my $chunk (@{$job->{_chunks}})
    {
    $line = $tpl; replace_templates(\$line,$chunk); $list .= $line;
    }
  $$txt =~ s/##table##/$list/;
  $$txt;
  }

sub check_list
  {
  # create a table of all the chunks in the checklist of one job
  # used by cmd_status;type_job
  my ($self,$job) = @_;

  my ($txt,$tpl) = $self->read_table_template("check.tpl");
  return if !defined $txt;

  if ($job->checklist() > 0)
    {
    my $list = ""; my $line; my $bg;
    foreach my $i (keys %{$job->{_checklist}})
      {
      $line = $tpl;
      my $chunk = $job->{_checklist}->{$i};
      print STDERR "DEBUG Can not find chunk $i->[0]\n" if !defined $chunk;
      replace_templates(\$line,$chunk);
      $line =~ s/##result##/$i->[1] || 'not yet known'/eg;
      $list .= $line;
      }
    $$txt =~ s/(<!--##head##|##head##-->)//g;	# kill table header comments
    $$txt =~ s/##table##/$list/;
    }
  else
    {
    $$txt =~ s/<!--##head##(.|\n)*##head##-->/The check list is currently empty.\n/;	# kill entire table
    }
  $$txt;
  }

#############################################################################

sub status_chunks
  {
  # create a table of all open chunks across all jobs
  my $self = shift;

  my ($txt,$tpl) = ($self->{tpl},$self->{tplrow});

  my $list = ""; my $line; my $bg;
  foreach my $j (keys %{$self->{jobs}})
    {
    my $job = $self->{jobs}->{$j};
    next unless $job->is_running();
    my $chunks = 0;			# how many open chunks in this job?
    foreach my $i (@{$job->{_chunks}})
      {
      # only "open" chunks
      next if $i->status() != ISSUED && $i->status() != FAILED && $i->status() != VERIFY;
      $chunks++;	
      $line = $tpl;
      foreach ($i->fields())
        {
        $line =~ s/##($_.*?)##/$i->get_as_string($1)/eg;
        }
      $list .= $line;
      }
    # append an empty line to seperate jobs
    if ($chunks > 0)
      {
      $line = $tpl; $line =~ s/##.*?##//g; $list .= $line;
      }
    } # next job
  $$txt =~ s/##table##/$list/;
  $txt;
  }

sub status_debug
  {
  # generate HTML statistics with debug output
  my $self = shift;

  my %hash;

  eval { require Devel::Size; };		# Devel::Size::Report;

  if ($Devel::Size::VERSION)
    {
    my $time = Time::HiRes::time();
# XXX TODO: this seems to take forever (does it loop/hang?)
#    my $report =  Devel::Size::Report::report_size ($self, { class => 1, total => 1, summary => 1, terse => 1 });

    my $report = sprintf("%0.1f Kb", Devel::Size::total_size ($self) / 1024);

    $hash{memory} = "Using Devel::Size for memory report:\n<ul class='small'>\n";
    $hash{memory} .= " <li class='small'> main data object uses <b>$report</b>\n";
    my $cache = $Dicop::Request::VALID;
    my $stats = $cache->statistics();
    
    $report = sprintf("%0.1f Kb", Devel::Size::total_size ($Dicop::Request::VALID) / 1024);
    $hash{memory} .= " <li class='small'> request cache uses <b>$report</b>";
    $hash{memory} .= " and contains " . $cache->items() . " items.";
    $hash{memory} .= " It had <b>$stats->{puts}</b> puts and <b>$stats->{gets}</b> gets";
#    my $hp = sprintf("%0.2f%%", 100 * $stats->{hits} / ($stats->{gets} || 1));
    my $hp = 100 * $stats->{hits} / ($stats->{gets} || 1);
    $hp = $hp->numify() if ref $hp; $hp = sprintf("%0.2f%%", $hp);
#    my $mp = sprintf("%0.2f%%", 100 * $stats->{misses} / ($stats->{gets} || 1));
    my $mp = 100 * $stats->{misses} / ($stats->{gets} || 1);
    $mp = $mp->numify() if ref $mp; $mp = sprintf("%0.2f%%", $mp);
    $hash{memory} .= " (<b>$stats->{hits}</b> hits ($hp) and $stats->{misses} misses ($mp)).\n";
    $hash{memory} .= "</ul>\n<p class='small'>";

    # this will count $self, too, since $self->{object}->{1}->{_parent} points to $self :/
#    $hash{memory} .= " <table>\n";
#    foreach my $key (@MY_OBJECTS)
#      {
#      my $report = sprintf("%0.1f Kb", Devel::Size::total_size ($self->{$key}) / 1024);
#      $hash{memory} .= "  <tr><td class='code'>$key</td><td align='right'><b>$report</b></td></tr>\n";
#      }
#    $hash{memory} .= " </table>\n";

    $time = Time::HiRes::time() - $time;
    $hash{memory} .= sprintf( "Took %0.2f seconds to compile memory report.\n", $time);
    }
  else
    {
    $hash{memory} = "Devel::Size couldn't be loaded - no memory statistics possible.";
    }

  $hash{version} = " <table>\n";
  $hash{version} .= " <tr><th>Module</th><th>Version</th></tr>\n";
  $hash{version} .= " <tr><td class='code' style='text-align: left;'>Perl</td><td class='code'>v$]</td>\n";
  # generate version info
  my @mod = qw/
    Math::BigInt
    Math::BigFloat
    Math::String
    Math::String::Charset::Wordlist
    Net::Server
    Dicop::Base
    Digest::MD5
    Devel::Size
    File::Spec
    Mail::Sendmail
    HTTP::Request
    Time::HiRes
    /;

  push @mod, qw/Devel::Leak/ if defined $self->{_debug};

  # generate version info
  for my $mod (sort @mod)
    {
    no strict 'refs';
    my $ver = ${ $mod . '::VERSION'; } || 'unknown';
    $ver = 'v'. $ver unless $ver eq 'unknown';
    $hash{version} .= " <tr><td class='code' style='text-align: left;'>$mod</td><td class='code'>$ver</td>\n";
    if ($mod eq 'Math::BigInt')
      {
      my $c = Math::BigInt->config();
      my $l = $c->{lib}; $l =~ s/Math::BigInt:://;
      $hash{version} .= " <tr><td class='code' style='text-align: left;'>Math::BigInt lib</td><td class='code'>$l v$c->{lib_version}</td>\n";
      }
    }
  $hash{version} .= "</table>\n";
  
  replace_templates ($self->{tpl},\%hash);

  $self->{tpl};
  }

sub status_server
  {
  # generate HTML statistics about your status
  my $self = shift;

  my %hash;
  foreach (@MY_OBJECTS)
    {
    $hash{$_} = scalar keys %{$self->{$_}} || 0;
    }
 
  # init counts 
  foreach (qw/done suspended running failed tobedone solved/) { $hash{$_} = 0; }
  # update counts
  foreach my $j (keys %{$self->{jobs}})
    {
    my $job = $self->{jobs}->{$j};
    my $f = lc(Dicop::status($job->status()));
    $hash{$f} ++;
    }
  
  $hash{rawpower} = $self->reference_speed();

  replace_templates ($self->{tpl},\%hash);

  $self->{tpl};
  }
 
sub reset_client
  {
  # reset a client
  my ($self,$req) = @_;

  my $client = $self->get_client($req->{id});
  return unless defined $client;
  $client->reset();
  $self->status($req,$client);			# return proper template
  }

sub reset_clients
  {
  # reset all clients
  my ($self,$req) = @_;

  foreach my $id (keys %{$self->{clients}})
    {
    $self->{clients}->{$id}->reset();
    }
  $self->status($req);				# return proper template
  }

sub terminate_clients
  {
  # schedule a termination of all clients
  my ($self,$req) = @_;

  foreach my $id (keys %{$self->{clients}})
    {
    $self->{clients}->{$id}->terminate();
    }
  $self->status($req);				# return proper template
  }

sub terminate_client
  {
  # schedule a termination of one client
  my ($self,$req) = @_;

  my $client = $self->get_client($req->{id});
  return unless defined $client;
  $self->{clients}->{$req->{id}}->terminate();
  $self->status($req,$client);			# return proper template
  }

sub status_clientmap
  {
  # create a colormap of all the clients, denoting with colors their status
  my $self = shift;
  my $req = shift;

  my ($txt,$tpl) = ($self->{tpl}, $self->{tplrow});
  my $width = $req->{width} || 16;

  # build the table line by line
  my $line = ''; my $table = ''; my $cells = 0;
  my $online = 0;
  my $clients = $self->{clients};
  foreach my $item (sort { $a <=> $b } keys %$clients)
    {
    my $i = $clients->{$item};
    $online++ if $i->is_online();
    my $cell = $tpl;
    # must go over item, not line, since line can contain ##self## etc
    foreach (keys %$i)
      {
      $cell =~ s/##($_.*?)##/$i->get_as_string($1)/eg;
      }
    $line .= $cell;
    if ($cells++ >= $width)
      {
      # next line
      $table .= "<tr>$line</tr>\n"; $line = ''; $cells = 0;
      }
    }
  $table .= "<tr>$line</tr>" if $line ne '';
  
  $clients = scalar keys %$clients;
  $$txt =~ s/##online##/$online/g;
  $online = $clients - $online;
  $$txt =~ s/##offline##/$online/g;
  $$txt =~ s/##clientcount##/$clients/g;

  # insert the generated map-table into the template
  $$txt =~ s/##table##/$table/;
  $txt;
  }

sub status_casebyname
  {
  # find a case by it's name
  my ($self,$req,$client,$info) = @_;

  my $name = lc($req->{name});
  my $cases = $self->{cases};
  my $case;
  foreach my $id (keys %$cases)
    {
    $case = $cases->{$id}, last if (lc($cases->{$id}->{name}) eq $name);
    }

  if (!defined $case)
    {
    return $req->{_id} . ' ' . $self->log_msg(430, 'case', 'name', $req->{name});
    }

  # fake a "cmd_status;type_case;id_1234' request
  delete $req->{name};
  $req->{id} = $case->{id};
  $req->{type} = 'case';

  $self->status($req,$client,$info);
  }

sub status_jobresults
  {
  # cmd_status;type_jobresults is really a "job" page in disguise
  my $self = shift;
  my ($req,$client,$info) = @_;

  $req->{type} = 'job';

  $self->status($req,$client,$info);
  }

sub status_proxies
  {
  # create a table of clients, sorted by rank
  my $self = shift;
  $self->status_clients(shift,'proxies');
  }

sub status_clients
  {
  # XXX TODO: replace by call to _gen_table()

  # create a table of clients, sorted by keys, speed, id, online or name
  my $self = shift;
  my $req = shift;
  my $type = shift || "clients";	# for proxies

  my ($txt,$tpl) = ($self->{tpl}, $self->{tplrow});
  
  my $list = ""; my ($line,$i);
  my $hl = $req->{id} || 0; my $bgcolor; 
  my $item_nr = 0;
  # calculate rank, percent etc
  my @things; my $t;
  my $sum = Math::BigInt->bzero();
  foreach my $item (keys %{$self->{$type}})
    {
    $t = {};
    $t->{item}  = $self->{$type}->{$item};	# shortcut
    my $i = $t->{item};
    $t->{keys}  = $i->{done_keys}; 
    $t->{name}  = $i->{name};
    $t->{id}    = $i->{id};
    $t->{speed} = $i->{speed};
    $t->{online} = $i->is_online();
    $sum += $t->{keys};
    push @things,$t; 
    }
  # sort on speed, keys, id, online or name
  my $sort = $req->{sort} || 'speed';
  $sort = 'id' if $type eq 'proxies';
  if ($sort ne 'name')
    {
    @things = sort { (($b->{$sort}||0) <=> ($a->{$sort}||0))
      or $a->{name} cmp $b->{name} } @things;
    }
  else
    {
    @things = sort { $a->{name} cmp $b->{name} } @things;
    }
  my $last = Math::BigInt->bzero();
  my $online = 0;
  foreach my $c (@things)
    {
    $i = $c->{item}; $item_nr++;
    $line = $tpl;
    $line =~ s/##trclass##//g;		# not supported yet
    $line =~ s/##rank##/$item_nr/g;
    $line =~ s/##lost_percent##/0/g;
    $last = $c->{keys} - $last;
    $line =~ s/##done_diff##/$last/g;
    $line =~ s/##done_keys##/$c->{keys}/g;
    my $perc = 0; 
    $perc = $c->{keys} / $sum unless $sum->is_zero();
    $perc = sprintf('%.2f',"$perc" * 100);
    $line =~ s/##done_percent##/$perc/g;
    $last = $c->{keys};
    # must go over item, not line, since line can contain ##self## etc
    foreach (keys %$i)
      {
      $line =~ s/##($_.*?)##/$i->get_as_string($1)/eg;
      }
    $online++ if $i->is_online();
    $list .= $line;
    }
  my $clients = scalar @things;
  $$txt =~ s/##online##/$online/g;
  $online = $clients - $online;
  $$txt =~ s/##offline##/$online/g;
  $$txt =~ s/##clientcount##/$clients/g;

  $$txt =~ s/##table##/$list/;
  $txt; 
  }

sub status_main
  {
  # generate HTML statistics about your status
  my ($self,$req) = @_;

  my %hash;
  foreach (@MY_OBJECTS)
    {
    $hash{$_} = scalar keys %{$self->{$_}} || 0;
    }
  
  foreach (qw/done suspended running tobedone failed/) { $hash{$_} = 0; }
  
  # now generate a joblist and add it below main status
  $hash{joblist} = $self->sorted_job_list($req, \%hash);

  replace_templates ($self->{tpl},\%hash);
  $self->{tpl}; 
  }

sub sorted_job_list
  {
  # generate a sorted joblist as HTML
  my ($self, $req, $hash, $ids) = @_;

  my $filter = { };
  if (defined $req->{filter})
    {
    my @f = split /\s*,\s*/,$req->{filter};
    foreach (@f)
      {
      my $f = Dicop::status_code($_);
      $filter->{$f} = 1 if $f > 0;		# error? ignore it
      }
    }
  else
    {
    # default is only running jobs
    foreach my $f (qw/SOLVED DONE SUSPENDED FAILED/)
      {
      $filter->{Dicop::status_code($f)} = 1; 
      }
    }
  
  my ($jl,$tpl) = $self->read_table_template("job.tpl");
  my $jlist = ""; my $rowtpl = "";
  $ids = $self->{jobs} if !defined $ids;
  foreach my $j (sort { $b <=> $a } keys %$ids)
    {
    my $job = $ids->{$j};
    my $status = $job->status();
    my $f = lc(Dicop::status($status));
    $hash->{$f} ++;

    next if exists $filter->{$status};			# filter out?
    $rowtpl = $tpl; $rowtpl =~ s/##job(\w+)##/$job->get_as_hex($1);/eg;
    $jlist .= $rowtpl;
    }
  $$jl =~ s/##table##/$jlist/;
  $$jl;
  }

sub status_client
  {
  # generate HTML statistics about a client
  my ($self,$req) = @_;

  my $txt = $self->{tpl};
 
  my $client = $self->get_client($req->{id});
  return $client if !ref $client;
 
  foreach (qw/speed_factor/)
    {
    $$txt =~ s/##$_##/$client->get_as_string($_)/eg; 
    }
  my ($text,$tplf) = $self->read_table_template("jobspeed.tpl");
  return if !defined $text;
  my $table = "";
  foreach my $job (sort { $a <=> $b } keys %{$client->{job_speed}})
    {
    my $tpl = $tplf;

    $tpl =~ s/##jobid##/$job/g;
    my $c = $client->{chunks}->{$job} || 0;
    $tpl =~ s/##chunks##/$c/g;

    my $js = $client->{job_speed}->{$job};
    $tpl =~ s/##real_speed##/$js/g;

    my $job = $self->get_object( { type => 'job', id => $job }, 'noerror' );
    next unless $job;

    my $jst = $job->{jobtype}->{speed};
    $jst = $jst->numify() if ref($jst);
    $js = $js->numify() if ref($js);

    $tpl =~ s/##jobtype_speed##/$jst/g;
    my $f = 'unknown';
    $f = int(100 * $js / $jst) / 100 if $jst != 0;
    $tpl =~ s/##factor##/$f/g;
    $table .= $tpl; 
    }
  # merge jobspeed table with it's header 
  $$text =~ s/##table##/$table/;
  $$txt =~ s/##job_speed##/$$text/;

  ($text,$tplf) = $self->read_table_template("failures.tpl");
  return if !defined $tplf;
  $table = "";
  foreach my $jobtype (sort { $a <=> $b } keys %{$client->{failures}})
    {
    my $tpl = $tplf;
    my $f = $client->{failures}->{$jobtype};
    $tpl =~ s/##jobtype##/$jobtype/g;
    $tpl =~ s/##failures##/$f->[0]/g;
    my $ft = $f->[1]; 
    $ft = scalar localtime($ft) if ($ft || 0) != 0;
    $ft = 'never' if $f->[1] == 0;
    $tpl =~ s/##last_failure##/$ft/g;
    $table .= $tpl; 
    } 
  # merge failures table with it's header 
  $$text =~ s/##table##/$table/;
  $$txt =~ s/##failures##/$$text/;

  replace_templates ($txt,$client);
  $txt; 
  }

sub status_charset
  {
  # generate HTML statistics about a specific charset
  my $self = shift;
  my $req = shift;

  my $txt = $self->{tpl};

  my $cs = $self->get_charset($req->{id});
  return if !ref $cs;

  foreach my $k (qw/stringlengths set/)
    {
    $$txt =~ s/##$k##/$cs->get_as_string($k)/eg;
    }

  my $samples = decode($req->{samples} || '');
  my @samples = split /[\r\n]+/, $samples;
  my $valid = ''; my $invalid = '';
  my $set = $cs->charset();		# get Math::String::Charset
  foreach my $sample (@samples)
    {
    chomp($sample);
    $sample = substr($sample,0,32) if length($sample) > 32;
    if ($sample =~ /^0x/)
      {
      $sample =~ s/^0x//;
      $sample = h2a($sample);
      }

    my $str = Math::String->new($sample,$set);
    if ($str->is_nan())
      {
      $invalid .= "'$sample'\n";
      }
    else
      {
      $valid .= "'$sample' (" . $str->as_number() . ")\n";
      }
    }
  $$txt =~ s/##validsamples##/$valid/g;
  $$txt =~ s/##invalidsamples##/$invalid/g;
  $$txt =~ s/##samples##/$samples/g;

  replace_templates ($txt,$cs);
  $txt;
  }

###########################################################################

sub check_auth_request
  {
  # check the auth or info request a client/proxy sent us for basic validity
  # Return ref to $client, or error message 
  my ($self,$req,$rid,$check_proxy) = @_;

  $rid ||= 'req0000';
  $check_proxy ||= 0;
  $rid .= ' ';

  my $id = $req->{id} || 0;
  my $client = $self->get_client($id,'no_error');
  my $proxy;
  if (!ref $client)
    {
    if ($check_proxy != 0)
      {
      # if not found in list of clients, retry as proxy
      $client = $self->get_proxy($id,'no_error');
      if (!ref $client)
        {
        return $rid.$self->log_msg(465,'client or proxy', $id)."\n"; 	# error
        }
      }
    else
      {
      return $rid.$self->log_msg(465,'client', $id)."\n"; 	# error
      }
    }

  # check client's IP/mask against peeraddress  
  my $ip = $self->{peeraddress};

  # in case of an info request from the proxy, check the IP the client sent us
  # against the client IP/MASK (otherwise we would check the proxy IP against
  # the stored client IP)
  $ip = $req->{ip} if $req->is_info();

  my $check = $self->check_peer( $ip, $client->{ip} || '', $client->{mask} || '', $id );

  return $rid . $check if $check;
 
  my $required_version = $self->{config}->{require_client_version} || 0;
  my $required_build = $self->{config}->{require_client_build} || 0;
  $required_version =~ s/[^0-9\.]//g;
  $required_build =~ s/[^0-9\.]//g;
  my ($version,$build) = split /-/, ($req->{version} || '0-0');
  $build = 0 unless defined $build;
  $version = 0 unless defined $version;
  $version =~ s/[^0-9\.]//g; $build =~ s/[^0-9]//g;
  if (($required_version > 0))
    {
    # version looks like: 2.20-6 meaning version 2.20, build 6  
    my $outdated = 0;
    $outdated ++ if $required_version > $version;
    if (($required_build != 0) && ($required_version == $version))
      {
      # check build version
      $outdated ++ if $required_build > $build;
      }
    return 
     $rid.$self->log_msg(452,"$required_version build $required_build")."\n"
     if $outdated;
    }

  my $temp = $req->{temp} || 0;
  my $fan = $req->{fan} || 0;
  my $arch = $req->{arch} || 'unknown';
  my $ok = 0;
  $arch =~ /^(\w+)(-?.*)\z/i;			# match arch-subarch
  my $subarch = lc($2 || ''); $arch = lc($1 || '');
  $subarch =~ s/[^\w-]//;			# allow only a-z0-9-
  foreach my $a (@{$self->{allowed_archs}})
    {
    $ok = 1, last if $a eq $arch;
    }
  $arch .= $subarch;				# "linux-i386-foo" normalized

  return $rid.$self->log_msg(467,$arch)."\n" if $ok == 0; # wrong architecture
  my $os = $req->{os} || 'unknown';
  my $cpuinfo = $req->{cpuinfo} || '';
  my $c = $client->connected($arch,"$version-$build",$os,$temp,$fan,$cpuinfo,Dicop::Base::time(),$req->{reason}||'');

  # error, rate-limit, or terminate
  if (!ref($c))
    {
    return $rid.$self->log_msg($c)."\n";
    }
  $client;						# okay
  }

sub worker_hash
  {
  # Construct worker name from worker_dir, arch, and jobtype, then make hash
  # (or update it) and return it in compact form as 'hash_123456789abcdef'
  # Honour client's sub-arch
  # upon error, return ref to error message
  my ($self, $jobtype, @archs) = @_;

  my $wd = $self->{config}->{worker_dir} || File::Spec->curdir();

  my $w;
  # try first the deepest subdir, then one up and so on
  foreach my $arch (@archs)
    {
    my @dirs = split /-/, $arch; 	# linux-i368 => 'linux', 'i386' => 'linux/i386'
    $w = File::Spec->catfile ($wd, @dirs, $jobtype->{name} || '');
    # for mswin32, also try the .exe variant
    $w .= '.exe' if (!-f $w && -f $w.'.exe');
    last if -f $w;
    }

  # still not existing or directory
  if (!-e $w || !-f $w)
    {
    $w = $self->log_msg(90,$w) . "\n";	# oups not a file, error
    return \$w;
    }
  $self->{worker_hash}->{$w} = Dicop::Hash->new($w)
    unless ref $self->{worker_hash}->{$w};
  my $hash =  $self->{worker_hash}->{$w}->as_hex();
  return \"Couldn't hash file '$w': $hash\n" if ref($hash);

  # Include the worker name for the client, but without the worker dir (the
  # client will add it's own worker dir)
  $w =~ s/^$wd\///;
  
  # Remove also the first arch dir:
  # worker/linux/i386/foo/test => i386/foo/test
  # worker/linux/test => test
  $w =~ s/^.*?\///;

  "hash_$hash;worker_$w;";
  }

sub hash
  {
  # make hash from target file (or target data if given a scalar ref) and
  # return it in compact form as '123456789abcdef'
  # upon error, return ref to error message
  my ($self,$filename,$hash, $data) = @_;

  $hash = 'target' unless $hash;

  # ref($data) means the data is in memory in $$data instead in a file
  if (!ref($data) && (!-e $filename || !-f $filename))
    {
    my $error = $self->log_msg(91,$hash,$filename,$!);		# oups error
    return \$error;
    }

  $hash .= '_hash';

  if (ref($data))
    {
    # since the contents of $$data can have changed, but the Hash module
    # will not detect this, we clear our old hash
    delete $self->{$hash}->{$filename};
    }
  else
    {
    $data = $filename;			# hash disk file
    }

  $self->{$hash}->{$filename} = Dicop::Hash->new($data)
    unless ref $self->{$hash}->{$filename};
  $self->{$hash}->{$filename}->as_hex();
  }

sub hash_file
  {
  # find file, hash it, return request for client to download this file,
  # or error if file cannot be found or hashed
  my ($self,$file,$hashname,$type) = @_;

  $type ||= 101;
  my $hash = $self->hash($file,$hashname); 
  if (ref($hash))
    {
    # something went wrong, and since we need that file absolutely, call the
    # client's requests all off with an "internal error, retry later" msg
    my $txt = "req0000 Error on hashing '$file': $$hash\n" .
              'req0000 ' . msg(500) . "\n";
    return $txt;                              		# forget this
    }
  'req0000 ' . msg($type,$hash,$file) . "\n";  		# client: U need this!
  }

sub request_work
  {
  # client requested work, so give it to him
  my ($self,$req,$client,$info,$debug) = @_;

  my $params = msg(301);			# default: no work for now
  return "$req->{_id} $params\n" if $self->jobs() == 0;		# no jobs!

  my ($proxy,$msg);			# if client came via proxy
  ($proxy,$client,$msg) = $self->_client_from_info($req,$client,$info);
  return $msg if defined $msg;		# error

  my $random = rand(); my $txt = "";
  my $percent = abs(int($self->{config}->{minimum_rank_percent} || 0))/100;

  my $cfg = $self->{config};
  # add the additional file(s) to the list of files to be downloaded by client
  my $file = $cfg->{charset_definitions} || '';
  $txt .= $self->hash_file($file) if $file ne '';

  my $tries = 0;
  my ($job,$chunk);
  my $last_job = 0;
  my $found = 0;			# found work?
  while ($tries++ < 16)			# try 16 times to find work
    {
    if ($random < $percent)
      {
      $job = $self->adjust_job_priorities($random);
      # found one; if we need retry it, and next time select one at random
      $random = $percent+1;	
      }
    else
      {
      # just take any job
      $job = $self->get_random_job();
      }
    next unless ref $job;
    if ($last_job != 0)
      {
      # not the same job again
      next if ($job->{id} == $last_job);
      }
    $txt .= "req0000 099 checking job $job->{id} (last was $last_job)\n"
     if defined $debug ;
    $last_job = $job->{id};
    my ($cnt,$time) = $client->failures($job->{jobtype}->{id});
    if ($cnt > 2) 				# if too many failures
      {
      $txt .= "req0000 099 too many failures ($cnt)\n" if defined $debug;
      # if too long ago
      if (Dicop::Base::time() - $time > $self->{resend_test})
        {
	# send testcase(s) again to client to see if it is now fit
        $txt .= "req0000 099 resending test\n" if defined $debug;
	$txt .= $self->request_test($req,$client,$info,$job->{jobtype}->{id});
	$found = 1;
        }
      next;					# try another job
      }

    # check that we have a worker for the client first, to avoid creating
    # unnec. chunks in the job
    # assumes client's arch was sent correctly and updated
    my $par = $self->worker_hash($job->{jobtype}, $client->architectures());
    # can't find worker for this job and this architecture, so try another
    if (ref($par))
      {
      $txt .= "req0000 $$par" if defined $debug;	# sent error msg
      $found = 1;
      next;
      }

    # ok, now try to find chunk if we found job
    $txt .= "req0000 099 find chunk in job $job->{id}\n" if defined $debug;
    my $s = $job->status();				# note status
    my $size = $req->{size} || 5;
    $size = $cfg->{min_chunk_size} if $size < $cfg->{min_chunk_size};
    $size = $cfg->{max_chunk_size} if $size > $cfg->{max_chunk_size};
    # find chunk
    my $chunk = $job->find_chunk($client,a2h(random(128)),$req->{size});
    if (($s != $job->status()) && ($job->status() == DONE))
      {
      # job got closed because no more open chunks
      my $reason = 'stopped'; $reason = 'closed' if $job->results() == 0;
      $self->email($reason,undef, $job);		# send mail
      $self->_send_event('job_failed', $job)
	if $reason eq 'stopped';		# create event if necc.
      $job->status(FAILED);
      $self->log_msg(751,$job->{id},$client->{id});
      }	
    # didn't find chunk in this job, so try another
    next unless ref $chunk;			
    
    $txt .= "req0000 099 found id $chunk->{id} size $chunk->{_size}\n"
     if defined $debug;

    # In some cases we need to write a chunk description file (CDF) and send
    # this over instead of a chunk. This routine also checks nec. files and
    # hashes them:

    my ($type,$cdf,$cdfname) = $self->description_file ($job, $chunk, $req->{_id});
    my $jj = $job->{jobtype};

    # "$cdf" contains the response to the client (even if $type == undef)
    $txt .= $cdf;

    if (defined $type)
      {
      # some error occured
      return $cdf unless $type > 0;

      # handle type 101 and 112 here:
      if ($type == 102 || $type == 112)
	{
	# CDF
	$par .= "chunkfile_$cdfname;";
	$par .= "token_$chunk->{token};";
	}
      else
	{
	# JDF
	$par .= "job_$job->{id};";	
	$par .= "chunk_$chunk->{id};";

	# nec. information
	$par .= "token_$chunk->{token};";
	$par .= 'start_' . $chunk->get_as_hex('start').';';
	$par .= 'end_' . $chunk->get_as_hex('end').';';
        $par .= "target_". encode($job->get('target')).";";
        $par .= 'set_' . encode($cdfname).';';
	}
      }
    else
      {
      # all other cases: create normal chunk and send it as msg 200
      # optional information
      $par .= "job_$job->{id};";	
      $par .= "chunk_$chunk->{id};";

      # nec. information
      $par .= "token_$chunk->{token};";
      $par .= "start_".$chunk->get_as_hex('start').';';
      $par .= "end_".$chunk->get_as_hex('end').';';
      $par .= "target_". encode($job->get('target')).";";
      $par .= "set_$job->{charset}->{id};";
      }

    # if the job or jobtype requires extra files to send to the client:
    $txt .= $self->extra_files($job, $client->architectures());

    $params = $self->log_msg(200,$par);
    $txt .= "req0000 099 chunk size " . $chunk->get('size') . "\n"
     if defined $debug;
    $found = 1;
    last;	# found job, all is well
    } # end while tries
  if ($found == 0)
    {
    # Just no work for client? So send a pristine message to him
    $txt = "$req->{_id} $params\n";
    }
  else
    {
    # send debug output, even though we might have no work (missing worker?)
    $txt .= "$req->{_id} $params\n";
    }
  $txt;
  }
    
sub extra_files
  {
  my ($self,$job, @arch) = @_;

  my $response = '';

  my @files = $job->extra_files(@arch);
  foreach my $file (@files)
    {
    $response .= $self->hash_file(
      File::Spec->catfile('target', @$file),
      'target');
    }
  @files = $job->{jobtype}->extra_files(@arch);
  foreach my $file (@files)
    {
    $response .= $self->hash_file(
      # worker/linux/someworkerfile
      File::Spec->catfile('worker', @$file),
      'worker');
    }
  $response;
  }

sub _client_from_info
  {
  my ($self,$req,$client,$info) = @_;

  my $proxy;

  if (defined $info && ref($info) && ($info->is_info()))
    {
    $proxy = $client;
    $client = $self->get_client($info->{id});
    if (!ref $client)
      {
      # error
      return (undef,undef, "$req->{_id} ".$self->log_msg(465,$info->{id})."\n");
      }
    }
  ($proxy,$client);
  }

sub request_test
  {
  # client requested test cases, so send him all or only ones for a specifiy
  # jobtype
  my ($self,$req,$client,$info,$jobtype) = @_;
  $jobtype = $jobtype || 0;

  my ($proxy,$msg);			# if client came via proxy
  ($proxy,$client,$msg) = $self->_client_from_info($req,$client,$info);
  return $msg if defined $msg;		# error

  my $txt = "";
  my $cfg = $self->{config}; my $file = $cfg->{charset_definitions} || '';
  # send client a message to check/update this file
  $txt .= $self->hash_file($file) if $file ne '';

  foreach my $tc (sort { 
   $self->{testcases}->{$b}->{jobtype}->{id} <=> 
   $self->{testcases}->{$a}->{jobtype}->{id} }
    keys %{$self->{testcases}})
    {
    my $t = $self->{testcases}->{$tc};
    
    # only tests for this jobtype 
    next if $jobtype > 0 && $t->{jobtype}->{id} != $jobtype;

    # only tests that are not disabled
    next if $t->{disabled};

    # assumes client's arch was sent correctly and updated
    my $par = $self->worker_hash($t->{jobtype},$client->architectures());
    if (ref $par)
      {
      $txt .= "$req->{_id} $$par";	# error, hash would be invalid
      next;
      }
    
    # In some cases we need to write a chunk description file (CDF) and send
    # this over instead of a chunk. This routine also checks for nec. files
    # and hashes them.

    my ($type,$cdf,$cdfname) = $self->description_file ($t, undef, $req->{_id});
    my $jj = $t->{jobtype};
    # "$cdf" contains the response to the client (even if $type == undef)
    $txt .= $cdf;

    if (defined $type)
      {
      # some error occured
      return $cdf unless $type > 0;

      # handle type 101 and 112 here:
      if ($type == 102 || $type == 112)
        {
        # CDF
        $par .= "chunkfile_$cdfname;";
        # XXX TODO: send MD5 hash of random data to not tell client this is a testcase
        $par .= 'token_2;';
        }
      else
        {
        # JDF
        $par = "job_test-$t->{id};$par";

        # nec. information
        $par .= "start_".$t->get_as_hex('start').";";
        $par .= "end_".$t->get_as_hex('end').";";
        $par .= "target_" . encode($t->get('target')).";";
	
        # dummy value
        $par .= 'chunk_2;';
        # XXX TODO: send MD5 hash of random data to not tell client this is a testcase
        $par .= 'token_2;';
        $par .= 'set_' . encode($cdfname).';';
        }
      }
    else
      {
      # all other cases: create normal chunk and send it as msg 200
      # optional information
      $par = "job_test-$t->{id};$par";

      # nec. information
      $par .= "start_".$t->get_as_hex('start').';';
      $par .= "end_".$t->get_as_hex('end').';';
      $par .= "target_" . encode($t->get('target')).";";
      # dummy value
      $par .= "chunk_2;";
      # XXX TODO: send MD5 hash of random data to not tell client this is a testcase
      $par .= 'token_2;';
      $par .= "set_$t->{charset}->{id};";
      }

    # if the testcase/jobtype requires extra files to be send to the client:
    $txt .= $self->extra_files($t,$client->architectures());

    $txt .= "$req->{_id} 200 $par\n";
    }
  $txt;
  }

sub report
  {
  # client want's to report work or test case result
  my ($self,$req,$client,$info) = @_;

  my ($proxy,$msg);			# if client came via proxy
  ($proxy,$client,$msg) = $self->_client_from_info($req,$client,$info);
  return $msg if defined $msg;		# error
  
  my ($job,$chunk);

  my $crc = $req->{crc} || 0;
  my $code = 203; my $txt = "";
  if ($req->{job} =~ /^test/)
    {
    $code = 409;		# default: failed
    # server should note what was send to client and use this instead of
    # relying on what client sends back
    $req->{job} =~ /-([0-9]+)$/; my $id = $1 || 0;
    my $tc = $self->get_testcase($id) unless $id == 0;
    if (ref($tc))
      {
      # client reported test case with valid jobtype
      # found correct result or failed the right tests?
      my $tcr = a2h($tc->{result} || '');
      my $res = $req->{result}; $res = '' unless defined $res;

      if ($tcr ne '')
        {
        $code = 204 if ($req->{status} eq 'SOLVED') && ($tcr eq $res);
        $self->log_msg(701, $id, 'SOLVED', $tcr, $req->{status}, $res) unless $code == 204;
        }
      else
        {
        $code = 204 if ($req->{status} eq 'DONE') && ($res eq '');
        $self->log_msg(701, $id, 'DONE', '', $req->{status}, $res) unless $code == 204;
        }
      }
    else
      {
      # no such test job
      return "$req->{_id} " .$self->log_msg(410,$id). "\n"
      }
    # if test failed: increment failure counter
    if ($code == 409)
      {
      $client->count_failure($tc->{jobtype}->{id},3);	# failed
      $client->store_error(Dicop::Base::time(),$req->{reason}||'');
      }
    else
      {
      $client->count_failure($tc->{jobtype}->{id},0);	# success, reset count
      }
    }
  else
    {
    # test what client delivered
    return "$req->{_id} " . $self->log_msg(408,$req->{status}). "\n"
     if $req->{status} !~ /^(FAILED|DONE|SOLVED|TIMEOUT)$/i;
    $job = $self->get_job($req->{job});
    return "$req->{_id} " . $self->log_msg(401,$req->{job}). "\n"
     unless defined $job;
    $chunk = $job->get_chunk($req->{chunk});
    return "$req->{_id} " . $self->log_msg(402,$req->{chunk},$job->{id}). "\n"
     unless defined $chunk;
    return "$req->{_id} " . $self->log_msg(403,$req->{token}). "\n"
     if $chunk->{token} ne $req->{token};
    return "$req->{_id} " . $self->log_msg(405). "\n"
     unless $chunk->{status} == ISSUED;
    return "$req->{_id} " . $self->log_msg(404,$client->{id}). "\n"
     unless $chunk->{client}->{id} == $client->{id};
    my $status = Dicop::status_code($req->{status});
    return "$req->{_id} " . $self->log_msg(416). "\n"
     if $status == DONE && (($req->{result}||'') ne '');
    
    $self->log_msg(750,$req->{result}||'', $chunk->{id}, $job->{id})
      if $status == SOLVED;			# log all SOLVED reports
   
    # my $cjs = $client->{job_speed}->{$job->{id}};
    my $keys = $chunk->size();				# addition correct
    # for TIMEOUT (and SUCCESS) calculate how many keys client really did
    # not yet SUCCESS, happens seldom and poses problems
    my $border = $chunk->start();
    if ($status == TIMEOUT)
      {
      $border = Math::String->new(h2a($req->{result}),$chunk->charset());
      if ($border->is_nan())
        {
	# result isn't a valid math string
        return "$req->{_id} " . $self->log_msg(406,$req->{result},$job->{id}). "\n";
        }
      if ($border <= $chunk->start() || $border >= $chunk->end())
        {
	# result isn't between start/end
        return "$req->{_id} " . $self->log_msg(406,$req->{result},$job->{id}). "\n";
        }
      # Split chunk at absolute pos (and don't round border up, but only down)
#      my $new_chunk = $chunk->split($req->{result});
#      if (!defined $new_chunk)
#        {
#        # split failed, couldn't split at border
#        return "$req->{_id} " . $self->log_msg(406,$req->{result},$job->{id}). "\n";
#        }
      $keys = 0;	 # for now don't split
#      $keys = $chunk->size();		# first split up part, how many done?
      }

    # let the client object handle the report. This will set the chunk to
    # some status (DONE, SOLVED, FAILED, TIMEOUT, VERIFY or BAD).

    my $cfg = $self->{config};
    # needed_done, needed_solved      
    my ($new_status,$rc,$msg) =
      $chunk->verify($client, $status, $req->{result}||'',
       $crc, $cfg->{verify_done_chunks}, $cfg->{verify_solved_chunks}, 
	$req->{reason} || '');
    # store errors especially for bad chunks
    $client->store_error(Dicop::Base::time(),$req->{reason}||'');
      
    if ($new_status == BAD)
      {
      if ($rc < 0)
        {
        # couldn't add verifier
        $msg = "$rc $msg";
        $self->log_msg(700,$msg);
	# send mail
        $self->email('verify_error',undef, $job,$chunk,$client, undef, $msg);
        }
      else
        { 
        $self->email('bad_result',undef,  $job,$chunk,$client);	# send mail
        }
      # don' clear the list, so that admin can still see the verifier list for
      # bad chunks
      # the chunk will stay BAD until it is converted to TOBEDONE later on
      $chunk->status(BAD);
      $code = 414;
      $code++ if ($status == SOLVED);				# msg 415
      return "$req->{_id} " . $self->log_msg($code). "\n";
      }
    
    # BAD chunks are not reported to the job or client (no point)
 
    $client->report($job,$chunk,$req->{took},$keys,$status);

#      $txt .= "req0000 099 client speed after: $client->{speed} (job: "
#           .  "$cjs->[0] / $cjs->[1])\n";
  
    if ($req->{job} =~ /^test/)
      {
      # XXX TODO
      # don't report for test jobs
      print STDERR "trying to report testcase $req->{job}\n";
      }

      $proxy->report($job,$chunk,$req->{took}) if defined $proxy;
      $job->report_chunk($chunk,$req->{took});
      

#      $txt .= "req0000 099 client speed prev: $client->{speed} (job: "
#           .  "$cjs->[0] / $cjs->[1])\n";
#    $cjs = $client->{failures}->{$job->{jobtype}->{id}};
#      $txt .= "req0000 099 client failure counter: ",
#      $cjs->[0]||'undefined',"\n";

    # chunk might be VERIFY (for both DONE or SOLVED reports), so use request
    $code = 201 if $req->{status} eq 'DONE';

    #########################################################################
    # check for events that occured:

    # job finished, but no result?
    if (($code == 201) && ($job->status() == DONE || $job->status() == FAILED))
      {
      my $reason = 'stopped';
      $reason = 'closed' if $job->results() == 0 || $job->status() == FAILED;
      $self->email($reason,undef, $job,$chunk,$client);		# send mail
      $self->_send_event('job-failed', $job)
	if $reason eq 'stopped';		# create event if necc.
      $job->status(FAILED);
      }
#    Dicop::Event::logger('logs/debug.log',"$chunk->{id} $chunk->{status} ".$chunk->get_as_hex('start')." ".$chunk->get_as_hex('end')." $chunk->{issued}");
    # found result? (regardless whether we stopped job or not)
    if ($chunk->status() == SOLVED)
      {
      my ($res,$result) = $self->add_result($job,$client,$req);
      $txt .= "\nreq0000 099 add result: $res\n";
      $code = 202;
      # include client owner if requested
      $self->email('result',undef, $job,$chunk,$client,$result)	# send mail
	if defined $result;					# no dupes
      $self->_send_event('found_result', $job, $result)	# create event if
	if defined $result;					# no dupes
      # start a new job with result of old as target?
      if ($job->{newjob})
        {
	my $r = 'cmd_add;type_job';
        $r .= ";start_".a2h($job->{'newjob-start'});
        $r .= ";end_".a2h($job->{'newjob-end'});
        $r .= ";haltjob_" . $job->{'newjob-haltjob'};
        $r .= ";case_" . $job->{case}->{id};			# same case
	my $d = $job->{'newjob-description'} || '';
	$d =~ s/##description##/$job->{description}/;
        $r .= ";description_$d";
	$d = $job->{'newjob-rank'}; $d =~ s/##rank##/$job->{rank}/;
	$d =~ s/[^0-9]+//; $r .= ";rank_$d";
        $r .= ";charset_".$job->{'newjob-charset'}->{id};
        $r .= ";jobtype_".$job->{'newjob-jobtype'}->{id};
        $r .= ";target_$req->{result}";
	# and now add job to ourself
        $self->add( 
         Dicop::Request->new ( id => 'req0001', data => $r, patterns => $self->{request_patterns} ), 
	  { user => $job->{owner} }, {}, 'no_result_needed' );

        } 
      $self->flush(); 		# force a data flush
      } # end found result
    # in case of TIMEOUT, we need now to split chunk to mark first part as done
    if ($status == TIMEOUT)
      {
      # XXX TODO (see also chunk->verify() and above)
      }
    # now try to merge chunk with others
    $job->merge_chunks($job->get_chunk_nr($chunk->{id}))
     if ($chunk->{status} == DONE);
    }
  return "$req->{_id} " .$self->log_msg($code,$job->{id},$chunk->{id}). "\n"
   . $txt;
  }

#############################################################################
# event handling

sub output
  {
  # called by _connect_server
#  print STDERR @_,"\n";
  }

sub _sleeping
  {
  # called by _connect_server
  }

sub _die_hard
  {
  # called by _connect_server
  }

sub _create_event
  {
  my ($self, $event_name, $job, $result) = @_;

  my $cfg = $self->{config};

  # check for a valid event name 
  return unless $event_name && $event_name =~ /^(job_failed|found_result|new_job)\z/; 

  my $url = $cfg->{send_event_url_format} || '';

  # if no URL defined, return
  return unless $url;

  # load the event text
  my $event = $self->read_template( 'event/' . $event_name . '.txt');

  return unless ref $event;
  
  $event = $$event;

  ###########################################################################
  # replace templates
    
  my $time = scalar localtime(Dicop::Base::time());
  
  $url =~ s/##localtime##/$time/g;
  $event =~ s/##localtime##/$time/g;

  my ($charset,$case);
  if (defined $job)
    {
    $url =~ s/##job(id|description|name|start|startlen|end|endlen|owner|target)##/ encode($job->get_as_string($1))/eg;
    $url =~ s/##job(jobtype|case|charset)##/ encode($job->{$1}->{id})/g;
    $event =~ s/##job(id|description|name|start|startlen|end|endlen|owner|target)##/$job->get_as_string($1)/eg;
    $event =~ s/##job(jobtype|case|charset)##/$job->{$1}->{id}/g;
    $case = $job->{case};
    $charset = $job->{charset};
    }
  if (ref $result)
    {
    $url =~ s/##(result_ascii|result_hex)##/ encode($result->get_as_string($1))/eg;
    $event =~ s/##(result_ascii|result_hex)##/$result->get_as_string($1)/eg;
    $url =~ s/##result_len##/length($result->get_as_string('result_ascii'))/eg;
    $event =~ s/##result_len##/length($result->get_as_string('result_ascii'))/eg;
    }
  if (ref $case)
    {
    $url =~ s/##case(id|description|referee|name)##/ encode($case->get_as_string($1))/eg;
    $event =~ s/##case(id|description|referee|name)##/$case->get_as_string($1)/eg;
    }
  if (ref $charset)
    {
    $url =~ s/##charset(id|description|name)##/encode($charset->get_as_string($1))/eg;
    $event =~ s/##charset(id|description|name)##/$charset->get_as_string($1)/eg;
    }

  # url will not be valid if it still contains templates
  return if $event =~ /##.*##/;
  
  # insert encoded event txt into url
  $event = encode($event);
  $url =~ s/##eventtext##/$event/;
  
  # url not valid if it still contains templates
  return if $url =~ /##.*##/;

  $url;
  }

sub _send_event
  {
  # send one event via the event_url defined in the config
  my $self = shift;

  my $url = $self->_create_event(@_);		# create URL and text
  return unless defined $url;

  my $res = $self->_connect_server($url); 	# send url and return response

  if (!$res->is_success())
    {
    print STDERR "Error on sending event url '$url': ",
	         $res->code(), ' ', $res->message(), "\n";
    }
  }

sub _replace_mail_templates
  {
  my ($self,$message, $job,$chunk,$client,$result,$rc) = @_;
  my $c = $self->{config};
 
  # mail_XXX are also inserted in the body, if nec.
  my $names = { chunk => $chunk, client => $client, result => $result,
    charset => $job->{charset}, jobtype => $job->{jobtype},
    errorcode => $rc || 'unknown error',
    name => $c->{name},
    };

  # include these only if the message is about a chunk (result found etc)
  if (defined $chunk)
    {
    $names->{verifierlist} = $chunk->dump_verifierlist();
    $names->{chunkstart} = $chunk->{start};
    $names->{chunkend} = $chunk->{end};
    $names->{chunkstatus} = uc(Dicop::status($chunk->{status}));
    $names->{chunkid} = $chunk->{id};
    }

  foreach my $name (keys %$names)
    {
    next unless defined $names->{$name};        # skip undefined values
    if (ref($names->{$name}))
      {
      # if $c->{name} is an object
      $$message =~ s/##$name(.+?)##/$names->{$name}->get_as_hex($1)||'';/eg
      }
    else
      {
      # if $c->{name} is a string
      $$message =~ s/##$name##/$names->{$name}/g;
      }
    }

  # replace job after jobtype
  $$message =~ s/##job(.+?)##/$job->get_as_hex($1)||'';/eg if defined $job;
  }

sub read_dictionaries
  {
  # create a list of usable dictionaries and return it as array ref
  my ($self) = @_;

  my $list = {};
  my $dir = File::Spec->catdir ( 'target', 'dictionaries' );

  # return silently nothing to avoid swamping of error log with errors for
  # non-existing dictionaries
  opendir DIR, $dir or return [];
  # crumble ("Can not read dir $dir: $!") and return $list;
  my @files = readdir DIR;
  closedir DIR;
 
  foreach my $file (@files)
    {
    my $f = File::Spec->catfile($dir,$file);
    next unless -f $f;
    next unless $file =~ /\.md5$/;		# only checksum files
    # open checksum file, and read in dict name and checksum

    # if it cannot be read, skip it
    my $check = read_list ( $f );
    next unless ref($check) eq 'ARRAY';
    my $data = {};
    foreach my $line (@$check)
      { 
      chomp($line);
      my ($var,$val) = split /\s*=\s*/, $line;
      $var = lc($var);
      $var =~ s/^\s*//; $val =~ s/\s*$//;
      $val =~ s/^"//; $val =~ s/"\s*$//;
      $data->{$var} = $val;
      }
    
    # hash the corrosponding dictionary file. By putting it into dict_hash
    # we can re-use the hash later on when sending it to the client.
    my $dict_file = File::Spec->catfile($dir,$data->{file}||'');

    my $hash = $self->hash( $dict_file ,'dict');

    if (ref($hash))
      {
      crumble ($hash); next;
      }

    # hash in checksum file does not match hash of actual file:
    if ($self->{dict_hash}->{$dict_file}->as_hex() ne $data->{md5})
      {
      crumble ("Checksum in $file does not match hash of $data->{file}.");
      next;
      }

    # Good one, so keep it 
    $list->{$data->{file}} = $data->{description} || $data->{file};
    }
  $list;
  }

1; 

__END__

#############################################################################

=pod

=head1 NAME

Dicop::Data -- contains all the jobs (with chunks), proxies, testcases, clients etc

=head1 SYNOPSIS

	use Dicop::Data;

	$data = Dicop::Data->new();

	$job = $data->get_job(5);	# return the job object #5
	$job->get_chunk(3);		# get the chunk w/ id 3 from this job

See C<dicopd> and C<dicopp> on how to use this.

=head1 REQUIRES

perl5.005, Dicop::Base, Dicop::Item, Dicop::Data::Charset, Dicop::Data::Job, 
Dicop::Data::Charset::Dictionary, Dicop::Data::Client, Dicop::Data::Proxy,
Dicop::Request, Dicop::Data::Result, Dicop::Data::Chunk,
Dicop::Data::Group, Dicop::Data::User, Dicop::Data::Jobtype,
Dicop::Data::Case, Dicop::Data::Testcase, Dicop::Item, Dicop::Config,
Dicop::Client, Dicop::Security, Mail::Sendmail, Dicop::Event, Time::HiRes,
Dicop::Files, File::Spec

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

Upon creating such an object, the server locks a file and reads it's data
into memory. Upon destroying the object, the lock is released and possible
changes are written back to the disk. From time to time the modified data
is written back to the disk.

For each client-connect an extra file is locked to prevent from multiply
client-connects to interfere with each other. This lock is released after
the response was sent to the client.

All the data is read immidiately, but only written back if changed or a
certain time period has passed.

=head1 METHODS

=head2 get_job, get_proxy, get_charset, get_jobtype, get_testcase, get_result, get_client, get_group

Given an ID, return the appropriate object.
	
	print $self->get_proxy(1);		# get proxy w/ id 1

=head2 jobs/proxies/charsets/jobtypes/testcases/results/groups/clients

Return the appropiate number of objects.

	print $self->proxies();		# how many proxies do I know

=head2 get_object

	$object = $data->get_object( { type => 'proxy', id => 123 }, $noerror );

General case of the get_foo() methods. Does not throw an error if C<$noerror>
is true, this can be used to check for the existance of an object with a 
certain type and ID.

=head2 get_highest_priority()

Find the job with highest priority and return it.

=head2 adjust_job_priorities()

For all running jobs calculate their job priority and store them, returns
a job that matches a minimum priority.

=head2 del_user(), del_charset(), del_job(), del_client(), del_group()

Check if we can delete this object, and if so, remove any references to the
object in question. Returns an error message if the deletion is not possible,
otherwise undef.

=head2 cfg_default()
  
Given a set of keys and their values (a list or hash reference),
sets these values as default in the internal cfg object, unless
the key is already defined there.

=head2 check()

Applies self-check on startup and crumbles if errors in data structure are
present.

=head2 parse_requests()

This parses the form parameters as send by the client (via GET/PUT) and breaks
them into requests. It then sorts the requests into groups and returns
references to these groups (as arrays):

	($auth,$info,$reports,$requests,$forms) = $self->parse_requests();

=head2 handle_requests()

Takes the returned request groups from L<parse_requests> and handles them after
some basic checks, like for maximum number of requests, existing
authentication etc.

This also prints the result back to the client on STDOUT.
  
=head2 hash_file()

	$self->hash_file($file, $optional_hash_name);

Find a file, hash it and return a message for the client to download this file.
Upon error, returns the proper error response to the client.

Uses L<hash()> internally.

=head2 hash()

	$self->hash($file);
	$self->hash($file,'target');
	$self->hash($file,'dict');

	$self->hash($filename,'dict', \"file data");

Make a hash from a file and return it in compact form as
something like C<123456789abcdef>. Upon errors like the file not being
found or unreadable, a reference to the error message is returned.

The second optional parameter is the name of the hashkey were to put the file
hash.

The three-arg form uses the data stored in the third argument as the
actual file contents without reading the file from disk. The filename
is still used to store the hash under a unique key.

=head2 worker_hash()

Construct the worker name from config's worker_dir, arch (as sent by client),
and the requested jobtype. It then makes or updates the hash for that worker
executable and returns it in compact form as 'hash_123456789abcdef'.

Upon error, it returns a ref to an error message.

This is used by both L<request_work> and L<request_test>.

=head2 log_msg()

Return a message string by number, along with embedded parameters. Works just
like Event::msg, but it also logs the message to a logfile, depending on
C<log_level> and the message code.

Typical usage:

  	$self->log_msg(430,$type,'id',$id);
  
=head2 _create_event()

	$self->_create_event( $event_name, $job);
	$self->_create_event( $event_name, $job, $result);
	
Examples:

	$self->_create_event( 'job_failed', $job);

=head2 email()

Prepare an email with an announcement by reading in a template text, completing it
with the actual informations and then putting the email into the send queue.

Typical call:
  
	$self->email($type,$cc, $job,$chunk,$client,$result, $rc);

C<job>, C<chunk>, $<client> and C<result> can be undefined and will be skipped
then (they do not make sense for every email template). C<type> is the name
of the actual mail template without path and extension. C<cc> contains the
address(es) to Cc: on the mail.

=head2 chunk_list
  
Create a table of all chunks of one job from an HTML template. See also
L<check_list()>.

=head2 check_list()

Create a table of all the chunks in the checklist of one job from an HTML
template. See also L<chunk_list()>.

=head2 job_list()

Create a table of all the jobs belonging to a certain case from an HTML
template. See also L<chunk_list()>.

=head2 sorted_job_list

Used by L<status_main()> and L<job_list()> (indirectly via L<status_case()>)
to generate a sorted and filtered list of jobs.

=head2 check_clients()

This checks all clients for whether they are still online (aka returning
results) or went offline. For each client no longer online, an email will be
sent to the administrator using appropriate template (e.g. "offline.txt").

Will return a hash which keys are the id's of the clients that went offline.
That is used by the testsuite.

=head2 reference_speed()

Calculate the entire cluster speed base on the reference client. Returns a
integer number that represents the count of "reference clients" the cluster
has.

=head2 speed()

Calculates the speed of the cluster for a particulary job in keys/s. In list
context returns speed and average speed per client.

This considers only the clients that were active in the given timeframe. Will
also skip clients that failed to often, or never worked on a chunk before. The
returned speed is corrected by the percentage of the job, e.g a job that
currently 10% of the cluster speed will return only 1/10 of it's current speed
value.

	$self->speed($job->id(),3600*6);	# consider last 6 hours

=head2 report()

Client want's to report work or test case result, so check the result in.

=head2 request_file()

The client requested us to tell him one or more URIs for a particular file.

=head2 request_work()

Client requested work from us, so try to find a suitable chunk and give it to
him.

=head2 request_test()

Client requested test cases (or server determined it was time to send the
tests to the client again), so send him all or only the testcases for a
specifiy jobtype.

=head2 status_chunks()
  
Create as HTML output a table of all open chunks across all jobs.

=head2 help()

Create as HTML output either a help overview page (type eq 'list') or a help
page to a certain topic (type is the topic name).

=head2 status_clients()

Create as HTML output a status page about all the clients, sorted by their
speed, name, keys done so far, id or online status.

=head2 terminate_clients

	$self->terminate_clients();

Flags all clients so that upon next connect they will terminate immidiately
and can be restarted by the outer client script, effectively forcing an
upgrade of all clients.

=head2 reset()

	$self->reset($request);

Returns a template (reset.txt) telling the user that the reset of an item was
successfully. Called by C<reset_client>.

=head2 reset_client()

	$self->reset_client($request);

Resets a client and then calls C<$self->reset()> to return a template.

=head2 reset_clients()

	$self->reset_clients($request);

Resets all clients and then calls C<$self->reset()> to return a template.

=head2 status_clientmap()

Create as HTML output a table showing a small colored field for each client,
denoting their online or offline status.

=head2 status_proxies()

Create as HTML output a status page about all the proxies, sorted by their
speed, name, keys done so far, id or online status.

=head2 status_main()

Create as HTML output a status page about one the main server status, e.g.
the list of running (or other combinations, like suspended + done) jobs.

=head2 _flush_data()

This writes the data back to disk.

=head2 _clear_email_queue()

	$self->_clear_email_queue();

Delete everything in the email send queue. Mainly used by the testsuite.

=head2 flush_email_queue()
  
Tries to send all mails in the queue, and return the number of mails
successfully sent. This is called outside the code that handles a client
request, so that the client does not need to wait until all the emails are
sent.

This routine will also put all to-be-sent emails into a logfile.

=head2 _search()

Searches the database and then returns a list of all matches.

=head2 get_random_job()

Get one of the running jobs at random. Returns undef if no jobs are in the
running state.

=head2 write_charsets_def()

See L<Dicop::Files|Dicop::Files>.

=head2 description_file()

See L<Dicop::Files|Dicop::Files>.

=head2 type()

	$data->type();

Return the type of the server as string, e.g. either 'server' or 'proxy'.

=head2 search()

Generate the list of search results via L<_search()> and return an HTML
page with these results.

=head2 status_config()

Generate an HTML page showing all the current configuration settings.

=head2 status_server()
  
Generates the "detailed status" page and contains statistics about our status,
the running time, connects/request counters etc.

=head2 read_template()

Read a 'normal' template file from the template dir, honouring styles (e.g.
the latter override the general templates). Inside the template text, includes
file via C<##include_filename.inc##>.

Returns the 'finished' template, ready to be filled with data.

=head2 read_table_template()

Works just like L<read_template()>, except that it looks for an embedded table
template via C<< <!-- start --> >> and C<< <!-- end --> >> and generates
both the normal template text and a template for one row of the embedded table.

This also honours styles and includes files vi C<##include_filename.inc##>.

=head2 add_result()

Add a result to our result-list.

=head2 add_item()
  
Add an item to server's in-memory database.

=head2 add_clients()
 
	$self->add_clients ($request, $client, $info_request);
 
Add a range of clients to the server. Called by C<add()>, and then itself calls
C<add()> in turn for each client to be added.

=head2 add()
	
	$self->add ($request, $client, $info_request, $no_template);

Creates and adds one item to the in-memory database. Returns a template
filles with the fields of the newly created item. Returns an error if the
item could not be constructed or added.

If the last parameter C<no_template> is defined, no template will be loaded
from disk, instead the return value will be the ID of the added object.

=head2 insert_object()

Insert an object with all it's parameters into a HTML template, e.g. fills
the template with the fields from the object.

=head2 confirm()

Generate an HTML form that asks for confirmation of deletion of some object.

=head2 _include_template()

Find C<##include_filename.inc##> inside a template and include the file there.

=head2 read_dictionaries()

Creates a list of all available dictionary files so that they can be inserted
into the HTML form for adding a dictionary charset. Returns a hash reference
mapping filenames to their descriptions.

=head2 check_auth_request()

Check the auth or info request a client/proxy sent us for basic validity.
Returns either a ref to the client/proxy referenced by the auth request, or an
error message.

=head2 del()

Really deletes an object from the database after the confirmation was sent in.

=head2 del_item()

Check whether we can really delete an item from the server's
in-memory database. If not, return error message, otherwise delete item.

=head2 status_charset()

Create a HTML status page with the details of a specific character set.

=head1 BUGS

See the L<BUGS> file for details.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

