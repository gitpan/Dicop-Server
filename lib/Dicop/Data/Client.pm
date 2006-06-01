############################################################################
# Dicop/Data/Client.pm - a client in the distributed system
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Client;
use vars qw($VERSION);
$VERSION = 1.04;	# Current version of this package
require  5.005;		# requires this Perl version or later

use base qw(Exporter Dicop::Item);
use strict;

use Dicop::Base qw/decode/;
use Dicop qw( MAX_FAILED_AGE MAX_ISSUED_AGE FAILED DONE SOLVED TIMEOUT );
use Math::BigFloat;

sub _MAX_CONNECTS () { 24; }
sub is_proxy () { 0; }

#############################################################################
# private, initialize self 

sub _init
  {
  my ($self,$args) = @_;
 
  $self->{done_keys} = Math::BigInt->bzero();
  $self->{lost_keys} = Math::BigInt->bzero();
  $self->{done_chunks} = 0;
  $self->{lost_chunks} = 0;
  $self->{failed_chunks} = 0;
  $self->{uptime} = 0;
  $self->{last_connect} = 0;			# never
  $self->{last_chunk} = 0;			# never
  $self->{connects} = '';			# list of times between two c.
  $self->{online} = 0;				# currently offline
  $self->{chunk_time} = 0;			# time between two connects
  $self->{send_terminate} = 0;			# flag: false, don't send stop
  $self->{arch} = '';
  $self->{last_error} = 0;			# never
  $self->{last_error_msg} = '';			# none yet

  $self->SUPER::_init($args,$self);
  $self->SUPER::_default( {
    job_speed => { },
    failures => { },
    chunks => { },
    cpuinfo => [ '',0 ],
    }, $self );
  
  $self->{max_failed_age} = 
    3600 * ( $args->{max_failed_age} || MAX_FAILED_AGE );
  $self->{max_issued_age} = 
    3600 * ( $args->{max_issued_age} || MAX_ISSUED_AGE );
  }

sub _construct
  {
  my $self = shift;

  $self->{group} = $self->{_parent}->get_group($self->{group}) unless ref $self->{group};
  $self->{connects} = [ split (/,/,$self->{connects}) ]
   if !ref($self->{connects});
  
  $self;
  }

#############################################################################
# public stuff

sub put
  {
  my ($self,$var,$data) = @_;
 
  if ($var =~ /^(done_keys|lost_keys)/)
    {
    $data = Math::BigInt->new($data||0);
    }
  if ($var =~ /^(chunks|failures|job_speed)$/)
    {
    my @array = split /,/,$data;
    $data = {};
    foreach (@array)
      {
      my @d = split /_/,$_; my $job = shift @d;
      # chunks and job_speed: 1 entry, failures 2 entries
      $d[0] ||= 0;
      $d[1] = $d[1] || $d[0] || 1;
      if ($var eq 'failures')
        {
        # format of failures:
	#		  count, time
        $data->{$job} = [ $d[0], $d[1] ];
        }
      else
        {
	# chunks and job_speed store only one value
        $data->{$job} = $d[0];
        }
      }
    }
  if ($var =~ /^(connects|cpuinfo)$/)
    {
    $data = [ split(/,/,$data) ];	# 987654321,9876543340, ...
					# AMD,350
    }
  if ($var eq 'trusted')
    {
    $data = 0 if (!defined $data) || ($data eq '');
    $data = 1 if $data ne '0';
    }
  $self->{$var} = $data;
  }

sub _fix_job_speeds
  {
  # Go through the job_speeds table and fix it up.
  # If the optional jobtype is defined, speed for this jobtype will
  # be reset - this is used after changing the speed of a jobtype
  my ($self,$jobtype) = @_;
 
  $jobtype ||= 0;				# undef => 0

  foreach my $jobid (keys %{$self->{job_speed}})
    {
    my $job = $self->{_parent}->get_job($jobid);
    # if job does not exist any more (should not happen), delete entry
    delete $self->{job_speed}->{$jobid} and next if !defined $job;

    my $js = $job->{jobtype}->{speed};

    my $cjs = $self->{job_speed}->{$jobid};
    # if current speed not defined, assume it equals the jobtype speed
    $self->{job_speed}->{$jobid} = $js if 
      (($cjs || 0) <= 1) ||			# jobtype speed not defined
      ($jobtype == $job->{jobtype}->{id});	# given jobtype matches
    }
  $self->modified(1);				# is modified just in case
  $self->speed_factor();
  }

###############################################################################

sub terminate
  {
  my $self = shift;

  # flag client, so that on next connect() it will get a disconnect message
  $self->{send_terminate} = 1;
  $self;
  }

sub store_error
  {
  my ($self,$time,$error) = @_;

  if ($error ne '')
    {
    # store the error message (max 4kb) the client send us
    $self->{last_error} = $time;
    $self->{last_error_msg} = substr($error,0,4096);
    }
  }

sub connected
  {
  # this client connected, so update certain fields
  my $self = shift;
  my $arch = shift || 'unknown';
  my $version = shift || 'unknown';
  my $os = shift || 'unknown';
  my $temp = shift || 0;
  my $fan = shift || 0;
  my $cpuinfo = shift || 'unknown CPU,0';
  my $time = shift || Dicop::Base::time(); 
  my $error = shift || '';
  
  $self->{last_connect} = $time;
  $self->{version} = $version;
  $self->{os} = $os;
  $self->{arch} = $arch;
  $self->{fan} = $fan;
  $self->{temp} = $temp;
  $self->{cpuinfo} = [ split(/,/, $cpuinfo) ];
  $self->store_error($time,$error) if $error ne '';
  
  if ($self->{send_terminate} != 0)		# send stop signal?
    {
    $self->{send_terminate} = 0;		# but only once
    return 463;					# yup, signal error
    }

  # keep last 24 connects
  my $c = $self->{connects};
  # only store the connect when it has advanced in timeline (or is the first)
  push @$c,$self->{last_connect} 
    if @$c == 0 || $c->[-1] < $self->{last_connect};

  @$c = splice (@$c, - _MAX_CONNECTS(), _MAX_CONNECTS) if scalar @$c > _MAX_CONNECTS;
  $self->{chunk_time} = 0;
  if (@$c > 1)
    {
    my $t = $c->[-1] - $c->[0]; $t = 0 if $t < 0;
    $self->{chunk_time} = int($t / (scalar @$c - 1));
    }

  $self->modified(1);

  if ($self->rate_limit())
    {
    pop @$c;			# remove last connect so that it doesn't count	
    return 302;			# signal error
    }
  $self;			# okay
  }

sub rate_limit
  {
  my $self = shift;

  # rate-limit client to no more than one per 2.5 minutes
  return ((@{$self->{connects}} > (_MAX_CONNECTS-2)) && ($self->{chunk_time} < 60));
  }

sub discard_job
  {
  # a certain job in the server is closed, so discard any cached information
  # about it
  my $self = shift;
  my $job = shift;

  delete $self->{job_speed}->{$job};
  delete $self->{chunks}->{$job};
  $self->modified(1);
  }

sub failures
  {
  # return number of failures for a given jobtype, in list context return
  # number of failures and time of last failure
  my ($self,$jobtype) = @_;

  $jobtype = 0 if !defined $jobtype;
  my $fc = $self->{failures}->{$jobtype};
  $fc->[0] = 0 if !defined $fc->[0];	# no counter yet?
  $fc->[1] = 0 if !defined $fc->[1];	# no date yet?
  wantarray ? ($fc->[0], $fc->[1]) : $fc->[0];
  }

sub reset
  {
  # reset job_speed, average speed, delete failure counters etc
  my $self = shift;

  $self->{job_speed} = { };
  $self->{connects} = [ ];
  $self->{failures} = { };
  $self->{speed} = Math::BigFloat->new(100);
  $self->{last_error} = 0;
  $self->{last_error_msg} = '';
  $self->modified(1);
  }

sub job_speed
  {
  # return your speed for a given job or calculate it from defaults
  my ($self,$job,$jobspeed) = @_;

  if (!defined $self->{job_speed}->{$job})
    {
    $self->{job_speed}->{$job} 
      = int(Math::BigFloat->new($self->{speed}) * $jobspeed / 100);
    # no need to call speed_factor() here, since $self->{speed} won't change
    }
  $self->{job_speed}->{$job};
  }

sub count_failure
  {
  # given a job number, increment the failure counter for this job
  # if increment is zero, the counter will be reset
  my $self = shift;
  my $jobtype = shift;
  my $inc = shift||0;

  $self->{failures}->{$jobtype} = [ 0, 0 ]
   unless ref ($self->{failures}->{$jobtype});
  my $fc = $self->{failures}->{$jobtype};
  if ($inc != 0)
    {
    $fc->[0] += $inc;			# inc counter
    $fc->[1] = Dicop::Base::time();	# remember time	
    }
  else
    {
    $fc->[0] = 0;			# reset counter
    $fc->[1] = 0;			# forget time
    }
  }

sub report
  {
  # this client reported work back, so check it in
  my $self = shift;
  my $job = shift;
  my $chunk = shift;
  my $took = shift;	# time in seconds it took to calculate
  # keys done by client (not chunk->size() for TIMEOUT or SOLVED)
  my $done = shift || 0;
  my $status = shift || $chunk->status();
 
  $self->{last_chunk} = shift || Dicop::Base::time(); 
  if ($status == FAILED)
    {
    $self->{failed_chunks} ++;
    $self->count_failure($job->{jobtype}->{id},1);
    }
  else # DONE, SOLVED, TIMEOUT
    {
    $self->{done_keys} += $done;
    $self->{done_chunks} ++;
    $self->{chunks}->{$job->{id}} ++;
    $self->{uptime} += $took;
    }
  $self->adjust_speed($done,$took,$job->{id},$status);
  $self->modified(1);
  $self;
  }

sub adjust_speed
  {
  my ($self,$size,$took,$jobid,$status) = @_;

  # no correct for failed or succeded chunks
  return if $status == FAILED || $status == SOLVED;

  # should not be undef since is set when handing out work
  my $spd = Math::BigFloat->new($self->{job_speed}->{$jobid} || 100);
  my $factor = 1;
  if ($status == TIMEOUT)
    {
    # if timeout, reduce to << 0.5 otherwise maxsize will be the same, and
    # client might grab a chunk of roughly the same size (and fail) again	
    $factor = 0.2;
    }
  elsif (($size > 26) && ($took < 60) && ($took > 0)) 
    {
    # very small chunks increase the client speed slightly
    # the reason is that otherwise a client with a speed too low would never
    # increase it's speed for that job. OTOH increasing here by factor 2 would
    # mean that the clients speed would shoot up when it encounters a small
    # junk (maybe an end of job, or a left-over chunk from a much slower
    # client)
    $factor = 1.2;
    $factor = 1.5 if $took < 5;
    }
  # $size and $took must be some sensible values
  elsif (($size > 26) && ($took > 60)) 
    {
    # calculate new speed value
    # average of last speed + new speed
    my $new = ($spd + Math::BigFloat->new($size)/$took)/2;
    # calculate and limit factor to 0.2 .. 2
    $factor = $new/$spd;		# same as new/(old*2) + 0.5
    $factor = $factor->numify();
    $factor = 0.5 if $factor < 0.5;
    $factor = 2 if $factor > 2;
    }
  # correct speed for job
  if ($factor != 1)
    {
    my $t = $spd * $factor;
    $self->{job_speed}->{$jobid} = $t->as_number();	# to BigInt
    $self->speed_factor();
    }
  $self->{speed};
  }
  
sub speed_factor
  {
  # calc average speed factor based on jobtype's and client's current speed
  my $self = shift;

  my $speed = Math::BigFloat->bzero(); my $i = 0;
  foreach my $s (keys %{$self->{job_speed}})
    { 
    my $js = $self->{job_speed}->{$s};
    $js = 0 unless defined $js;

    next if $js == 0;					# not any work yet

    my $job = $self->{_parent}->get_job($s); 		# ask parent for job
    next if !ref($job);					# not existing
    next unless $job->is_running(); 			# finished/stopped

    my $jobtypespeed = $job->{jobtype}->{speed} || 0;	# speed from jobtype
    next if $jobtypespeed == 0;				# still no job speed?

    my $jt = $job->{jobtype}->{id};

    $self->{failures}->{$jt} = [ 0, 0 ] if
     !exists $self->{failures}->{$jt};

    my $fc = $self->{failures}->{$jt};
    next unless $fc->[0] < 3;				# too many failures

    $speed += Math::BigFloat->new($js)->bdiv($jobtypespeed);
    $i++;
    }
  $self->{speed} = Math::BigFloat->new(100)
   if ($self->{speed} || 0) == 0;			# if not yet defined
  return if $i == 0;					# should not happen
  $self->{speed} = int(100*$speed/$i);			# store factor as MBI
  }

sub punish
  {
  # The client tried to report a chunk, but the result or checksum differed
  # from what another client previously reported. So "punish" it for this.
  my ($self, $pain) = @_;

  # does nothing yet
  # XXX TODO
  $self;
  }

sub lost_chunk
  {
  # the client failed to deliver a chunk after a certain time (it probably
  # went offline), so update his stats
  my $self = shift;
  my $chunk = shift;

  $self->{lost_keys} += $chunk->size();
  $self->{lost_chunks} ++;
  $self->modified(1);
  $self;
  }

sub went_offline
  {
  # tell whether client went offline, reset went_offline
  my $self = shift;

  my $t = $self->{went_offline};	# only once == 1	
  $self->{went_offline} = 0;		# forget what happened
  $t;
  }

sub is_online
  {
  # test whether client is too long offline
  my $self = shift;
  my $ago = shift || return $self->{online};

  my $now = shift || Dicop::Base::time();
  if (($now - $self->{last_chunk}) > $ago)
    {
    if ($self->{online} != 0)
      {
      $self->{online} = 0;		# from online to offline
      $self->{went_offline} = 1;	# remember what happened
      $self->modified(1);
      }
    return 0;				# offline
    }
  if ($self->{online} == 0)
    {
    $self->{online} = 1;		# online
    $self->{went_offline} = 0;		# forget that we were offline
    $self->modified(1);
    } # else already online
  1;
  }

sub get_as_hex
  {
  my $self = shift;
  my $key = lc(shift||"");
  return localtime ($self->{$key}) if ($key eq 'last_chunk');
  
  $self->get_as_string($key);
  }

sub get_as_string
  {
  # return a field of yourself as plain string (stringify passwords/numbers)
  # return "" for non-existing fields
  my $self = shift;
  my $key = lc(shift||"");

  my $time = Dicop::Base::time();

  if ($key eq 'last_connectcolor')			# fake key
    {
    # never connected?
    return 'nocon' if $self->{last_connect} == 0;
    # connected, but did not yet return?
    return 'noreturn' if $self->{last_chunk} == 0;
    return 'online' if $time - $self->{last_connect} < 3600;
    return 'unknown' if $time - $self->{last_connect} < 2*3600;
    return 'offline';
    }
  if ($key eq 'last_chunkcolor')			# fake key
    {
    # never connected?
    return 'nocon' if $self->{last_connect} == 0;
    # connected, but did not yet return?
    return 'noreturn' if $self->{last_chunk} == 0;
    return 'online' if $time - $self->{last_chunk} < 3600;
    return 'unknown' if $time - $self->{last_chunk} < 2*3600;
    return 'offline';
    }
  if ($key eq 'last_connect')
    {
    return 'Never connected' if $self->{last_connect} == 0;  
    return Dicop::Base::ago($time - $self->{last_connect}) . ' ago';
    }
  if ($key eq 'last_chunk')
    {
    return 'Never connected' if $self->{last_connect} == 0;  
    return 'Never reported back' if $self->{last_chunk} == 0;  
    return Dicop::Base::ago($time - $self->{last_chunk}) . ' ago';
    }
  if ($key eq 'chunk_time')
    {
    return Dicop::Base::ago($self->{chunk_time});
    }
  if ($key eq 'cpuinfo')				# fake key
    {
    return "$self->{cpuinfo}->[0], " .
      int($self->{cpuinfo}->[1] || 0) .
      " MHz";
    }
  if ($key eq 'uptime')
    {
    return Dicop::Base::simple_ago($self->{uptime});
    }
  if ($key eq 'group')
    {
    return "$self->{$key}->{id} ($self->{$key}->{name})";
    }
  # fake key speed_factor
  if ($key eq 'speed_factor')
    {
    my $s = $self->{speed}; $s = $s->numify() if ref($s) =~ /^Math::Big/;
    return sprintf ("%.2f",$s / 100);
    }
  if ($key eq 'last_error_msg')
    {
    # decode the error message for HTML display
    my $msg = decode($self->{$key});
    # encode some HTML entities to avoid the error message messing with
    # the user's browser (this should also kill all scripts etc)
    $msg =~ s/&/&amp;/;
    $msg =~ s/</&lt;/;
    $msg =~ s/>/&gt;/;
    return $msg;
    }

  $self->SUPER::get_as_string($key);
  }

sub architectures
  {
  # return the architectures we belong to. {arch} can be something like
  # "linux-i386" and a client with that belongs to 'linux-i386' and 'linux',
  # so generate both
  my $self = shift;

  my @archs = split /-/, $self->{arch};
  my @client_archs = ();
  while (scalar @archs > 0)
    {
    push @client_archs, join('-', @archs);
    pop @archs;
    }
  @client_archs;
  }

1;

__END__
#############################################################################

=pod

=head1 NAME

Dicop::Data::Client - a client in the L<Dicop|Dicop::Dicop> system.

=head1 SYNOPSIS

    use Dicop::Data::Client;

=head1 REQUIRES

perl5.005, Exporter, Dicop::Server, Dicop::Data, Math::Bigfloat

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

For a description of fields a client has, see C<doc/Objects.pod>.

=head1 METHODS

=head2 architectures()

	my @archs = $client->architectures();
  
Returns the architectures the client belong to. C<{arch}> can be something like
"linux-i386" and a client with that belongs to 'linux-i386' and 'linux', so this
would return a list of ('linux-i386', 'linux').

=head2 went_offline()

Returns 0 for no, and 1 for yes. Returns only one time 1, then returns 0
until the client goes offline again.

=head2 is_online()

Given a time in seconds, test whether client did a connect in that timeframe.
If yes, return 0 (client is online) or 1 (client offline).

=head2 is_proxy()

Return true if the client is a proxy. False for normal clients.

=head2 lost_chunk

Client failed to report back for a chunk, so update his stats.

=head2 reset()

	$client->reset();

Reset the clients statistics, like job speed, average speed, and
delete failure counters etc.

=head2 discard_job()

A job on the server is done/suspended/closed so the client can discard cached
information (notebly the speed value). This is necc. to avoid huge cache
growths.

=head2 adjust_speed()

	my $speed = $client->adjust_speed($size, $took, $jobid, $status);

Adjusts the speed factor of the job on this client, taking
into account the size of the chunk (in keys), the time it took to
complete (in seconds) and the status (failed or timeout?).

=head2 speed_factor()

Recalculate the average speed factor from the different job speeds.

=head2 count_failure()

Increment the failure counter for a given jobtype. If given increment is zero,
the counter will be reset.
    
	$self->count_failure($jobtype,2);	# inc by 2
	$self->count_failure($jobtype,0);	# reset

=head2 failures()

Return number of failures (the so-called failure score) for a jobtype. For
each FAILED chunk the score is raised by 1, and for each FAILED testcase the
score is raised by 3. If this this score is greater than 2, the client will be
denied work for this particular jobtype.

The counter will be reset when the client successfully finishes all testcases
for that jobtype. This is forced after 6 hours by sending the client the
appropriate testcases if the failure counter is too high. Alternatively a
restart of the client will reset the counter, since the client will request
and work on all testcases.

=head2 store_error()

	$client->store_error( $time, $error_text);

Given a time stamp and an error message, stores these two to
display them on the GUI later.

=head2 punish()

	$client->punish($pain);

The client tried to report a chunk, but the result or checksum differed from
what another client previously reported. So "punish" it for this. Trusted
clients are imune to this, while untrusted ones get their "health" decreased,
until they "die". "Dead" clients are no longer able to work in the cluster,
which is the entire idea behind this punishment setup.

Clients that are trusted are know to be deliver always good results (barring
hardware failures, which can be detected by known testcases), while untrusted
clients are unknown for their quality. By punishing the untrusted ones and
leaving the trusted ones alone, each untrusted client caught cheating will
get punished and the result from it will be thrown away.

Idially, the first attempt to deliver a faulty result will also put the client
into the suspicious group, which means it absolutely *must* verify the work
with a trusted client and *must* succeed in doing so. Only then it is put
back in the "untrusted" group.

=head2 job_speed()

Return a clients speed for a given job in keys/s. In case this is not defined,
calculates the speed from it's onw average speed and the given default speed
for the jobtype based on the following formula:

	$jobspeed = $client_speed * $jobtype_speed / 100;

=head2 report()

Client reported back work, so update his stats, recalculate speed value etc.

=head2 connected()

Client connected, update his stats.

=head2 rate_limit()

	return if $self->rate_limit();

Returns true if the client's rate limit was reached, meaning no more connects
are allowed at the current time.

=head2 terminate()

	$client->terminate()

Flags the client, so that on next connect the client get's a C<terminate now>
signal, which causes the client to stop. If the client is started by a
script running in an endless-loop, this script will download the newest
client and retry. So this is effecitvely a forced client-uopdate.

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

