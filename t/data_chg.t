#!/usr/bin/perl -w

# Test for Dicop::Data - chaning objects

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 83;
  }

use Dicop qw/ISSUED TOBEDONE DONE VERIFY SUSPENDED SOLVED/;
use Dicop::Data;

require "common.pl";

Dicop::Event::handler( sub { } );	# zap error handler to be silent

$Dicop::Handler::NO_STDERR = 1;         # disable informative message

{
  no warnings;
  *Dicop::Data::flush = sub { };		# never flush the testdata
}

###############################################################################
# Construct a Data object using testdata and testconfig
# Then check default and config entries

# remove any left-over charsets.def
unlink "test-worker/charsets.def" if -e "test-worker/charsets.def";
die ("Cannot unlink 'test-worker/charsets.def': $!")
  if -e "test-worker/charsets.def";

#############
#############
# contruct data object
#############
#############

my $data = Dicop::Data->new( cfg_dir => './test-config', _warn => 'not' );

is ($data->check(),undef);	# construct was okay

is ($data->type(),'server');

# each 'type' has X entries, so we try to find them all
my $count = {
  charsets => 9,
  clients => 2,
  groups => 2,
  jobs => 5,
  jobtypes => 4,
  proxies => 1,
  results => 2,
  testcases => 2,
  users => 1,
  cases => 1,	# one auto created
  };

foreach my $key (keys %$count)
  {
  is ($data->$key(),$count->{$key}, "$count->{$key} $key");
  }

my $rc;

###############################################################################
###############################################################################
# changes that don't work e.g. leave the object alone

$rc = $data->change( {  type => 'testcase', jobtype => 2, id => 1,
			start => '30303031', end => '303030303030',
			target => 'target/test/test3.tgt',
			charset => 2, description => 'wizzard', result => '30303033',
			dirty => 1 } );

is ($rc,"437 Could not change item: Field 'start' ends not in '000'");

# before:
#Dicop::Data::Testcase {
#  charset = 1
#  description = "test for test job"
#  dirty = 0
#  end = "4141414141,475255"
#  id = 1
#  jobtype = 1
#  result = "41424344,19010"
#  start = "41414141,18279"
#  target = 41424344
#  }

my $tc = $data->get_testcase(1);
is ($tc->{start}, 'AAAA', 'start' );
is ($tc->{end}, 'AAAAA', 'end' );
is ($tc->{result}, 'ABCD', 'result' );
is ($tc->{target}, '41424344', 'target' );
is ($tc->{description}, 'test for test job', 'description' );
is (ref($tc->{charset}), 'Dicop::Data::Charset', 'charset' );
is (ref($tc->{jobtype}), 'Dicop::Data::Jobtype', 'jobtype' );
is ($tc->{charset}->{id}, 1, 'charset #1' );
is ($tc->{jobtype}->{id}, 1, 'jobtype #1' );

###############################################################################
###############################################################################
# now change some things

###############################################################################
# change job

$data->get_job(1)->{status} = TOBEDONE;
$data->get_job(2)->{status} = TOBEDONE;
$data->adjust_job_priorities();

is ($data->get_job(1)->{priority}, 10, 'new priority is 10' );
is ($data->get_job(2)->{priority}, 90, 'new priority is 90' );
my $job = $data->get_job(1);
is ($job->{rank}, 100, 'rank 100' );
is ($job->{status}, TOBEDONE, 'status TOBEDONE' );
is ($job->{maxchunksize}, 0, 'new max chunk size 0' );

# save ref to see if it stays
my $old_chunk_list = $job->{_chunks}->[0]->as_string();

$job = $data->get_job(2);
is ($job->{rank}, 80, 'rank 80' );
is ($job->{status}, TOBEDONE, 'status TOBEDONE' );
is ($job->{maxchunksize}, 0, 'maxchunksize 0' );

$rc = $data->change( { type => 'job', id => 1, rank => 15, maxchunksize => 5,
			description => 'test+test',
			status => 'suspended', dirty => 1 } );

is ($data->jobs(),$count->{jobs}, 'cnt of jobs');
# only one running job left, so it's priority should have changed, too
$job = $data->get_job(2);
is ($job->{_error}, '', 'no error' );
is ($job->{priority}, 100, 'priority 100' );
# these did not change
is ($job->{rank}, 80, 'rank still 80' );
is ($job->{status}, TOBEDONE, 'status TOBEDONE' );
is ($job->{maxchunksize}, 0, 'maxchunksize 0' );
is ($job->{_modified}, 0, "unmodified since the priority doesn't cause a flush" );

$job = $data->get_job(1);
is ($job->{_error}, '', 'no error' );
# these did change
is ($job->{rank}, 15, 'rank now 15' );
is ($job->{description}, 'test test', 'description changed' );
is ($job->{status}, SUSPENDED, 'status changed' );
is ($job->{maxchunksize}, 5, 'maxchunksize now 5' );
is ($job->{_modified}, 1, 'was modified' );

is ($job->{_chunks}->[0]->as_string(), $old_chunk_list );

###############################################################################
# change testcase

$rc = $data->change( {  type => 'testcase', jobtype => 2, id => 1,
			start => '30303030', end => '3030303030',
			target => 'target/test/test3.tgt',
			charset => 2, description => 'wizzard+test', result => '30303030',
			dirty => 1 } );

$tc = $data->get_testcase(1);
is ($tc->{start}, '0000' );
is ($tc->{end}, '00000' );
is ($tc->{result}, '0000' );
is ($tc->{target}, 'target/test/test3.tgt' );
is ($tc->{description}, 'wizzard test' );
is ($tc->{_modified}, 1 );
is (ref($tc->{charset}), 'Dicop::Data::Charset' );
is (ref($tc->{jobtype}), 'Dicop::Data::Jobtype' );
is ($tc->{charset}->{id}, 2, 'charset #2' );
is ($tc->{jobtype}->{id}, 2, 'jobtype #2' );


###############################################################################
# change case

$rc = $data->change( {  type => 'case', 
			id => 1,
			name => '1234567', description => 'some',
			url => 'http://127.0.0.1',
			referee => 'me',
			} );

$tc = $data->get_case(1);
is ($tc->{name}, '1234567' );
is ($tc->{description}, 'some' );
is ($tc->{referee}, 'me' );
is ($tc->{url}, 'http://127.0.0.1' );

# change case to empty string for one field

$rc = $data->change( {  type => 'case', 
			id => 1,
			name => '12345671', description => 'some1',
			url => '',
			referee => 'me1',
			} );

$tc = $data->get_case(1);
is ($tc->{name}, '12345671' );
is ($tc->{description}, 'some1' );
is ($tc->{referee}, 'me1' );
is ($tc->{url}, '' );

##############################################################################
# change chunk

$job = $data->get_job(1);
my $c = $job->get_chunk(1);
is ($c->{status}, DONE, 'done' );
is (ref($c->{job}), 'Dicop::Data::Job' );

$rc = $data->change( {  type => 'chunk', job => 1, id => 1,
			status => 'solved',
			dirty => 1 } );

$job = $data->get_job(1);
$c = $job->get_chunk(1);

is ($c->{status}, SOLVED, 'solved');

##############################################################################
# change client

my $client = $data->get_client(1);
$rc = $data->change( {  type => 'client', id => 1,
			ip => '127.0.0.42', mask => '255.255.255.255',
			description => 'description client', name => 'myclient',
			dirty => 1 } );

$c = $data->get_client(1);

print "# Got: $rc\n" unless
 ok (ref($rc), 'SCALAR');
is ($c->error(), '');
is ($c->{description}, 'description client');
is ($c->{name}, 'myclient');
is ($c->{ip}, '127.0.0.42');
is ($c->{mask}, '255.255.255.255');
is ($c->{group}->{id}, 1, 'group #1');

$client = $data->get_client(1);
$rc = $data->change( {  type => 'client', id => 1,
			ip => '127.0.0.42', mask => '255.255.255.255',
			description => 'description client', name => 'myclient',
			group => 2, dirty => 1 } );

print "# Got: $rc\n" unless
  ok (ref($rc), 'SCALAR');
is ($c->error(), '');
is ($c->{group}->{id}, 2, 'group #2');
is ($c->{id}, 1, 'id #1');

###############################################################################
# change group

my $txt = $data->handle_requests(
    '192.168.1.1',
    'submit=true&cmd=change&type=group&id=1&style=blue&name=testtest&description=somefoo'
   .'&auth-pass=MyPrecious&auth-user=Gollum'
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
like ($txt, qr/group was changed(.|\n)*somefoo/, 'could change group');

###############################################################################
# change jobtype

$c = $data->get_client(1);
$c->{job_speed}->{1} = 189;
$c->{job_speed}->{4} = 171;
$c->_fix_job_speeds();
is ($c->{job_speed}->{1}, 189, 'job speed stays');		

$txt = $data->handle_requests(
    '192.168.1.1',
    'submit=true&cmd=change&type=jobtype&id=1&style=blue&speed=50&name=foo&description=somefoo&charset=1&minlen=1'
   .'&auth-pass=MyPrecious&auth-user=Gollum'
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
like ($txt, qr/jobtype was changed(.|\n)*somefoo/, 'could change jobtype');

$c = $data->get_jobtype(1);

is ($c->{speed}, 50);

$c = $data->get_client(1);
is ($c->{job_speed}->{1}, 50, 'job speed got reset');		
is ($c->{job_speed}->{2}, 50, 'job speed got reset');		
is ($c->{job_speed}->{4}, 171, 'job speed stays');

###############################################################################
# EOF

1;

END
  {
  # clean up
  unlink 'dicop_request_lock' if -f 'dicop_request_lock';
  unlink 'dicop_lockfile' if -f 'dicop_lockfile';
  unlink 'test-worker/charsets.def' if -f 'test-worker/charsets.def';
  unlink 'target/2.set' if -f 'target/2.set';
  }  


