#!/usr/bin/perl -w

# test POD for correctness

use strict;
use Test::More;

BEGIN
   {
   chdir 't' if -d 't';
   use lib '../lib';
   eval "use Test::Pod";
   # SKIP all and exit if Test::Pod unusable
   plan skip_all => 'Test::Pod not installed on this system' if $@;
   plan tests => 34;
   };

for my $file (qw(
  Dicop.pm
  Dicop/Data.pm
  Dicop/Client.pm
  Dicop/Files.pm
  Dicop/Server/Config.pm
  Dicop/Data/Case.pm
  Dicop/Data/Charset.pm
  Dicop/Data/Charset/Dictionary.pm
  Dicop/Data/Charset/Extract.pm
  Dicop/Data/Chunk.pm
  Dicop/Data/Chunk/Checklist.pm
  Dicop/Data/Client.pm
  Dicop/Data/Group.pm
  Dicop/Data/Job.pm
  Dicop/Data/Jobtype.pm
  Dicop/Data/Proxy.pm
  Dicop/Data/Result.pm
  Dicop/Data/Testcase.pm
  Dicop/Data/User.pm
  ../BUGS
  ../CHANGES
  ../CHANGES-2.20
  ../CHANGES-2.22
  ../CHANGES-2.23
  ../CHANGES-3.00
  ../INSTALL
  ../NEW
  ../README
  ../README.client
  ../README.darwin
  ../README.linux
  ../README.win32
  ../TODO
  ../UPGRADE
  ))
  {
  pod_file_ok('../lib/' . $file);
  }
