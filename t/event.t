#!/usr/bin/perl -w

# Test for Dicop::Data - adding objects

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 10;
  }

use Dicop qw/ISSUED TOBEDONE DONE VERIFY SUSPENDED SOLVED/;
use Dicop::Base qw/a2h time encode/;
use Dicop::Data;
use Dicop::Request;
use Dicop::Event;

Dicop::Event::handler( sub { } );	# zap error handler to be silent

$Dicop::Handler::NO_STDERR = 1;         # disable informative message

{
  no warnings;
  *Dicop::Data::flush = sub { };	# never flush the testdata
}

can_ok ('Dicop::Data', qw/
  _load_connector
  _connect_server
  _send_event
  _create_event
  /);

###############################################################################
###############################################################################
# Construct a Data object using testdata and testconfig
# Then check default and config entries

# remove any left-over charsets.def
unlink "test-worker/charsets.def" if -e "test-worker/charsets.def";
die ("Cannot unlink 'test-worker/charsets.def': $!")
  if -e "test-worker/charsets.def";

# now contruct data object
my $data = Dicop::Data->new( cfg_dir => './test-config', cfg => 'event.cfg', _warn => 'not' );

is ($data->check(),undef, 'construct ok');	# construct was okay

is ($data->type(),'server', 'type server');

my $rc;

###############################################################################
# _create_event() - failures

my $url = $data->_create_event( );
is ($url, undef, 'no event name');

$url = $data->_create_event( 'invalid_event' );
is ($url, undef, 'invalid event name');

$url = $data->_create_event( 'job_failed' );
is ($url, undef, 'valid event name, but no URL');

$data->{config}->{send_event_url_format} = 'http://192.168.1.2:89/event?casename=##casename##&text=##eventtext##';
$url = $data->_create_event( 'job_failed' );
is ($url, undef , 'valid event name, valid URL, but no job/case');

my $time = encode(scalar localtime(time()));

###############################################################################
# _create_event() - valid

$url = $data->_create_event( 'job_failed', $data->get_job(1) );
is ($url, 'http://192.168.1.2:89/event?casename=Default+case&text=Completed+job+%231+%28test+for+chaining+jobs%29,+but+did+not+find+any+result.%0a%0a' ,
          'valid url');

$url = $data->_create_event( 'new_job', $data->get_job(1) );
is ($url, 'http://192.168.1.2:89/event?casename=Default+case&text=Started+a+new+job+%231+%28test+for+chaining+jobs%29+with+charset%0a1+%28upper+ASCII+characters%29,+from+5+to+6+characters.%0a%0a' ,
          'valid url');

$url = $data->_create_event( 'found_result', $data->get_job(1), $data->get_result(1) );
is ($url, "http://192.168.1.2:89/event?casename=Default+case&text=$time".'%0aFound+a+result+for+job+%231+%28test+for+chaining+jobs%29:+%27ABCDE%27+%284142434445%29%0a%0a',
          'valid url');

###############################################################################
# EOF

1;

END
  {
  # clean up
  unlink 'dicop_request_lock' if -f 'dicop_request_lock';
  unlink 'dicop_lockfile' if -f 'dicop_lockfile';
  }  

