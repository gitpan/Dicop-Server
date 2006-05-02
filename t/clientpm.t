#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 933;
  use_ok qw/Dicop::Client/;
  }

can_ok ('Dicop::Client', qw/
  _delete_temp_files
  /);

use File::Spec;

$Dicop::Client::NO_STDERR = 1;		 # disable informative messages

###############################################################################
# break_chunk (normal mode)

my $hash = Dicop::Client->_break_chunk( 'job_5;test_4;data_1,2,3' );
is (ref($hash),'HASH');
is ($hash->{job},5, 'job 5');
is ($hash->{test},4, 'test 4');
is (ref $hash->{data},'ARRAY');
is ($hash->{data}->[0],1, 'is 1');
is ($hash->{data}->[1],2, 'is 2');
is ($hash->{data}->[2],3, 'is 3');
is (scalar keys %$hash,3, '3 keys');

# break_chunk (chunk description file JDF)
$hash = Dicop::Client->_break_chunk( 'chunkfile_target%2fdata%2f3%2f3%2d2%2etxt' );
is (ref($hash),'HASH');
is ($hash->{chunkfile},'target/data/3/3-2.txt');
is (scalar keys %$hash,1, '1 key');

# break_chunk (chunk description file CDF)
$hash = Dicop::Client->_break_chunk( 'chunkfile_target%2fdata%2f3%2f3%2d2%2etxt;token_1234567890abcdef' );
is (ref($hash),'HASH');
is ($hash->{chunkfile},'target/data/3/3-2.txt');
is ($hash->{token},'1234567890abcdef');
is (scalar keys %$hash,2, '2 keys');

###############################################################################
# extract_result

my ($code,$res) = Dicop::Client->_extract_result( 
"Last tested password in hex was '303030'\nStopcode is '0'" );
is ($code,0, 'code 0');
is ($res,'303030', 'res 303030');

###############################################################################
# object stuff

my $client = new Dicop::Client ( id => 55, config => 'client.cfg', 
 language => 'de', debug => 0, server => 'server123', _no_warn => 1,
 test => 1, chunks => 12, via => 'LWP', retries => 4711, chunk_count => 42, );

is (ref($client),'Dicop::Client');
is ($client->{test},1, '1 test');
is ($client->{chunks},12, '12 chunks');
is ($client->{cfg}->{server},'http://server123:8888/');
is ($client->{id},'55','overriding config file');
is ($client->{cfg}->{language},'de');
is ($client->{done_chunks},0, '0 done chunks');
is ($client->{via},'Dicop::Client::LWP');
is ($client->{cfg}->{retries}, 4711, 'retries: 4711');
is ($client->{cfg}->{chunk_count}, 42, 'the answer is');

is (ref($client->{file_hash}),'HASH');
for my $k (qw/ident more_work test_cases/)
  {
  is (ref($client->{$k}),'Dicop::Request');
  is ($client->{$k}->error(),'');
  }

###############################################################################
# via defaults to LWP

$client = new Dicop::Client ( config => 'client.cfg', _no_warn => 1, ); 
is ($client->{id},'1234');		# from config file
is ($client->{test},0);
is ($client->{chunks},0);
is ($client->{done_chunks},0);
is ($client->{debug},0);
is ($client->{cfg}->{language},'en');
is ($client->{cfg}->{retries}, 16);
is ($client->{cfg}->{chunk_count}, 1);

###############################################################################
# retries and chunk_count in cfg

$client = new Dicop::Client ( config => 'client2.cfg', _no_warn => 1, ); 
is ($client->{id},'1234');		# from config file
is ($client->{test},0);
is ($client->{chunks},0);
is ($client->{done_chunks},0);
is ($client->{debug},0);
is ($client->{cfg}->{language},'en');
is ($client->{cfg}->{retries}, 8);
is ($client->{cfg}->{chunk_count}, 2);

###############################################################################
# retries and chunk_count in cfg and commandline

$client = new Dicop::Client ( config => 'client2.cfg', retries => 18, _no_warn => 1,
  chunk_count => 12 ); 
is ($client->{id},'1234');		# from config file
is ($client->{test},0);
is ($client->{chunks},0);
is ($client->{done_chunks},0);
is ($client->{debug},0);
is ($client->{cfg}->{language},'en');
is ($client->{cfg}->{retries}, 18);
is ($client->{cfg}->{chunk_count}, 12);

###############################################################################
# test loading of Dicop::Client::wget

$client = new Dicop::Client ( id => 55, config => 'client.cfg', 
 language => 'de', debug => 0, server => 'server123', _no_warn => 1,
 test => 1, chunks => 12, via => 'wget' );

is (ref($client),'Dicop::Client');
is ($client->{test},1);
is ($client->{via},'Dicop::Client::wget');
is (ref($client->{ua}),'Dicop::Client::wget');

###############################################################################
# test loading of Dicop::Client::wget with arguments

$client = new Dicop::Client ( id => 55, config => 'client.cfg', 
 language => 'de', debug => 0, server => 'server123', _no_warn => 1,
 test => 1, chunks => 12, via => 'wget,proxy=on' );

is (ref($client),'Dicop::Client');
is ($client->{test},1);
is ($client->{via},'Dicop::Client::wget');
is (ref($client->{ua}),'Dicop::Client::wget');
is ($client->{ua}->{proxy},'on');

###############################################################################
# test for parsing server text responses

my $r;

$r = $client->_parse_responses('<PRE>');
is (scalar @$r,0, '0 responses');

$r = $client->_parse_responses('<PRE>\nref0000 200 job_20;start_656565');
is (scalar @$r,0, '0 responses');

$r = $client->_parse_responses(
  "<PRE>\nreq0001 200 token_1234;type_2;set_15;worker_des-1.03;start_65656565;end_6565656565;target_66656565;size_17576");
is (scalar @$r,1, '1 response');

$r = $client->_parse_responses(
  "req0001 200 foo_1\nreq0001 100 blah\n<ignore>\nreq0001 100 foo");
is (scalar @$r,1, '1 response');

###############################################################################
# test for handling the parsed responses

# 100        : ignore
#   1 .. 199 : system message
# 200        : work for you
# 201 .. 299 : accepted
# 300 .. 399 : soft error
# 400 .. 449 : hard error on single request
# 450 .. 499 : hard error on all requests

#############################################################################

$client->{tobesent}->{req0001} = { cmd => 'test' };
$r = $client->_handle_responses( [ [ 'req0001', 1, 'ignore'] ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 0, 'request not sent again');

$client->{tobesent}->{req0001} = { cmd => 'test' };
$r = $client->_handle_responses( [ [ 'req0001', 199, 'ignore'] ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 0, 'request not sent again');

$client->{tobesent}->{req0001} = { cmd => 'auth' };
$r = $client->_handle_responses( [ [ 'req0001', 100, 'ignore'] ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 1, 'auth request sent again');

# disable the _retrieve_files() routine, so that the next test doesn't actually try
# to do this

no warnings 'redefine';
my @k;
*Dicop::Client::_retrieve_files = sub { @k = @_; 0; };

#############################################################################
# setup fake output routine to catch output from client
my @lines;
*Dicop::Client::output = sub { push @lines, @_; };

$client->{tobesent}->{req0001} = { cmd => 'test' };
$r = $client->_handle_responses( [ [ 'req0001', 200, 'worker_test.pl;hash_12345677890'] ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 0, 'request not sent again');
is (scalar @{$client->{todo}}, 1, 'work was stored');
$client->{todo} = [];				# clear todo

$client->{tobesent}->{req0001} = { cmd => 'test' };
$r = $client->_handle_responses( [ [ 'req0001', 201, 'worker_test.pl;hash_1234567890'] ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 0, 'request not sent again');

$client->{tobesent}->{req0001} = { cmd => 'test' };
$r = $client->_handle_responses( [ [ 'req0001', 299, 'accept'] ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 0, 'request not sent again');

$client->{tobesent}->{req0001} = { cmd => 'test' };
$r = $client->_handle_responses( [ [ 'req0001', 300, 'accept'] ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 1, 'NOK, sent request again');

$client->{tobesent}->{req0001} = { cmd => 'test' };
$r = $client->_handle_responses( [ [ 'req0001', 399, 'accept'] ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 1, 'NOK, sent request again');

$client->{tobesent}->{req0001} = { cmd => 'test' };
$r = $client->_handle_responses( [ [ 'req0001', 400, 'accept'] ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 0, 'NOK, but dont sent request again');

$client->{tobesent}->{req0001} = { cmd => 'test' };
$client->{tobesent}->{req0002} = { cmd => 'test2' };
$r = $client->_handle_responses( [ 
  [ 'req0001', 300, 'accept'], 
  [ 'req0002', 200, 'worker_test.pl;hash_1234567890'] 
 ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 1, '1 NOK, 1 OK');

$client->{tobesent}->{req0001} = { cmd => 'test' };
$r = $client->_handle_responses( [ [ 'req0001', 449, 'accept'] ], 1 );
is ($r,0, 'r is 0');
is (keys %{$client->{tobesent}}, 0, 'NOK, but dont resent request');

#############################################################################
#test hard errors

for my $msg (450..499)
  {
  $client->{tobesent}->{req0001} = { cmd => 'test' };
  $r = $client->_handle_responses( [ [ 'req0001', $msg, 'deny'] ], 1 );
  is ($r,1, 'error');

  # send queue is not cleared by handle_responses any longer, so simulate it:
  $client->_clear_send_queue() if $r != 0;
  is (keys %{$client->{tobesent}}, 2, 'cleared queue');
  is ($client->{tobesent}->{req0001}->{cmd}, 'auth'); 		# send ident
  is ($client->{tobesent}->{req0002}->{cmd}, 'request'); 	# send work request

  $client->{tobesent}->{req0001} = { cmd => 'test' };
  $client->{tobesent}->{req0002} = { cmd => 'test2' };
  $r = $client->_handle_responses( [ 
    [ 'req0001', $msg, 'accept'], 
    [ 'req0002', 200, 'accept'] 
   ], 1 );
  is ($r,1, 'error');
  $client->_clear_send_queue() if $r != 0;
  is (keys %{$client->{tobesent}}, 2, 'cleared queue');
  is ($client->{tobesent}->{req0001}->{cmd}, 'auth'); 	# send ident
  is ($client->{tobesent}->{req0002}->{cmd}, 'request'); 	# send work request

  $client->{tobesent}->{req0001} = { cmd => 'test' };
  $client->{tobesent}->{req0002} = { cmd => 'test2' };
  $r = $client->_handle_responses( [ 
    [ 'req0001', $msg, 'deny'], 
    [ 'req0002', 500, 'deny'] 
   ], 1 );
  is ($r,1, 'error');
  $client->_clear_send_queue() if $r != 0;
  is (keys %{$client->{tobesent}}, 2, 'cleared queue');
  is ($client->{tobesent}->{req0001}->{cmd}, 'auth'); 	# send ident
  is ($client->{tobesent}->{req0002}->{cmd}, 'request'); 	# send work request

  # hard errors take precedence over anything else
  $client->{tobesent}->{req0001} = { cmd => 'test' };
  $client->{tobesent}->{req0002} = { cmd => 'test2' };
  $r = $client->_handle_responses( [ 
    [ 'req0001', $msg, 'deny'], 
    [ 'req0002', 300, 'deny'] 
  ], 1 );
  is ($r,1, 'error');
  $client->_clear_send_queue() if $r != 0;
  is (keys %{$client->{tobesent}}, 2, 'cleared queue');
  is ($client->{tobesent}->{req0001}->{cmd}, 'auth'); 	# send ident
  is ($client->{tobesent}->{req0002}->{cmd}, 'request'); 	# send work request
  }

#############################################################################

# throw away former output
@lines = ();

$client->{tobesent}->{req0002} = { cmd => 'test' };
$client->{tobesent}->{req0003} = { cmd => 'test2' };
$r = $client->_handle_responses( [ 
  [ 'req0001', 200, 'worker_test;'], 
  [ 'req0002', 400, 'deny'] 
 ], 1 );
is ($r,0,'no error');
$client->_clear_send_queue() if $r != 0;
is (keys %{$client->{tobesent}}, 2, 'resend one plus auth');
ok ($client->{tobesent}->{req0001}->{cmd}, 'auth'); 	# send ident
ok ($client->{tobesent}->{req0003}->{cmd}, 'test2'); 	# resend this

$client->{tobesent}->{req0002} = { cmd => 'test' };
$client->{tobesent}->{req0003} = { cmd => 'test2' };
$r = $client->_handle_responses( [ 
  [ 'req0001', 200, 'accept'], 
  [ 'req0002', 500, 'deny'] 
 ], 1 );
is ($r,0,'no error');
$client->_clear_send_queue() if $r != 0;
is (keys %{$client->{tobesent}}, 3, 'resend one plus auth');
is ($client->{tobesent}->{req0001}->{cmd}, 'auth'); 	# send ident
is ($client->{tobesent}->{req0003}->{cmd}, 'test2'); 	# resend this
is ($client->{tobesent}->{req0002}->{cmd}, 'test'); 	# resend this

#############################################################################
# check that client handles msg 101/102 properly
  {
  my (@k, @f);
  *Dicop::Client::_retrieve_files = sub { @f = @_; 0; };
  *Dicop::Client::_check_file = sub { @k = @_; 0; };
  *Dicop::Client::_file_ok = sub { @k = @_; 0; };

  for my $msg (101 .. 102)
    {
    @lines = ();
    $r = $client->_handle_responses( [ 
      [ 'req0000', $msg, 'abcdef0123456789 "test.txt"'], 
     ], 1 );
    is ($r,0,'no error');
    is ($k[2],'abcdef0123456789');
    is ($k[1],'test.txt');
    print "# Got unexpected output: ", join("\n",@lines) if @lines != 0;
    }
  }

#############################################################################
# worker_name

my $arch = $client->architecture();
isnt ($arch, '', 'non-empty arch');

is (join ("/", $client->_worker_name( { worker => 'test' } )), 
  File::Spec->catfile('test-worker',$arch,'test'));

my ($n,$w) = $client->_worker_name( { worker => 'test' } );

is ($n, File::Spec->catdir('test-worker',$arch));
like ($w, qr/^test/, 'test or test.exe'); 

my $full_arch = $client->full_arch();
is ($arch, $full_arch); # 'arch eq fullarch'

$client->{cfg}->{sub_arch} = 'i386';
my $full_arch = $client->full_arch();
is ($arch ne $full_arch, 1); # 'arch ne fullarch'

is ($client->sub_arch(), 'i386', 'sub_arch');

# simulate mswin32 on client
$arch = 'mswin32'; $client->{arch} = 'mswin32';

my ($n,$w) = $client->_worker_name( { worker => 'test' } );

is ($n, File::Spec->catdir('test-worker',$arch));
is ($w, 'test.exe'); 

# avoid double extension
my ($n,$w) = $client->_worker_name( { worker => 'test.exe' } );

is ($n, File::Spec->catdir('test-worker',$arch));
is ($w, 'test.exe'); 

##############################################################################
# sleeping

$client->{sleeped} = 0;
$client->{cfg}->{wait_on_idle} = 1;			# one second
$client->_sleeping(0,'',1);				# dont print anything
is ($client->{sleeped},1, 'sleeped');
is ($client->{sleep_factor},2,'1*2 = 2');
is ($lines[0],'Currently nothing to do');

###############################################################################
# get_more_work

$client->{tobesent} = {};				# clear send cache
$client->_get_more_work();
is (keys %{$client->{tobesent}},1, 'got added');

###############################################################################

$client->{tobesent} = {};				# clear send cache
$client->_store('cmd_request;type_work');		# store w/ scalar
is (keys %{$client->{tobesent}},1, 'got added');

###############################################################################
# _delete_temp_files

open FILE, '>test.txt' or die ("cannot write test.txt: $!");
print FILE "foo";
close FILE;
open FILE, '>client.log' or die ("cannot write client.log: $!");
print FILE "foo";
close FILE;

is (join(":", sort keys %{$client->{temp_files}}), 'test.txt', 'no temp files');

$client->{temp_files}->{'client.log'} = undef;
is (join(":", sort keys %{$client->{temp_files}}), 'client.log:test.txt', 'no temp files');

$client->_delete_temp_files();
is (join(":", sort keys %{$client->{temp_files}}), '', 'no temp files');

###############################################################################
# _remove_sub_arch

is ($client->_remove_sub_arch('foo'), 'foo', 'remove sub arch');
$client->{cfg}->{sub_arch} = 'i386-amd';
my $a = $client->architecture();
is ($client->_remove_sub_arch("worker/$a/i386/amd/foo"), "worker/$a/foo", 'remove sub arch');

###############################################################################
# _die_hard()

eval { $client->_die_hard("Hmmmpf!") };

like ($@, qr/Hmmmpf!/, 'died properly');

###############################################################################
# all done

unlink 'client.log' if -e 'client.log';

1;
