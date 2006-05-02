#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  unshift @INC, '../../lib';
  chdir 't' if -d 't';
  plan tests => 56;
  }

# dummy parent for charset
package Foo;

require "common.pl";

use Dicop::Data::Charset;
use Dicop::Data::Jobtype;
my $jobtype = new Dicop::Data::Jobtype ( id => 5 );

# while ocnstructing, also test that normal and hex sequences work

my $charset1 = new Dicop::Data::Charset ( set => '\x61 .. \x7a', id => 1 );
$charset1->_construct();
my $charset2 = new Dicop::Data::Charset ( set => "'A'..'Z'", id => 2 );
$charset2->_construct();
my $charset3 = new Dicop::Data::Charset ( set => '0x61 .. 0x7a', id => 1 );
$charset3->_construct();

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
  my ($self,$id) = @_;
  return $charset1 if $id == 1;
  $charset2;
  }

sub get_jobtype
  {
  $jobtype;
  }

sub get_job
  {
  Dicop::Data::Job->new( jobtype => $jobtype);
  }

package main;

use Dicop::Data::Charset;

###############################################################################
# simple charset

my $charset = new Dicop::Data::Charset ( set => "'a'..'f'" );
$charset->_construct();

is (ref($charset), 'Dicop::Data::Charset','ref');
is ($charset->check(),'','check');
is ($charset->get('id'),3,'id');		# 2 dummy charsets already created
my $cs = $charset->charset();
is (ref($cs),'Math::String::Charset','ref');

is (ref($charset->{_charset}),'Math::String::Charset','ref');
is ($charset->{set},'616263646566','set');
is ($charset->{type},'simple','type');
is ($cs->order(),1,'order');
is ($cs->length(),6,'lenght');

my $text;
$text  = "Dicop::Data::Charset {\n";
$text .= "  description = \"Digits (0-9)\"\n";
$text .= "  dirty = 0\n";
$text .= "  id = 2\n";
$text .= "  set = 30313233343536373839\n";
$text .= "  }\n";

$charset = Dicop::Item::from_string ( $text );
$charset->_construct();
is ($charset->get('id'),2,'id');
$cs = $charset->charset();
is (ref($cs),'Math::String::Charset','ref');

is (ref($charset->{_charset}),'Math::String::Charset','ref');
is ($charset->{set},'30313233343536373839','set');
is ($cs->order(),1,'order');
is ($cs->length(),10,'length');
is ($cs->char(0),'0','char(0)');
is ($cs->char(-1),'9','char(-1)');

###############################################################################
###############################################################################
# grouped charsets

$charset = new Dicop::Data::Charset ( 
 cpos0 => '0', cset0 => '1', 
 cpos1 => '-1', cset1 => '2',
 type => 'grouped',
 );
$charset->{_parent} = Foo->new();
$charset->_construct();

is (ref($charset), 'Dicop::Data::Charset','ref');
is ($charset->check(),'','check');

# check that all cposX and csetX were removed
foreach my $key ( keys %$charset)
  {
  print "# invalid leftover key '$key'\n" if !ok ($key !~ /^c(set|pos)/);
  }
is ($charset->{id}, 5, 'id');

is (ref($charset->{_charset}), 'Math::String::Charset::Grouped');
$cs = $charset->{_charset};

# check that the generated grouped set is really what we wanted 
# 0 => a-z, -1 => A-Z

is ($cs->first(),'','first');
is ($cs->first(1)||'','','first(1)');
is ($cs->first(2),'aA','first(2)');
is ($cs->first(3),'aaA','first(3)');

is ($charset->get('sets'),'-1,2,0,1');

###############################################################################

$charset = new Dicop::Data::Charset ( 
 cpos0 => '0', cset0 => '1', 
 cpos1 => '1', cset1 => '2',
 type => 'grouped',
 );
$charset->{_parent} = Foo->new();
$charset->_construct();

is (ref($charset), 'Dicop::Data::Charset', 'new seemed to work');
is ($charset->check(),'', 'check');

# check that all cposX and csetX were removed
foreach my $key ( keys %$charset)
  {
  print "# invalid leftover key '$key'\n" if !unlike ($key, qr/^c(set|pos)/, 'key');
  }
is ($charset->{id}, 6, 'id');

is (ref($charset->{_charset}), 'Math::String::Charset::Grouped', 'new seemed to work');
$cs = $charset->{_charset};

# check that the generated grouped set is really what we wanted 
# 0 => A-Z, -1 => a-z

is ($cs->first(),'', 'first');
is ($cs->first(1)||'','','first(1)');
is ($cs->first(2),'Aa','first(2)');
is ($cs->first(3),'Aaa','first(3)');

is ($charset->get('sets'),'0,1,1,2', 'sets');

is (Math::String->new('Aaa',$cs),'Aaa', 'can construct string');

###############################################################################
# check_strings

my $hash = { start => 'Aa', end => 'Aaa' };

$charset->check_strings( $hash, qw/start end/); 

is (ref($hash->{start}), 'Math::String', 'start');
is (ref($hash->{start}), 'Math::String', 'end');


