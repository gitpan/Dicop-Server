#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../../lib', '../lib';
  chdir 't' if -d 't';
  plan tests => 1048;
  }

use Dicop::Event;

require "common.pl";

my $R = 'Dicop::Request';

#############################################################################
# general request tests

my $request = $R->new ( 
   id => 'req0001', 
   data => 'cmd_auth;arch_win32;id_5;version_0.24;fan_5360;temp_45.1',
  );
is $request->error(),"";

my $keys = 0;
foreach (keys %$request)
  { 
  $keys++ unless /^_/;
  }
is ($keys, 6+1, "we have 'dirty' in there");
is ($request->{id}, 5, 'id 5');
is ($request->{version}, 0.24, 'version');
is ($request->{fan}, 5360, 'fan');
is ($request->{temp}, 45.1, 'temp');
is ($request->{cmd}, 'auth','auth');
is ($request->{arch}, 'win32', 'win32');
is ($request->is_auth(),1, 'auth');
is ($request->is_info(),0, 'no info');
is ($request->is_request(),0, 'no request');
is ($request->is_form(),0, 'no form');

$request = $R->new ( 
   id => 'req0001', 
   data => 'cmd_info;arch_win32;id_5;version_0.24;ip_1.2.3.4;for_req0002', 
  );
is_type($request,'info');

$request = $R->new ( 
   id => 'req0001', 
   data => 'cmd_info;arch_win32;id_5;version_0.24;ip_1.2.3.4;for_req0002,req0003', 
  );
is_type($request,'info');

#############################################################################
# requests:

$request = $R->new ( 
   id => 'req0001', 
   data => 'cmd_request;type_test', 
  );
is_type($request,'request');

$request = $R->new ( 
   id => 'req0001', 
   data => 'cmd_request;type_work;count_1;size_1', 
  );
is_type($request,'request');

$request = $R->new ( 
   id => 'req0001', 
   data => 'cmd_request;type_file;name_worker%2ftest', 
  );
is_type($request,'request');

#############################################################################
# illegal form type
$request = $R->new ( id => 'req0001', 
   data => 'cmd_form;type_job1',
 );
isnt ($request->error(),"","type_job1");

# you cant request to add a chunk
$request = $R->new ( id => 'req0001', 
   data => 'cmd_form;type_chunk',
   );
isnt ($request->error(),"","cmd_form;type_chunk");

# "test" is no longer valid
$request = $R->new ( id => 'req0001', 
   data => 'cmd_test;',
);
isnt ($request->error(),"","cmd_test;");

# "nojobs" is no longer valid
$request = $R->new ( id => 'req0001', 
   data => 'cmd_request;type_test;nojobs_1,2,3',
);
isnt ($request->error(),"","cmd_request;type_test;nojobs_1,2,3");

###############################################################################
# (in)valid requests, and copy() (using Weapons of Mass DATA-testing)
# also, do evaluate request

my ($line, $request_string, $result);
while ($line = <DATA>)
  {
  chomp $line;
  next if $line =~ /^\s*$/;		# skip empty lines
  next if $line =~ /^#/;		# skip comments

  my ($request_string, $result ) = split /\|/, $line;
  $result ||= 'invalid 1';

  my $req = $R->new ( id => 'req0001', 
    data => $request_string, encoded => ($line =~ /[%\+]/ || 0) );
  print "# encoded\n" if ($line =~ /[%\+]/ || 0);
  if ( (($req->error() || "") ne '') && ($result =~ /invalid/))
    {
    print "# expect invalid: ",$req->error()||'';
    }
  else
    {
    is ($req->error(), '');		# no error
    # multiple ';' should be ignored silently, so we ignore them, too
    $request_string =~ s/;+/;/g;
    is ($req->as_request_string(),"req0001=$request_string");
    # test that copy() works
    is ($req->copy()->as_request_string(),$req->as_request_string());
    }
  my $rc = $req->class() . ' ' . $req->auth();
  print "# Expected: '$result', got: '$rc'\n",
        "# for $request_string\n" if !ok ($rc,$result);
  }
    
my $data = 
  "cmd_add;count_1;description_hot;group_model;ip_127.0.0.1;mask_255.255.255.0;name_Ivonna%20Humpalot;pwd_ohyes;pwdrepeat_ohyes;trusted_off;type_client";

# decoding %20 => ' ' => encoding it to '+'
$request = $R->new ( id => 'req0001', 
    data => $data, encoded => 1 );

$data =~ s/%20/+/;
is ($request->as_request_string(), "req0001=$data");

###############################################################################
# test empty parameters

$request = $R->new ( id => 'req0001', 
   data => 'cmd_request;type_work;size_5;', );
is ($request->as_request_string(),"req0001=cmd_request;size_5;type_work");

###############################################################################
# test changing id

is ($request->request_id(), 'req0001');
$request->field('_id','req0002');
is ($request->request_id(), 'req0002');
$request->request_id('req0003');
is ($request->request_id(), 'req0003');
$request->request_id('abc0004');		# can't do this
is ($request->request_id(), 'req0003');

###############################################################################
# test adding a job (parameters with '-')

$request = $R->new ( id => 'req0001', 
   data => 'case_2;cmd_add;type_job;newjob_on;newjob-jobtype_4;newjob-description_description;newjob-charset_5;newjob-start_30303030;newjob-end_3030303030;end_30303030;start_30303030;charset_5;jobtype_4;description_jdescr;rank_100;target_21;',
   );
is ($request->error(),"", 'no error');

# newjob-haltjob_on
$request = $R->new ( id => 'req0001', 
   data => 'case_2;cmd_add;type_job;newjob_on;newjob-jobtype_4;newjob-description_description;newjob-charset_5;newjob-start_30303030;newjob-end_3030303030;end_30303030;start_30303030;charset_5;jobtype_4;newjob-haltjob_on;description_jdescr;rank_100;target_21;',
   );
is ($request->error(),"", 'no error');

# haltjob_on
$request = $R->new ( id => 'req0001', 
   data => 'case_2;cmd_add;type_job;newjob_on;newjob-jobtype_4;newjob-description_description;newjob-charset_5;newjob-start_30303030;newjob-end_3030303030;end_30303030;start_30303030;charset_5;jobtype_4;haltjob_on;description_jdescr;rank_100;target_21;',
   );
is ($request->error(),"", 'no error');

###############################################################################
# maxchunksize for jobs

$request = $R->new ( id => 'req0001', 
   data => 'case_2;cmd_add;type_job;newjob_on;newjob-jobtype_4;newjob-description_description;newjob-charset_5;newjob-start_30303030;newjob-end_3030303030;end_30303030;start_30303030;charset_5;jobtype_4;description_jdescr;rank_100;target_21;maxchunksize_0',
   );
is ($request->error(),"", 'no error');

$request = $R->new ( id => 'req0001', 
   data => 'case_2;cmd_add;type_job;newjob_on;newjob-jobtype_4;newjob-description_description;newjob-charset_5;newjob-start_30303030;newjob-end_3030303030;end_30303030;start_30303030;charset_5;jobtype_4;description_jdescr;rank_100;target_21;maxchunksize_2',
   );
is ($request->error(),"", 'no error');

$request = $R->new ( id => 'req0001', 
   data => 'case_2;cmd_add;type_job;newjob_on;newjob-jobtype_4;newjob-description_description;newjob-charset_5;newjob-start_30303030;newjob-end_3030303030;end_30303030;start_30303030;charset_5;jobtype_4;description_jdescr;rank_100;target_21;maxchunksize_2;newjob-maxchunksize_0',
   );
is ($request->error(),"", 'no error');

$request = $R->new ( id => 'req0001', 
   data => 'case_2;cmd_add;type_job;newjob_on;newjob-jobtype_4;newjob-description_description;newjob-charset_5;newjob-start_30303030;newjob-end_3030303030;end_30303030;start_30303030;charset_5;jobtype_4;description_jdescr;rank_100;target_21;maxchunksize_2;newjob-maxchunksize_12',
   );
is ($request->error(),"", 'no error');

###############################################################################
# test request with empty value (and making a copy of it)
  
$data = 'charset_1;cmd_change;description_foobared;end_62;id_1;jobtype_2;result_;start_61;target_target/test/test.tgt;type_testcase';

$request = $R->new ( id => 'req0001', data => $data );
if (!is ($request->error(),"", 'no error'))
  {
  print "# Failed for request: '$data'\n";
  }
# copy() and compare
is ($request->copy()->as_request_string(),$request->as_request_string());

1; # EOF

###############################################################################
###############################################################################

sub is_type
  {
  my ($request,$type) = @_;

  my $done = 0; 
  for my $t (qw/auth info request form/)
    {
    my $method = 'is_' . $t;
    my $res = $t eq $type ? 1 : 0;
    my $cmt = $t; $cmt = 'no ' . $cmt if $t ne $type;
    $done ++ if $t eq $type;
    is ($request->$method(), $res, $cmt);
    }
  warn ("is_type() called with invalid type '$type'") if $done != 1;
  }

###############################################################################
# Some valid combinations to test for follow. param names sorted alphabetically
__DATA__
arch_win32;cmd_auth;fan_5360;id_5;temp_43.2;version_0.24|admin 1
arch_win32;cmd_auth;fan_5360;id_5;pid_0;temp_43.2;version_0.24|admin 1
arch_win32;cmd_auth;fan_5360;id_5;pid_123;temp_43.2;version_0.24|admin 1
charset_2;cmd_add;description_%25%5f-%3d+%3b;fixed_3;minlen_0;name_n;script_bar;speed_10;type_jobtype|admin 1
cmd_status;id_1;type_case|status 0
cmd_status;name_1234;type_casebyname|status 0
cmd_status;id_1234;type_casebyname|invalid 1
cmd_status;type_main|status 0
cmd_status;type_config|admin 0
cmd_status;filter_TOBEDONE;type_main|status 0
cmd_status;filter_DONE,TOBEDONE;type_main|status 0
cmd_status;type_server|status 0
cmd_status;type_debug|admin 0
cmd_status;id_1;type_job|status 0
cmd_status;id_1;type_jobresults|status 0
cmd_status;type_results|status 0
cmd_status;sort_up;type_results|status 0
cmd_status;sort_up;sortby_job;type_results|status 0
cmd_status;sort_upstr;sortby_description;type_results|status 0
cmd_status;id_1;type_results|status 0
cmd_status;id_1;type_client|stats 0
cmd_status;type_clients|status 0
cmd_status;sort_name;type_clients|status 0
cmd_status;sort_id;type_clients|status 0
cmd_status;sort_keys;type_clients|status 0
cmd_status;sort_online;type_clients|status 0
cmd_status;sort_speed;type_clients|status 0
cmd_status;type_search|status 0
cmd_status;type_chunks|status 0
cmd_status;id_1;type_chunks|status 0
cmd_status;type_proxies|status 0
cmd_status;id_1;type_proxies|status 0
cmd_status;type_charsets|status 0
cmd_status;id_1;type_charsets|status 0
cmd_status;id_1;type_charset|status 0
cmd_status;id_1;samples_foo%0abar;type_charset|status 0
cmd_status;id_1;samples_foobar;type_charset|status 0
cmd_status;type_jobtypes|status 0
cmd_status;sort_up;type_jobtypes|status 0
cmd_status;sort_upstr;type_jobtypes|status 0
cmd_status;sort_upstr;sortby_name;type_jobtypes|status 0
cmd_status;sort_up;sortby_id;type_jobtypes|status 0
cmd_status;id_1;type_jobtypes|status 0
cmd_status;type_groups|status 0
cmd_status;id_1;type_groups|status 0
cmd_status;type_users|status 0
cmd_status;id_1;type_users|status 0
cmd_status;type_clientmap|status 0
cmd_status;type_clientmap;width_10|status 0
browse_target;cmd_status;form_cmd%5fstatus%3btype%5ftestcase;params_style%5fblue;path_.;targetfield_target;type_file|status 0
cmd_status;form_cmd%5fstatus%3btype%5ftestcase;params_style%5fblue;path_.;targetfield_target;type_file|status 0
case_0;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_groups|admin 1
case_1;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_groups|admin 1
case_0;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_charsets|admin 1
case_1;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_charsets|admin 1
case_0;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_clients|admin 1
case_1;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_clients|admin 1
case_0;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_jobs|admin 1
case_1;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_jobs|admin 1
case_0;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_results|admin 1
case_1;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_results|admin 1
case_0;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_proxies|admin 1
case_1;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_proxies|admin 1
case_0;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_testcases|admin 1
case_1;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_testcases|admin 1
case_0;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_jobtypes|admin 1
case_1;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_jobtypes|admin 1
case_0;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_users|admin 1
case_1;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_users|admin 1
case_0;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_cases|admin 1
case_1;cmd_search;description_ANY;id_ANY;ip_ANY;name_ANY;type_cases|admin 1
cmd_request;type_test|work 0
cmd_request;size_1;type_work|work 0
cmd_change;id_1;job_1;status_tobedone;type_chunk|admin 1
cmd_change;id_1;job_1;status_done;type_chunk|admin 1
cmd_change;id_1;job_1;status_failed;type_chunk|invalid 1
cmd_change;id_1;job_1;status_done;type_chunk|admin 1
cmd_change;id_1;job_1;status_bad;type_chunk|invalid 1
charset_1;cmd_change;description_foobared;end_62;id_1;jobtype_2;result_22;start_61;target_target/test/test.tgt;type_testcase|admin 1
charset_1;cmd_change;description_foobared;disabled_on;end_62;id_1;jobtype_2;result_22;start_61;target_target/test/test.tgt;type_testcase|admin 1
charset_1;cmd_change;description_foobared;end_62;id_1;jobtype_2;start_61;target_target/test/test.tgt;type_testcase|admin 1
charset_1;cmd_change;description_foobared;end_62;;id_1;jobtype_2;start_61;target_target/test/test.tgt;type_testcase|admin 1
charset_1;cmd_change;description_foobared;end_62;;id_1;jobtype_2;prefix_313233;start_61;target_target/test/test.tgt;type_testcase|admin 1
cmd_change;description_runaway;id_1;name_jane+dow;type_group|admin 1
case_2;cmd_change;description_once+in+a+blue+moon;id_1;maxchunksize_0;rank_90;status_suspended;type_job|admin 1
case_2;cmd_change;description_may+the+source+be+with+your+code;id_1;maxchunksize_0;rank_90;status_failed;type_job|admin 1
case_2;cmd_change;description_double+egg,+bacon,+beans,+and+tomatos;id_1;maxchunksize_0;rank_90;status_solved;type_job|admin 1
case_2;cmd_change;description_bye+now;id_1;maxchunksize_0;rank_90;status_tobedone;type_job|admin 1
case_2;cmd_change;description_bye+now;id_1;maxchunksize_0;newjob_on;rank_90;status_tobedone;type_job|admin 1
charset_1;cmd_change;description_changed;id_1;name_d+meat;script_none;speed_1000;type_jobtype|admin 1
charset_1;cmd_change;description_changed;id_1;name_unnamed;speed_1000;type_jobtype|admin 1
charset_1;cmd_change;description_changed;id_1;name_dirty+jobscript;speed_1000;type_jobtype|admin 1
charset_1;cmd_change;description_changed;files_win:+Some.dll,this.dat%3b+linux:+this.dat;id_1;name_dirty+jobscript;speed_1000;type_jobtype|admin 1
charset_1;cmd_change;description_changed;files_win:+Some.dll,this.dat%3b+linux:+this.dat;id_1;minlen_3;name_dirty+jobscript;speed_1000;type_jobtype|admin 1
cmd_change;id_1;name_testuser;pwd_123;pwdrepeat_123;type_user|admin 1
cmd_confirm;id_1;type_client|admin 0
cmd_confirm;id_1;type_proxy|admin 0
cmd_confirm;id_1;type_testcase|admin 0
cmd_confirm;id_1;type_charset|admin 0
cmd_confirm;id_1;type_result|admin 0
cmd_confirm;id_1;type_job|admin 0
cmd_confirm;id_1;type_user|admin 0
cmd_confirm;id_1;type_jobtype|admin 0
cmd_del;id_1;type_case|admin 1
cmd_del;id_1;type_client|admin 1
cmd_del;id_1;type_proxy|admin 1
cmd_del;id_1;type_testcase|admin 1
cmd_del;id_1;type_charset|admin 1
cmd_del;id_1;type_result|admin 1
cmd_del;id_1;type_job|admin 1
cmd_del;id_1;type_jobtype|admin 1
cmd_del;id_1;type_user|admin 1
chunk_2;cmd_report;crc_123;job_2;status_FAILURE;token_2;took_30|work 0
chunk_2;cmd_report;crc_123;job_2;status_FAILURE;token_2;took_10|work 0
chunk_2;cmd_report;crc_123;job_2;reason_Can%27t+download+file+%27test.tgt%27;status_FAILURE;token_2;took_2|work 0
chunk_2;cmd_report;crc_123;job_2;result_61626364;status_SOLVED;token_ring;took_10|work 0
arch_linux;cmd_auth;id_55;os_os/2,v4.0;version_0.2|admin 1
arch_linux;cmd_auth;id_55;os_os/2,v4.0;version_0.2|admin 1
arch_armv4l;cmd_auth;id_1;pass_Friend;user_TheGrey;version_1|admin 1
arch_win32;cmd_info;cpuinfo_Katmai-III-%25300-Mhz;for_req0002;id_55;ip_1.2.3.4;os_os/2,v4.0;version_0.2|admin 1
arch_win32;cmd_info;cpuinfo_Katmai-III-%25300-Mhz;for_req0002,req0003;id_55;ip_1.2.3.4;os_os/2,v4.0;version_0.2|admin 1
arch_win32;cmd_info;cpuinfo_AMD-K6-200Mhz;for_req0001;id_55;ip_1.2.3.4;os_os/2,v4.0;version_0.2|admin 1
cmd_form;type_jobtype|admin 0
cmd_form;type_job|admin 0
cmd_form;type_group|admin 0
cmd_form;type_proxy|admin 0
cmd_form;type_testcase|admin 0
cmd_form;type_client|admin 0
cmd_form;type_charset|admin 0
cmd_form;type_simplecharset|admin 0
cmd_form;type_extractcharset|admin 0
cmd_form;type_groupedcharset|admin 0
cmd_form;type_dictionarycharset|admin 0
cmd_form;type_user|admin 0
cmd_form;type_case|admin 0
cmd_form;id_1;type_jobtype|admin 0
cmd_form;id_1;type_job|admin 0
cmd_form;id_1;type_group|admin 0
cmd_form;id_1;type_proxy|admin 0
cmd_form;id_1;type_testcase|admin 0
cmd_form;id_1;type_client|admin 0
cmd_form;id_1;type_charset|admin 0
cmd_form;id_1;type_user|admin 0
cmd_form;id_1;type_case|admin 0
cmd_form;style_red;type_jobtype|admin 0
cmd_form;style_red;type_job|admin 0
cmd_form;style_red;type_group|admin 0
cmd_form;style_red;type_proxy|admin 0
cmd_form;style_red;type_testcase|admin 0
cmd_form;style_red;type_client|admin 0
cmd_form;style_red;type_charset|admin 0
cmd_form;style_red;type_user|admin 0
cmd_form;profile_default;type_jobtype|invalid 1
cmd_form;profile_default;type_job|invalid 1
cmd_form;profile_default;type_group|invalid 1
cmd_form;profile_default;type_proxy|invalid 1
cmd_form;profile_default;type_testcase|invalid 1
cmd_form;profile_default;type_client|invalid 1
cmd_form;profile_default;type_charset|invalid 1
cmd_form;profile_default;type_user|invalid 1
cmd_form;profile_default;type_case|invalid 1
cmd_form;profile_default+set;type_jobtype|invalid 1
cmd_form;profile_default+set;type_job|invalid 1
cmd_form;profile_default+set;type_group|invalid 1
cmd_form;profile_default+set;type_proxy|invalid 1
cmd_form;profile_default+set;type_testcase|invalid 1
cmd_form;profile_default+set;type_client|invalid 1
cmd_form;profile_default+set;type_charset|invalid 1
cmd_form;profile_default+set;type_user|invalid 1
cmd_form;profile_default+set;type_case|invalid 1
cmd_confirmreset;id_1;type_client|admin 0
cmd_reset;id_1;type_client|admin 1
cmd_reset;type_clients|admin 1
cmd_reset;style_red;type_clients|admin 1
cmd_reset;id_1;style_red;type_client|admin 1
cmd_terminate;type_clients|admin 1
cmd_terminate;id_1;type_client|admin 1
cmd_terminate;id_1;style_blue;type_client|admin 1
cmd_terminate;style_red;type_clients|admin 1
charset_2;cmd_add;description_f;fixed_3;minlen_1;name_n;script_bar;speed_10;type_jobtype|admin 1
charset_2;cmd_add;description_foo;fixed_0;minlen_1;name_n;speed_10;type_jobtype|admin 1
charset_2;cmd_add;description_foo;files_win32:+this.dat,+some.dll%3b+linux:+this.dat;fixed_0;minlen_1;name_n;speed_10;type_jobtype|admin 1
charset_2;cmd_add;description_f;fixed_3;id_12;minlen_1;name_n;script_bar;speed_10;type_jobtype|admin 1
charset_2;cmd_add;description_foo;fixed_0;id_12;minlen_1;name_n;speed_10;type_jobtype|admin 1
charset_2;cmd_add;description_foo;files_win32:+this.dat,+some.dll%3b+linux:+this.dat;fixed_0;id_123;minlen_1;name_n;speed_10;type_jobtype|admin 1
case_2;charset_1;cmd_add;description_foo;end_61;jobtype_4;rank_100;start_61;target_29;type_job|admin 1
case_2;charset_1;cmd_add;description_foo;end_61;jobtype_4;prefix_65;rank_100;start_61;target_20;type_job|admin 1
case_2;charset_1;cmd_add;description_foo;end_61;jobtype_4;prefix_a;prefixinascii_on;rank_100;start_61;target_6541;type_job|admin 1
ascii_on;case_2;charset_1;cmd_add;description_foo;end_a;jobtype_4;prefix_a;rank_100;start_a;target_6541;type_job|admin 1
ascii_on;case_2;charset_1;checkothers_on;cmd_add;description_foo;end_a;jobtype_4;prefix_a;rank_100;start_a;target_6541;type_job|admin 1
case_2;charset_1;cmd_add;description_foo;end_61;jobtype_4;newjob_on;newjob-end_414141;newjob-start_4141;prefix_a;prefixinascii_on;rank_100;start_61;target_6541;type_job|admin 1
case_2;charset_1;cmd_add;description_foo;end_61;jobtype_4;newjob_on;newjob-ascii_on;newjob-end_414141;newjob-start_4141;prefix_a;prefixinascii_on;rank_100;start_61;target_6541;type_job|admin 1
case_2;charset_1;cmd_add;description_foo;end_61;jobtype_4;newjob_on;newjob-ascii_on;newjob-end_414141;newjob-prefix_4142;newjob-start_4141;prefix_a;prefixinascii_on;rank_100;start_61;target_6541;type_job|admin 1
case_2;charset_1;cmd_add;description_foo;end_61;jobtype_4;newjob_on;newjob-ascii_on;newjob-end_414141;newjob-maxchunksize_12;newjob-prefix_4142;newjob-start_4141;prefix_a;prefixinascii_on;rank_100;start_61;target_6541;type_job|admin 1
case_2;charset_1;cmd_add;description_foo;end_61;jobtype_4;maxchunksize_12;newjob_on;newjob-ascii_on;newjob-end_414141;newjob-maxchunksize_12;newjob-prefix_4142;newjob-start_4141;prefix_a;prefixinascii_on;rank_100;start_61;target_6541;type_job|admin 1
case_2;charset_1;cmd_add;description_foo;end_61;jobtype_4;maxchunksize_0;newjob_on;newjob-ascii_on;newjob-end_414141;newjob-maxchunksize_12;newjob-prefix_4142;newjob-start_4141;prefix_a;prefixinascii_on;rank_100;start_61;target_6541;type_job|admin 1
case_2;charset_1;cmd_add;description_foo;end_61;jobtype_4;maxchunksize_0;newjob_on;newjob-ascii_on;newjob-end_414141;newjob-maxchunksize_0;newjob-prefix_4142;newjob-start_4141;prefix_a;prefixinascii_on;rank_100;start_61;target_6541;type_job|admin 1
cmd_add;description_foo;name_frodo;type_group|admin 1
cmd_add;description_foo;group_1;ip_127.0.0.1;mask_255.255.255.255;name_gandalf;pwd_123;pwdrepeat_123;type_proxy|admin 1
cmd_add;description_foo;group_1;id_123;ip_127.0.0.1;mask_255.255.255.255;name_gandalf;pwd_123;pwdrepeat_123;type_proxy|admin 1
cmd_add;description_foo;set_31323334353637383930;type_simplecharset|admin 1
cmd_add;description_foo;set_%27a%27..%27z%27;type_simplecharset|admin 1
cmd_add;cpos0_1;cset0_1;description_foo;type_groupedcharset|admin 1
cmd_add;cpos0_1;cset0_1;description_foo;style_Coral,round;type_groupedcharset|admin 1
cmd_add;cpos0_1;cpos15_1;cset0_1;cset15_1;description_foo;type_groupedcharset|admin 1
cmd_add;description_foo;file_testlist.lst;type_dictionarycharset|admin 1
cmd_add;description_foo;set_1;skip_0;type_extractcharset|admin 1
cmd_add;description_foo;set_1;skip_1;type_extractcharset|admin 1
cend0_1;cmd_add;cpos0_0;cset0_1;cstart0_1;description_foo;file_testlist.lst;type_dictionarycharset|admin 1
cend0_1;cend1_1;cmd_add;cpos0_0;cpos1_1;cset0_1;cset1_1;cstart0_1;cstart1_1;description_foo;file_testlist.lst;type_dictionarycharset|admin 1
cend0_1;cend2_1;cmd_add;cpos0_0;cpos2_1;cset0_1;cset2_1;cstart0_1;cstart2_1;description_foo;file_testlist.lst;type_dictionarycharset|admin 1
cend0_1;cend3_1;cmd_add;cpos0_0;cpos3_1;cset0_1;cset3_1;cstart0_1;cstart3_1;description_foo;file_testlist.lst;type_dictionarycharset|admin 1
cend0_1;cend4_1;cmd_add;cpos0_0;cpos4_1;cset0_1;cset4_1;cstart0_1;cstart4_1;description_foo;file_testlist.lst;type_dictionarycharset|admin 1
cend0_1;cend15_1;cmd_add;cpos0_0;cpos15_1;cset0_1;cset15_1;cstart0_1;cstart15_1;description_foo;file_testlist.lst;type_dictionarycharset|admin 1
cmd_add;description_foo;file_testlist.lst;lower_on;type_dictionarycharset|admin 1
cmd_add;description_foo;file_testlist.lst;type_dictionarycharset;upper_on|admin 1
cmd_add;description_foo;file_testlist.lst;lowerfirst_on;type_dictionarycharset|admin 1
cmd_add;description_foo;file_testlist.lst;lowerlast_on;type_dictionarycharset|admin 1
cmd_add;description_foo;file_testlist.lst;type_dictionarycharset;upperlast_on|admin 1
cmd_add;description_foo;file_testlist.lst;type_dictionarycharset;upperfirst_on|admin 1
cmd_add;description_foo;file_testlist.lst;type_dictionarycharset;upperodd_on|admin 1
cmd_add;description_foo;file_testlist.lst;type_dictionarycharset;uppereven_on|admin 1
cmd_add;description_foo;file_testlist.lst;type_dictionarycharset;uppervowels_on|admin 1
cmd_add;description_foo;file_testlist.lst;type_dictionarycharset;upperconsonants_on|admin 1
cmd_add;description_foo;file_testlist.lst;lower_on;lowerfirst_on;lowerlast_on;type_dictionarycharset;upper_on;upperconsonants_on;uppereven_on;upperfirst_on;upperlast_on;upperodd_on;uppervowels_on|admin 1
charset_1;cmd_add;description_foo;end_61;jobtype_2;start_61;target_31;type_testcase|admin 1
charset_1;cmd_add;description_foo;disabled_on;end_61;jobtype_2;start_61;target_31;type_testcase|admin 1
charset_1;cmd_add;description_foo;end_61;jobtype_2;prefix_313233;start_61;target_31;type_testcase|admin 1
charset_1;cmd_add;description_foo;end_61;jobtype_2;prefix_313233;result_313233;start_61;target_31;type_testcase|admin 1
cmd_add;count_1;description_hot;group_model;ip_127.0.0.2;mask_255.255.255.0;name_Ivonna+Humpalot;pwd_ohyes;pwdrepeat_ohyes;trusted_off;type_client|admin 1
cmd_add;count_2;description_hot;group_model;ip_127.0.0.2;mask_255.255.255.0;name_Ivonna+Humpalot;pwd_ohyes;pwdrepeat_ohyes;trusted_;type_client|admin 1
cmd_change;description_hot;group_1;id_1;ip_127.0.0.2;mask_255.255.255.0;name_me;pwd_nope;pwdrepeat_nope;trusted_;type_client|admin 1
cmd_change;description_hot;group_1;id_1;ip_127.0.0.2;mask_255.255.255.0;name_me;pwd_nope;pwdrepeat_nope;trusted_1;type_client|admin 1
cmd_change;description_hot;group_1;id_1;ip_127.0.0.2;mask_255.255.255.0;name_me;pwd_nope;pwdrepeat_nope;type_client|admin 1
cmd_add;name_justin+case;pwd_s3cr3t;pwdrepeat_s3cr3t;type_user|admin 1
cmd_help;type_client|status 0
cmd_help;type_list|status 0
cmd_help;type_dicop|status 0
cmd_help;type_dicopd|status 0
cmd_help;type_new|status 0
cmd_help;type_proxy|status 0
cmd_help;type_config|status 0
cmd_help;style_Ice;type_client|status 0
cmd_help;style_Ice;type_list|status 0
cmd_help;style_Ice;type_dicop|status 0
cmd_help;style_Ice;type_dicopd|status 0
cmd_help;style_Ice;type_new|status 0
cmd_help;style_Ice;type_proxy|status 0
cmd_help;style_Ice;type_config|status 0
cmd_help;style_Ice;type_worker|status 0
# test ignoring multiple ';'
cmd_help;;type_list|status 0
cmd_help;;;type_list|status 0
# test adding charsets
cmd_add;description_foo;set_303132333435363738339;type_simplecharset|admin 1
cmd_add;description_foo;set_1;skip_0;type_extractcharset|admin 1
cmd_add;description_foo;set_1;skip_1;type_extractcharset|admin 1
cmd_add;description_foo;forward_1;set_1;skip_1;type_extractcharset|admin 1
cmd_add;description_foo;forward_1;reverse_1;set_1;skip_1;type_extractcharset|admin 1
cmd_add;description_foo;forward_1;lower_1;reverse_1;set_1;skip_1;type_extractcharset|admin 1
cmd_add;description_foo;forward_1;lower_1;reverse_1;set_1;skip_1;type_extractcharset;upper_1|admin 1
# invalid requests
cmd_help;type_foo|invalid 1
cmd_status;type_jobresults|invalid 1
cmd_status;type_case|invalid 1
cmd_status;type_case;style_default|invalid 1
cmd_status;type_case;filter_DONE|invalid 1
cmd_status;type_case;filter_DONE,TOBEDONE|invalid 1
cmd_status;type_case;filter_DONE;style_default|invalid 1
cmd_status;type_case;filter_DONE,TOBEDONE;style_default|invalid 1
cmd_change;id_1;type_case|invalid 1
cmd_change;id_1;type_client|invalid 1
cmd_change;id_1;type_job;rank_90;status_suspended;maxchunksize_0;|invalid 1
cmd_change;id_1;type_job;rank_90;status_tobedone;maxchunksize_0|invalid 1
cmd_change;id_1;type_job;rank_90;status_solved;maxchunksize_0|invalid 1
cmd_change;id_1;type_job;rank_90;status_failed;maxchunksize_1|invalid 1
cmd_change;id_1;type_job;rank_90;status_bad;maxchunksize_5;|invalid 1
cmd_change;id_1;type_job;rank_90;status_done;maxchunksize_0|invalid 1
cmd_change;id_1;type_job;rank_90;status_suspended;maxchunksize_0;description_test|invalid 1
cmd_change;id_1;type_job;rank_90;status_tobedone;maxchunksize_0;description_test+test|invalid 1
cmd_change;id_1;type_job;rank_90;status_solved;maxchunksize_0;description_EatThis!|invalid 1
cmd_change;id_1;type_job;rank_90;status_failed;maxchunksize_1;description_undescribable|invalid 1
cmd_change;id_1;type_testcase;|invalid 1
cmd_change;id_1;type_group|invalid 1
cmd_change;id_1;type_jobtype|invalid 1
cmd_confirmreset;type_client|invalid 1
