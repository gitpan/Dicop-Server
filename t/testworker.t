#!/usr/bin/perl -w

# test that the password generator generates the right sequences of passwords

use Test;
use strict;
my ($worker,$dir);
my $printout = 0;		# 1 for debug

BEGIN
  {
  chdir 't' if -d 't';
  plan tests => 307;
  $worker = 'test';
  $dir = 'worker/';
  }

chdir $dir;
my (@args,$code,@a,$rc,$v);
while (<DATA>)
  {
  chomp();
  next if /^#/;
  @args = split /,/, $_;
  @a = splice @args,0,7;
  print "# $a[0] $a[1] $a[2] $a[3] $a[4]\n";
  $rc = `./$worker $a[0] $a[1] $a[2] $a[3] $a[4] 2`;
  print "$rc" if $printout != 0;
  $rc =~ s/\nAt '(.+)'/$v = shift @args; $v = 'no more output' if !defined $v; ok($1,$v); '';/eg;
  $rc =~ /Last tested password in hex was '(.*)'/;
  $code = $1 || '';
  ok ("Last pwd '$code'","Last pwd '$a[5]'");
  $rc =~ /Stopcode is '(.*)'/;
  $code = $1; $code = '' if !defined $code;	# keep a '0'
  ok ("Stop code '$code'","Stop code '$a[6]'");
  while (scalar @args > 0)
    {
    ok ('nothing',shift @args);
    }
  }

# test timeout
$rc = `./$worker 61 4141414141 414141414141414141 5 2`;
$rc =~ /Stopcode is '(.*)'/;
ok ("Stop code '$1'","Stop code '2'");

1; # EOF

# format is:
# start,end,target,set,timeout,expected_lastpwd,expected_stopcode,expected_pwds
__DATA__
303030,303030,30303030,2,0,303030,0,303030
4161,4261,416161,33,0,4261,0,4161,4162,4163,4164,4165,4166,4167,4168,4169,416a,416b,416c,416d,416e,416f,4170,4171,4172,4173,4174,4175,4176,4177,4178,4179,417a,4261
61,4141,414141,5,0,4141,0,61,62,63,64,65,66,67,68,69,6a,6b,6c,6d,6e,6f,70,71,72,73,74,75,76,77,78,79,7a,4141
30,3033,303030,2,0,3033,0,30,31,32,33,34,35,36,37,38,39,3030,3031,3032,3033
30,3030,303030,2,0,3030,0,30,31,32,33,34,35,36,37,38,39,3030
30,3031,303030,2,0,3031,0,30,31,32,33,34,35,36,37,38,39,3030,3031
3032,3038,303030,2,0,3038,0,3032,3033,3034,3035,3036,3037,3038
30303030,30303130,30303034,2,0,30303034,1,30303030,30303031,30303032,30303033,30303034
30,3032,30303030,6,0,3032,0,30,31,32,33,34,35,36,37,38,39,41,42,43,44,45,46,47,48,49,4a,4b,4c,4d,4e,4f,50,51,52,53,54,55,56,57,58,59,5a,61,62,63,64,65,66,67,68,69,6a,6b,6c,6d,6e,6f,70,71,72,73,74,75,76,77,78,79,7a,3030,3031,3032
0000000000,0000000021,1000000005,14,0,0000000021,0,0000000000,0000000001,0000000002,0000000003,0000000004,0000000005,0000000006,0000000007,0000000008,0000000009,000000000a,000000000b,000000000c,000000000d,000000000e,000000000f,0000000010,0000000011,0000000012,0000000013,0000000014,0000000015,0000000016,0000000017,0000000018,0000000019,000000001a,000000001b,000000001c,000000001d,000000001e,000000001f,0000000020,0000000021
0000000000,0000000002,0000000001,14,0,0000000001,1,0000000000,0000000001
417a61,426161,41616161,33,0,426161,0,417a61,417a62,417a63,417a64,417a65,417a66,417a67,417a68,417a69,417a6a,417a6b,417a6c,417a6d,417a6e,417a6f,417a70,417a71,417a72,417a73,417a74,417a75,417a76,417a77,417a78,417a79,417a7a,426161
5a6a,416163,5a6a6a6a,33,0,416163,0,5a6a,5a6b,5a6c,5a6d,5a6e,5a6f,5a70,5a71,5a72,5a73,5a74,5a75,5a76,5a77,5a78,5a79,5a7a,416161,416162,416163,
5a30,416235,5a616130,34,0,416235,0,5a30,5a31,5a32,5a33,5a34,5a35,5a36,5a37,5a38,5a39,416130,416131,416132,416133,416134,416135,416136,416137,416138,416139,416230,416231,416232,416233,416234,416235
