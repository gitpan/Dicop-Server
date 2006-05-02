#!/usr/bin/perl -w

# Test for Dicop::Data - deleting objects

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 34;
  }

use Dicop qw/ISSUED TOBEDONE DONE VERIFY/;

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

is ($data->check(),undef, 'construct was ok');

is ($data->type(),'server', 'type');

# each 'type' has X entries, so we try to find them all
my $count = {
  cases => 1,
  charsets => 9,
  clients => 2,
  groups => 2,
  jobs => 5,
  jobtypes => 4,
  proxies => 1,
  results => 2,
  testcases => 2,
  users => 1,
  };

foreach my $key (keys %$count)
  {
  is ($data->$key(),$count->{$key}, $key);
  }

my $rc;

###############################################################################
# first things we can't delete (doesn't alter data)
$rc = $data->del_item( { type => 'charset', id => 1 } );
is ($data->charsets(),$count->{charsets}, 'cannot del charset');

# object does not exist (wrong type)
$rc = $data->del_item( { type => 'charsetss', id => 2 } );
is ($data->charsets(),$count->{charsets}, 'wrong type');

# object does not exist (wrong id)
$rc = $data->del_item( { type => 'charset', id => 111 } );
is ($data->charsets(),$count->{charsets}, 'wrong ID');

# need at least one user!
$rc = $data->del_item( { type => 'user', id => 1 } );
is ($data->users(),$count->{users}, 'need one user!');

# needed by some client
$rc = $data->del_item( { type => 'group', id => 1 } );
is ($data->groups(),$count->{groups}, 'group needed by some client');

$rc = $data->del_item( { type => 'case', id => 1 } );
is ($data->cases(),$count->{cases}, 'case needed by some jobs');

###############################################################################
# now delete some things
$rc = $data->del_item( { type => 'client', id => 2 } );
is ($data->clients(),$count->{clients}-1, 'deleted client');

# set both jobs to be done
$data->get_job(1)->{status} = TOBEDONE;
$data->get_job(2)->{status} = TOBEDONE;

$data->adjust_job_priorities();

is ($data->get_job(1)->{priority}, 10, 'priority 10');
is ($data->get_job(2)->{priority}, 90, 'priority 90' );
$rc = $data->del_item( { type => 'job', id => 1 } );
is ($data->jobs(),$count->{jobs}-1, 'deleted job');
# test that deletion of job adjusts priorities
is ($data->get_job(2)->{priority}, 100, 'priority 100' );

$rc = $data->del_item( { type => 'proxy', id => 10 } );
print "# $rc\n" unless
 is ($data->proxies(),$count->{proxies}-1, 'deleted proxy');

$rc = $data->del_item( { type => 'jobtype', id => 1 } );
is ($data->jobtypes(),$count->{jobtypes}-1, 'deleted jobtype');

$rc = $data->del_item( { type => 'result', id => 1 } );
is ($data->results(),$count->{results}-1, 'deleted result');

$rc = $data->del_item( { type => 'group', id => 2 } );
is ($data->groups(),$count->{groups}-1, 'deleted group');

$rc = $data->del_item( { type => 'testcase', id => 1 } );
is ($data->testcases(),$count->{testcases}-1, 'deleted testcase');

$rc = $data->del_item( { type => 'charset', id => 2 } );
is ($data->charsets(),$count->{charsets}-1, 'deleted charset #2');

# type with 's' at end
$rc = $data->del_item( { type => 'charsets', id => 1 } );
is ($data->charsets(),$count->{charsets}-2, 'deleted charset #1');

###############################################################################
# add a case

# prepare data
my $r = 'cmd_add;type_case';
$r .= ";description_some+test";
$r .= ";referee_me";
$r .= ";name_1234";

my $req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
my $result = ${ $data->add( $req ) };

like ($result, qr/case was added/, 'added');

# case 2 exists now
my $j = $data->get_case($count->{cases}+1);
is (ref($j), 'Dicop::Data::Case', 'case does exist' );

$rc = $data->del_item( { type => 'case', id => 2 } );
is ($data->cases(),$count->{cases}, 'deleted case');

###############################################################################
# EOF

1;

END
  {
  # clean up
  unlink 'dicop_request_lock' if -f 'dicop_request_lock';
  unlink 'dicop_lockfile' if -f 'dicop_lockfile';
  unlink 'test-worker/charsets.def' if -f 'test-worker/charsets.def';
  }  

