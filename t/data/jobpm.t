#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  unshift @INC, '../../lib';
  chdir 't' if -d 't';
  plan tests => 247 + 145;
  }

 # dummy parent for job
package Foo;

require "common.pl";

use base qw/Dicop::Item/;
use Dicop::Data::Charset;
use Dicop::Data::Jobtype;
use Dicop::Data::Case;
my $jobtype = Dicop::Data::Jobtype->new ( id => 5, fixed => 3 );
my $case = Dicop::Data::Case->new ( id => 1 );

my $charset = new Dicop::Data::Charset ( set => "'a'..'z'", id => 2, );
$charset->_construct();
my $charset_upper = new Dicop::Data::Charset ( set => "'A'..'Z'", id => 32, );
$charset_upper->_construct();

sub new
  {
  my $self = {};

  bless $self;
  }

sub modified
  {
  }

sub get_charset
  {
  my $self = shift;
  return $charset if ($_[0] == 1);
  $charset_upper;
  }

sub get_jobtype
  {
  return $jobtype;
  }

sub get_job
  {
  return Dicop::Data::Job->new( jobtype => $jobtype);
  }

sub get_case
  {
  return $case;
  }

package main;
              
require "common.pl";

use Dicop::Data::Chunk;
use Dicop::Data::Job;
use Dicop::Data::Client;
use Dicop qw/DONE TOBEDONE FAILED SOLVED ISSUED VERIFY BAD/;

use Math::String::Charset;

my $client = new Dicop::Data::Client ( speed => 100 );
$client->{_parent} = new Foo;

is (ref($charset),"Dicop::Data::Charset");

my $job = new Dicop::Data::Job ( start => 'aaa', end => 'zaaaa', 
  description => 'desc', owner => 'test', charset => $charset,
  ascii => 1, case => 1, 
  );
$job->{_parent} = Foo->new();
$job->{jobtype} = $jobtype;

is ($job->get('case'), 1, 'case');

is (join(":", $job->extra_files('win32')), '', 'no extra files in win32');

$job->_construct();
is ($job->{id},1, 'id');
is ($job->chunks(), 2, '2 chunks');
is ($job->chunks(DONE), 1, '1 DONE' );
is ($job->chunks(TOBEDONE), 1, '1 TOBEDONE' );
is ($job->chunks(FAILED), 0, '0 FAILED' );
is ($job->chunks(BAD), 0, '0 BAD' );
is ($job->{_chunks}->[0]->status(), DONE, 'DONE');
is ($job->{_chunks}->[1]->status(), TOBEDONE, 'TOBEDONE');
is ($job->{_chunks}->[0]->{start}, 'aaa');
is ($job->{_chunks}->[0]->{end}, 'aaa');
is ($job->{_chunks}->[1]->{start}, 'aaa');
is ($job->{_chunks}->[1]->{end}, 'zaaaa');
is ($job->{maxchunksize}, 0, 'maxchunksize');
is ($job->status(), TOBEDONE, 'status TOBEDONE');
is ($job->get('start'), '616161,703');
is ($job->get_as_hex('start'), '616161', 'start');
is ($job->get('end'), '7a61616161,11899655', 'end');
is ($job->get_as_hex('end'), '7a61616161', 'end');

is (ref($job->{_checklist}),'HASH');

is ($job->size(), Math::String->new('zaaaa')->bsub('aaa')->as_number() + 1, 'size');
is ($job->{_last_chunk_age_check}, 0, 'check_age is 0');
is ($job->{_find_chunk_steps}, 0, 'debug');
is ($job->{_first_tobedone}, undef);

foreach my $p (qw/prefix newjob newjob-start newjob-end newjob-prefix/)
  {
  is ($job->get($p), '', "empty $p");
  }

is ($job->get('newjob-rank'),'##rank##', 'newjob rank');
is ($job->get('newjob-description'),'##description## pwd', 'newjob description');

is ($job->get_as_string('startlen'), 3, 'startlen');
is ($job->get_as_string('endlen'), 5, 'endlen');

is ($job->extra_fields(),'', 'no extra fields');
is ($job->extra_params(),'', 'no extra params');

# construct a single chunk
my $cs = $job->{charset}->charset();

my $chunk = new Dicop::Data::Chunk ( 
  job => $job, start => Math::String->new('aaa',$cs),
  end => Math::String->new('zaaaa',$cs), 
  );
$chunk->{_parent} = $job;
$chunk->_construct();

# we did survive until here
is ($chunk->size(), 26*26*26*26*26+26*26*26+1, 'size');
is ($job->check(), "", 'check' );
is ($job->percent_done(),'0.00', 'percent done');
is ($job->percent_done(-3),'0.000', 'percent done 3digits');
$chunk->status(DONE);
is ($job->percent_done(-3),'0.000', 'percent done 3digits');
is ($job->percent_done(-6),'0.000008', 'percent done 6digits');
is ($job->percent_done(1), '0.000008', 'percent done 1digits');
is ($job->percent_done(2),'0.0000084', 'percent done 2digits');
is ($chunk->{start}, 'aaa', 'start');
is ($chunk->{end}, 'zaaaa', 'end');

my $now = Dicop::Base::time();

###########################################################################
# test _restrict_chunksize()

is ($job->_restrict_chunksize(1), 5, 'restrict_chunksize() < 5 => 5');
is ($job->_restrict_chunksize(200), 5,'restrict_chunksize() > 120 => 120 => 5 (due to < 2 h)');
is ($job->_restrict_chunksize(5), 5, 'restrict_chunksize() = 5');
$job->{maxchunksize} = 20;
is ($job->_restrict_chunksize(5), 5, 'restrict_chunksize() < 20 => X');
is ($job->_restrict_chunksize(20), 20, 'restrict_chunksize() <= 20 => X');
is ($job->_restrict_chunksize(22), 20, 'restrict_chunksize() > 20 => 20');
$job->{maxchunksize} = 0;
$job->{created} = $now - 7201;

###########################################################################
# regular chunk testing

# 2 will be corrected to 5, so make the client slower
$client->{speed} = 50;

$chunk = $job->find_chunk($client,'dummy_secret',2);
is (ref($chunk), 'Dicop::Data::Chunk');
is ($chunk->size(), 26*26*26+1, 'minimum size is 26*26*26+1, not 100');
is ($job->chunks(), 3, '3 chunks' );
is ($job->check(), "", 'check' );
is ($job->{_last_chunk_age_check} < $now+1, 1, 'may vary 1 second');
is ($job->{_first_tobedone}, 2, 'first_tobedone set to chunk #2');

# create another one for testing split/merge
$client->{speed} = 1;
$chunk = $job->find_chunk($client,'dummy secret',1,26*26*26*10);
is (ref($chunk), 'Dicop::Data::Chunk');
is ($chunk->size(), 26*26*26*10+1, 'min size' );
is ($job->chunks(), 4, '4 chunks');
is ($job->check(), "", 'check' );
is ($job->{_first_tobedone}, 3);			# set to chunk #3

# test merge
$job->{_chunks}->[1]->status(DONE);
$job->{_chunks}->[2]->status(DONE);
$job->merge_chunks (2);
is ( $job->{_first_tobedone}, 1, 'first_tobedone reduced by 2 merges');

is ($job->{_chunks}->[0]->size(),193337, 'size');
is ($job->{_chunks}->[0]->{start},'aaa', 'start');
is ($job->{_chunks}->[0]->{end},'kaaa', 'end');
is ($job->chunks(), 2, '2 chunks');
is ($job->check(), "", 'check' );

for my $i (2 ..6)
  {
  $chunk = $job->find_chunk($client,'dummy secret',1,26*26*26*10);
  is ($job->{_first_tobedone}, $i, "tobedone $i");
  }

is ($job->chunks(), 7, '7 chunks');
is ($job->check(), "", 'check');

for my $i (1..5)
  {  
  $job->{_chunks}->[$i]->status(DONE);
  }

$job->merge_chunks (3);
is ($job->{_first_tobedone}, 1, 'first_tobedone points to second chunk');

is ($job->chunks(), 2, '2 chunks left');
is ($job->{_chunks}->[0]->size(),1072137, 'chunk size');
is ($job->{_chunks}->[0]->{start},'aaa', 'start aaa');
is ($job->{_chunks}->[0]->{end},'biaaa', 'end biaaa');

# check get_as_string
is ($job->get_as_string('start'),'aaa', 'start aaa');
is ($job->get_as_hex('start'),'616161', 'start 616161');


###########################################################################
# put()

is ($job->put('foo',5),5, 'store foo as 5');
$job->put('bar',5);
is ($job->get('bar'),5, 'bar is 5');

###########################################################################
# first chunk will have automatic size of 5 minutes due to automatic $wanted
# adjustment

$job->{created} = $now; $job->{maxchunksize} = 0; 

my $chunks = 3;
$chunk = $job->find_chunk($client,'dummy_secret',1);
is (ref($chunk), 'Dicop::Data::Chunk');
is ($chunk->size(), 26*26*26 + 1, 'minimum size is 26*26*26+1, not 100');
is ($job->chunks(), $chunks++, 'chunks' );
is ($job->check(), "", 'check');
is ($job->{_last_chunk_age_check} < $now+1, 1);	# may vary 1 second
is ($job->{_first_tobedone}, 2);			# set to chunk #2

# next one will have min size
$chunk = $job->find_chunk($client,'dummy_secret',1,100);
is (ref($chunk), 'Dicop::Data::Chunk');
is ($chunk->size(), 26*26*26 + 1 ); # minimum size is 26*26*26+1, not 100
is ($job->chunks(), $chunks++ );
is ($job->check(), "" );
is ($job->{_last_chunk_age_check} < $now+1, 1);	# may vary 1 second

# next one will have 6 minutes
$job->{maxchunksize} = 6; 

$chunk = $job->find_chunk($client,'dummy_secret',50);
is (ref($chunk), 'Dicop::Data::Chunk');
is ($chunk->size(), 2 * 26*26*26 + 1 ); 
is ($job->chunks(), $chunks++ );
is ($job->check(), "" );
is ($job->{_last_chunk_age_check} < $now+1, 1, 'may vary 1 second');

# don't care about {chunksize}
$job->{maxchunksize} = 0; 
$job->{created} = $now - 7201; 

$job->{_chunks}->[1]->status(DONE);
$job->{_chunks}->[2]->status(DONE);
$job->{_chunks}->[3]->status(DONE);
$job->merge_chunks (2);

##############################################################################
# check get_chunk (by id)

$chunk = $job->get_chunk(1);
is (ref($chunk),'Dicop::Data::Chunk');
$chunk = $job->get_chunk(6);
is ($chunk, undef, 'chunk 6 does not exist');

# by nummer
$chunk = $job->get_chunk_nr(1);
is ($chunk,0, '0 chunk');

##############################################################################
# check report chunk (with chunk's nr == 0 to test merge_chunk for that)

$chunk = $job->get_chunk(1);
$job->report_chunk($chunk,123);
is ($job->{runningfor},123, "running for: += took, although it's wrong");
is ($job->{chunks},1, '++');
is ($job->{results},0, 'none found yet');
is ($job->{status},TOBEDONE, 'not changed');
is ($chunk->status(),DONE, 'status DONE');
is ($job->chunks(),2, '2 chunks');

# simulate $chunk->verify($client, SOLVED, $crc);
$chunk->status(SOLVED);

$job->report_chunk($chunk,321);
is ($job->{runningfor},444, "+= took, although it's wrong");
is ($job->{chunks},2, ' one more');
is ($job->results(),1, 'just found one');
is ($job->{status},SOLVED, 'stopped');
is ($job->chunks(),2, '2 chunks');

# not implemented yet:
# make job bigger
#$job->end('zzzaaaa');
# does it still hold?
#ok ( $job->check(), 0 );

# is_running()

$job->{status} = DONE;
is ($job->is_running(),0, 'not running');
$job->{status} = TOBEDONE;
is ($job->is_running(),1, 'running');

# check the first_tobedone optimization

# we cannot split the job into more than 60 chunks due to it's size, so
$job->{_first_tobedone} = undef;
# split list into at least 100 chunks
for (my $i = 1; $i < 62; $i++)
  {
  $chunk = $job->find_chunk($client,'dummy secret',1,26*26*26*10);
  is ($job->{_first_tobedone}, $i+1, "first_tobedone $i+1" ) if $i < 61;
  # the last is not split, so first_tobedone is not incremented
  is ($job->{_first_tobedone}, $i, "first_tobedone $i" ) if $i == 61;
  }
# this does thus "fail"
$chunk = $job->find_chunk($client,'dummy secret',1,26*26*26*10);
is ($job->{_first_tobedone}, undef, 'first_tobedone undef');
is ($job->chunks(), 62, '62 chunks');

# now set some chunks as done,
$job->{_chunks}->[44]->status(TOBEDONE);
$job->{_chunks}->[43]->status(TOBEDONE);
$chunk = $job->find_chunk($client,'dummy secret',1,26*26*26*10);
# since 43 will be found, _first_tobedone will also point to 43 (it should be
# 44, but that doesn't matter much)
is ($job->{_first_tobedone}, 43, 'first_tobedone 43');

# merge_chunks() cannot merge, so first_tobedone does not change:
$job->merge_chunks (43);
is ($job->{_first_tobedone}, 43, 'first_tobedone 43');

$now = $job->{_find_chunk_steps};
$chunk = $job->find_chunk($client,'dummy secret',1,26*26*26*10);
is ( $job->{_first_tobedone}, 44, 'first_tobedone 44');
is ($job->{_find_chunk_steps} - $now, 2, 'took only two steps?');

# merge_chunks() merges two chunks _before_ first_chunk_pointer
$job->{_chunks}->[43]->status(DONE);
$job->{_chunks}->[44]->status(DONE);
$job->merge_chunks (43);
is ($job->{_first_tobedone}, 43, 'first_tobedone 43');

$job->{_chunks}->[40]->status(DONE);
$job->{_chunks}->[41]->status(DONE);
$job->merge_chunks (40);
is ($job->{_first_tobedone}, 42, 'first_tobedone 42');

# merge_chunks() merges two chunks _after_ first_chunk_pointer

$job->{_chunks}->[50]->status(DONE);
$job->{_chunks}->[51]->status(DONE);
$job->merge_chunks (50);
is ($job->{_first_tobedone}, 42, 'first_tobedone 42');

##############################################################################
# test whether find_chunk can work with VERIFY and BAD chunks

# create a chunk list with only one VERIFY and one TOBEDONE chunk
for (my $i = 0; $i < scalar @{$job->{_chunks}}; $i++)
  {
  $job->{_chunks}->[$i]->status(DONE);
  }
$job->{_chunks}->[51]->status(VERIFY);
$job->{_chunks}->[-1]->status(TOBEDONE);

# chunks_in_list($job);
$chunk = $job->find_chunk($client,'dummy secret',1,26*26*26*10);
is (ref($chunk), 'Dicop::Data::Chunk');
# chunks_in_list($job);

# the VERIFY chunk was issued (roughly the same size)
is ($job->{_chunks}->[51]->status(),ISSUED, 'ISSUED');

##############################################################################
# test that a too large VERIFY chunk is not re-issued to a slow client

# merge the last 8 ones together to create a big one
$job->{_chunks}->[-1]->status(DONE);
$job->merge_chunks(58);
$job->{_chunks}->[-1]->status(TOBEDONE);
$job->{_chunks}->[-2]->status(DONE);
$job->merge_chunks(50);
$job->{_chunks}->[-2]->status(VERIFY);

# now:
#chunk id 1 (index 0) 10563177 status 8 (verify) 'aaa' => 'wcaaa'
#chunk id 66 (index 1) 1335777 status 3 (tobedone) 'wcaaa' => 'zaaaa' 1

$chunk = $job->find_chunk($client,'dummy secret',1,26*26*26);

# now:
#chunk id 1 (index 0) 10563177 status 8 (verify) 'aaa' => 'wcaaa'
#chunk id 66 (index 1) 17577 status 1 (issued) 'wcaaa' => 'wdaaa' 1
#chunk id 70 (index 2) 1318201 status 3 (tobedone) 'wdaaa' => 'zaaaa'

is ($chunk->{id}, 66, 'id 66');
is ($job->chunks(), 3, '3 chunks');

# also tests that a large verify chunk is never split up
$job->{_chunks}->[-1]->status(VERIFY);
$chunk = $job->find_chunk($client,'dummy secret',1,26*26*26);

# find_chunk() failed, no chunks small enough or ready to split
is (ref($chunk),'');

##############################################################################
# test a find_chunk() of job with only two chunks, one DONE, the other VERIFY

# bug #1: (would loop endlessly until v2.20_36)

$job->{_chunks}->[-2]->status(DONE);
$job->{_chunks}->[-1]->status(DONE);
$job->{_chunks}->[0]->status(TOBEDONE);
$job->merge_chunks(1);
$job->{_chunks}->[0]->status(DONE);
$job->{_chunks}->[1]->status(VERIFY);

# now:
#chunk id 1 (index 0) 10563177 status 2 (done) 'aaa' => 'wcaaa'
#chunk id 63 (index 1) 1335777 status 8 (verify) 'wcaaa' => 'zaaaa' 1

$job->{_chunks}->[1]->clear_verifiers();
$job->{_chunks}->[1]->add_verifier($client, DONE, '', 'cafebabe');

is ($job->chunks(), 2, '2 chunks');

$chunk = $job->find_chunk($client,'dummy_secret',2);
is (ref($chunk), '');					# got no chunk

is ($job->status(), TOBEDONE, 'status TOBEDONE');

# bug #2: first_tobedone >= $cnt would set job to DONE until v2.20_36

$job->{_first_tobedone} = 2;

$chunk = $job->find_chunk($client,'dummy_secret',2);
is (ref($chunk), '');					# got no chunk
is ($job->status(), TOBEDONE, 'TOBEDONE');

##############################################################################
# test for 'len:3' and 'first:3' notation in start/end

for my $len (qw/len first/)
  {
  $job = new Dicop::Data::Job ( start => $len . ':3', end => $len . ':5', 
  description => 'desc', owner => 'test', charset => $charset,
  ascii => 1, target => ' abcdef0123456789ABCDEF ', 
  );
  $job->{_parent} = Foo->new();
  $job->_construct();

  ok ($job->{start}, 'aaa');
  ok ($job->{end}, 'aaaaa');
  ok ($job->{target}, 'abcdef0123456789ABCDEF'); # test if spaces are stripped
  }

# test for 'len:0' and 'first:0' notation in start/end being illegal
for my $len (qw/len first/)
  {
  $job = new Dicop::Data::Job ( start => $len . ':0', end => $len . ':1', 
  description => 'desc', owner => 'test', charset => $charset,
  ascii => 1, target => ' abcdef0123456789ABCDEF ', 
  );
  $job->{_parent} = Foo->new();
  $job->_construct();

  like ($job->{_error}, qr/Length 0 in start='$len:0' must be/, 'Length 0 in start=');
   
  $job = new Dicop::Data::Job ( start => $len . ':1', end => $len . ':0', 
  description => 'desc', owner => 'test', charset => $charset,
  ascii => 1, target => ' abcdef0123456789ABCDEF ', 
  );
  $job->{_parent} = Foo->new();
  $job->_construct();
  
  like ($job->{_error}, qr/Length 0 in end='$len:0' must be > 0/, 'Length 0 in end=');
  }

##############################################################################
# test for 'last:3' notation in start/end

$job = new Dicop::Data::Job ( start => 'last:3', end => 'last:5', 
  description => 'desc', owner => 'test', charset => $charset,
  ascii => 1, target => ' abcdef0123456789ABCDEF ', 
  );
$job->{_parent} = Foo->new();
$job->_construct();

is ($job->{start}, 'zzz');
is ($job->{end}, 'zzzzz');
is ($job->{target}, 'abcdef0123456789ABCDEF');	# test if spaces are stripped

##############################################################################
# test for checklist handling

is (ref($job->{_checklist}), 'HASH');
is (scalar $job->checklist(), 0, 'checklist');

my $job_2 = new Dicop::Data::Job ( start => 'len:3', end => 'len:5', 
  description => 'desc', owner => 'test', charset => $charset,
  ascii => 1, target => ' abcdef0123456789ABCDEF ', 
  );
$chunk = $job->get_chunk(1);
$chunk->{job} = $job_2;				# simulate different job

is (ref($chunk), 'Dicop::Data::Chunk');
is ($chunk->{id}, 1, 'id 1');

is ($job->{lastchunk}, 2, 'lastchunk 2');
is ($job->{_modified}, 0, '_modified 0');
is ($job_2->{_modified}, 0);
my $copy = $job->check_also($chunk, $chunk->{start});
is (scalar $job->checklist(), 1);
is ($job->{lastchunk}, 3, 'made copy?');
is ($job->{_modified}, 1, 'now modified');
is ($job_2->{_modified}, 0, '_modified 0');

is ($chunk->{id},1, 'id 1');
is ($copy->{id},3, 'id 3');
is ($copy->{job}->{id},$job->{id});
is (ref($copy), 'Dicop::Data::Chunk::Checklist');

my $rc = $job->_checklist_del_chunk($chunk);
is (scalar $job->checklist(), 1, 'not found => not deleted');
is ($rc, undef, 'not deleted since not found');

## check get_chunk() looking into checklist, too
$rc = $job->get_chunk(3);
is (ref($rc), 'Dicop::Data::Chunk::Checklist');
is ($rc->{id}, 3, 'id 3');
is ($rc, $copy);

$rc = $job->_checklist_del_chunk($copy);
is (scalar $job->checklist(), 0);		# not found => not deleted
is (ref($rc),ref($job));

##############################################################################
# test for _new_chunk_id()

is ($job->{lastchunk}, 3);
is ($job->new_chunk_id(),4);
is ($job->{lastchunk}, 4);

##############################################################################
# check get_chunk also working in checklist

$chunk = new Dicop::Data::Chunk ( 
  job => $job_2, start => Math::String->new('aaa',$cs),
  end => Math::String->new('zaaaa',$cs), 
  );
$copy = $job->check_also($chunk, Math::String->new('abc',$cs) );
is (scalar $job->checklist(), 1);

$rc = $job->get_chunk($copy->{id});
is (ref($rc), 'Dicop::Data::Chunk::Checklist');
is ($rc, $copy);

##############################################################################
# check find_chunk() also working in checklist

$rc = $job->{_first_tobedone};

$chunk = $job->find_chunk($client,'dummy_secret',2);
is (ref($chunk), 'Dicop::Data::Chunk::Checklist');
is ($chunk->{id}, $copy->{id});
is ($chunk, $copy);

is ( $job->{_first_tobedone}, $rc, 'not changed');

##############################################################################
# check adding a job with newjob on (and also with charset id as
# newjob-charset and also with first:N and last:N

# 29 * 5 = 145 tests
for my $test (1..5)
  {
  my $start = '414141';
  my $end = '41414141';
  my $cs = $charset_upper;
  my $ascii = '';
  if ($test == 2)
    {
    $cs = $charset_upper->{id};
    }
  elsif ($test == 3)
    {
    $cs = $charset_upper;
    $start = 'len:3';
    $end = 'first:4';
    }
  elsif ($test == 4)
    {
    $cs = $charset_upper->{id};
    $start = 'len:3';
    $end = 'first:4';
    }
  elsif ($test == 5)
    {
    $cs = $charset_upper->{id};
    $start = 'AAA';
    $end = 'AAAA';
    $ascii = 'on';
    }
  $job = new Dicop::Data::Job ( start => 'aaa', end => 'zaaaa', 
    description => 'desc', owner => 'test', charset => $charset,
    ascii => 1,
    newjob => 'on', 
    'newjob-start' => $start,
    'newjob-end' => $end,
    'newjob-charset' => $cs,
    'newjob-rank' => '##rank##',
    'newjob-prefix' => 'Prefix',
    'newjob-ascii' => $ascii,
    'newjob-description' => '##description## pwd',
    );
  ok ( ref($job),'Dicop::Data::Job');
  
  $job->{_parent} = new Foo;
  $job->{jobtype} = $jobtype;
  $job->_construct();

  is ($job->{_error} || '', '');
  is ($job->chunks(), 2, '2 chunks');
  is ($job->chunks(DONE), 1, 'DONE' );
  is ($job->chunks(TOBEDONE), 1, 'TOBEDONE' );
  is ($job->chunks(FAILED), 0, 'FAILED' );
  is ($job->{_chunks}->[0]->status(), DONE, 'status');
  is ($job->{_chunks}->[1]->status(), TOBEDONE, 'status');
  is ($job->{_chunks}->[0]->{start}, 'aaa');
  is ($job->{_chunks}->[0]->{end}, 'aaa');
  is ($job->{_chunks}->[1]->{start}, 'aaa');
  is ($job->{_chunks}->[1]->{end}, 'zaaaa');
  is ($job->status(), TOBEDONE, 'status');
  is ($job->get('start'), '616161,703');
  is ($job->get_as_hex('start'), '616161');
  is ($job->get('end'), '7a61616161,11899655');
  is ($job->get_as_hex('end'), '7a61616161');
  is (ref($job->{_checklist}),'HASH');
  is ($job->size(), Math::String->new('zaaaa')->bsub('aaa')->as_number() + 1);
  is ($job->{_last_chunk_age_check}, 0, 'age check');
  is ($job->{_find_chunk_steps}, 0);		# DEBUG
  is ($job->{_first_tobedone}, undef);
  is ($job->get('prefix'),'');

  is ($job->get('newjob'),'on');
  is ($job->get('newjob-start'),'414141,703');
  is ($job->get('newjob-end'),'41414141,18279');
  is ($job->get('newjob-rank'),'##rank##');
  is ($job->get('newjob-description'),'##description## pwd');
  is ($job->get('newjob-prefix'),'Prefix');
  }

##############################################################################
# check find_chunk() doing proper check_age() in checklist
# TODO

$job->{jobtype} = Dicop::Data::Jobtype->new ( id => 5, fixed => 3, extrafields => 'username, foo_bar' );
$job->{extra0} = 'bar';
$job->{extra1} = 'baz test';

is (scalar $job->{jobtype}->extrafields(), 2, 'username, foo_bar');
is (join(",", $job->{jobtype}->extrafields()), 'username,foo_bar', 'extrafields()');

is ($job->extra_params(), 'username_bar;foo%5fbar_baz+test', 'extra_params');
is ($job->extra_fields(), "extra0=757365726e616d65,626172\nextra1=666f6f5f626172,62617a2074657374\n", 'extra_fields');

1; # all tests done

##############################################################################
# for debugging

sub chunks_in_list
  {
  my $job = shift;
  print "chunks in list\n"; my $i = 0;
  foreach my $c (@{$job->{_chunks}})
    {
    print "chunk id $c->{id} (index $i) ",$c->size()," status $c->{status}";
    print " (".Dicop::status($c->status()).")";
    print " '$c->{start}' => '$c->{end}'";
    print " $c->{client}->{id}" if ref($c->{client});
    print "\n";
    $i ++;
    }
  }
