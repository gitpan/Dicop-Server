#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  plan tests => 37;
  chdir 't' if -d 't';
  }

use Dicop qw/
	  DONE ISSUED SOLVED TOBEDONE FAILED TIMEOUT
	  SUSPENDED UNKNOWN VERIFY BAD WAITING
	  MAX_ISSUED_AGE MAX_FAILED_AGE
	/;

# actual numbers do not matter, but check whether they exist
is (DONE,DONE);
is (ISSUED,ISSUED);
is (SOLVED,SOLVED);
is (TOBEDONE,TOBEDONE);
is (FAILED,FAILED);
is (SUSPENDED,SUSPENDED);
is (UNKNOWN,UNKNOWN);
is (TIMEOUT,TIMEOUT);
is (VERIFY,VERIFY);
is (BAD,BAD);
is (WAITING,WAITING);

is ($Dicop::BUILD >= 0, 1);
 
is (Dicop::status_code('foo'),-1);
is (Dicop::status(0),'unknown'); is (Dicop::status_code('UNKNOWN'),0);
is (Dicop::status(1),'issued'); is (Dicop::status_code('ISSUED'),1);
is (Dicop::status(2),'done'); is (Dicop::status_code('DONE'),2);
is (Dicop::status(3),'tobedone'); is (Dicop::status_code('TOBEDONE'),3);
is (Dicop::status(4),'solved'); is (Dicop::status_code('SOLVED'),4);
is (Dicop::status(5),'failed'); is (Dicop::status_code('FAILED'),5);
is (Dicop::status(6),'suspended'); is (Dicop::status_code('SUSPENDED'),6);
is (Dicop::status(7),'timeout'); is (Dicop::status_code('TIMEOUT'),7);
is (Dicop::status(8),'verify'); is (Dicop::status_code('VERIFY'),8);
is (Dicop::status(9),'bad'); is (Dicop::status_code('BAD'),9);
is (Dicop::status(10),'waiting'); is (Dicop::status_code('WAITING'),10);

is (Dicop->base_version() > 3, 1, 'base_version: ' . Dicop->base_version());
like (Dicop->base_version(), qr/^\d\.\d{6}\z/, 'base_ver looks good');

