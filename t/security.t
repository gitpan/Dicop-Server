#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  plan tests => 299;
  chdir 't' if -d 't';
  }

use Dicop::Security qw/
  valid_net valid_ip
  hash_pwd
  ip_is_in_net
  ip_is_in_net_list
  /;
#use Dicop::Server::Security qw/ evaluate_request /;

# load messages and request patterns
require "common.pl";

###############################################################################
# ip and net checking/matching

ok (valid_net('1.2.3.4/32'),1);
ok (valid_net('1.2.3.0/24'),1);
ok (valid_net('1.2.0.0/16'),1);
ok (valid_net('1.0.0.0/8'),1);
ok (valid_net('1.2.3.4/0'),0); 	# only 0.0.0.0/0 is valid
ok (valid_net('0.0.0.0/0'),1);
ok (valid_net('1.2.3.4'),1);	# special case, IP is a (very restricted) net
ok (valid_net('1.2.3.4/'),0);
ok (valid_net('1.2.3.4/1'),0);

ok (valid_net('any'),1);
ok (valid_net('none'),1);

ok (valid_ip(undef),0);
ok (valid_ip('1.2.3.4'),1);
ok (valid_ip('256.2.3.4'),0);
ok (valid_ip('256.256.3.4'),0);
ok (valid_ip('256.256.356.456'),0);
ok (valid_ip('2.256.3.4'),0);
ok (valid_ip('1.2.256.3'),0);
ok (valid_ip('1.2.3.256'),0);
ok (valid_ip('1.2.0.4'),1);
ok (valid_ip('0.0.0.0'),1);
ok (valid_ip('255.255.255.255'),1);
ok (valid_ip('1.2.0.-4'),0);
ok (valid_ip('1.2.0'),0);

ok (valid_ip('none'),0);			# only as net, not as IP
ok (valid_ip('any'),0);				# only as net, not as IP

ok (ip_is_in_net('1.2.3.4','1.2.3.4'),1);	# valid net
ok (ip_is_in_net('1.2.3.4','1.2.3.4/'),-2);	# invalid net
ok (ip_is_in_net('-1.2.3.4','1.0.0.0/8'),-1);	# invalid ip
ok (ip_is_in_net('-1.2.3.4','1.2.3.4/7'),-1);	# both, invalid ip

ok (ip_is_in_net('1.2.3.4','1.2.3.4/32'),1);
ok (ip_is_in_net('1.2.3.4','1.2.3.0/24'),1);
ok (ip_is_in_net('1.2.3.4','1.2.0.0/16'),1);
ok (ip_is_in_net('1.2.3.4','1.0.0.0/8'),1);
ok (ip_is_in_net('1.2.3.4','0.0.0.0/0'),1);

my $r1 = rand(255)+1; my $r2 = rand(255)+1;
my $r3 = rand(255)+1; my $r4 = rand(255)+1;
for (my $i = 0; $i < 256; $i++)
  {
  my $ok = 0;
  $ok++ unless ip_is_in_net("$r1.$r2.$r3.$i","$r1.$r2.$r3.$i/32");
  $ok++ unless ip_is_in_net("$r1.$r2.$r3.$i",'$r1.$r2.$r3.0/24');
  for (my $j = 0; $j < 256; $j++)
    {
    $ok ++ unless ip_is_in_net("$r1.$r2.$j.$i",'$r1.$r2.0.0/16');
# takes too long:
#    for (my $k = 0; $k < 256; $k++)
#      {
#      $ok ++ unless ip_is_in_net("$r1.$k.$j.$i",'$r1.0.0.0/8');
#      }
    }
  ok ($ok,0);
  }

my $nets = [ '1.2.3.0/24', '2.3.4.5/32', '3.4.0.0/16', '4.0.0.0/16' ];

foreach my $ip ('1.2.3.4', '2.3.4.5', '3.4.1.2', '4.0.1.2')
  {
  my $rc = ip_is_in_net_list($ip,$nets);
  ok ($rc,1);
  }

foreach my $ip ( '2.3.4.6' )
  {
  my $rc = ip_is_in_net_list($ip,$nets);
  ok ($rc,0);
  }

###############################################################################
# hash_pwd and valid_user

ok (hash_pwd('Test'),'0cbc6611f5540bd0809a388dc95a615b');
ok (hash_pwd("OneRingMyPrecious\n"),'67bec90bb676ab497383be1759521b64');

my $req = Dicop::Request->new( id => 'req0001', 
 data => 'cmd_status;type_main' );
$req->error('some error');

my ($action,$pwd) = ($req->class(), $req->auth());
ok ($action, 'invalid');		# errornous requests => invalid

1;
