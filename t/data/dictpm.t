#!/usr/bin/perl -w

# test Dicop::Data::Charset::Dictionary

use Test;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  unshift @INC, '../../lib';
  chdir 't' if -d 't';
  plan tests => 52;
  }

use Dicop::Data::Charset::Dictionary;

require "common.pl";

#0 dicop
#1 dictionary
#2 naughty
#3 test
#4 withlongwords

###############################################################################
# dictionary charset

my $charset = Dicop::Data::Charset::Dictionary->new ( 
  file => 'testlist.lst',
  forward => 1, 
  lower => 1, 
  );
$charset->_construct();

ok (ref($charset), 'Dicop::Data::Charset::Dictionary');
ok ($charset->check(),'');
ok ($charset->get('id'),1);
ok ($charset->get('file'),'testlist.lst');
ok ($charset->get('stages'),1);
ok ($charset->get('mutations'),1);
ok ($charset->appends(),0);		# no append/prepend sets
my $cs = $charset->charset();
ok (ref($cs),'Math::String::Charset::Wordlist');

ok ($charset->get('type'),'dictionary');
ok ($cs->order(),1);
ok ($cs->length(),5);		# one stage * one mutation * 6 words

# offset into dictionary file
#ok ($charset->offset(1),0);
#ok ($cs->offset(0),0);
#ok ($charset->offset(2),5);
#ok ($cs->offset(1),5);

my $text;
$text  = "Dicop::Data::Charset::Dictionary {\n";
$text .= "  description = \"Test test\"\n";
$text .= "  dirty = 0\n";
$text .= "  id = 2\n";
$text .= "  file = testlist.lst\n";
$text .= "  stages = 2\n";
$text .= "  mutations = 1023\n";
$text .= "  type = dictionary\n";
$text .= "  }\n";

$charset = Dicop::Item::from_string ( $text );
$charset->_construct();
ok ($charset->get('id'),2);
ok ($charset->get('file'),'testlist.lst');
ok ($charset->get('stages'),2);
ok ($charset->get('mutations'),1023);
$cs = $charset->charset();
ok (ref($charset),'Dicop::Data::Charset::Dictionary');
ok (ref($cs),'Math::String::Charset::Wordlist');

ok (ref($charset->{_charset}),'Math::String::Charset::Wordlist');
ok ($cs->order(),1);
ok ($cs->length(),5);
ok ($cs->char(0),'dicop');
ok ($cs->char(-1),'withlongwords');

ok ($cs->first(1),'dicop');

##############################################################################
# test with scale

$charset = Dicop::Data::Charset::Dictionary->new ( 
  file => 'testlist.lst', 
  forward => 1, 
  upper => 1, 
  lower => 1, 
  );
$charset->_construct();

ok (ref($charset), 'Dicop::Data::Charset::Dictionary');
ok ($charset->check(),'');
ok ($charset->get('id'),3);
ok ($charset->get('file'),'testlist.lst');
ok ($charset->get('stages'),0x1);
ok ($charset->get('mutations'),0x3);
ok ($charset->get('scale'),2);
ok ($charset->appends(),0);		# no append/prepend sets
$cs = $charset->charset();
ok (ref($cs),'Math::String::Charset::Wordlist');

ok ($charset->get('type'),'dictionary');
ok ($cs->order(),1);
ok ($cs->length(),5);		# one stage * one mutation * 6 words

ok ($cs->char(0),'dicop');
ok ($cs->char(-1),'withlongwords');

ok ($cs->first(1),'dicop');

my $word = Math::String->new('',$cs)->first(1);
ok ($word, 'dicop');
ok ($word->as_number(),2);	# scale == 2, so, 0,2,4,6 etc

$word++;
ok ($word, 'dictionary');
ok ($word->as_number(),4);	# scale == 2, so, 0,2,4,6 etc

$word++;
ok ($word, 'naughty');
ok ($word->as_number(),6);	# scale == 2, so, 0,2,4,6 etc

$word = Math::String->from_number(2,$cs);
ok ($word, 'dicop');
ok ($word->as_number(),2);	# scale == 2, so, 0,2,4,6 etc

$word = Math::String->from_number(4,$cs);
ok ($word, 'dictionary');
ok ($word->as_number(),4);	# scale == 2, so, 0,2,4,6 etc

$word = Math::String->from_number(6,$cs);
ok ($word, 'naughty');
ok ($word->as_number(),6);	# scale == 2, so, 0,2,4,6 etc

my $start = Math::String->new('',$cs)->first(1);
my $end = Math::String->new('',$cs)->last(1);

ok ($end, 'withlongwords');
ok ($end->copy()->bsub($start)->binc()->as_number(), 10);

