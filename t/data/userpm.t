#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 5;
  }

require "common.pl";

use Dicop::Data::User;

my $user = new Dicop::Data::User ( 
  name => 'test = a',
  pwdhash => '0123456789abcdefABCDEF',
  description => 'Oh no!',
  salt => 'salted',
  );

# we did survive until here

is ($user->get('id'), 1, 'id');
is ($user->{name}, 'test  a', 'name');
is ($user->{pwdhash}, '0123456789abcdefABCDEF', 'pwdhash');
is ($user->{description}, 'Oh no!', 'description');
is ($user->{salt}, 'salted', 'salt');

