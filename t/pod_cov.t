#!/usr/bin/perl -w

# test POD coverage

use strict;
use Test::More;

BEGIN
   {
   chdir 't' if -d 't';
   use lib '../lib';
   eval "use Test::Pod::Coverage";
   plan skip_all => 'Test::Pod::Coverage not installed on this system' if $@;
   plan tests => 19;
   };

pod_coverage_ok(
  "Dicop",
  { also_private => [ qw/
    BAD
    DONE
    FAILED
    ISSUED
    MAX_FAILED_AGE
    MAX_ISSUED_AGE
    SOLVED
    SUSPENDED
    TIMEOUT
    TOBEDONE
    UNKNOWN
    VERIFY
    WAITING 
  /] },
  "Dicop, constants are private");

my $trust = { coverage_class => 'Pod::Coverage::CountParents' };

for my $p (qw(
  Dicop::Data
  Dicop::Client
  Dicop::Files
  Dicop::Server::Config
  Dicop::Data::Case
  Dicop::Data::Charset
  Dicop::Data::Charset::Dictionary
  Dicop::Data::Charset::Extract
  Dicop::Data::Chunk
  Dicop::Data::Chunk::Checklist
  Dicop::Data::Client
  Dicop::Data::Group
  Dicop::Data::Job
  Dicop::Data::Jobtype
  Dicop::Data::Proxy
  Dicop::Data::Result
  Dicop::Data::Testcase
  Dicop::Data::User
  ))
  {
  pod_coverage_ok( $p, $trust, "$p is covered");
  }

