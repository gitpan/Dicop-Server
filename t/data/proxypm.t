#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../../lib', '../lib';
  chdir 't' if -d 't';
  plan tests => 16;
  }

# dummy parent for chunk
package Foo;

require "common.pl";

use Dicop::Data::Charset;
use Dicop::Data::Jobtype;
use Dicop::Data::Job;
use Dicop::Data::Result;
use Dicop::Data::Case;
my $jobtype = new Dicop::Data::Jobtype ( fixed => 3);
my $case = new Dicop::Data::Case ( id => 1);

my $charset = new Dicop::Data::Charset ( set => "'a'..'z'" );
my $result = new Dicop::Data::Result ( result_hex => '303132' );
$charset->_construct();

sub new
  {
  my $self = {};

  bless $self;
  }

sub modified
  {
  }

sub get_charset
  {
  return $charset;
  }

sub charset
  {
  return $charset;
  }

sub get_jobtype
  {
  return $jobtype;
  }

sub get_result
  {
  return $result;
  }

sub get_case
  {
  return $case;
  }

package main;

use Dicop::Event;
use Dicop::Data::Proxy;

# setup dummy objects
my $job = new Dicop::Data::Job ( start => 'aaa', end => 'zaaa',
  description => 'desc', owner => 'test', charset => 1,
  ascii => 1,
  );
$job->{_parent} = new Foo;
$job->_construct();

my $cs = $job->{charset}->charset();

my $chunk = new Dicop::Data::Chunk (
  job => $job, start => $job->{start},
   end => $job->{end}, id => 2,
  );
$chunk->{_parent} = $job;
$chunk->_construct();

$chunk->_checksum();

###############################################################################
# actual tests

my $proxy = new Dicop::Data::Proxy (
  name => 'proxy1'
  );
is ($proxy->is_proxy(),1, 'is_proxy');
is ($proxy->{last_chunk},0, 'never');
is ($proxy->{lost_keys},0,'none');
is ($proxy->{lost_chunks},0,'no lost chunks');
is ($proxy->{done_keys},0,'no done keys');
is ($proxy->{done_chunks},0,'no done chunks');
is ($proxy->{uptime},0,'no uptime yet');

is (ref($proxy),'Dicop::Data::Proxy');
is ($proxy->get_as_string('name'),'proxy1');
is ($proxy->get('name'),'proxy1');

###############################################################################
# lost chunk

$proxy->lost_chunk( $job, $chunk );
is ($proxy->{lost_keys}, $chunk->size(), 'size');
is ($proxy->{lost_chunks}, 1, 'one lost chunk');

###############################################################################
# report

$proxy->report( $job, $chunk, 1234 );
is ($proxy->{done_keys}, $chunk->size());
is ($proxy->{done_chunks}, 1, 'one done chunk');
is ($proxy->{uptime}, 1234, '1234 uptime');
is ($proxy->{last_chunk}, Dicop::Base::time(), 'time');

