#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../../lib', '../lib';
  chdir 't' if -d 't';
  plan tests => 13;
  }

use Dicop::Event;
use Dicop::Data::Result;

require "common.pl";

my $result = new Dicop::Data::Result (
  type_description => 'tdescr',
  job_description => 'jdescr', 
  client_name => 'clientname',
  result_hex => '30313233',
  time => 12,
  );

is (ref($result),'Dicop::Data::Result');
is ($result->get_as_string('job_description'),'jdescr');
is ($result->get_as_string('type_description'),'tdescr');
is ($result->get('job'),0,'no job');
is ($result->get('type'),0, 'no type');
is ($result->get('client'),0, 'no client');
is ($result->get('client_name'),'clientname');

is ($result->get_as_string('result_ascii'),'0123', 'ascii 0123');
is ($result->get_as_hex('result_ascii'),'0123', 'ascii 0123');
is ($result->get_as_string('result_hex'),'30313233', 'hex 30313233');
is ($result->get_as_hex('result_hex'),'30313233', 'hex 30313233');

is ($result->get('time'),12);

#############################################################################
# 'time' is correct

$result = new Dicop::Data::Result (
  type_description => 'tdescr',
  job_description => 'jdescr', 
  client_name => 'clientname',
  result_hex => '30313233',
  );

is ($result->get('time'), Dicop::Base::time(), 'time equals current time');


