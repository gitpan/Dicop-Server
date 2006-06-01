############################################################################
# Dicop/Data/Job.pm - a job in the distributed system
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Job;
use vars qw($VERSION);
$VERSION = 1.07;	# Current version of this package

use base qw(Dicop::Item);
use strict;

use Dicop qw(DONE SOLVED ISSUED TOBEDONE FAILED SUSPENDED TIMEOUT BAD VERIFY);

use Dicop::Data::Chunk;
use Dicop::Data::Chunk::Checklist;
use Math::BigFloat lib => 'GMP';
use Math::String;
use Dicop::Event qw/crumble/;
use Dicop::Base qw/h2a a2h write_file ago simple_ago encode/;

my $HUNDRED = Math::BigFloat->new(100);		# constant to speed up math

#############################################################################
# private, initialize self 

sub _init
  {
  my ($self,$args) = @_;

  $self->SUPER::_init($args,$self);
  $self->{created} = Dicop::Base::time();
  $self->{modified} = $self->{created};

  $self->SUPER::_default( {
    _secret => 0,
    }, $self );
 
  # store them as hex until they are converted to Math::String objects
  $self->{start} = a2h($self->{start}) if $args->{ascii};
  $self->{end} = a2h($self->{end}) if $args->{ascii};
  if ($args->{'newjob-ascii'})
    {
    $self->{'newjob-start'} = a2h($self->{'newjob-start'}); 
    $self->{'newjob-end'} = a2h($self->{'newjob-end'});
    }
 
  $self->{lastchunk} = 0;			# id
  $self->{runningfor} = 0;			# seconds we are working on job
  $self->{last_chunk} = $self->{modified};	# when was last chunk returned
  $self->{chunks} = 0;				# number of done chunks
  $self->{results} = 0; 			# number of results
  $self->{_chunks} = undef;			# chunk list not there yet
  $self->{status} = TOBEDONE;
  $self->{priority} = 0;
  $self->{_last_chunk_age_check} = 0;
  $self->{_first_tobedone} = undef;		# not defined from start
  $self->{_find_chunk_steps} = 0;		# debug counter
  $self->checklist_empty();			# no entries in checklist yet
  $self->{owner} = $args->{owner} || 'unknown';
  $self->{_modified} = 0;
  $self;
  }

sub _construct
  {
  # after new, and some presetting by Data.pm, we are ready to fully construct
  # ourself:
  my ($self,$args) = @_;

  $self->{imagefile} = '' unless defined $self->{imagefile};
  $self->{dictionary} = '' unless defined $self->{dictionary};
  $self->{prefix} = '' unless defined $self->{prefix};
  $self->{charset} = $self->{_parent}->get_charset($self->{charset}) 
    unless ref $self->{charset};

  # A '-1' signals we should use the "addcase-XXX" fields and add a new case
  if ($self->{case} eq '-1')
    {
    my $params = {};
    foreach my $k (qw/name description referee url/)
      { 
      $params->{$k} = $self->{"addcase-$k"};
      }
    # if it doesn't already exist, add case and set case_id to our case
    $self->{case} = $self->{_parent}->_add_case( $params );
    }
  # no longer need these
  foreach my $k (qw/name description referee url/)
    {
    delete $self->{'addcase-' . $k};
    }

  $self->{case} = $self->{_parent}->get_case($self->{case}) 
    unless ref $self->{case};

  warn ("Case $self->{case} undefined") unless ref($self->{case});
 
  if ($self->{charset}->type() eq 'extract')
    {
    # if charset needs to extract strings from image, clone it
    $self->{charset} = $self->{charset}->copy();
    # and give it the name of the image file
    $self->{charset}->image_file_name( $self->{imagefile} );
    }
  else
    { 
    $self->{charset}->dirty();
    }

  # start and are like this "string,1234", or like this "string"
  # so convert them to objects, if possible
  $self->{_error} = 
   $self->{charset}->check_strings ($self, qw/start end/);
  return if $self->{_error}; 

  $self->{jobtype} = $self->{_parent}->get_jobtype($self->{jobtype})
    unless ref $self->{jobtype};

  # check that the minlen of the jobtype is honoured
  my $minlen = $self->{jobtype}->get('minlen');

  # not for wordlist or extract, these are always one character long
  if ($minlen != 0 && ($self->{charset}->type() !~ /^(dictionary|extract)$/))
    {
    foreach my $key (qw/start end/)
      {
      if ($self->{$key}->length() < $minlen)
        {
        $self->{_error} = 
          "minimum length from jobtype is $minlen, but $key is only "
          . length($self->{$key}) . ' characters long';
        }
      }
    }

  $self->{end} = $self->{start} if $self->{end} < $self->{start};
  if ($self->{end} == $self->{start})
    {
    $self->{_error} = 
      "job $self->{id} start $self->{start} not smaller than end $self->{end}" and
     return;
    }
 
  # XXX TODO: our template could do this for us 
  $self->{newjob} = '' if $self->{newjob} !~ /^on$/i;
  $self->{haltjob} = '' if $self->{haltjob} !~ /^on$/i;
  $self->{checkothers} = '' if $self->{checkothers} !~ /^on$/i;

  if ($self->{newjob})
    {
    # newjob: rank and description will be replaced on creating the new job
    $self->{'newjob-charset'} = 
     $self->{_parent}->get_charset($self->{'newjob-charset'}) 
      unless ref $self->{'newjob-charset'};
    $self->{'newjob-charset'}->dirty();
    $self->{'newjob-jobtype'} = 
      $self->{_parent}->get_jobtype($self->{'newjob-jobtype'})
      unless ref $self->{'newjob-jobtype'};

    my $cs = $self->{'newjob-charset'};
    $self->_from_string_form($cs, 'newjob-start','newjob-end');

    $self->{'nowjob-end'} = $self->{'newjob-start'}
     if $self->{'newjob-end'} < $self->{'newjob-start'};
    if ($self->{'newjob-end'} == $self->{'newjob-start'})
      {
      $self->{_error} = 
       "newjob start $self->{'newjob-start'} not smaller than newjob end $self->{'newjob-end'}";
      return;
      }
    }

  if (!defined $args->{chunks})
    { 
    # no chunks gicen by caller

    # if we already have an (old) chunklist, keep this
    if (!defined $self->{_chunks})
      {
      # create two chunks (one done as first, another tobedone), 
      my $chunk = new Dicop::Data::Chunk ( 
        id => $self->new_chunk_id(), 
        start => $self->{start},
        end => $self->{start},
        status => DONE,
        job => $self,
        _secret => $self->{_secret},
        _parent => $self->{_parent},
        );
      my $chunk_end = new Dicop::Data::Chunk ( 
        id => $self->new_chunk_id(), 
        start => $self->{start},
        end => $self->{end},
        status => TOBEDONE,
        job => $self,
        _secret => $self->{_secret},
        _parent => $self->{_parent},
        );
      $chunk->_construct();
      $chunk_end->_construct();
      $self->{_chunks} = [ $chunk, $chunk_end ];	# We Are The Chunkians...
      }
    }
  else
    {
    $self->{_chunks} = $args->{chunks};
    }

  $self->_convert_target() if ($self->{_error} || '') eq '';
  $self->_adjust_size();
  }

sub _convert_target
  {
  # convert target from file name to bytes using 'script' from jobtype
  # if target is not path to target file (*.tgt) or hex-bytes and we have a
  # script, use this to convert target
  my $self = shift;
  my $type = shift || '';

  $self->{target} = '' if !defined $self->{target};
  $self->{target} =~ s/^\s+//;		# strip spaces at front
  $self->{target} =~ s/\s+$//;		# strip spaces at end

  # remove constructs like "/./" and "../target"
  $self->{target} =~ s#/./##g;			# strip "/./"
  $self->{target} =~ s#^../target#target#g;	# ^../target => ^target

  my $s = $self->{jobtype}->{script} || '';
  my $rc = '';

  # XXX TODO: check for chroot() and warn, since this is likely not going to
  # work in conjunction with external scripts (especially not Perl scripts)

  # if we have a script and the target is a file not ending in .tgt
  if ($s ne '' && (-f $self->{target}) && ($self->{target} !~ /\.tgt$/))
    {
    # untaint $s
    $s =~ /^([a-zA-Z0-9]+)$/;
    $s = ($self->{_parent}->{config}->get('scripts_dir') || 'scripts') . "/$1";
    if (-e $s)
      {
      my $t = $self->{target}; 
      if ($t !~ /^([a-zA-Z0-9\.\/\\_:,+ -]+)$/)
        {
        $self->{_error} = "Bad characters in filename '$t'";
        return $self;	# so that $self->check() fails and job is not added
        }
      $t = $1;		# extract untainted target value
      $t =~ s/\.\.//g;	# remove '..'
      delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};   # Make %ENV saf
      # untaint PATH from ENV
      $ENV{'PATH'} = '/bin/:/usr/bin/';

      my $extra = $self->extra_params();

      #########################################################################
      # exec the script
      # "script targetfile JOBID EXTRAPARAMS" or 
      # "script targetfile testTESTCASEID EXTRAPARAMS"
      $rc = `$s "$t" "$type$self->{id}" "$extra"`;

      my $exit_value  = int($? / 256);
      my $signal_num  = $? & 127;
      my $dumped_core = $? & 128;

      if ($exit_value != 0)
	{
        $self->{_error} = "Could not run script '$s \"$t\"': $! (exit code ($exit_value)\n";
	$rc = '';
        }
      else
        {
        # XXX TODO: use a generic routine for this
        $rc =~ s/&/&amp;/g;             # web-safe
        $rc =~ s/</&lt;/g;              # web-safe
        $rc =~ s/>/&gt;/g;              # web-safe

        $self->{script_output} =
	 "Result from script '$s' for '$t':<PRE>$rc</PRE>\n";
        if ($rc !~ /Target: ["'](.*?)["']/i)
          {
          $self->{_error} = "script '$s $t' did not"
	   ." return proper target information, run manually and cut & paste the"
	   ." output. Output was: <pre>\n$rc</pre>";
          }
        else
          {
          $self->{target} = $1;
          }
        }
      }
    else
      {
      $self->{_error} = "script '$s' not found, can't convert target file to hash.";
      }
    }
  }

sub new_chunk_id
  {
  # generate a new, unique chunk ID for that job. The lowest possible IDs must
  # be > 0, hence the preincrement.
  my $self = shift;
  ++$self->{lastchunk};
  }

#############################################################################
# public stuff

sub percent_done
  {
  # return percentage of already done keys (e.g. 1 for 1%)
  my $self = shift;
  my $round = shift || -2;              # round result?

  my $sum = $self->size();
  return Math::BigFloat->bzero() if $sum->is_zero();

  my $done = Math::BigInt->bzero();
  foreach my $c (@{$self->{_chunks}})
    {
    next if $c->status() != DONE;
    $done->badd($c->size());
    }

  # round to $round digits after the dot ($round < 0) or with a fixed number of
  # digits ($round > 0)
  $done = Math::BigFloat->new($done->bmul($HUNDRED));		# * 100
  my ($a,$p) = (undef,$round);
  if ($round > 0)
    {
    ($a,$p) = ($round,undef);
    }
  $done->bdiv(Math::BigFloat->new($sum),$a,$p);
  }

sub keys_todo
  {
  # return number of keys still to do as Math::BigInt
  my $self = shift;

  my $todo = Math::BigInt->bzero();
  foreach my $c (@{$self->{_chunks}})
    {
    $todo->badd($c->size()) if $c->status() != DONE;
    }
  $todo;
  }

sub keys_done
  {
  # return sum of already done chunks
  my $self = shift;
 
  my $done = Math::BigInt->bzero();
  foreach my $c (@{$self->{_chunks}})
    {
    $done->badd($c->size()) if $c->status() == DONE;
    }
  $done;
  }

sub merge_chunks
  {
  # Merge two consecutive chunks if they both have the status DONE
  # This keeps the chunklist small.
  my $self = shift;
  my $nr = shift; $nr = -1 if !defined $nr;

  my $chunks = $self->{_chunks};			# shortcut
  crumble ("$self\::merge: chunk $nr does not exist"), return 0 
   if $nr < 0;
  crumble ("$self\::merge: chunk $nr does not exist"), return 0 
   if !defined $chunks->[$nr];
  return 0 unless $chunks->[$nr]->status() == DONE;	# huh?
 
  # 0,1,2,3,4,5,6
  # x   x x   x		x = done (case 2 & 3 = DONE should not happen, but we
  #                     guard against it in any case
  #         x           4 becomes done
  # 0,1,2,3,4,6		5 is merged into 4
  # x   x x x 
  # 0,1,2,3,6		4 is merged into 3
  # x   x x  
  # 0,1,2,6		3 is merged into 2
  # x   x 		merging ends now since neither 1 nor 6 are done 

  my $merged;				# stop merging if there are no more
  my $merge_count = 0;			# will usually not be >2
  do
    {
    my $two = $nr + 1; $merged = 0;
    if ($two < @$chunks)		# try next one
      {
      # try to merge the latter into the former, so that when we delete $nr, 
      # the smaller id is keept
      if ($chunks->[$two]->status() == DONE)
        {
        $chunks->[$nr]->merge($chunks->[$two]);
        # now delete second chunk ($two)
        splice @$chunks,$two,1;
	$merged++; $merge_count ++;
        # if first_tobedone > than first chunk number, decrese it.
        # example: (merge 3 and 4 together, first points to [x])
        # before: 0 1 2 3 [4] 5 6 | 0 1 2 [3] 4 5 6 | 0 1 2 3 4 [5] 6
        # after:  0 1 2 [3] 5 6   | 0 1 2 [3] 5 6   | 0 1 2 3 [5] 6
        $self->{_first_tobedone} --
          if ((defined $self->{_first_tobedone}) &&
              ($self->{_first_tobedone} > $nr));
        }
      }
    $two = $nr; $nr--;
    if ($nr >= 0)			# try previous one
      {
      if ($chunks->[$nr]->status() == DONE)
        {
        $chunks->[$nr]->merge($chunks->[$two]);
        # now delete second chunk ($two, former nr)
        splice @$chunks,$two,1;
	$merged++; $merge_count ++;
        $self->{_first_tobedone} --
          if ((defined $self->{_first_tobedone}) &&
              ($self->{_first_tobedone} > $nr));
        }
      else
        {
        $nr++;			# previous is not DONE, so try again next one
        }
      }
    } while ($merged > 0);	# unless in one go we did not merge something
  $self->modified(1) if $merge_count > 0;
  # if only one chunk is left, it must have status of DONE and the job failed
  if (@$chunks == 1)
    {
    $self->status(FAILED);
    }
  $merge_count;
  }
    
sub _restrict_chunksize
  {
  my $self = shift;
  my $wanted = shift || 5;

  # maxchunksize:
  #  <= 0: automatic chunk size
  #  > 0 : take whatever client wants
  $self->{maxchunksize} ||= 0;
  if ($self->{maxchunksize} <= 0)
    {
    # if job is not at least two hours old, create only small chunks
    $wanted = 5 if Dicop::Base::time() - $self->{created} < 2 * 3600;
    }
  else
    {
    $wanted = $self->{maxchunksize} if $self->{maxchunksize} < $wanted;
    }
  
  # limit to 5 min .. 120 min 
  $wanted = 5 if $wanted < 5;
  $wanted = 120 if $wanted > 120;

  $wanted;
  }

sub _DEBUG () { 0; }

sub find_chunk
  {
  # Given a client's speed value, try to find a suitable chunk for him.
  # If there are chunks in our check list, try them first. Otherwise walk the
  # normal chunk list of the job.
  # If we find a chunk that's too big, split it.
  # As we walk the list, we will also convert ISSUED, FAILED or BAD chunks to
  # DONE, when they are over their age, so that they can be retried.
  # When the job has no more chunks that are ISSUED, TOBEDONE, BAD or FAILED,
  # it will be closed (set to DONE).

  #############################################################################
  # This is _HOT_ code, and executed for nearly each client request. Walking
  # the growing list and checking takes longer than anything else due to the
  # now optimized split (which formerly took most of the time).

  # Profiling run over 500 work requests / starting with 4 chunks, ending with
  # 504) using Math::BigInt 1.60 shows that check_age and find_chunk take the
  # most time.

  #  Total Elapsed Time = 32.40225 Seconds
  #  User+System Time = 31.55225 Seconds
  #Exclusive Times
  #%Time ExclSec CumulS #Calls s/call Csec/c Name
  # 18.2   5.755  5.417 126250 0.0000 0.0000 Dicop::Data::Chunk::check_age
  # 11.3   3.591 25.472    500 0.0072 0.0509 Dicop::Data::Job::find_chunk
  # 6.75   2.129  2.987  11563 0.0002 0.0003 Math::BigInt::objectify
  # 6.59   2.078  2.523  33116 0.0001 0.0001 Math::BigInt::is_zero
  # 5.79   1.828  3.620   1000 0.0018 0.0036 Dicop::Data::Request::check
  # 4.42   1.396  9.708   2004 0.0007 0.0048 Dicop::Data::Chunk::_checksum
  # 4.31   1.359  1.356   1000 0.0014 0.0014 Dicop::Data::Request::check_params
  # 4.12   1.299  1.794   6645 0.0002 0.0003 Math::BigInt::new
  # 3.96   1.249  0.731 129760 0.0000 0.0000 Dicop::time
  # 3.61   1.140  1.103   9137 0.0001 0.0001 Math::BigInt::round
  # 3.26   1.030  0.875  38628 0.0000 0.0000 Math::BigInt::Calc::_is_zero
  # 2.72   0.859 17.132  25213 0.0000 0.0007 Math::BigInt::__ANON__

  # So we check the age of the chunks only every now and then (1 minute),
  # since they expire after hours checking them several times per second is
  # overkill:
  #  Total Elapsed Time = 25.31050 Seconds
  #  User+System Time = 25.01050 Seconds
  #Exclusive Times
  #%Time ExclSec CumulS #Calls s/call Csec/c Name
  # 8.43   2.108  2.623  33116 0.0001 0.0001 Math::BigInt::is_zero
  # 7.67   1.919  2.741  11563 0.0002 0.0002 Math::BigInt::objectify
  # 6.12   1.530 17.756    500 0.0031 0.0355 Dicop::Data::Job::find_chunk
  # 5.95   1.488  3.225   1000 0.0015 0.0032 Dicop::Data::Request::check
  # 5.67   1.419  1.415   1000 0.0014 0.0014 Dicop::Data::Request::check_params
  # 4.95   1.239  1.570   6645 0.0002 0.0002 Math::BigInt::new
  # 4.66   1.166  9.307   2004 0.0006 0.0046 Dicop::Data::Chunk::_checksum
  # 4.59   1.149  0.957  38628 0.0000 0.0000 Math::BigInt::Calc::_is_zero
  # 4.43   1.107  4.228   8034 0.0001 0.0005 Math::BigInt::bcmp
  # 4.00   1.000  0.954   9137 0.0001 0.0001 Math::BigInt::round
  # 3.46   0.865  2.457   2501 0.0003 0.0010 Math::BigInt::bdiv
  # 3.31   0.829 17.510  25213 0.0000 0.0007 Math::BigInt::__ANON__

  # Another optimization is to not walk the entire list if we don't need to.
  # We store in $self->{_first_tobedone} the index of the first chunk that is
  # (possible) available (e.g. has TOBEDONE). Instead of walking from front,
  # we start walking there. The only exception is when we do an age-check, in
  # this case we start at the front and also reset _first_tobedone. As we go
  # along the list, we also look for a new first_tobedone in case some chunk
  # get's converted to TOBEDONE again, this enables a quick start the next time
  # we need to find a chunk.

  # Benchmark on a PIII 500 calling $count times find_chunk() on an empty job:
  #
  # count: | 100  500 1000  2000  4000
  # -------|---------------------------
  # v2.18  | 2.4 15.7 40.8 121.7 397.9
  # v2.19  | 2.2 12.1 26.7  64.5 168.3                          
  # v2.20  | 2.1 10.9 21.7  43.9  89.6  (all in seconds)
  # v2.20  | 2.1 10.8 21.5  44.3  89.4  (with ++ of first_tobedone)

  # We see that with v2.20 it is perfectly linear, two times a count takes
  # twice the time, which is the best we can do.
  #############################################################################
 
  my $self = shift;
  my ($client,$secret,$wanted,$prefered_size) = @_;

  # calculate the prefered amount of passwords from client speed and job
  # speed modifier (since jobs are different "fast")

  # ask client for his speed for this job or let him calculate it
  if (!defined $prefered_size)
    {
    # pwds/s
    my $client_speed =
      $client->job_speed($self->{id},$self->{jobtype}->{speed});
    # correct $wanted to be in the job's specific limits
    # pwds/s * seconds => keys the client needs (exceeds easily 2^32, thus MBI)
    $prefered_size = Math::BigInt->new($client_speed) *
      $self->_restrict_chunksize($wanted) * 60;			# in seconds
    }
  $prefered_size = Math::BigInt->new($prefered_size) if !ref($prefered_size);
  my $maxsize = $prefered_size + $prefered_size;
  my $chunk = undef;			# as a default, take none
  my $now = Dicop::Base::time();	# for the conversion to DONE

  my $i = 1; 				# counter, but skip first DONE chunk
  my $check_age = 0;			# default no check
  if (($now - $self->{_last_chunk_age_check}) > 60)
    {
    $self->{_last_chunk_age_check} = $now; $check_age = 1;
    }
  else
    {
    # Additionally, we remember the last TOBEDONE chunk (and modify this
    # pointer whenever a chunk changes it's status) and start our search
    # there.
    $i = $self->{_first_tobedone} if defined $self->{_first_tobedone};
    } 
  
  if (scalar keys %{$self->{_checklist}} != 0)
    {
    $chunk = 
     $self->_find_in_checklist($maxsize,$client,$now,$check_age);
    if (defined $chunk)			# found some chunk?
      {
      return $chunk->issue($client,$secret);
      }
    }

  my $cnt = $self->chunks();		# only once, wont change
  my ($chunk_fits,$fits,$cur);		# chunk fits client? cur == shortcut
  my $open_chunks = 0;
  my $chunk_nr = -1;			# nr of chunk that we will use/split

  print "DEBUG start $i (count ",scalar @{$self->{_chunks}},")\n" if _DEBUG;

  # The following code contains coarse language, rude optimizations and
  # violent assignments, readers discretion is advised.
 
  $self->{_first_tobedone} = undef;
  # if _first_tobedone pointed at last chunk or after it, don't close job!
  $open_chunks++ if $i == $cnt;
  # for each chunk in list
  while ($i < $cnt)		
    {
    $self->{_find_chunk_steps}++;	# debug/test, count the steps
    $cur = $self->{_chunks}->[$i];	# shortcut
    $cur->check_age($client,$now)	# first, make TOBEDONE if too old
      if $check_age;			# but don't check too often 
    print "DEBUG at chunk $i\n" if _DEBUG;
    $open_chunks++ if $cur->is_open();	# count chunks that are open 
    if (($cur->{status} == TOBEDONE) ||
        ($cur->{status} == VERIFY)) 	# this one could be used
      {
      # If we encounter a open chunk earlier than the previously known,
      # remember it.
      # Actually, this might be the chunk we will issue, so it should be $i+1.
      # This is handled below when the chunk is split, which accounts for most
      # cases. Other cases where we re-issue a chunk are slightly non-optimal,
      # but benchmarks show that this does not matter at all.
      # This works, because this is the only place that converts chunks back
      # to TOBEDONE (if check_age) (except merge_chunks()), so we only need to
      # modify _first_tobedone here (and in merge_chunks()).
      $self->{_first_tobedone} = $i
       if !defined $self->{_first_tobedone};

      $fits = ($cur->size() < $maxsize) || 0;
      print " DEBUG fits: $fits\n" if _DEBUG;

      # if chunk is in the VERIFY state, and the client is already in the list
      # of verifiers, it cannot verify this chunk, so choose another chunk for
      # this client:
      $i++, next if $cur->verified_by($client);

      # if none defined, take it alway
      if (!defined $chunk)		# if none yet, take this
        {
        print " DEBUG taken\n" if _DEBUG;
        $chunk = $cur; $chunk_nr = $i; $chunk_fits = $fits;
        }
      else
        {
        # take it only if the former one was a VERIFY one and didn't fit and
        # the current one is smaller or TOBEDONE 
        if (($chunk->{status} == VERIFY && !$chunk_fits) &&
            ($cur->{status} == TOBEDONE || $cur->size() < $chunk->size()))
          {
          print " DEBUG taken another\n" if _DEBUG;
          $chunk = $cur; $chunk_nr = $i; $chunk_fits = $fits;
          }
        }
      # if size is okay, take it without looking further (this will leave some
      # old chunks temp. as ISSUED|FAILED and will corrected by the next run
      # through the list)
      last if $chunk_fits;
      print "DEBUG still at it\n" if _DEBUG;

      # We arrive here only for non-fitting chunks.
      # If we don't check the ages, we can stop if it doesn't fit and is
      # TOBEDONE, since we will probably not find a smaller one (or even if
      # we did, we want to use up the first up first). Exception are too big
      # VERIFY chunks, we need to look further for smaller ones since they
      # cannot be spliced up.
      last if !$check_age && $chunk->{status} == TOBEDONE;
      }
    $i++;				# next chunk
    }
  print "DEBUG steps $self->{_find_chunk_steps}\n" if _DEBUG;
  print "DEBUG next  ",$self->{_first_tobedone}||'undef',"\n" if _DEBUG;
  if ($open_chunks == 0)		# found no chunks at all
    {
    $self->status(DONE);		# close job
    return;
    }
  return if !defined $chunk;		# did not found any suitable

  # split chunks that are too big, but not VEIRFY chunks
  return if ($chunk->{status} == VERIFY && $chunk->{_size} > $maxsize * 2);

  if ($chunk->{_size} > $maxsize)
    {
    # if found chunk is too big, split it
    my $new = $chunk->split($prefered_size,$self->{jobtype}->{fixed});
    splice (@{$self->{_chunks}},$chunk_nr+1,0,$new)	# insert after
	if defined $new;				# if split worked
    # If we split $chunk, we issue $chunk (the one first_tobedone is pointing
    # to), so first_tobedone can point one further right away. This reduces
    # the number of scanning steps by a factor of two, but improves
    # performance only by a about 0.5% (see above).
    # This also sets _first_tobedone to $cnt in some cases, which means the
    # checking loop above will not entered until we check the chunk's age
    # again, which is why we guard against setting the job to DONE at the
    # loop's top
    $self->{_first_tobedone}++ if ($self->{_first_tobedone}||0) == $chunk_nr;
    # we issue $chunk here, not $new
    }
  $chunk->issue($client,$secret);
  }

sub _find_in_checklist
  {
  # look through checklist and see if we have a chunk to be checked
  my ($self,$maxsize,$client,$now,$check_age) = @_;

  # XXX TODO: We assume that the checklist is short (even empty most of the
  # times) so that we can simple walk it entirely. Maybe we should cache how
  # many open chunks are in it, to prevent needless loops when there is only
  # one chunk in the check phase?

  my $clist = $self->{_checklist};
  foreach my $id (keys %$clist)
    {
    my $cur = $clist->{$id};
    $cur->check_age($client,$now)	# first, make TOBEDONE if too old
      if $check_age;			# but don't check too often 
    if ($cur->{status} == TOBEDONE)
      {
      # Ok, we bite. But before we can take it, we must slice it up, so that
      # it fits the client's speed. We do this by making the chunk smaller
      # around the supposed result, so that the result is still included. 
      my $size = $cur->size();
      if ($size > $maxsize)
        {
        my $new = $cur->copy();				# keep the original
        my $factor = $size / $maxsize; 			# as BigInt
	$factor = Math::BigInt->new(2) if $factor < 2;	# but at least halve
	# shrink chunk around the result by a factor of $factor
        $new->shrink($cur->{result},$factor,$self->{jobtype}->{fixed});
        $cur = $new; 					# return the shrunken
        }
      return $cur;
      } 
    }
  return;				# did not found any suitable chunk
  }

sub checklist_empty
  {
  # empty the checklist
  my $self = shift;

  $self->{_checklist} = {};
  }

sub check_also
  {
  # add a chunk to the check list
  my ($self,$chunk,$result) = @_;
 
  my $copy = $chunk->copy();
  $copy->{job} = $self;				# adopt the clone

  # make unique ID
  $copy->{id} = $self->new_chunk_id(); 

  # set chunk status to TOBEDONE
  $copy->status(TOBEDONE);
  # mark ourself as modified (status() above should already do this)
  $self->modified(1);
  # store result for later shrink
  $copy->{result} = $result;			

  bless $copy, 'Dicop::Data::Chunk::Checklist';	# and mark it as ours

  $self->{_checklist}->{$copy->{id}} = $copy;
 
  $copy;
  }

sub _chunk_is_in_checklist
  {
  # check whether a given chunk is in the list or not
  my ($self,$chunk_id,$token) = shift;

  # XXX TODO:
  #  when chunk_id is undefined (not sent to client and thus not returned)
  #  we must walk all entries (and/or have a token => id mapping for quick
  #  access)

  # does chunk_id exist?
  return 0 if !exists $self->{_checklist}->{$chunk_id};
  
  # if yes, does the chunk have the correct token?
  return 0 if ($self->{_checklist}->{$chunk_id}->{token} eq $token);
  1;					# found it
  }

sub _checklist_del_chunk
  {
  # remove a given chunk from the list
  my ($self,$chunk) = @_;

  # $chunk should be found using _chunk_is_in_checklist() !

  return unless exists $self->{_checklist}->{$chunk->{id}};
  delete $self->{_checklist}->{$chunk->{id}};
  
  $self;
  }

sub checklist
  {
  # in scalar context, return number of chunks in checklist
  my $self = shift;

  scalar keys %{$self->{_checklist}};
  }

sub report_chunk
  {
  # Report a working result back as DONE, FAILED, SOLVED, or TIMEOUT.
  # Should only be called after $chunk->verify().
  my ($self,$chunk,$took) = @_;

  $self->{last_chunk} = Dicop::Base::time();	# when was last chunk returned
  $self->{runningfor} += $took;			# this is not right, should
						# take overlaps into account
  my $status = $chunk->{status};		# DONE, FAILED, SOLVED, TIMEOUT
  $self->{chunks}++ 				# one more done or solved
   if (($status == DONE) || ($status == SOLVED));
  if ($status == SOLVED)
    {
    $self->{results}++;
    $self->{status} = SOLVED if $self->{haltjob} eq 'on'; # halt job?
    }
  # If chunk was in checklist and is DONE, remove it from there.
  # This leaves SOLVED chunks in the checklist so we can see their results.
  elsif ((ref($chunk) eq 'Dicop::Data::Chunk::Checklist') &&
     ($chunk->{status} == DONE))
    {
    $self->_checklist_del_chunk($chunk);
    }
  }

sub status
  {
  # set your status to TOBEDONE, SOLVED, FAILED, SUSPENDED etc
  # return current status 
  my $self = shift;

  if (defined $_[0])
    {
    $self->{status} = shift;
    $self->{_parent}->adjust_job_priorities();
    $self->modified(1); 
    }
  $self->{status};
  }

sub is_running
  {
  my $self = shift;
  
  ($self->{status} == TOBEDONE) || 0; 
  }

sub results
  {
  my $self = shift;
  # return number of results
  $self->{results};
  }

sub chunks
  {
  # return number of chunks that have a certain status (or all if no status)
  my $self = shift;
  my $status = shift;
 
  return scalar @{$self->{_chunks}} if !defined $status;

  # walk list, collect
  my $cnt = 0;
  foreach my $c (@{$self->{_chunks}})
    {
    $cnt++ if $c->status() == $status;
    }
  $cnt;
  }

sub chunk
  { 
  # return a chunk by number
  my $self = shift;
  my $chunk = shift || 0;

  return if ($chunk > @{$self->{_chunks}}) || ($chunk < 0);
  $self->{_chunks}->[$chunk];
  }

sub get_chunk_nr
  { 
  # return a chunk's nr by id
  my $self = shift;
  my $chunk = shift || 0;

  my $i = 0;
  my $j = scalar @{$self->{_chunks}};
  for ($i = 0; $i < $j; $i++)
    {
    return $i if $self->{_chunks}->[$i]->{id} == $chunk;
    }
  }

sub get_chunk
  { 
  # return a chunk by id
  my $self = shift;
  my $chunkid = shift || 0;

  my $cl = $self->{_checklist};
  return $cl->{$chunkid} if exists $cl->{$chunkid};

  # TODO: This should be a hash, not a list
  foreach my $c (@{$self->{_chunks}})
    {
    return $c if $c->{id} == $chunkid;
    }
  undef;
  }

sub check
  {
  # do an internal self check and see if chunk list is "ok"
  my $self = shift;

  return $self->{_error} if defined $self->{_error};	# for aborting add
  my $sum = new Math::BigInt 0;
  foreach my $c (@{$self->{_chunks}})
    {
    $sum += $c->size(); 
    }
  my $expected = $self->{_size} + scalar @{$self->{_chunks}} - 1;
  return "Chunklist sum $sum not equal job's size $expected in job $self->{id}"
   if $sum != $expected;
  
  # check that each chunk ends with what the next starts and vice versa
  # also check that chunk ids are counting upwards
  my $i = 0; my ($a,$b); my $cnt = @{$self->{_chunks}} - 1;
  my $error;
  foreach my $c (@{$self->{_chunks}})
    {
    last if defined $error;
    if ($i != 0)
      {
      $a = $self->{_chunks}->[$i-1];
      $b = $self->{_chunks}->[$i];
      if ($a->{end} != $b->{start})
        {
        $error = "Chunk $i: $a->{start} : $a->{end} $b->{start} : $b->{end}\n";
        }
      }
    # don't test for last chunk	
    if ($i < $cnt-1)
      {
      $a = $self->{_chunks}->[$i];
      $b = $self->{_chunks}->[$i+1];
# sorted order not necc.
#      $error 
#       = "Chunks not in sorted order (ID $a->{id} comes before $b->{id})"
#       if ($a->{id} > $b->{id});
      if ($a->{end} != $b->{start})
        {
        $error = "Chunk $i: $a->{start} : $a->{end} $b->{start} : $b->{end}\n";
        }
      }
    $i++;
    } 
  $error = "" if !defined $error;
  $error;
  }

sub put
  {
  my $self = shift;
  my ($key,$val) = @_;
 
  #$val = h2a("$val") if $key =~ /^(newjob-start|newjob-end)$/;
  $val = Math::BigInt->new($val) if $key =~ /^chunks$/;

  $val = Dicop::status_code($val) if $key eq 'status' && $val !~ /^\d+$/;
  $self->{$key} = $val;
  }

sub get_as_hex
  {
  my $self = shift;

  my $key = lc(shift || '');

  return a2h($self->{$key}) if $key =~ /^(newjob-)?(start|end)$/;
  $self->get_as_string($key);
  }

sub get_as_string
  {
  # return a field of yourself as plain string (stringify passwords/numbers)
  # return "" for non-existing fields
  my $self = shift;
  my $key = lc(shift||"");

  return ago($self->{runningfor}) if $key eq 'runningfor';
  return ago( $self->{last_chunk} - $self->{created})
   if $key eq 'runningsince';
  if ($key =~ /^(willtake|willtakesimple|finished)$/)			# fake keys
    {
    my $r = $HUNDRED - $self->percent_done(4);		# use 4 digits accur.
    return "(already done)" if $r->is_zero();
    if ($r < $HUNDRED)
      {
      # get avarage speed
      my $spd = Math::BigFloat->new($self->{_parent}->speed($self));
      # get keys still to do by using some more accur.
      my $keys = $self->keys_todo();
      return "(unknown time)"
       if $keys->is_nan() || $spd->is_nan() || $spd->is_zero();
      $keys = $keys->bdiv($spd)->numify();		# (keys / keys/s) == s
      return ago($keys) if $key eq 'willtake';
      return simple_ago($keys) if $key eq 'willtakesimple';
      return scalar localtime(Dicop::Base::time() + $keys);
      }
    return "(unknown time)";
    }
  return $self->keys_done() if $key eq 'keys_done';

  # fake keys:
  return $self->{_parent}->speed($self). ' keys/s'
   if $key eq 'keyspersecond';
  return $self->{$1}->length()
   if $key =~ /^(start|end)len$/;
  return $self->percent_done() if $key eq 'percent_done';
  return int($self->percent_done()) if $key eq 'percent_done_int';
  return Dicop::status($self->{status}) if $key eq 'status';

  # fake key 'extras'
  if ($key eq 'extras')
    {
    # get the names of the extra fields from our jobtype
    my @extras = $self->{jobtype}->extra_fieldnames();
    my $txt = ''; my $i = 0;
    foreach my $extra (@extras)
      {
      my $p = $self->{"extra$i"}; $p = '<b>not set!</b>' unless defined $p;
      $txt .= "$extra => \"$p\", ";
      $i++;
      }
    $txt =~ s/, $//;    # remove last ','
    return $txt;
    }

  my $f = $key; $f =~ s/_.*//;

  return $self->{$f}->{$2} 
   if $key =~ /^(case|charset|jobtype)_(name|description)$/;

  $self->SUPER::get_as_string($key);

  }

sub charset
  {
  # return our Math::String::Charset object
  my $self = shift;

  $self->{charset}->charset();
  }

sub flush
  {
  # write chunk list to disk
  my ($self,$base_dir) = @_;

  return unless $self->modified();     			 # do nothing?

  $self->_write_chunk_list($base_dir,'chunks');		# normal chunks
  $self->_write_chunk_list($base_dir,'checklist');	# checklist chunks

  $self;
  }

sub _write_chunk_list
  {
  my ($self,$base_dir,$type) = @_;

  my $dir = "$base_dir/$self->{id}";
  my $file = "$dir/$type.lst";

  CORE::mkdir($dir,0755) if (!-e $dir);	# for 5_005: CORE::mkdir($dir,0755)
  die ("Can not create directory $dir - wrong permissions? $!")
   if (!-e $dir && !-d $dir);
  my $output = "";
  $type = 'check' if $type eq 'checklist';	# => check.lst
  foreach my $chunk (@{$self->{'_'.$type}})
    {
    $output .= $chunk->as_string();
    }
  write_file ($file,\$output);
  }

sub size
  {
  my $self = shift;
  $self->{_size}->as_number();
  } 

sub extra_params
  {
  # like extra_fields, but returns
  # username_Biffy+Baff;nose_red
  my $self = shift;

  # get the names of the extra fields from our jobtype
  my @extras = $self->{jobtype}->extra_fieldnames();

  return '' if @extras == 0;

  my $txt = ''; my $i = 0;
  foreach my $extra (@extras)
    {
    my $p = $self->{"extra$i"}; $p = 'not set!' unless defined $p;

    # untaint the name and the contents (basically allow anything
    # except "'<>/ and \n\t\r
    # since it goes out encoded)

    $extra =~ /^([\w_-]+)/i; my $name = $1 || next;
    $p =~ /^([^"'<>\/\n\t\r]+)/i; my $val = $1 || next;
    $txt .= encode($name) . '_' . encode($val) . ';';

    $i++;
    }
  $txt =~ s/;$//; 				# remove last ';'
  $txt;
  }

sub extra_fields
  {
  my $self = shift;
  # return list of extra fields in the following format:

  # extra0=username,Biffy Baff
  # extra1=nose,red

  # (the strings are converted to hex like "444546,303132")

  # get the names of the extra fields from our jobtype
  my @extras = $self->{jobtype}->extra_fieldnames();
  
  return '' if @extras == 0;

  my $txt = ''; my $i = 0;
  foreach my $extra (@extras)
    {
    my $e = "extra$i";
    my $p = $self->{$e}; $p = 'not set!' unless defined $p;
    $txt .= "$e=" . a2h($extra) . ',' . a2h($p)."\n";
    $i++;
    }
  $txt;
  }

sub extra_files
  {
  # XXX implement
  my ($self,$arch) = @_;

  # return extra files for client to download necc. for this job
  return;
  }

1;

__END__

#############################################################################

=pod

=head1 NAME

Dicop::Data::Job - a job in the L<Dicop|Dicop::Dicop> system.

=head1 SYNOPSIS

    use Dicop::Data::Job;

=head1 REQUIRES

perl5.005, Exporter, Dicop, Dicop::Item, Math::String, Math::BigInt,
Math::BigFloat

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

For a description of fields a job has, see C<doc/Objects.pod>.

=head1 CHUNK LIST

The chunk list contains all the chunks that make up the key/password room of
the job.

Each L<chunk|Dicop::Data::Chunk> can have a status of C<ISSUED>, C<DONE>,
C<TOBEDONE>, C<SOLVED>, or C<FAILED>.

Apart from creation, there are only two events that will change the chunklist.

=head2 Client Request

When a client requests a piece of work, the following things will happen:

=over 2

=item Conversion to TOBEDONE

Any chunk that is C<FAILED> or C<ISSUED> for too long will be converted to
C<TOBEDONE> so that it can be issued to a client again.

=item Finding an appropriate sized TOBEDONE chunk

The list is then searched for a chunk that fit's the clients wish for
amount of work best. If the best fitting chunk is actually more than twice
what the client requested, the chunk is split into two parts, and the smaller
part is taken. If the chunk is smaller, it is used nonetheless to prevent
small chunks from lingering in the system indefinitely.

=back

Thus due to a client request the chunk list may grow by zero or one chunk,
which will always be of the type C<TOBEDONE>.

=head2 Client Returns Chunk

The chunk the client reported back is setto C<SOLVED>, C<FAILED> or C<DONE>,
depending on what the client reported.

When the chunk is set to C<DONE>, it will be tried to be merged with the
chunk before and after it. 

Thus returning a C<DONE> chunk may shrink the chunk list by 0-2 chunks.
Returning a C<FAILED> or C<SOLVED> chunk will not shrink or grow the chunk
list.

The chunk list will be kept at the minimum size by this mechanism. The only
way it could grow is by one client requesting lots of chunks without returning
them. This is prevented by the server via a maximum number of chunks per
client.

For performance reasons the reporting back of a chunk will only look at this
chunk and it's two neighbours. The algorithm to find a chunk for a client will
only look as far as it needs to find a suitable chunk. 

=head1 CLOSING A JOB

A job will be closed (set to C<STOPPED>) when one of the following occurs:

=over 2

=item Solution found

When a solution is found, and the jobs flags don't permit it running after
that (e.g. you want only one solution).

=item No more open chunks

When there are no more open (C<ISSUED>, C<FAILED> or C<TOBEDONE>) chunks. This
is only checked at the time of finding a chunk to be issued to a client.

=back

=head1 METHODS

=head2 extra_files()

        @files = $job->extra_files($architecture);

Return list of extra filenames necc. for this job, including files neccessary
due to the jobtype this job has.

=head2 extra_fields()

        $txt = $job->extra_fields();

If the jobtype for that job mandates extra fields, will return a text listing
them in the following format:

	extra0=username,Biffy Baff
	extra1=nose,red

The strings are converted to hex like "444546,303132".

This routine is used to include them into the chunk description file.

=head2 extra_params()

        $txt = $job->extra_params();

If the jobtype for that job mandates extra fields, will return a text listing
them in the following format:

  	username_Biffy+Baff;nose_red

This is suitable for returning them as a Dicop::Request.

=head2 flush()

	$job->flush($base_dir):

Write the chunk list of the job to the disk.

=head2 check()

Check internal data structures like the chunklist, and in case of error,
return this error. Undef for "ok".

=head2 chunk()

Return the Nth chunk.

=head2 chunks()

Return number of chunks with a certain status. If no argument is given,
returns number if all chunks.

=head2 charset()

Returns the jobs charset as a Math::String::Charset object.

=head2 is_running()

Returns true if the job is currently running, e.g. not suspended or
done.

=head2 status()

Return status code of job.

=head2 results()

Return number of results.

=head2 get_chunk()

Return a chunk by it's id. This does also look in the checklist, so it will
always return any chunk in the job, not only the "normal" ones.

=head2 get_chunk_nr()

Return a chunk's index number by it's id.

=head2 report_chunk()

	$job->report_chunk($chunk,$took);

Report a chunk back from a client, increase the results counter. Does not merge
or split chunks, because the size of the chunk is needed later on.

If the chunk was in the checklist, and is finally DONE, it will be removed
from the checklist.

=head2 merge_chunks()

Given a chunk number (Nth chunk in array), tries to merge the next and
previous chunks with that chunk until no longer both the next and the previous
chunk are C<DONE>.

Returns number of merging operations (aka deleted chunks).

=head2 size()

Return jobs size (aka key-room size) as Math::BigInt.

=head2 percent_done()

Return the percent of already done keys in this job as float with two digits
after the dot. See also L<keys_done>.

=head2 keys_todo()

Return the number of keys still todo in this job as a big integer.
See also L<percent_done> and L<keys_done>.

=head2 keys_done()

Return the number of already done keys in this job as a big integer.
See also L<percent_done>.

=head2 find_chunk()

Given a client's speed value, try to find a suitable chunk for him. If we
find a chunk that's too big, split it in two smaller pieces. The first slice
will match the speed of the client.

As we walk the list, we will also convert ISSUED chunks to DONE, when
they are over their age. When the job has no more chunks that are ISSUED,
TOBEDONE or FAILED, it will be closed (set to DONE).

This is _HOT_ code, and executed for nearly each client request. OTOH,
walking a list of 10.000 chunks takes currently less time than the final
splitting of the chunk.

=head2 checklist()

	my $count = $job->checklist();

Return number of chunks currently in checklist.

=head2 checklist_empty()

Clears the check list (empties it).

=head2 new_chunk_id()

	$chunk->{id} = $self->new_chunk_id();

Create a new, unique ID for a new chunk.

=head2 check_also()

	$job->check_also($chunk);

Makes a copy of the chunk (which contained a result), gives it a unique (for
this job) ID, and adds it to the checklist.

The new chunk's status is also set to TOBEDONE, also a flag telling that this
chunk is part of the checklist is set.

Returns reference to the new chunk.

=head1 INTERNAL METHODS

=head2 _checklist_del_chunk
	
	$job->checklist_del_chunk($chunk);

Delete the given chunk from the list.

=head2 _find_in_checklist

Walks the checklist to find a suitable chunk for the client. The checklist is
the list of chunks we need to check in addition to the normal keyspace
contained in our chunklist - typically for results from other jobs.

=head2 _chunk_is_in_checklist

Checks whether a given chunk (by it's id and token) is in the checklist or
not. Used to decide whether a back-comming result from a client was for a
chunk in the check list or inside the normal chunk list. (The IDs between the
two lists are unique, so the ID alone would suffice to make the distinction,
but we will later on have only the token delivered back by the client)

=head2 _restrict_chunksize

Restricts the chunksize to be in the range of 1..120 minutes. In addition, if
C<max-chunk-size> is set to 0, restricts the chunksize to a maximum of 5 if the
job is not yet two hours old.

=head2 _convert_target

Converts a target file name (any file that does not end in .tgt) via an
external script) to either a target hash or a target file. Sets
C<$self->{_error}> in case anything goes wrong, or C<$self->{script_output}>
in case the script run sucessfull.

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut


