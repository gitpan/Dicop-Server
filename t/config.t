#!/usr/bin/perl -w

# chekc Dicop::Server::Config

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 2;
  use_ok (qw/Dicop::Server::Config/);
  }

can_ok ('Dicop::Server::Config', qw/
  allowed_keys
  /);

1;
