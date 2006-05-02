#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../../lib';
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 143;
  }

# dummy parent for client to get group, job etc
package Foo;

require "common.pl";

use Dicop::Data::Group;
use Dicop::Data::Job;
use Dicop::Data::Chunk;
use Dicop::Data::Jobtype;
use Dicop qw/DONE/;

my $group = Dicop::Data::Group->new();
my $jobtype = Dicop::Data::Jobtype->new( id => 5, fixed => 3);
my $jobtype_2 = Dicop::Data::Jobtype->new( id => 7, fixed => 3);
my $job = Dicop::Data::Job->new( jobtype => $jobtype );
my $job_2 = Dicop::Data::Job->new( jobtype => $jobtype_2 );
my $job_3 = Dicop::Data::Job->new( jobtype => $jobtype );

$job_3->{status} = DONE;

sub new
  {
  my $self = {};

  bless $self;
  }

sub modified
  {
  }

sub get_group
  {
  return $group;
  }

sub get_job
  {
  my ($self,$id) = @_;
 
  return $job if $id < 10;
  return $job_2 if $id < 20;
  $job_3;
  }

package main;

require "common.pl";

use Dicop qw/DONE FAILED TIMEOUT/;
use Dicop::Data::Client;
use Dicop::Data::Chunk;

my $client = Dicop::Data::Client->new ( 
  name => 'test = a',
  ip => "100.200.300.400",
  mask => "100.200.300.400",
  connects => '1,2,3',
  );
$client->{_parent} = new Foo;
$client->_construct();

#############################################################################
# we did survive until here, check defaults

is ($client->is_proxy(), 0, 'not a proxy');

is ($client->get('id'),1, 'id');
is ($client->get('name'), 'test  a', 'name');
is ($client->{ip}, '100.200.300.400', 'ip');
is ($client->{mask}, '100.200.300.400', 'mask');
is ($client->{trusted}, 0, 'untrusted by default');
is (join(":", @{$client->{connects}}), '1:2:3', 'connect');

is (join(':', $client->architectures()), '', 'architectures()');
$client->{arch} = 'linux';
is (join(':', $client->architectures()), 'linux', 'architectures()');
$client->{arch} = 'linux-i386';
is (join(':', $client->architectures()), 'linux-i386:linux', 'architectures()');
$client->{arch} = 'linux-i386-foo';
is (join(':', $client->architectures()), 'linux-i386-foo:linux-i386:linux', 'architectures()');

for my $k (qw/done_keys lost_keys/)
  {
  is ($client->{$k}, 0, $k);
  is (ref($client->{$k}), 'Math::BigInt', "ref $k");
  }

is ($client->punish(0), $client, 'punish');

is (ref($client->{connects}),'ARRAY', 'connects');
is (ref($client->{failures}),'HASH', 'failures');
is (ref($client->{job_speed}),'HASH', 'job_speed');
is (ref($client->{chunks}),'HASH', 'chunks');

is ($client->get('last_error'), 0, 'no error yet');
is ($client->get('last_error_msg'), '', 'no error yet');

my $zero_date = scalar localtime(0);
is ($client->get_as_string('last_error'), $zero_date, 'no error yet');
is ($client->get_as_string('last_error_msg'), '', 'no error yet');

$client->{chunks}->{2} = 1234;
$client->{chunks}->{3} = 4321;
is ($client->get('chunks'),'2_1234,3_4321', 'chunks');
$client->{chunks} = {};						# reset

# test speed setting and adjusting
is ($client->{speed}, 100, 'speed');

my $js = $client->job_speed(2,240);
is ($js, 240, 'js');
is ($client->{job_speed}->{2},240, 'job_speed');

$client->count_failure(5,0);					# init counter
is ($client->{failures}->{5}->[0],0, 'no failures');

is ($client->{failures}->{5}->[0],$client->failures(5), 'failures');
is ($client->{speed}, 100, 'speed 100');

is ($client->{job_speed}->{2}, 240, 'speed');

$client->adjust_speed (48000,100,2,DONE);		# size 48000, took 100, job 2 => 480/s

is ($client->{speed}, 360, '240 + 480 / 2 => 360 and jobtype speed is 100 => 360 / 100 => 3.6 * 100');
is ($client->{job_speed}->{2}, 360, 'speed');

$client->adjust_speed (36000,100,2,DONE);	# nothing changes
is ($client->{speed}, 360, 'speed');
is ($client->{job_speed}->{2},360, 'js');

$client->adjust_speed (12000,100,2,DONE);	# 3.6+1.5 => 4.8 / 2 => 2.4
is ($client->{speed}, 240, 'speed');
is ($client->{job_speed}->{2},240,'js');

$client->adjust_speed (100,100,2,TIMEOUT);
is ($client->{speed}, 48, 'set to 20% due to failure');
is ($client->{job_speed}->{2},48, '240 * 0.2');

$client->adjust_speed (100,100,2,FAILED);
is ($client->{speed}, 48, 'nothing should change');
is ($client->{job_speed}->{2},48, '240 * 0.2');

$client->adjust_speed (48000,100,2,DONE);	# 4800 pwds in 100 s
is ($client->{speed}, 96, 'and doubled again');
is ($client->{job_speed}->{2},48*2,'48*2');

$client->adjust_speed (480000,100,2,DONE);
is ($client->{speed}, 96*2, 'not more than 2 times');
is ($client->{job_speed}->{2},48*2*2, '48*2*2');

# if chunk is too small, increase by 20% (>5 seconds) or 50% (< 5 seconds)
$client->adjust_speed (48000,4,2,DONE);
is ($client->{speed}, 96*2*1.5,'+50%');
is ($client->{job_speed}->{2},48*2*2*1.5, '48*2*2*1.5');

$client->adjust_speed (48000,6,2,DONE);
is ($client->{speed}, int(96*2*1.5*1.2));		# +20%
is ($client->{job_speed}->{2},int(192*1.5*1.2));

# failure counter and count_failures
is ($client->failures(5),0, 'initially 0');
$client->count_failure(5,3);			# failed a test for jobtype 5');
is ($client->failures(5), 3, 'now 3');

$client->count_failure(5,0);
my $time = $client->{failures}->{5}->[1];
my ($cnt,$time1) = $client->failures(5);
is ($time1,$time, 'in list mode (0,$time)');
is ($cnt,$time,'was reset');

$client->count_failure(5,2);			# add 2
is ($client->failures(5),2, '2 failures');

$client->count_failure(5,0);			# reset counters
is ($client->failures(5),0, '0 failures');

$client->count_failure(5,5);			# add again 5
is ($client->failures(5),5, '5 failures');

# test report and failure counter
my $chunk = Dicop::Data::Chunk->new( start => 'aaa', end => 'aaaa' );
$chunk->{_size} = 7;				# fake size
$chunk->status(FAILED);
is ($chunk->status(),FAILED, 'FAILED');
is ($client->{failed_chunks}, 0, '0 failed chunks');

$job->{id} = 2;
$client->report ($job,$chunk,100,$chunk->{_size});
is ($client->{failed_chunks}, 1, '1 failed');
is ($client->failures(5),6, '4+1');
is ($client->{uptime}, 0, '0 uptime');
is ($client->{done_chunks}, 0, 'done_chunks');
is ($client->{done_keys}, 0, 'done_keys');
is (scalar keys %{$client->{chunks}},0, 'no chunks yet');

$chunk->status(DONE);
$client->report ($job,$chunk,1004,$chunk->{_size});
is ($client->{failed_chunks}, 1, 'still 1');
is ($client->failures(5),6, 'still 6');
is ($client->{done_keys}, $chunk->{_size}, 'size');
is ($client->{done_chunks}, 1, 'done 1');
is ($client->{chunks}->{2}, 1, 'job 5');
is ($client->{uptime}, 1004, 'uptime');
is ($client->{online},0, 'is online');
is ($client->{went_offline},0, 'not offline');

# discard job deletes job speed
$client->discard_job(2);
is (exists $client->{job_speed}->{2} || 0,0, 'js');
is (exists $client->{chunks}->{2} || 0,0, 'chunks');

$client->connected('architecture','v1.02','OS',123,1234);
is ($client->{arch},'architecture');
is ($client->{os},'OS');
is ($client->{version},'v1.02');
is ($client->{_modified},1,'modified');
is ($client->{temp},'123','temp');
is ($client->{fan},'1234','fan');
is ($client->{cpuinfo}->[0],'unknown CPU');
is ($client->{cpuinfo}->[1],0, 'cpuinfo');
is (scalar @{$client->{connects}}, 4, '1+3 connects');

is ($client->get('last_error'), 0, 'no error yet');
is ($client->get('last_error_msg'), '', 'no error yet');

is ($client->get_as_string('last_error'), $zero_date, 'no error yet');
is ($client->get_as_string('last_error_msg'), '', 'no error yet');

$client->connected('architecture','v1.02','OS',123,1234,'AMD,350000000');
is ($client->{cpuinfo}->[0],'AMD');
is ($client->{cpuinfo}->[1],'350000000', 'Mhz');

# speed_factor

$client->{job_speed} = {};			# clear data
$client->{failures} = {};
$client->{failures}->{3} = [ 3, 0, 0 ];		# clear data
$client->{job_speed}->{0} = 0;			# ignored due to == 0
$client->{job_speed}->{1} = 0;			# ditto
$client->{job_speed}->{2} = 100;		# not ignored
$client->{job_speed}->{4} = 200;		# factor 2
$client->{job_speed}->{5} = 300;		# factor 3, sum =>  5/2 => 2.5
$client->{job_speed}->{6} = 500;		# factor 5, sum => 10/3 => 3.33
$client->{job_speed}->{12} = 10;		# ignored 
$client->{failures}->{7} = [ 4, 0 ];		# ignored, more than 3 failures (4 > 3)
$client->{job_speed}->{20} = 500;		# ignored, not running
$client->speed_factor();
is ($client->{speed},275);			#  11 / 4 = 2.75
is ($client->get_as_string('speed_factor'),2.75);

###############################################################################
# connects and check rate-limitation

$time = Dicop::Base::time();				# now (plus minus 1 second)
$client->{last_connect} = $time;

$client->{connects} = [];
for (my $i = 0; $i < 25; $i ++)
  {
  my $rc = $client->connected('architecture','v1.02','OS',123,1234,'',$time);
  $time += 3600;	# simulate a connect per hour
  }
is (scalar @{$client->{connects}}, 24, 'exactly 24 connects');
is ($client->{chunk_time},3600, 'avrg one hour');

# rate-limit

$client->{chunk_time} = 0;
$client->{last_connect} = $time;
$client->{connects} = [];
for (my $i = 0; $i < 21; $i ++)
  {
  push @{$client->{connects}}, $time; $time ++;	# at least one second 
  }
# these 22 are ok
my $rc = $client->connected('architecture','v1.02','OS',123,1234,'',$time++);
is (scalar @{$client->{connects}}, 22,'22 connects');
is ($client->{chunk_time},1,'time');
is ($rc,$client,'client');

# but 23 is an unlucky number
$rc = $client->connected('architecture','v1.02','OS',123,1234,'',$time);
is (scalar @{$client->{connects}}, 22);	# still 22, not added 
is ($client->{chunk_time},1);
is ($rc,302);				# code 302 means rate-limit kicked in

# check some fake keys for HTMLification

$time = Dicop::Base::time();
$client->{last_connect} = 0;			# never connect
is ($client->get_as_string('last_connectcolor'), 'nocon');
$client->{last_connect} = $time-20;		# 20 seconds ago
is ($client->get_as_string('last_connectcolor'), 'online');
$client->{last_connect} = $time-3603;		# 1 hour, 3 seconds ago
is ($client->get_as_string('last_connectcolor'),'unknown');
$client->{last_connect} = $time-(2*3600+3);	# 2 hours, 3 seconds ago
is ($client->get_as_string('last_connectcolor'),'offline');

$client->{last_chunk} = 0;			# never connect
$client->{last_connect} = 0;			# never connect
is ($client->get_as_string('last_chunkcolor'), 'nocon');
$client->{last_connect} = $time - 20;		# not yet return
is ($client->get_as_string('last_chunkcolor'), 'noreturn');
$client->{last_chunk} = $time-20;		# 20 seconds ago
is ($client->get_as_string('last_chunkcolor'), 'online');
$client->{last_chunk} = $time-3603;		# 1 hour, 3 seconds ago
is ($client->get_as_string('last_chunkcolor'), 'unknown');
$client->{last_chunk} = $time-(2*3600+3);	# 2 hours, 3 seconds ago
is ($client->get_as_string('last_chunkcolor'), 'offline');

# cpuinfo
$client->{cpuinfo} = [ 'unknown CPU', 0];
is ($client->get_as_string('cpuinfo'),'unknown CPU, 0 MHz');
$client->{cpuinfo} = [ 'AMD', '851.123' ];
is ($client->get_as_string('cpuinfo'),'AMD, 851 MHz');

is ($client->is_online(),0);
is ($client->is_online(3600),0);
is ($client->went_offline(),0);

$client->{online} = 1;
is ($client->is_online(),1);
is ($client->is_online(3600),0);
is ($client->went_offline(),1);
is ($client->went_offline(),0);		# only one time 1

is ($client->{lost_chunks},0, 'zero lost chunks');
$client->lost_chunk($chunk);
is ($client->{lost_chunks},1, '1 lost chunk');
is ($client->{lost_keys},7, 'lost keys 7');

# check that fields retain their BigNumberiness

my $clone = Dicop::Item::from_string($client->as_string());
for my $k (qw/done_keys lost_keys/)
  {
  is (ref($clone->{$k}), 'Math::BigInt', 'isa a Math::BigInt');
  }

#############################################################################
# check that terminate all does indeed try to terminate the client

$client->terminate();
$rc = $client->connected('architecture','v1.02','OS',123,1234,'',$time);
is (scalar @{$client->{connects}}, 22, 'still 22, not added'); 
is ($client->{send_terminate},0, 'not again');
is ($rc,463, 'code 463 means terminator kicked in');

# check that the job_speed is preserved correctly
#$clone = $client->as_string();
#print "# $clone\n" unless
# ok ($clone =~ /\bjob_speed = 1_100_100\b/, 1);

#############################################################################
# check that error message and time are stored

$rc = $client->connected('architecture','v1.02','OS',123,1234,'',$time,'some+error+occured');

is ($client->get('last_error'), $time, 'error time');
is ($client->get('last_error_msg'), 'some+error+occured', 'error stored encoded');

is ($client->get_as_string('last_error'), scalar localtime($time), 'error time');
is ($client->get_as_string('last_error_msg'), 'some error occured', 'error returned decoded');

#############################################################################
# reset client

isnt (scalar keys %{$client->{job_speed}}, 0, 'data exists');
isnt (scalar @{$client->{connects}}, 0, 'data exists');
isnt (scalar keys %{$client->{failures}}, 0, 'data exists');
isnt ($client->{speed}, 100, 'data exists');

$client->reset();

is (scalar keys %{$client->{job_speed}}, 0, 'data exists');
is (scalar @{$client->{connects}}, 0, 'data exists');
is (scalar keys %{$client->{failures}}, 0, 'data exists');
is ($client->{speed}, 100, 'data exists');
is (ref($client->{speed}), 'Math::BigFloat', 'speed is bigfloat');
is ($client->get_as_string('last_error'), $zero_date, 'no error yet');
is ($client->get_as_string('last_error_msg'), '', 'no error yet');

$client->store_error (1,'Some+error');
$zero_date = scalar localtime(1);
is ($client->get_as_string('last_error'), $zero_date, 'error');
is ($client->get_as_string('last_error_msg'), 'Some error', 'error msg decoded');

