#!/usr/bin/perl -w

# Test if Dicop::Data dies if no users are defined, the config is not found
# or certain critical config sections are not filled in

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 18;
  }

use Dicop qw/ISSUED/;
use Dicop::Data;

require "common.pl";

Dicop::Event::handler( sub { @_; } );	# zap error handler to be silent

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

my ($data,$rc);

my $test = "\$data = Dicop::Data->new( cfg_dir => './test-config', data_dir => './test-data2', _warn => 'not' );";
$rc = eval $test;

like ($@, qr/^No users found, please run  .\/adduser.pl  before first server startup/, 'adduser required');

$test = "\$data = Dicop::Data->new( cfg_dir => './test-config', data_dir => './test-data2', cfg => 'non-existing-file', _warn => 'not:' );";
$rc = eval $test;

like ($@, qr/^Global config file 'test-config\/non-existing-file' does not exist/, 'non-existing-file');

foreach my $w (qw/stats status work admin/)
  {
  $test = "\$data = Dicop::Data->new( cfg_dir => './test-config', ".
    "cfg => '$w'.'_allow.cfg', data_dir => './test-data', _warn => 'not:');";
  $rc = eval $test;
  like ($@, qr/^803 Key 'allow_$w' must not be empty\/undefined in 'test-config\/$w\_allow.cfg'/, "non empty allow_$w");

  $test = "\$data = Dicop::Data->new( cfg_dir => './test-config', ".
    "cfg => '$w'.'_deny.cfg', data_dir => './test-data', _warn => 'not:');";
  $rc = eval $test;
  like ($@, qr/^803 Key 'deny_$w' must not be empty\/undefined in 'test-config\/$w\_deny.cfg'/, "deny_$w");
  }
  
# test that net's are valid
foreach my $w (qw/stats status work admin/)
  {
  $test = "\$data = Dicop::Data->new( cfg_dir => './test-config2', ".
    "cfg => '$w'.'_allow.cfg', data_dir => './test-data', _warn => 'not:');";
  $rc = eval $test;
  like($@, qr/^802 Value '1.2.3' for key 'allow_$w' invalid in 'test-config2\/$w\_allow.cfg' at line/, "invalid_allow_$w");
  
  $test = "\$data = Dicop::Data->new( cfg_dir => './test-config2', ".
    "cfg => '$w'.'_deny.cfg', data_dir => './test-data', _warn => 'not:');";
  $rc = eval $test;
  like ($@, qr/^802 Value '1.2.3' for key 'deny_$w' invalid in 'test-config2\/$w\_deny.cfg' at line/, "invalid_deny_$w");
  }


# EOF

1;

END
  {
  # clean up
  unlink 'dicop_request_lock' if -e 'dicop_request_lock';
  unlink 'dicop_lockfile' if -e 'dicop_lockfile';
  unlink 'test-worker/charsets.def' if -e 'test-worker/charsets.def';
  }  

