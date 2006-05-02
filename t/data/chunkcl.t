#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  unshift @INC, '../../lib';
  unshift @INC, '../lib';
  unshift @INC, 'data/';
  chdir 't' if -d 't';
  plan tests => 108 + 17;
  }

use vars qw/$class/;

$class = 'Dicop::Data::Chunk::Checklist';

require "chunk.inc";

