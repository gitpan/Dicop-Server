#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  unshift @INC, '../../lib';
  chdir 't' if -d 't';
  plan tests => 3;
  use_ok ('Dicop::Data::Case');
  }

my $case = new Dicop::Data::Case ( id => 7, name => 'testcase', description => 'some description', url => 'none' );

is (ref($case), 'Dicop::Data::Case', 'new seemed to work');
is ($case->{id}, 7, 'id 7');

##############################################################################
# all tests done

1;

