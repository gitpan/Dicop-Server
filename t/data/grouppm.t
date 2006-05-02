#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 6;
  }

require "common.pl";

use Dicop::Data::Group;

my $group = Dicop::Data::Group->new ( 
  name => 'test = a',
  description => '"blah"'
  );

# we did survive until here

is ($group->get('id'), 1, 'id is 1');
is ($group->{name}, 'test  a', 'name');
is ($group->{description}, 'blah', 'description');

$group = Dicop::Data::Group->new ( );

is ($group->get('id'), 2, 'id is 2');
isnt ($group->{name}, '', 'name is set to some default');
isnt ($group->{description}, '', 'description is set to some default');

