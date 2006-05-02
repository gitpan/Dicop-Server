#!/usr/bin/perl -w

# Test for Dicop::Data mail template check, e.g. that the templates are there
# at startup.
# check also that the templates are substituted properly

use Test;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 33;
  }

use Dicop qw/ISSUED TOBEDONE DONE VERIFY/;

require "common.pl";

use Dicop::Data;

Dicop::Event::handler( sub { } );	# zap error handler to be silent

$Dicop::Handler::NO_STDERR = 1;         # disable informative message

{
  no warnings;
  *Dicop::Data::flush = sub { };		# never flush the testdata
}

##############################################################################
# Construct a Data object using testdata and testconfig, this should fail

# remove any left-over charsets.def
unlink "test-worker/charsets.def" if -e "test-worker/charsets.def";
die ("Cannot unlink 'test-worker/charsets.def': $!")
  if -e "test-worker/charsets.def";

##############################################################################
# contruct data object, this should fail

my $data;
eval {
  $data = Dicop::Data->new( 
    cfg_dir => './test-config', 
    cfg => 'no_templates.cfg', _warn => 1 );
  };

ok_undef ($data);	# did not work out
print "# $@\n" unless ok (substr($@,0,26), 'Too many errors, aborting.');

##############################################################################
# contruct data object, this should work

eval {
  $data = Dicop::Data->new( 
    cfg_dir => './test-config', _warn => 1 
    );
  };

ok (ref($data), 'Dicop::Data');			# worked

my $job = $data->get_job(1);
my $chunk = $job->get_chunk(1);
my $client = $data->get_client(1);
my $result = $data->get_result(1);
$data->{peeraddress} = '127.0.0.1';

foreach my $type (qw/ result newjob offline bad_result verify_error closed /)
  {
  $data->_clear_email_queue();
  $data->email($type,undef, $job,$chunk,$client,$result);

  ok (scalar @{$data->{email_queue}}, 1);		# got added

  ok (ref($data->{email_queue}->[0]), 'HASH');		# as hash ref
  
  my $msg = $data->{email_queue}->[0]->{message};
  ok (ref($msg), '');					# body as scalar
  
  # remove inline URLs, because these are false positives 
  $msg =~ s/##selfstatus_(\w+)##//;

  print "# $msg\n" 
   unless ok ($msg =~ /##/, '');			# no left over templates
  my $ok = 0;
  foreach my $line ( split /\n/, $data->{email_queue}->[0]->{header} )
    {
    my $key = $line; $key =~ s/:\s.*//;			# remove anythig after :
    if ($line =~ /##/)					# left over template?
      {
      $ok ++;
      print "# Leftover in '$key:': '$line'\n";
      }
    }
  ok ($ok, 0);						# all headers ok?
  }

sub ok_undef
  {
  my $u = shift;
  ok (1,1), return if !defined $u;

  ok ($u,"undef");
  }

