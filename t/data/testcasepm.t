#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  unshift @INC, '../../lib';	# for running manually
  chdir 't' if -d 't';
  plan tests => 28;
  }

# dummy parent for testcase
package Foo;

require "common.pl";

use Dicop::Data::Charset;
use Dicop::Data::Jobtype;
my $jobtype = Dicop::Data::Jobtype->new( fixed => 3 );

my $charset = Dicop::Data::Charset->new ( set => "'a'..'z'" );
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

sub get_jobtype
  {
  return $jobtype;
  }

sub get_object
  {
  my ($self,$req) = @_;
  
  my $method = 'get_' . $req->{type};
  $self->$method($req->{id});
  }

package main;

use Dicop::Data::Testcase;
use Dicop::Data::Job;

my $tc = new Dicop::Data::Testcase ( 
  start => '65656565',
  end => '6565656565',
  jobtype => 1,
  charset => 1,
  description => 'test case #1',
  target => 'abcdefg0123456789',
  );
$tc->{_parent} = Foo->new();
$tc->_construct();

# we did survive until here

is ($tc->get('id'), 1, 'id');
is ($tc->get('end'), '6565656565,2376275', 'end');
is ($tc->get('start'), '65656565,91395', 'start');
is ($tc->get_as_hex('start'), '65656565', 'start as hex');
is ($tc->get_as_hex('end'), '6565656565', 'end as hex');
is (ref($tc->{charset}), 'Dicop::Data::Charset', 'charset ref');
is ($tc->{charset}->error(), '', 'no error in charset construction');

is ($tc->get('disabled'), '', 'enabled by default');

is ($tc->get_as_string('startlen'), 4, 'startlen');
is ($tc->get_as_string('endlen'), 5, 'endlen');

is ($tc->put('disabled','on'), 'on', 'disabled now');
is ($tc->put('disabled', 0), 0, 'enabled again');

is ($tc->extra_fields(), '', 'no extra fields');
is ($tc->extra_params(), '', 'no extra params');

is (ref($tc->{jobtype}),'Dicop::Data::Jobtype', 'jobtype ref');
is ($tc->{description}, 'test case #1', 'description');
is ($tc->{target}, 'abcdef0123456789','target filtered');

is ( $tc->{prefix},'', 'prefix');
is ( $tc->get('prefix'),'', 'prefix'); 

$tc->{end} = '65616161';
$tc->{_error} = '';
is ($tc->check(),"Field 'start' ends not in 'aaa'", 'check start');
$tc->{start} = '61616161';
$tc->{end} = 'aaba';
$tc->{_error} = '';
is ($tc->check(),"end ('aaba') is not a valid Math::String for set 1", 'check end');

$tc->{start} = '616161';
$tc->{end} = '61616161';
$tc->{_error} = '';
is ($tc->check(),"Field 'start' shorter than 4 chars", 'check start len');

$tc->{start} = '61616162';
$tc->{end} = '61616161';
$tc->{_error} = '';
is ($tc->check(),"Field 'start' ends not in 'aaa'", 'check start ending');
$tc->{start} = '61616161';
$tc->{end} = '61616261';
$tc->{_error} = '';
is ($tc->check(),"Field 'end' ends not in 'aaa'", 'check end ending');

###############################################################################
# target files ending in .tgt

$tc = new Dicop::Data::Testcase ( 
  start => '65656565', end => '6565656565', jobtype => 1, charset => 1,
  description => 'test case #1',
  target => 'target/test.tgt',
  );
$tc->{_parent} = Foo->new();
$tc->_construct();
is ($tc->{target}, 'target/test.tgt', 'target filename');

###############################################################################
# target files NOT ending in .tgt but existing

$tc = new Dicop::Data::Testcase ( 
  start => '65656565', end => '6565656565', jobtype => 1, charset => 1,
  description => 'test case #1',
  target => 'data/testcasepm.t',
  );
$tc->{_parent} = Foo->new();
$tc->_construct();
is ($tc->{target}, 'data/testcasepm.t', 'target filename');

###############################################################################
# start/end are len/first/last

$tc = new Dicop::Data::Testcase ( 
  start => 'len:1',
  end => 'first:5',
  jobtype => 1,
  charset => 1,
  description => 'test case #1',
  target => 'abcdefg0123456789',
  );
$tc->{_parent} = Foo->new();
$tc->_construct();

is ($tc->get_as_string('start'), '61', 'start');
is ($tc->get_as_string('end'), '6161616161', 'end');

