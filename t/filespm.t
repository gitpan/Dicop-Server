#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 19;
  }

require "common.pl";

use Dicop::Data;

package main;

use Dicop::Base;
Dicop::Event::handler( sub { } );	# zap error handler to be silent

$Dicop::Handler::NO_STDERR = 1;		# disable informative messages

{
  no warnings;
  *Dicop::Data::flush = sub { };	# never flush the testdata
}

my $data = Dicop::Data->new( cfg_dir => './test-config', _warn => 1 );

is ($data->check(),undef, 'new worked'); # construct was okay

#############################################################################
# _inline_file()

my ($type,$res,$file) = $data->_inline_file( 111, "my test\n", "test.txt", 'req0001', '');

is ($type, 111, 'type 111');
is ($res, "req0001 111 65b4fff2c0dc0be7a63257a125fc74a2 \"$file\" \"my+test%0a\"\n", 'inlined file');
is ($file, "test.txt");

#############################################################################
# same file name, but different contents

($type,$res,$file) = $data->_inline_file( 111, "my test 2\n", "test.txt", 'req0001', '');

is ($type, 111, 'type 111');
is ($res, "req0001 111 0a434d01fd0c92019ff24e5d9e78c984 \"$file\" \"my+test+2%0a\"\n", 'inlined file');
is ($file, "test.txt");

#############################################################################
# different file name, and different contents

($type,$res,$file) = $data->_inline_file( 111, "my test 3\n", "test1.txt", 'req0001', '');

is ($type, 111, 'type 111');
is ($res, "req0001 111 6cd1b7cdf25004ede36b65c275d75912 \"$file\" \"my+test+3%0a\"\n", 'inlined file');
is ($file, "test1.txt");

#############################################################################

($type,$res,$file) = $data->_inline_file( 111, "my test\n", "test.txt", 'req0001', 'req0000 100 "foo" "1234"'."\n");

is ($type, 111, 'type 111');
is ($res, "req0001 111 65b4fff2c0dc0be7a63257a125fc74a2 \"$file\" \"my+test%0a\"\nreq0000 100 \"foo\" \"1234\"\n", 'inlined file');
is ($file, "test.txt");


#############################################################################
# _create_file()

for my $tt (101,102)
  {
  ($type,$res,$file) = $data->_create_file( $tt, "my test\n", "test.txt", 'req0001', '');

  my $t = $tt + 10;
  is ($type, $t, "type $t");
  is ($res, "req0001 $t 65b4fff2c0dc0be7a63257a125fc74a2 \"$file\" \"my+test%0a\"\n", 'inlined file');
  is ($file, "test.txt");
  }


