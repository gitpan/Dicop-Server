#!/usr/bin/perl -w

# Test for Dicop::Data - adding objects

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 134;
  }

use Dicop qw/ISSUED TOBEDONE DONE VERIFY SUSPENDED SOLVED/;
use Dicop::Base qw/a2h/;
use Dicop::Data;
use Dicop::Request;
use Dicop::Event;

Dicop::Event::handler( sub { } );	# zap error handler to be silent

$Dicop::Handler::NO_STDERR = 1;         # disable informative message

{
  no warnings;
  *Dicop::Data::flush = sub { };	# never flush the testdata
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

is ($data->check(),undef, 'construct ok');	# construct was okay

is ($data->type(),'server', 'type server');

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
  cases => 1,		# one auto-created
  };

foreach my $key (keys %$count)
  {
  is ($data->$key(),$count->{$key}, "$key => $count->{$key}");
  }

my $rc;

###############################################################################
# add job and see if it get's marked as modified

# prepare data
my $r = 'cmd_add;type_job';
$r .= ";start_". a2h('abcd');
$r .= ";end_". a2h('zzzz');
$r .= ";description_some+test";
$r .= ";rank_90";
$r .= ";charset_3";
$r .= ";jobtype_1";
$r .= ";target_616263";
$r .= ";case_1";

my $req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
my $result = ${ $data->add( $req, undef, { user => 'test' } ) };

my $j = $data->get_job($count->{jobs}+1);
is (ref($j), 'Dicop::Data::Job', 'job' );
is ($j->{_modified}, 1, 'modified' );
print "# case is $j->{case}" unless
  is (ref($j->{case}), 'Dicop::Data::Case', 'case is 1 as default' );

is ( $j->{case}->{id}, 1, 'default case ID #1');
is ( $j->{owner}, 'test', 'owner was set correctly');

###############################################################################
# add job and see if the jobtype's minlen gets honoured

# prepare data
$r = 'cmd_add;type_job';
$r .= ";start_". a2h('abcd');
$r .= ";end_". a2h('zzzz');
$r .= ";description_some+test";
$r .= ";rank_90";
$r .= ";charset_3";
$r .= ";jobtype_2";
$r .= ";target_616263";
$r .= ";case_1";

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = ${ $data->add( $req ) };

print "# '$result'\n"
  unless is ($result =~ /436 Could not add item: minimum length from jobtype is 6, but end is only 4 characters long/, 1, 'could not add');

# job does not exist
$j = $data->get_job($count->{jobs}+2);
is (ref($j), '', 'job does not exist' );

###############################################################################
# add simple charset (fails due to already existing charset)

# prepare data
$r = 'cmd_add;type_simplecharset';
$r .= ";description_some+test";
$r .= ";set_%27a%27..%27z%27";		# 'a' .. 'z'

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = ${ $data->add( $req ) };

print "# '$result'\n"
  unless is ($result =~ /431 A charset '6162636465666768696a6b6c6d6e6f707172737475767778797a' already exists with/, 1, 'could not add');

# charset exist
$j = $data->get_charset($count->{charsets}+1);
is (ref($j), '', 'charset does not exist' );

###############################################################################
# add simple charset (fails due to non existing type "charset" (these are now
# "simplecharset"

# prepare data
$r = 'cmd_add;type_charset';
$r .= ";description_some+test";
$r .= ";set_%27a%27..%27x%27";		# 'a' .. 'x'

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );

# and now add it
$result = ${ $data->add( $req ) };

print "# '$result'\n"
  unless is ($result =~ /462 Invalid request - no request pattern matched/, 1, 'could not add');

# charset exist
$j = $data->get_charset($count->{charsets}+2);
is (ref($j), '', 'charset exists' );

###############################################################################
# add simple charset (with 'a'..'z' as set)

# prepare data
$r = 'cmd_add;type_simplecharset';
$r .= ";description_some+test";
$r .= ";set_%27a%27..%27x%27";		# 'a' .. 'x'

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = ${ $data->add( $req ) };

print "# '$result'\n"
  unless is ($result =~ /simplecharset was added/, 1, 'could add');

# charset exist
$j = $data->get_charset(224);		# 222 (exists already), 223 (failed), 224
is (ref($j), 'Dicop::Data::Charset', 'charset exists' );

###############################################################################
# add simple charset (with 'a'..'z','0'..'9' as set)

# prepare data
$r = 'cmd_add;type_simplecharset';
$r .= ";description_some+test";
$r .= ";set_%27a%27..%27x%27,%270%27..%279%27";		# 'a' .. 'z','0'..'9'

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = ${ $data->add( $req ) };

print "# '$result'\n"
  unless is ($result =~ /simplecharset was added/, 1, 'could add');

# charset exist
$j = $data->get_charset(224);		# 222 (exists already), 223 (failed), 224
is (ref($j), 'Dicop::Data::Charset', 'charset exists' );

###############################################################################
# add job with a script (also tests new 'script_dir' field in config)

# prepare data
$r = 'cmd_add;type_job';
$r .= ";start_". a2h('abcd');
$r .= ";end_". a2h('zzzz');
$r .= ";description_some+test";
$r .= ";rank_90";
$r .= ";charset_3";
$r .= ";jobtype_1";
$r .= ";target_target/test.dat";
$r .= ";case_1";

$req =  Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );

print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = $data->add( $req );

print "# '$result'\n"
  unless is ($result !~ /436 Could not add item:/, 1, 'could not add');

$j = $data->get_job($count->{jobs}+3);
if ( is (ref($j), 'Dicop::Data::Job', 'job does exist') )
  {
  is ($j->get('target'), 'cafebabe', 'target was transformed');
  }
else
  {
  is (1,0, 'no job - no target');
  }

###############################################################################
# poke the jobtype and add an invalid script (thus giving error):
my $jt = $data->get_jobtype(1);
$jt->{script} = 'noscript';

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(),'', 'no error');

# and now add it
$result = ${ $data->add( $req ) };

print "# '$result'\n"
  unless is ($result =~ /436 Could not add item: script 'test-scripts\/noscript' not found, can't convert target file to hash./, 
	     1, 'proper error');

# does not exist
$j = $data->get_job($count->{jobs}+4);
is (ref($j), '', 'job does not exist');

###############################################################################
# add job with imagefile parameter

# prepare data
$r = 'cmd_add;type_job';
$r .= ";start_". a2h('abcd');
$r .= ";end_". a2h('zzzz');
$r .= ";description_some+test";
$r .= ";rank_90";
$r .= ";charset_3";
$r .= ";jobtype_1";
$r .= ";target_616263";
$r .= ";case_1";
$r .= ";imagefile_target/image/image.img";

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = $data->add( $req );

$j = $data->get_job($count->{jobs}+5);
print "# $result\n" unless
  is (ref($j), 'Dicop::Data::Job', 'ref ok');
is ($j->{imagefile}, 'target/image/image.img', 'proper target');
is ($j->{_modified}, 1, 'modified');

###############################################################################
###############################################################################
# mass-add clients

# prepare data
$r = 'cmd_add;type_client';
$r .= ";count_12";
$r .= ";description_some+clients";
$r .= ";name_client10";
$r .= ";ip_127.0.0.1";
$r .= ";mask_255.255.255.0";
$r .= ";group_1";
$r .= ";id_10";
$r .= ";pwd_1234";
$r .= ";pwdrepeat_1234";

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = $data->add( $req );

my $cnt = $data->clients();

is ($cnt, 12 + $count->{clients}, '# of clients');

for (my $i = 10; $i < 20; $i ++)
  {
  print "# at client: $i\n";
  my $client = $data->get_client($i);
  is (ref($client), 'Dicop::Data::Client', 'client ok');
  is ($client->{id}, $i, 'id');
  is ($client->{name}, "client" . $i, 'name');
  is ($client->{ip}, '127.0.0.' . ($i-9), 'ip');
  }

###############################################################################
# mass-add with non-numerical ID

$r = 'cmd_add;type_client';
$r .= ";count_5";
$r .= ";description_some+clients";
$r .= ";name_clientfoo10";
$r .= ";ip_127.0.0.1";
$r .= ";mask_255.255.255.0";
$r .= ";group_1";
$r .= ";id_foo10";
$r .= ";pwd_1234";
$r .= ";pwdrepeat_1234";

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = $data->add( $req );

$cnt = $data->clients();

is ($cnt, 12 + 5 + $count->{clients}, '5 more clients');

my $s = 1;
for (my $i = 'foo10'; $i ne 'foo15'; $i++)
  {
  print "# at client: $i\n";
  my $client = $data->get_client($i);
  is (ref($client), 'Dicop::Data::Client', 'client exist');
  is ($client->{id}, $i, 'id');
  is ($client->{name}, "client" . $i, 'name');
  is ($client->{ip}, "127.0.0.$s", 'ip'); $s++;
  }

###############################################################################
# mass-add with different ID

# prepare data
$r = 'cmd_add;type_client';
$r .= ";count_2";
$r .= ";description_some+clients";
$r .= ";name_client";
$r .= ";id_400";
$r .= ";ip_127.0.0.1";
$r .= ";mask_255.255.255.0";
$r .= ";group_1";
$r .= ";id_400";
$r .= ";pwd_1234";
$r .= ";pwdrepeat_1234";

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = $data->add( $req );

$cnt = $data->clients();

is ($cnt, 12 + 5 + 2 + $count->{clients}, 'two more');

$s = 1; my $id = 400; my $c = 'client';
for (my $i = '50'; $i ne '52'; $i++)
  {
  print "# at client: $i\n";
  my $client = $data->get_client($id);
  is (ref($client), 'Dicop::Data::Client', 'client ref');
  is ($client->{id}, $id, 'id');
  is ($client->{name}, $c++, 'name');
  is ($client->{ip}, "127.0.0.$s", 'ip');
  $s++; $id++;
  }

###############################################################################
# add a case

# prepare data
$r = 'cmd_add;type_case';
$r .= ";description_some+test";
$r .= ";referee_me";
$r .= ";name_1234";

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = ${ $data->add( $req ) };

like ($result, qr/case was added/, 'added');

# case 2 exists now
$j = $data->get_case($count->{cases}+1);
is (ref($j), 'Dicop::Data::Case', 'case does exist' );

###############################################################################
# add a case without returning template (returns ID instead)

# prepare data
$r = 'cmd_add;type_case';
$r .= ";description_some+test";
$r .= ";referee_me";
$r .= ";name_1234";

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = $data->add( $req, undef, undef, 'no_template' );

is ($result, 3, 'case added as case #3');

# case 3 exists now
$j = $data->get_case($count->{cases}+2);
is (ref($j), 'Dicop::Data::Case', 'case does exist' );

###############################################################################
# add a case fails when the name already exists

$result = 
  $data->_add_case ( 
   { name => 1234, description => 'some', referee => 'me', url => '' } 
  );

is ($result, 3, 'case not added');

###############################################################################
# add a case works when the name doesn't exist

$result = 
  $data->_add_case ( 
   { name => 12345, description => 'some', referee => 'me', url => '' } 
  );

is ($result, 4, 'case added as #4');

###############################################################################
# add job with a case at the same time

# prepare data
$r = 'cmd_add;type_job';
$r .= ";start_". a2h('abcd');
$r .= ";end_". a2h('zzzz');
$r .= ";description_some+test";
$r .= ";rank_90";
$r .= ";charset_3";
$r .= ";jobtype_1";
$r .= ";target_616263";
$r .= ";case_-1";
$r .= ";addcase-name_1234567";
$r .= ";addcase-description_new+case";
$r .= ";addcase-url_";
$r .= ";addcase-referee_me";

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = $data->add( $req );

$j = $data->get_job($count->{jobs}+6);
print "# $result\n" unless
  is (ref($j), 'Dicop::Data::Job', 'ref ok');
is (ref($j->{case}), 'Dicop::Data::Case', 'case');
is ($j->{case}->{id}, 5, 'case of job is 5');

###############################################################################
# empty fields will be filled in automatically

# prepare data
$r = 'cmd_add;type_job';
$r .= ";start_". a2h('abcd');
$r .= ";end_". a2h('zzzz');
$r .= ";description_some+test";
$r .= ";rank_90";
$r .= ";charset_3";
$r .= ";jobtype_1";
$r .= ";target_616263";
$r .= ";case_-1";
$r .= ";addcase-name_12345678";
$r .= ";addcase-description_new+case";
$r .= ";addcase-url_";
$r .= ";addcase-referee_";

$req = Dicop::Request->new ( id => 'req0001', data => $r, patterns => $data->{request_patterns} );
print "# '$r'\n" unless
 is ($req->error(), '', 'no error');

# and now add it
$result = $data->add( $req );

$j = $data->get_job($count->{jobs}+7);
print "# $result\n" unless
  is (ref($j), 'Dicop::Data::Job', 'ref ok');
is (ref($j->{case}), 'Dicop::Data::Case', 'case');
is ($j->{case}->{id}, 6, 'case of job is 6');
is ($j->{case}->{referee}, 'no value set', 'case referee is default');

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

