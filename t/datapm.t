#!/usr/bin/perl -w

# Test for Dicop::Data - main server object, see also proxypm.t

use Test;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 636;
  }

use Dicop qw/ISSUED TOBEDONE DONE VERIFY/;
use Dicop::Data;
use Dicop::Mail;

# load messages and request patterns
require "common.pl";

package Dicop::Data::DummyClient;

sub new
  {
  return bless {}, 'Dicop::Data::DummyClient';
  }

sub failures { return (0,0); }

package main;

use Dicop::Base qw/read_file/;
Dicop::Event::handler( sub { } );	# zap error handler to be silent

$Dicop::Handler::NO_STDERR = 1;		# disable informative messages

{
  no warnings;
  *Dicop::Data::flush = sub { };		# never flush the testdata
}

sub check_email_for_leftover_templates
  {
  my $txt = shift;

  # Test::More would make this so much easier:
  # unlike ($txt, qr/##/, 'no templates left over in the text');

  ok (1,1) and return if $txt !~ /##/;
  ok ($txt,'no ##.*## templates in the text');
  }

$Dicop::Data::NEVER_INLINE_FILES = 1;

###############################################################################
# Construct a Data object using testdata and testconfig
# Then check default and config entries

my $txt;	# response
my $line = 0;	# current line
my @data;	# the lines in __DATA__
read_lines();	# read __DATA__ section

# remove any left-over charsets.def
unlink "test-worker/charsets.def" if -e "test-worker/charsets.def";
die ("Cannot unlink 'test-worker/charsets.def': $!")
  if -e "test-worker/charsets.def";

#############
#############
# contruct data object
#############
#############

my $data = Dicop::Data->new( cfg_dir => './test-config', _warn => 1 );

ok ($data->check(),undef);	# construct was okay

my $file = "test-worker/charsets.def";
# test contents of generated charset definition file
ok (-e $file, 1);
open FILE, $file or die "Cannot read $file: $!";
while (<FILE>)
  {
  next if /^#/;			# skip comments
  ok ($_,lines(1));
  }
close FILE;

ok (@{$data->{email_queue}},0);	# no entries yet

ok ($data->type(),'server');

ok ($data->{connects},0);
ok (ref($data->{requests}),'HASH');
ok ($data->{resend_test},360);

ok ($data->{last_flush},0);
ok ($data->{flush_time},0);
ok ($data->{style},'default');
ok (ref $data->{worker_hash},'HASH');
ok (ref $data->{target_hash},'HASH');

ok (ref $data->{allow},'HASH');
ok (ref $data->{deny},'HASH');

foreach (qw/admin work status stats/)
  {
  ok (ref $data->{allow}->{$_},'ARRAY');
  ok (ref $data->{deny}->{$_},'ARRAY');
  }

# clients offline
ok ($data->{last_check},0);

ok ($data->{config}->{log_level},63);		# from config
$data->{config}->{log_level} = 0;		# disable for tests

ok (join(' ',@{$data->{allow}->{admin}}),
  '192.168.0.1/32 192.168.0.2 192.168.1.0/24 10.20.30.40');
ok (join(' ',@{$data->{allow}->{stats}}),
  '0.0.0.0/0');
ok (join(' ',@{$data->{allow}->{status}}),
  '192.168.0.0/16 10.20.30.40');
ok (join(' ',@{$data->{allow}->{work}}),
  'any');

ok (join(' ',@{$data->{deny}->{admin}}),
  '127.0.0.0/24');
ok (join(' ',@{$data->{deny}->{stats}}),
  'none');
ok (join(' ',@{$data->{deny}->{status}}),
  'none');
ok (join(' ',@{$data->{deny}->{work}}),
  'none');

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
  };

foreach my $key (keys %$count)
  {
  ok ($data->$key(),$count->{$key});
  }

my $jj = $data->get_job(5);
ok ($jj->{target}, 'target/test.dat');

###############################################################################
# test that dictionary charset with append was correctly constructed

my $cs = $data->get_charset(7);
ok (ref($cs),'Dicop::Data::Charset::Dictionary');
ok (ref($cs->{sets}),'ARRAY');
ok (ref($cs->{sets}->[0]),'ARRAY');

ok ($cs->as_string(),lines(11));

$cs = $data->get_charset(8);
ok (ref($cs),'Dicop::Data::Charset::Dictionary');
ok (ref($cs->{sets}),'ARRAY');
ok (ref($cs->{sets}->[0]),'ARRAY');

ok ($cs->as_string(),lines(11));

###############################################################################
my $job =$data->get_job(1);
ok (ref($job),'Dicop::Data::Job');

my $chunk = $job->chunk(0);
ok (ref($chunk),'Dicop::Data::Chunk');

$job =$data->get_job(4);
ok (ref($job),'Dicop::Data::Job');
$chunk = $job->chunk(0);
ok (ref($chunk),'Dicop::Data::Chunk');
ok ($chunk->{job}->{id}, $job->{id});

my $jobtype =$data->get_jobtype(1);
ok (ref($jobtype),'Dicop::Data::Jobtype');

my $result =$data->get_result(1);
ok (ref($result),'Dicop::Data::Result');

my $group =$data->get_group(1);
ok (ref($group),'Dicop::Data::Group');

my $charset =$data->get_charset(6);
ok (ref($charset),'Dicop::Data::Charset::Dictionary');

$charset =$data->get_charset(1);
ok (ref($charset),'Dicop::Data::Charset');

my $client =$data->get_client(1);
ok (ref($client),'Dicop::Data::Client');
# some consistency checks
ok ($client->failures(7),123);
ok (join (' ',$client->failures(7)),'123 456');
# 400 200 replaced by 200 100
ok ($client->{job_speed}->{2},200);
ok ($client->{chunks}->{2},1234);
ok ($client->{chunks}->{3},4567);

my $testcase =$data->get_testcase(1);
ok (ref($testcase),'Dicop::Data::Testcase');

my $proxy = $data->get_proxy(10);
ok (ref($proxy),'Dicop::Data::Proxy');

foreach (qw/ User Case Testcase Charset Client Group Job Result Jobtype/)
  {
  my $object = $data->get_object( { type => lc($_), id => 1 } );
  ok (ref($object),"Dicop::Data::$_");
  }

my $object = $data->get_object( { type => 'proxy', id => 10 } );
ok (ref($object),"Dicop::Data::Proxy");

$object = $data->get_object( { type => 'chunk', id => 1, job => 1 } );
ok (ref($object),"Dicop::Data::Chunk");

###############################################################################
# authentication of users

ok ($data->authenticate_user('name','pwd'),-1);		# unknown user 'name'
ok ($data->authenticate_user('Gollum','pwd'),-2);	# wrong pwd
ok ($data->authenticate_user('Gollum','MyPrecious'),0);	# alright

###############################################################################
# try handling of requests and generating status pages

# request_test:

$client = $data->get_client(1);
print "# client arch: ", $client->{arch},"\n";

# request->{id} is used, but client is not used:
$txt = $data->request_test( { _id => 'req0001' } , $client );
ok ($txt,lines(3));

# the same again, but only tests for jobytpe == 1
$txt = $data->request_test( { _id => 'req0001' } , $client, undef, 1 );
ok ($txt,lines(2));

$client->{arch} .= '-i386amd';

# test with a different (non-existing) sub-architecture
$txt = $data->request_test( { _id => 'req0001' } , $client, undef, 1 );
ok ($txt,lines(2));

# reset client arch
$client->{arch} = 'linux';

# request_work (wait, no work for you since only job is closed):
$txt = $data->request_work( { _id => 'req0001' } , $client, undef, 1 );
ok ($txt,lines(1));

my $auth_req = Dicop::Request->new( id => 'req0003',
  data => 'cmd_auth;id_7;version_2.24;arch_linux;os_linux-2.4.1;ip_1.2.3.4' );

# make job TOBEDONE and retry request
$data->{jobs}->{1}->status(TOBEDONE);
$client = $data->get_client(1); $client->{arch} = 'foo';
$txt = $data->request_work( 
  { _id => 'req0001' } , $data->get_client(1), $auth_req, 1 );
ok ($txt,lines(4));			# 2 lines showing debug that
					# server tries to find job

# disable the automatic chunksize correction
$data->{jobs}->{1}->{created} = time - 72000;

# find work in job 1 (normal charset)
$data->{jobs}->{1}->status(TOBEDONE);
$client->{arch} = 'linux';
$txt = $data->request_work( 
  # size not defined will be corrected to size=>1
  { _id => 'req0001' } , $data->get_client(1), $auth_req, 1 );
$txt =~ s/token_[0-9a-f]+;/token_removed-to-compare;/;
ok ($txt,lines(6));			# 4 lines showing what server does

# find work in job 2 (prefix in charset, no CDF nec.)
$data->{jobs}->{1}->status(DONE);
$data->{jobs}->{2}->status(TOBEDONE);
$client->{arch} = 'linux';
$txt = $data->request_work( 
  { _id => 'req0001' } , $data->get_client(1), $auth_req, 1 );
$txt =~ s/token_[0-9a-f]+;/token_removed-to-compare;/;
ok ($txt,lines(7));			# 7 lines showing what server does

# wait, no work for you in none of the jobs
$data->{jobs}->{2}->status(DONE);
$client->{arch} = 'linux';
$txt = $data->request_work( 
  { _id => 'req0001' } , $data->get_client(1), $auth_req, 1 );
$txt =~ s/token_[0-9a-f]+;/token_removed-to-compare;/;
ok ($txt,lines(1));

#reset chunk for further tests:
$data->{jobs}->{1}->{_chunks}->[1]->{token} 
  = 'f7c5304b5fa091a09029e687354462c9';
$data->{jobs}->{1}->{_chunks}->[1]->{status} = TOBEDONE;

###############################################################################
# footer/header test

# these are not properly tested yet
$txt = $data->html_header();
ok (ref($txt),'');

$txt = $data->html_footer();
ok (ref($txt),'');

###############################################################################
# check authentication

my $request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_auth;id_5;version_0.24;arch_linux;os_linux-2.4.1' );
$txt = $data->check_auth_request( $request, 'req0001' );	
# error, 5 does not exists
ok ($txt,lines(1));

$data->{peeraddress} = "127.0.0.1"; 		# otherwise we get msg 457
$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_auth;id_1;version_0.24;arch_linux;os_linux-2.4.1' );
$txt = $data->check_auth_request( $request, 'req0001' );
# outdated (message 452)
ok ($txt,lines(1));

$data->{peeraddress} = "127.0.1.1"; 		# we get msg 457
$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_auth;id_1;version_2.12;arch_linux;os_linux-2.4.1' );
$txt = $data->check_auth_request( $request, 'req0001' );
# wrong IP (message 457)
ok ($txt,lines(1));

$data->{peeraddress} = "127.0.0.2"; 		# otherwise we would get msg 457

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_auth;id_1;version_2.11;arch_linux;os_linux-2.4.1' );
$txt = $data->check_auth_request( $request, 'req0001' );
# (build undefined => build 0) outdated (message 452)
ok ($txt,lines(1));

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_auth;id_1;version_2.11-2;arch_linux;os_linux-2.4.1' );
$txt = $data->check_auth_request( $request, 'req0001' );
# (build 2 < build 5) outdated (message 452)
ok ($txt,lines(1));

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_auth;id_1;version_2.24;arch_frobble;os_linux-2.4.1' );
$txt = $data->check_auth_request( $request, 'req0001' );
# architecture not know
ok ($txt,lines(1));

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_auth;id_1;version_2.12;arch_linux;os_linux-2.4.1' );
$txt = $data->check_auth_request( $request, 'req0001' );
# okay
ok (ref($txt),'Dicop::Data::Client');

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_auth;id_5;version_0.24;arch_linux;os_linux-2.4.1' );
$txt = $data->check_auth_request( $request, '' );	
# error, 5 does not exists
ok ($txt,lines(1));

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_auth;id_10;version_2.24;arch_linux;os_linux-2.4.1' );
my $request2 = Dicop::Request->new( id => 'req0003',
  data => 'cmd_info;id_7;version_2.24;arch_linux;os_linux-2.4.1;ip_1.2.3.4;for_req0002' );
my $request3 = Dicop::Request->new( id => 'req0002',
  data => 'cmd_request;type_test' );
my ($res,$map_req);

($client,$res,$map_req) = $data->request_auth( $request, [ $request2 ], [ $request3 ] );

ok (ref($map_req),'HASH');
ok (ref($client),'Dicop::Data::Proxy');		# proxy exist
ok ($client->{id},10);				# returned client is really the proxy

ok_undef ($map_req->{req0001});			# auth request was not checked
ok ($map_req->{req0002},lines(1));		# client 7 does not exist, so
						# req0002 is invalid

# in info requests the id must be a client, not a proxy (this will be done
# via the via_other-proxy-id parameter)

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_auth;id_10;version_2.24;arch_linux;os_linux-2.4.1' );
$request2 = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_info;id_10;version_2.24;arch_linux;os_linux-2.4.1;ip_1.2.3.4;for_req0002' );

($client,$res,$map_req) = $data->request_auth( $request, [ $request2 ] , [ $request3 ] );	

ok (ref($map_req),'HASH');
ok (ref($client),'Dicop::Data::Proxy');		# proxy exists
ok ($client->{id},10);				# returned client is proxy
ok ($map_req->{req0002},lines(1));		# client 10 does not exist, so
						# req0002 is invalid (a proxy
						# with ID 10 exists, but doesn't
						# count as client!)

###############################################################################
# check request for URLs (via fileserver) (error 411)

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_request;type_file;name_worker/linux/test' );
#			    # request client jobtype 
$txt = $data->request_file( $request, { }, 0 );
ok ($txt,lines(1));					# does not exist

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_request;type_file;name_test-worker/linux/test' );
#			    # request client jobtype 
$txt = $data->request_file( $request, { }, 0 );
ok ($txt,lines(1));					# illegal format

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_request;type_file;name_worker/../test' );
#			    # request client jobtype 
$txt = $data->request_file( $request, { }, 0 );
ok ($txt,lines(1));					# illegal format

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_request;type_file;name_worker/%21test' );
#			    # request client jobtype 
$txt = $data->request_file( $request, { }, 0 );
ok ($txt,lines(1));					# illegal format

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_request;type_file;name_worker/test%2b' );
#			    # request client jobtype 
$txt = $data->request_file( $request, { }, 0 );
ok ($txt,lines(2));					# ok

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_request;type_file;name_worker/test' );
#			    # request client jobtype 
$txt = $data->request_file( $request, { }, 0 );
ok ($txt,lines(2));					# okay, 2 URIs returned

$request = Dicop::Request->new( id => 'req0001', 
  data => 'cmd_request;type_file;name_./worker/test' );
#			    # request client jobtype 
$txt = $data->request_file( $request, { }, 0 );
ok ($txt,lines(2));					# okay, 2 URIs returned

###############################################################################
# check that parse requests return the proper arrays

my ($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' .
  'req0002=cmd_info;id_5;version_2.24;arch_linux;os_linux-2.4.1;ip_1.2.3.4;for_req0002'
  );
ok (scalar @$auth,1);     ok (scalar @$info,1);  ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,0); ok (scalar @$errors,0);

ok ($data->{requests}->{status},0);
ok ($data->{requests}->{auth},2);
ok ($data->{requests}->{report}->{work},0);
ok ($data->{requests}->{report}->{test},0);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},0);
ok ($data->{requests}->{request}->{file},0);
 
($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' .
  'req0002=cmd_status;type_server'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,1); ok (scalar @$errors,0);

ok ($data->{requests}->{status},1);
ok ($data->{requests}->{auth},3);
ok ($data->{requests}->{report}->{work},0);
ok ($data->{requests}->{report}->{test},0);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},0);
ok ($data->{requests}->{request}->{file},0);
 
($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' .
  'req0002=cmd_request;type_test'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,0);
ok (scalar @$requests,1); ok (scalar @$forms,0); ok (scalar @$errors,0);

ok ($data->{requests}->{status},1);
ok ($data->{requests}->{auth},4);
ok ($data->{requests}->{report}->{work},0);
ok ($data->{requests}->{report}->{test},0);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);
ok ($data->{requests}->{request}->{file},0);
 
($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' .
  'req0002=cmd_report;job_1;crc_123;took_12;token_1234;status_DONE;chunk_1'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,1);
ok (scalar @$requests,0); ok (scalar @$forms,0);  

print_errors($errors) unless ok (scalar @$errors,0);

ok ($data->{requests}->{status},1);
ok ($data->{requests}->{auth},5);
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},0);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);
ok ($data->{requests}->{request}->{file},0);
 
($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' .
  'req0002=cmd_report;job_test1;crc_123;took_12;token_1234;status_DONE;chunk_1'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,1);
ok (scalar @$requests,0); ok (scalar @$forms,0); 

print_errors($errors) unless ok (scalar @$errors,0);

ok ($data->{requests}->{status},1);
ok ($data->{requests}->{auth},6);
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);
ok ($data->{requests}->{request}->{file},0);
 
($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1' 
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,0); 

print_errors($errors) unless ok (scalar @$errors,0);

ok ($data->{requests}->{status},1);
ok ($data->{requests}->{auth},7);
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);
ok ($data->{requests}->{request}->{file},0);

($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' . 
  'req0002=cmd_request;type_file;name_worker/linux/test'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,0);
ok (scalar @$requests,1); ok (scalar @$forms,0); 

print_errors($errors) unless ok (scalar @$errors,0);

ok ($data->{requests}->{status},1);
ok ($data->{requests}->{auth},8);
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{file},1);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);

# check info requests
 
($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0001=cmd_auth;id_10;version_2.24;arch_linux;os_linux-2.4.1&' . 
  'req0002=cmd_info;id_7;ip_1.2.3.4;version_2.24;arch_linux;os_linux-2.4.1;for_req0003&' . 
  'req0003=cmd_request;type_file;name_worker/linux/test'
  );
ok (scalar @$auth,1);     ok (scalar @$info,1);  ok (scalar @$reports,0);
ok (scalar @$requests,1); ok (scalar @$forms,0);

print_errors($errors) unless ok (scalar @$errors,0);

ok ($data->{requests}->{status},1);
ok ($data->{requests}->{auth},10);		# info + auth => 1 +9 => 10
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{file},2);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);

# check search request

($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0002=cmd_search;case_0;type_jobs;id_ANY'
  );

# XXX TODO generates an error, and error counts as form (is this right?)
ok (scalar @$auth,0); ok (scalar @$info,0); ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,0); 

print_errors($errors) unless ok (scalar @$errors,1);

ok ($data->{requests}->{status},1);
ok ($data->{requests}->{auth},10);		# info + auth => 1 +9 => 10
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{file},2);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);

# check change request
($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' .
  'req0002=cmd_change;type_group;id_1;name_test;description_foo'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,1); ok (scalar @$errors,0);

ok ($data->{requests}->{status},2);
ok ($data->{requests}->{auth},11);		# yeah, but does it go to eleven?
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{file},2);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);

# check add request
($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' .
  'req0002=cmd_add;type_group;name_test;description_foo'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,1); ok (scalar @$errors,0);

ok ($data->{requests}->{status},3);
ok ($data->{requests}->{auth},12);
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{file},2);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);

##############################################################################
# test search engine

foreach my $type (keys %$count)
  {
  # check search result
  my $results = $data->_search (
    { id => 'ANY', 'ip' => 'ANY', name => 'ANY', description => 'ANY', },
    $type,
    );
  print "# searched $type for all results\n" unless
    ok (scalar keys %$results, $count->{$type});

  # no results possible (IDs are numeric)
  $results = $data->_search (
    { id => 'foo', 'ip' => 'ANY', name => 'ANY', description => 'ANY',
      case => 0 },
    $type,
    );
  print "# searched $type for zero results\n" unless
    ok (scalar keys %$results, 0);

  # proxies and clients have an IP, so exclude them
  next if $type =~ /^(proxies|clients)$/;

  # check search result for finding all (IP field does not exist, so it's
  # ignored)
  $results = $data->_search (
    { id => 'ANY', 'ip' => 'foo', name => 'ANY', description => 'ANY', },
    $type,
    );
  print "# searched $type\n" unless
    ok (scalar keys %$results, $count->{$type});
  
  }
  
# 2 results with ASCII in description, case insensitive
my $results = $data->_search (
    { id => 'ANY', 'ip' => 'ANY', name => 'ANY', description => 'ASCII',
      case => 0 },
    'charsets',
    );
print "# searched charsets for 2 results in charsets\n" unless
  ok (scalar keys %$results, 2);

# case insensitive
$results = $data->_search (
    { id => 'ANY', 'ip' => 'ANY', name => 'ANY', description => 'ascii',
      case => 0 },
    'charsets',
    );
print "# searched charsets for 2 results in charsets\n" unless
  ok (scalar keys %$results, 2);

# case sensitive
$results = $data->_search (
    { id => 'ANY', 'ip' => 'ANY', name => 'ANY', description => 'ascii',
      case => 1 },
    'charsets',
    );
print "# searched charsets for 0 results in charsets\n" unless
  ok (scalar keys %$results, 0);

# case sensitive, lower => 3 results
$results = $data->_search (
    { id => 'ANY', 'ip' => 'ANY', name => 'ANY', description => 'lower',
      case => 1 },
    'charsets',
    );
print "# searched charsets for 3 results in charsets\n" unless
  ok (scalar keys %$results, 3);

# case sensitive, lower => 3 results; id == 5 => 1 result
$results = $data->_search (
    { id => '5', 'ip' => 'ANY', name => 'ANY', description => 'lower',
      case => 1 },
    'charsets',
    );
print "# searched charsets for 1 results in charsets\n" unless
  ok (scalar keys %$results, 1);


##############################################################################
# check reqeusts from browser (and also with user/password info)

# TODO: should check for 'auth-pass' and 'auth-user', not 'auth-foo'
my $f = $data->convert_browser_request(
  Dicop::Base::parseFormArgs( 
   'submit=true&cmd=add&type=user&style=blue&name=admin&pwd=123456789&'
   .'pwdrepeat=123456789&auth-pass=MyPrecious&auth-user=Gollum'
   )
  );
ok (ref($f), 'HASH');
ok (scalar keys %$f, 3);	# 1 auth, 1 request, 1 encoded

$f = $data->convert_browser_request(
  Dicop::Base::parseFormArgs( 
   'submit=true&cmd=status&type=main&style=blue'
   )
  );
ok (ref($f), 'HASH');
ok (scalar keys %$f, 2);	# 1 request, 1 encoded	

($auth,$info,$reports,$requests,$forms,$errors) = $data->parse_requests(
  'submit=true&cmd=add&type=user&style=blue&name=admin&pwd=123456789&'
 .'pwdrepeat=123456789&auth-pass=MyPresious&auth-user=Gollum'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,1); ok (scalar @$errors,0);

ok ($data->{requests}->{status},4);
ok ($data->{requests}->{auth},13);
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{file},2);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);

###############################################################################
# test whether parse_requests parses more than it should
my $max = $data->{config}->{max_requests} || 256;
 
my $r = ""; my $req = 'req0001';
for (my $i = 0; $i <= $max+1; $i++) 
  {
  $r .=
  $req.'=cmd_info;id_1;version_2.24;arch_linux;os_linux-2.4.1;ip_1.2.3.4;for_req0002&';
  $req++; 
  }
chop($r);	# last '&'
($auth,$info,$reports,$requests,$forms) = $data->parse_requests( $r );
ok (scalar @$auth,0);     ok (scalar @$info,$max+1);  ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,0);

$max += 13;

ok ($data->{requests}->{status},4);
ok ($data->{requests}->{auth},$max+1);
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);

###############################################################################
# test that cmd_reset and cmd_terminate counts as form

($auth,$info,$reports,$requests,$forms) = $data->parse_requests(
 'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' .
  'req0002=cmd_reset;type_client;id_1'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,1);

ok ($data->{requests}->{status},5);
ok ($data->{requests}->{auth},$max+2);
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);
ok ($data->{requests}->{request}->{file},2);
 
($auth,$info,$reports,$requests,$forms) = $data->parse_requests(
 'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' .
  'req0002=cmd_reset;type_clients'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,1);

ok ($data->{requests}->{status},6);
ok ($data->{requests}->{auth},$max+3);
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);
ok ($data->{requests}->{request}->{file},2);

($auth,$info,$reports,$requests,$forms) = $data->parse_requests(
  'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' .
  'req0002=cmd_terminate;type_clients'
  );
ok (scalar @$auth,1);     ok (scalar @$info,0);  ok (scalar @$reports,0);
ok (scalar @$requests,0); ok (scalar @$forms,1);

ok ($data->{requests}->{status},7);
ok ($data->{requests}->{auth},$max+4);
ok ($data->{requests}->{report}->{work},1);
ok ($data->{requests}->{report}->{test},1);
ok ($data->{requests}->{request}->{work},0);
ok ($data->{requests}->{request}->{test},1);
ok ($data->{requests}->{request}->{file},2);
ok ($data->{requests}->{errors},0);
 
###############################################################################
# try to add clients

# request is invalid, thus authentication fails with error 462
$txt = $data->handle_requests( 
    '10.20.30.41',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0002=cmd_add;type_client;name_test;description_foo;ip_1.2.3.4;mask_255.255.255.255;pwd_123;pwdrepeat_123' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Expected: \"req0002 459 Parameter 'group' of command 'add', type 'client' is empty\"\n"
     ."# Got: '$txt'\n" unless
ok ($txt =~ /req0002 459 Parameter 'group' of command 'add', type 'client' is empty/,1);

# request is invalid, thus authentication fails with error 462
$txt = $data->handle_requests( 
    '10.20.30.41',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0002=cmd_add;type_client;name_test;group_1;description_foo;ip_1.2.3.4;mask_255.255.255.255;pwd_123' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Expected: \"req0002 459 Parameter 'pwdrepeat' of command 'add', type 'client' is empty\"\n"
     ."# Got: '$txt'\n" unless
ok ($txt =~ /req0002 459 Parameter 'pwdrepeat' of command 'add', type 'client' is empty/,1);

# IP not allowed
$txt = $data->handle_requests( 
    '10.20.30.41',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0002=cmd_add;count_1;type_client;name_test;description_foo;ip_1.2.3.4;mask_255.255.255.255;pwd_123;pwdrepeat_123;group_1;trusted_on' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Expected: 'req0000 413 Failed to authenticate request, IP 10.20.30.41 not allowed to connect'\n"
     ."# Got: '$txt'\n" unless
ok ($txt =~ /req0000 413 Failed to authenticate request, IP 10.20.30.41 not allowed to connect/,1);

# IP allowed, but no pwd/user
$txt = $data->handle_requests( 
    '192.168.1.1',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0002=cmd_add;count_1;type_client;name_test;description_foo;ip_1.2.3.4;mask_255.255.255.255;pwd_123;pwdrepeat_123;group_1;trusted_on' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Expected: 'req0000 469 Couldn't authenticate you, wrong user or password'\n"
     ."# Got: '$txt'\n" unless
ok ($txt =~ /req0000 469 Couldn't authenticate you, wrong user or password/,1);

##############################################################################
# try to add user
# then try to add something with this user and password

$txt = $data->handle_requests( 
    '192.168.1.1',
   'submit=true&cmd=add&type=user&style=blue&name=admin&pwd=123456789&'
   .'pwdrepeat=123456789&auth-pass=MyPrecious&auth-user=Gollum'
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Expected: 'The user was added with the following parameters'\n"
     ."# Got: '$txt'\n" unless
ok ($txt =~ /The user was added with the following parameters/i,1);

# now try to add another user (test pwd mismatch)

$txt = $data->handle_requests( 
    '192.168.1.1',
   'submit=true&cmd=add&type=user&style=blue&name=admin&pwd=123456789&'
   .'pwdrepeat=123123456789&auth-pass=MyPrecious&auth-user=Gollum'
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Expected: 'The user was added with the following parameters'\n"
     ."# Got: '$txt'\n" unless
ok ($txt =~ /The user could not be added.*Passwords do not match/i,1);

# now try to add another user with the second user (fixed in v2.20 build 20)

$txt = $data->handle_requests( 
    '192.168.1.1',
   'submit=true&cmd=add&type=user&style=blue&name=admin2&pwd=12123456789&'
   .'pwdrepeat=12123456789&auth-pass=123456789&auth-user=admin'
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Expected: 'The user was added with the following parameters'\n"
     ."# Got: '$txt'\n" unless
ok ($txt =~ /The user was added with the following parameters/i,1);

##############################################################################

$txt = $data->handle_requests (
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0002=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9invalid;status_DONE;crc_123' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /req0002 403 Invalid token/,1);

# no crc?
$txt = $data->handle_requests (
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0002=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9;status_DONE' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /req0002 459 Parameter 'crc' of command 'report', type 'unknown' is empty/,1);

$txt = $data->handle_requests(
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0004=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9;status_DONEINVALID;crc_123' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /req0004 408 Chunk status /,1);

$txt = $data->handle_requests(
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0005=cmd_report;took_12;chunk_12;job_1;token_f7c5304b5fa091a09029e687354462c9;status_DONE;crc_123' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /req0005 402 Unknown or invalid chunk /,1);

$txt = $data->handle_requests(
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0005=cmd_report;took_12;chunk_2;job_11;token_f7c5304b5fa091a09029e687354462c9;status_DONE;crc_123' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /req0005 401 Unknown or invalid job /,1);

$txt = $data->handle_requests(
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0003=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9;status_DONE;crc_123' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /req0003 405 Chunk not issued/,1);

$job = $data->get_job(1);
$chunk = $job->get_chunk(2);
$chunk->{status} = ISSUED;
$chunk->{client} = $data->get_client(2);

# empty crc?
$txt = $data->handle_requests (
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0002=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9;status_DONE;crc;'
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /req0002 450 Malformed request: 'invalid part'/,1);

$txt = $data->handle_requests (
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0002=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9;status_DONE;crc_;'
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /req0002 459 Parameter 'crc' of command 'report', type 'unknown' is empty/,1);

# result, but DONE?
$txt = $data->handle_requests (
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0002=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9;status_DONE;result_1234;crc_f00ba13;'
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /req0002 416 Done reports should not carry a result/,1);

$txt = $data->handle_requests(
    '127.0.0.5',
    'req0001=cmd_auth;id_1;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0005=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9;status_DONE;crc_123' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /req0005 404 Chunk does not belong to you/,1);


###############################################################################
# accepting a report for a chunk and then another due to VERIFY status
# 201 Done report accepted. Thanx!

$chunk->clear_verifiers();
ok ($chunk->add_verifier( $data->get_client(1), DONE, '', 'cafebabe'), 1);

$chunk->{token} = 'f7c5304b5fa091a09029e687354462c9';

$data->{config}->{verify_done_chunks} = 3;

$txt = $data->handle_requests(
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&'
  . 'req0003=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9;status_DONE;crc_cafebabe' 
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /201 Done report accepted. Thanx!/,1);

$job = $data->get_job(1);
$chunk = $job->get_chunk(2);
ok ($chunk->verifiers(),2);
ok ($chunk->status(), VERIFY);

$data->{config}->{verify_done_chunks} = 1;
$chunk->status(TOBEDONE);

#ok ($chunk->dump_verifierlist() =~ /^1\t2\t\tcafebabe\t[0-9]{10}\n1\t2\t\tcafebabe\t[0-9]{10}\n\n/, 1);
#
#print "is \n" if ($chunk->dump_verifierlist() =~ /1\t2\t\tcafebabe\t[0-9]{10}\n1\t2\t\tcafebabe\t[0-9]{10}\n\n/);


###############################################################################
# try to change something

$txt = $data->handle_requests(
    '192.168.1.1',
    'submit=true&cmd=change&type=group&id=1&style=blue&name=testtest&description=somefoo'
   .'&auth-pass=123456789&auth-user=admin'
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /group was changed(.|\n)*somefoo/,1);

$txt = $data->handle_requests(
    '192.168.1.1',
    'submit=true&cmd=add&type=group&style=blue&name=testtest&description=somefoo'
   .'&auth-pass=123456789&auth-user=admin'
  );
$txt = $$txt if ref($txt) eq 'SCALAR';
print "# Got: '$txt'\n" unless
ok ($txt =~ /<html>(.|\n)*somefoo/,1);

###############################################################################
# Request the different status pages. Just looks if they are non-empty and
# contain (some) HTML and no error messages pop up. Real content is not (yet)
# checked. 

foreach (qw/
  cmd_status;type_cases
  cmd_status;type_case;id_1
  cmd_status;type_casebyname;name_1234
  cmd_status;type_charsets
  cmd_status;type_charset;id_1
  cmd_status;type_chunks
  cmd_status;type_debug
  cmd_status;type_groups
  cmd_status;type_jobtypes
  cmd_status;type_jobresults;id_1
  cmd_status;type_main
  cmd_status;type_proxies
  cmd_status;type_results
  cmd_status;type_server
  cmd_status;type_testcases
  cmd_status;type_clientmap
  cmd_status;type_clients
  cmd_status;type_clients;sort_id
  cmd_status;type_clients;sort_name
  cmd_status;type_clients;sort_keys
  cmd_status;type_clients;sort_speed
  cmd_status;type_clients;sort_online
  cmd_status;type_client;id_1
  cmd_status;type_config
  cmd_status;type_style
  cmd_status;type_job;id_1
  cmd_status;type_search
  browse_target;cmd_status;form_cmd%5fstatus%3btype%5ftestcase;params_style%5fblue;path_.;targetfield_target;type_file
  cmd_status;form_cmd%5fstatus%3btype%5ftestcase;params_style%5fblue;path_.;targetfield_target;type_file
  cmd_status;form_cmd%5fstatus%3btype%5ftestcase;params_style%5fblue;targetfield_target;type_file
  cmd_search;case_0;type_clients;id_ANY;ip_ANY;description_ANY;name_ANY
  cmd_search;case_0;type_jobs;id_ANY;ip_ANY;description_ANY;name_ANY
  cmd_search;case_0;type_jobtypes;id_ANY;ip_ANY;description_ANY;name_ANY
  cmd_search;case_0;type_testcases;id_ANY;ip_ANY;description_ANY;name_ANY
  cmd_search;case_0;type_groups;id_ANY;ip_ANY;description_ANY;name_ANY
  cmd_search;case_0;type_proxies;id_ANY;ip_ANY;description_ANY;name_ANY
  cmd_search;case_0;type_results;id_ANY;ip_ANY;description_ANY;name_ANY
  cmd_search;case_0;type_charsets;id_ANY;ip_ANY;description_ANY;name_ANY
  cmd_search;case_0;type_users;id_ANY;ip_ANY;description_ANY;name_ANY
  cmd_search;case_0;type_users;id_foo;ip_ANY;description_ANY;name_ANY
  cmd_form;type_jobtype
  cmd_form;type_client
  cmd_form;type_group
  cmd_form;type_proxy
  cmd_form;type_testcase
  cmd_form;type_charset
  cmd_form;type_simplecharset
  cmd_form;type_groupedcharset
  cmd_form;type_extractcharset
  cmd_form;type_dictionarycharset
  cmd_form;type_user
  cmd_form;type_jobtype;id_1
  cmd_form;type_client;id_1
  cmd_form;type_group;id_1
  cmd_form;type_proxy;id_10
  cmd_form;type_testcase;id_1
  cmd_form;type_charset;id_1
  cmd_form;type_user;id_1
  cmd_form;type_jobtype;id_1;style_default
  cmd_form;type_client;id_1;style_default
  cmd_form;type_group;id_1;style_default
  cmd_form;type_proxy;id_10;style_default
  cmd_form;type_testcase;id_1;style_default
  cmd_form;type_charset;id_1;style_default
  cmd_form;type_user;id_1;style_default
  cmd_form;type_jobtype;style_default
  cmd_form;type_client;style_default
  cmd_form;type_group;style_default
  cmd_form;type_proxy;style_default
  cmd_form;type_testcase;style_default
  cmd_form;type_charset;style_default
  cmd_form;type_user;style_default
  cmd_help;type_list
  cmd_help;type_new
  cmd_help;type_client
  cmd_help;type_dicopd
  cmd_help;type_worker
  cmd_help;type_server
  cmd_help;type_files
  cmd_help;type_proxy
  cmd_help;type_security
  cmd_help;type_trouble
  /)
  {
  my $auth = "";
  $auth = '&req0002=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1' . 
    ';pass_MyPrecious;user_Gollum' if $_ =~ /^cmd_search/;
  $txt = $data->handle_requests( '10.20.30.40',
   "req0001=$_$auth" );
  $txt = $$txt if ref($txt) eq 'SCALAR';
  # got HTML?
  print "# Tried: '$_'\n# Got: '$txt' instead of HTML\n" unless ok ($txt =~ /(<TITLE>)/i,1);
  
  # help pages often contain these examples as C<##.....##>
  $txt =~ s/<code>##\w+##<\/code>//g if $_ =~ /^cmd_help/;
  $txt =~ s/<code>.*<\/code>//g if $_ =~ /^cmd_help;type_new/;
  
  next if ok ($txt =~ /##.*?##/,'');
  print "# left over templates for '$_':\n";			# leftovers
  $txt =~ s/##(.*?)##/print "# '$1'\n"; "##$1##"/eg;
  print "# result '$txt'\n";
  }
 
# todo:
# cmd_reset;type_client;id_1

# This are special, they contain ##rank## and ##description##, so filter
# these out

foreach my $key ( 
   'cmd_form;type_job', 
   'cmd_form;type_job;id_1',
   'cmd_form;type_job;;style_default',
   'cmd_form;type_job;id_1;style_default',
   'cmd_help;type_dicop',
   'cmd_help;type_glossary',
   'cmd_help;type_config',
   )
  {
  $txt = $data->handle_requests( 
    '10.20.30.40',
    "req0001=$key" );
  $txt = $$txt if ref($txt) eq 'SCALAR'; 
  print "# Got instead of HTML: '$txt'\n" unless
   ok ($txt =~ /(<TITLE>)/i,1);		# got HTML?
  $txt =~s/##(rank|description)##//g;
  $txt =~s/##id##.log//g;		# for config
  $txt =~s/##runningjobs##//g;		# for glossary
  if (!ok ($txt =~ /##.*?##/,''))
    {
    print "# left over templates for '$key':\n";	# leftovers
    $txt =~ s/##(.*?)##/print "# '$1'\n";/eg;
    }
  }

# check that results are sorted properly
  
{
  $txt = $data->handle_requests( '10.20.30.40',
   "req0001=cmd_status;type_results" );
  $txt = $$txt if ref($txt) eq 'SCALAR';
  # got HTML?
  print "# Tried: '$_'\n# Got: '$txt'\n" unless ok ($txt =~ /(<TITLE>)/i,1);
  print "# Results are in wrong order! Got: '$txt'\n"
   unless ok ($txt =~ /second result(.|\n)*test for chain/,1);
  last if ok ($txt =~ /##.*?##/,'');
  print "# left over templates for '$_':\n";			# leftovers
  $txt =~ s/##(.*?)##/print "# '$1'\n"; "##$1##"/eg;
}

###############################################################################
# check clients (no mail will be sent since mailserver is 'none')

my $time = Dicop::Base::time();
$data->{last_check} = 0;			# never
my $clients = $data->check_clients(1);
ok (scalar keys %$clients,0);			# no by default
ok ($data->{last_check},$time);

# force #2 to be down
$data->{clients}->{2}->{last_chunk} = $time - 17*3600 - 2;
$data->{clients}->{2}->{online} = 1;
$data->{clients}->{2}->{went_offline} = 0;
$data->{last_check} = $time - 3600*1 - 2;
$clients = $data->check_clients(1);
ok (join (' ',keys %$clients),'2');			# no by default

###############################################################################
# reference speed

$data->{clients}->{2}->{speed} = 200;
$data->{clients}->{1}->{speed} = 400;
$data->{clients}->{2}->{last_chunk} = $time - 7*3600;
$data->{clients}->{1}->{last_chunk} = $time - 7*3600;
$data->{clients}->{2}->{cpuinfo} = [ 'K6-2', 200 ];
$data->{clients}->{1}->{cpuinfo} = [ 'K6-2', 400 ];
ok ($data->reference_speed(),'0 x 200 Mhz K6-2');
$data->{clients}->{2}->{last_chunk} = $time;
$data->{clients}->{1}->{last_chunk} = $time;
ok ($data->reference_speed(),'3 x 200 Mhz K6-2');


###############################################################################
# add result (or don't)

my $base = 2;
$request = { result => 'abcdef' };
ok (scalar $data->results(),$base);		# got one
($res,$result) = 
  $data->add_result( $data->{jobs}->{1}, $data->{clients}->{1}, $request );
ok ($result->{id},$base+1);			# 1 and 2
ok (scalar $data->results(),$base+1);		# one more
($res,$result) = 
  $data->add_result( $data->{jobs}->{1}, $data->{clients}->{1}, $request );
ok_undef ($result);			# none added
ok (scalar $data->results(),$base+1);		# none more
$request = { result => 'abcdef01' };
($res,$result) = 
  $data->add_result( $data->{jobs}->{1}, $data->{clients}->{1}, $request );
ok ($result->{id},$base+2);			# 1,2 and 3
ok (scalar $data->results(),$base+2);		# one more

###############################################################################
# test starting new job

$job = $data->get_job(1);
$chunk = $job->get_chunk(2);
$chunk->{client} = $data->get_client(2);	# fake issue chunk to client
$chunk->{status} = ISSUED;			# fake issue status
$chunk->clear_verifiers();			# don't use verify at all
ok ($job->{newjob},'on');
$txt = $data->handle_requests(
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0005=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9;status_SOLVED;result_4142434446;crc_cafebabe' 
  );
ok (scalar $data->results(),$base+3);		# again one more
ok ($job->{newjob},'on');			# unchanged
ok ($data->jobs(),$count->{jobs}+1);
$job = $data->get_job(5);

ok (ref($job), 'Dicop::Data::Job');
# test that new job's haltjob is "on" per default
ok ($job->{haltjob},'on');

# test that newly started job gets same owner than the one that spawned it
ok ($job->{owner}, $data->get_job(2)->{owner});
ok ($job->{owner}, $data->get_job(3)->{owner});
ok ($job->{owner}, 'Fumbledoor');
ok ($job->{case}, $data->get_job(2)->{case});

###############################################################################
# test BAD results

# Technically, this shouldn't happen, a client cannot get a chunk if it is
# already in the verifier list. However, we test that this still fails with
# the proper error.

$data->{config}->{tpl_dir} = './test-tpl';
$data->{config}->{mailtxt_dir} = 'mail';

ok ($data->flush_email_queue(1),0);		# empty queue, so do nothing
$job = $data->get_job(1);
$chunk = $job->get_chunk(2);
$chunk->{client} = $data->get_client(2);	# fake issue chunk to client
$chunk->{status} = ISSUED;			# fake issue status
$job->{newjob} = 'on';				# none added yet
$job->{status} = TOBEDONE;

$txt = $data->handle_requests(
    '10.20.30.40',
    'req0001=cmd_auth;id_2;version_2.24;arch_linux;os_linux-2.4.1&' 
  . 'req0005=cmd_report;took_12;chunk_2;job_1;token_f7c5304b5fa091a09029e687354462c9;status_SOLVED;result_4142434447;crc_deadbeef' 
  );
ok (ref($data->get_job(2)), 'Dicop::Data::Job');
ok (scalar $data->results(),$base+3);	# none more (BAD result)
ok ($job->{newjob},'on');		# still none added	
ok ($data->jobs(),$count->{jobs}+1);	# still no more jobs

ok (@{$data->{email_queue}},1);		# 1 entry with bad_result

# more tests of this variant can be found in t/data_mail.t
check_email_for_leftover_templates($data->{email_queue}->[0]->{message});

print "# $data->{email_queue}->[0]->{message}\n" unless
ok ($data->{email_queue}->[0]->{message} =~
     /-3 Client already verified this - need somebody else/,1 );

###############################################################################
# email queue handling

ok ($data->flush_email_queue(1),0);		# empty queue, so do nothing
ok (@{$data->{email_queue}},0);			# no entries yet

$data->{email_queue} = [ { 
  header => 'header text\n',
  server => 'none',					# prevent sending
  message => 'body',
  } ];							# fake one mail
ok ($data->flush_email_queue(1),0);			# don't send this one
ok (@{$data->{email_queue}},0);				# no entries anymore
$job =$data->get_job(1);
$data->email('none',undef, $job);			# put one into queue
ok (@{$data->{email_queue}},1);				# one entrie

###############################################################################
# writing of chunk description files (CDF)

$file = 'target/data/3/3-2.txt'; unlink $file if -e $file;

$job = $data->get_job(3); $chunk = $job->get_chunk(2);

print "# prefix $job->{prefix}\n";
print "# Job $job chunk $chunk\n";

my ($type,$response,$file_name) = 
  $data->description_file($job, $chunk, 'req0002');
ok ($type,102);
ok (1, -e $file && -f $file);

my $doc = read_file($file); die ($doc) unless ref $doc;
ok ($$doc,lines(12));		# check contents of chunk file

unlink $file;

###############################################################################
# writing of chunk description files (JDF)

$file = 'target/data/2/2.set'; unlink $file if -e $file;

$job = $data->get_job(2); $chunk = $job->get_chunk(2);

print "# prefix $job->{prefix}\n";
print "# Job $job chunk $chunk\n";

($type,$response,$file_name) = 
  $data->description_file($job, $chunk, 'req0002');
ok ($type,101);
ok (1, -e $file && -f $file);

$doc = read_file($file); die ($doc) unless ref $doc;
ok ($$doc,lines(9));		# check contents of chunk file

unlink $file;

###############################################################################
# JDF with extra fields (does not change with chunks)

$file = 'target/data/4/4.set'; unlink $file if -e $file;

$job = $data->get_job(4); $chunk = $job->get_chunk(2);

print "# prefix $job->{prefix}\n";
print "# Job $job chunk $chunk\n";

($type, $response, $file_name) =
   $data->description_file($job, $chunk, 'req0002');
ok ($file_name,$file);
ok ($type,101);
ok (1, -e $file && -f $file);

$doc = read_file($file); die ("Could not read $file: $! " . ($doc||'')) unless ref $doc;
ok ($$doc,lines(10));		# check contents of chunk file

###############################################################################
# no JDF/CDF but a target file

$job = $data->get_job(5); $chunk = $job->get_chunk(2);

print "# target $job->{target}\n";
print "# Job $job chunk $chunk\n";

($type, $response, $file_name) =
   $data->description_file($job, $chunk, 'req0002');
ok ($file_name,undef);
ok ($type,undef);
ok ($response, lines(1));

###############################################################################
# hash_file()

# clear hash area
$data->{target_hash} = {};

# put target/test.dat into target hash with code 101
$res = $data->hash_file('target/test.dat');
ok (ref($data->{target_hash}->{'target/test.dat'}), 'Dicop::Hash');
my $msg101 = lines(1);
my $msg102 = lines(1);
ok ($res, $msg101);

$data->{target_hash} = {};
$res = $data->hash_file('target/test.dat', undef, 102);
ok (ref($data->{target_hash}->{'target/test.dat'}), 'Dicop::Hash');
ok ($res, $msg102);

# test with different hash storage area
$data->{target_hash} = {};
$data->{work_hash} = {};
$res = $data->hash_file('target/test.dat', 'work', 102);
ok (ref($data->{work_hash}->{'target/test.dat'}), 'Dicop::Hash');
ok ($res, $msg102);

###############################################################################
# worker_hash

$data->{worker_hash} = {};

#my ($self, $jobtype, @archs) = @_;

# use the one from "linux"
$res = $data->worker_hash( { name => 'test' }, 'linux' );
ok (ref($data->{worker_hash}->{'test-worker/linux/test'}), 'Dicop::Hash');
ok ($res, 'hash_bd1f66a9398b7b8f4b3b28bcf39477d5;worker_test;');

# use the one from "linux/i386"
$data->{worker_hash} = {};
$res = $data->worker_hash( { name => 'test' }, 'linux-i386', 'linux' );

ok (ref($data->{worker_hash}->{'test-worker/linux/i386/test'}), 'Dicop::Hash');
ok ($res, 'hash_68adb9335f48a9f3232bc43fbc14f583;worker_i386/test;');

# use the one from "linux" because "linux/i386" does not exist
$data->{worker_hash} = {};
$res = $data->worker_hash( { name => 'test2' }, 'linux-i386', 'linux' );
ok (ref($data->{worker_hash}->{'test-worker/linux/test2'}), 'Dicop::Hash');
ok ($res, 'hash_9cdb5de75417b86de9bc22d8a8fcbdf5;worker_test2;');

# non-existing worker
$data->{worker_hash} = {};
$res = $data->worker_hash( { name => 'non-existing' }, 'linux-i386', 'linux' );
ok ($data->{worker_hash}->{'test-worker/linux/non-existing'}, undef);
ok (ref($res), 'SCALAR');
ok ($$res, "090 Cannot find worker test-worker/linux/non-existing\n");

# worker is a directory
$data->{worker_hash} = {};
$res = $data->worker_hash( { name => 'i386' }, 'linux' );
ok ($data->{worker_hash}->{'test-worker/linux/i386'}, undef);
ok (ref($res), 'SCALAR');
ok ($$res, "090 Cannot find worker test-worker/linux/i386\n");

###############################################################################
# termination of all clients

ok ($data->get_client(1)->{send_terminate},0);
$data->terminate_clients();
ok ($data->get_client(1)->{send_terminate},1);

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
  unlink 'target/2_2.set' if -f 'target/2_2.set';
  }  

###############################################################################
# subs

sub lines
  {
  my $cnt = shift;

  my $t = "";
  while ($cnt > 0)
    {
    $t .= shift @data; $cnt--;
    }
  return $t;
  }

sub read_lines
  {
  # read responses from data section
  while (<DATA>)
    {
    push @data, $_ if $_ !~ /^#[^#]/; 		# store, except for comments
    }
  }

sub ok_undef
  {
  my $u = shift;
  ok (1,1), return if !defined $u;

  ok ($u,"undef");
  }

sub print_errors
  {
  my $errors = shift;
  
  foreach my $e (@$errors)
    {
    print '# ', $e->error() || '' ,"\n";
    }
  }

__END__
count=9
0:1:41:42:43:44:45:46:47:48:49:4a:4b:4c:4d:4e:4f:50:51:52:53:54:55:56:57:58:59:5a
0:2:30:31:32:33:34:35:36:37:38:39
0:3:61:62:63:64:65:66:67:68:69:6a:6b:6c:6d:6e:6f:70:71:72:73:74:75:76:77:78:79:7a
1:4:-2=2:-1=2:0=3
1:5:-1=2:0=3:1=1
2:6
2:7:0,2,1,2
2:8:0,2,1,2:1,2,2,3:0,3,1,1
3:222:
Dicop::Data::Charset::Dictionary {
  description = "test dictionary w/ append/prepend"
  dirty = 0
  file = testlist.lst
  id = 7
  mutations = 1023
  scale = 2220
  sets = 0_2_1_2
  stages = 3
  type = dictionary
  }
Dicop::Data::Charset::Dictionary {
  description = "test dictionary w/ append/prepend"
  dirty = 0
  file = testlist.lst
  id = 8
  mutations = 1023
  scale = 24740
  sets = 0_2_1_2,1_2_2_3,0_3_1_1
  stages = 3
  type = dictionary
  }
# request_test()
req0000 101 ecae51e06066a0cef235e0d07283f83c "test-worker/charsets.def"
req0001 200 job_test-2;hash_bd1f66a9398b7b8f4b3b28bcf39477d5;worker_test;start_41414141;end_41505050;target_414141414141;chunk_2;token_2;set_1;
req0001 200 job_test-1;hash_bd1f66a9398b7b8f4b3b28bcf39477d5;worker_test;start_41414141;end_4141414141;target_41424344;chunk_2;token_2;set_1;
# request_test()
req0000 101 ecae51e06066a0cef235e0d07283f83c "test-worker/charsets.def"
req0001 200 job_test-1;hash_bd1f66a9398b7b8f4b3b28bcf39477d5;worker_test;start_41414141;end_4141414141;target_41424344;chunk_2;token_2;set_1;
# request_test() (with non-existing subarch)
req0000 101 ecae51e06066a0cef235e0d07283f83c "test-worker/charsets.def"
req0001 200 job_test-1;hash_bd1f66a9398b7b8f4b3b28bcf39477d5;worker_test;start_41414141;end_4141414141;target_41424344;chunk_2;token_2;set_1;
# find work, but no jobs defined
req0001 301 Wait, currently no work for you
# find work, but worker does not exist
req0000 101 ecae51e06066a0cef235e0d07283f83c "test-worker/charsets.def"
req0000 099 checking job 1 (last was 0)
req0000 090 Cannot find worker test-worker/foo/test
req0001 301 Wait, currently no work for you
# find work, all is well
req0000 101 ecae51e06066a0cef235e0d07283f83c "test-worker/charsets.def"
req0000 099 checking job 1 (last was 0)
req0000 099 find chunk in job 1
req0000 099 found id 2 size 30001
req0000 099 chunk size 30001
req0001 200 hash_bd1f66a9398b7b8f4b3b28bcf39477d5;worker_test;job_1;chunk_2;token_removed-to-compare;start_4141414141;end_4142534a57;target_4142434445;set_1;
# find work in second job with prefix (creates a JDF)
req0000 101 ecae51e06066a0cef235e0d07283f83c "test-worker/charsets.def"
req0000 099 checking job 2 (last was 0)
req0000 099 find chunk in job 2
req0000 099 found id 2 size 60001
req0001 101 9203acd4d7700a155bac968d5e0c26bd "target/data/2/2.set"
req0000 099 chunk size 60001
req0001 200 hash_bd1f66a9398b7b8f4b3b28bcf39477d5;worker_test;job_2;chunk_2;token_removed-to-compare;start_4141414141;end_41444b5453;target_4142434445;set_target/data/2/2.set;
# XXX TODO: find work in second job with prefi with CDF
# req0001 200 hash_bd1f66a9398b7b8f4b3b28bcf39477d5;worker_test;chunkfile_target/data/2/2-2.txt;token_removed-to-compare;set_1;
# wait test
req0001 301 Wait, currently no work for you
# couldn't authenticate you test
req0001 465 Couldn't authenticate you, no such client '5'
req0001 452 Client outdated, please upgrade to at least v2.11 build 5
req0001 457 Your IP '127.0.1.1' does not match the stored IP from client '1'
req0001 452 Client outdated, please upgrade to at least v2.11 build 5
req0001 452 Client outdated, please upgrade to at least v2.11 build 5
req0001 467 Your architecture 'frobble' is not listed as allowed
req0000 465 Couldn't authenticate you, no such client '5'
req0000 465 Couldn't authenticate you, no such client '7'
req0000 465 Couldn't authenticate you, no such client '10'
req0001 412 File 'worker/linux/test' does not exist or is not readable
req0001 411 File name 'test-worker/linux/test' has illegal format
req0001 411 File name 'worker/../test' has illegal format
req0001 411 File name 'worker/!test' has illegal format
req0001 200 http://127.0.0.1:88888/test/worker/test+
req0001 200 http://127.0.0.1:99999/test/worker/test+
req0001 200 http://127.0.0.1:88888/test/worker/test
req0001 200 http://127.0.0.1:99999/test/worker/test
req0001 200 http://127.0.0.1:88888/test/worker/test
req0001 200 http://127.0.0.1:99999/test/worker/test
# XXX TODO: shouldn't the image_file also be in hex?
## This file was automatically generated. Do not edit.
## This is a temporary file and can safely be deleted.
## Chunk description file for job 3, chunk 2.

charset_id=222
image_file="../../target/images/image_3_2.img"
image_type=0
extract_set_id=2
start=3
end=11
password_prefix=666f6f626172
target=4142434445
## This file was automatically generated. Do not edit.
## This is a temporary file and can safely be deleted.
## Chunk description file for job 2, chunk 2.

charset_id=1
start=4141414141
end=414141414141
password_prefix=666f6f626172
target=4142434445
## This file was automatically generated. Do not edit.
## This is a temporary file and can safely be deleted.
## Chunk description file for job 4, chunk 2.

charset_id=1
start=4141414141
end=414141414141
target=4142434445
extra0=757365726e616d65,62726f776e
extra1=68616972636f6c6f72,7375676172
# target file hash for job 5
req0000 101 c1a708f3e14e36e388ec2f75d04ceff2 "target/test.dat"
req0000 101 c1a708f3e14e36e388ec2f75d04ceff2 "target/test.dat"
req0000 102 c1a708f3e14e36e388ec2f75d04ceff2 "target/test.dat"
