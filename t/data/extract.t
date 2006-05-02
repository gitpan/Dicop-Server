#!/usr/bin/perl -w

# test Dicop::Data::Charset::Extract

use Test;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  unshift @INC, '../../lib';
  chdir 't' if -d 't';
  plan tests => 9;
  }

use Dicop::Data::Charset::Extract;

require "common.pl";

###############################################################################
# extract charset

my $charset = Dicop::Data::Charset::Extract->new ( 
  description => 'test extract',
  set => 1, 
  );
$charset->_construct();

ok (ref($charset), 'Dicop::Data::Charset::Extract');
ok ($charset->check(),'');
ok ($charset->get('id'),1);
ok ($charset->get('set'),'1');
my $cs = $charset->charset();
ok (ref($cs),'Math::String::Charset');

ok ($charset->get('type'),'extract');
#ok ($cs->order(),1);
#ok ($cs->length(),5);		# one stage * one mutation * 6 words

my $text;
$text  = "Dicop::Data::Charset::Extract {\n";
$text .= "  description = \"test extract\"\n";
$text .= "  dirty = 0\n";
$text .= "  id = 2\n";
$text .= "  type = extract\n";
$text .= "  }\n";

$charset = Dicop::Item::from_string ( $text );
$charset->_construct();
ok ($charset->get('id'),2);
$cs = $charset->charset();
ok (ref($charset),'Dicop::Data::Charset::Extract');
ok (ref($cs),'Math::String::Charset');

