#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  unshift @INC, '../../lib';
  chdir 't' if -d 't';
  plan tests => 27;
  }

# # dummy parent for jobtype
# not needed yet
#package Foo;
#
#use Dicop::Data::Charset;
##use Dicop::Data::Jobtype;
#my $jobtype = new Dicop::Data::Jobtype ();
##
#my $charset = new Dicop::Data::Charset ( set => "'a'..'z'" );
#
#sub new
#  {
#  my $self = {};
#
#  bless $self;
#  }
#
#sub modified
#  {
#  }
#
#sub get_charset
#  {
#  return $charset;
#  }
#
#sub get_jobtype
#  {
#  return $jobtype;
#  }

package main;
              
use Dicop::Data::Jobtype;

require "common.pl";

my $jobtype = Dicop::Data::Jobtype->new ( script => 'script', name => 'test' );

is (ref($jobtype),"Dicop::Data::Jobtype", 'new seemed to work');

is ($jobtype->get('name'),'test', 'name');
is ($jobtype->get('script'),'script', 'script');
is ($jobtype->get('fixed'),0, 'fixed');
is ($jobtype->get('minlen'),1, 'minlen');
is ($jobtype->get('extrafields'), '', 'no extra fields');
is (join(":",$jobtype->extra_fieldnames()), '', 'no extra fields');
is (scalar $jobtype->extra_fieldnames(), 0, 'no extra fields');

###############################################################################
# change and can change

$jobtype = Dicop::Data::Jobtype->new ( { description => 'test',
			speed => 123,
			name => 'tname',
			script => 'somescript',
			fixed => 3,
			minlen => 9,
			extrafields => 'username,userhaircolor',
 } );
is ($jobtype->{description},'test', 'description');
is ($jobtype->{speed},123, 'speed');
is ($jobtype->{script},'somescript', 'script');
is ($jobtype->{fixed},3,'fixed');
is ($jobtype->{name},'tname','name');
is ($jobtype->{minlen},'9','minlen');
is ($jobtype->{files},'','files');
is ($jobtype->get('extrafields'), 'username,userhaircolor', 'two extra fields');
is (join(":",$jobtype->extra_fieldnames()), 'username:userhaircolor', 'two extra fields');

###############################################################################
# extra_files()

is (join(";", $jobtype->extra_files('win32')), '', 'no extra files');

$jobtype->{files} = 'win32:Some.dll, foo.dll, this.dat; linux:foobar.so, libsome.so';

is (join_files($jobtype->extra_files('win32')), 'win32=this.dat;win32=foo.dll;win32=Some.dll', 'win32 extra files');
is (join_files($jobtype->extra_files('os2')), '', 'no os2 extra files');
is (join_files($jobtype->extra_files('linux')), 'linux=libsome.so;linux=foobar.so', 'linux extra files');

$jobtype->{files} = 'all: more.dll; win32:Some.dll, foo.dll, this.dat; linux:foobar.so, libsome.so';

is (join_files($jobtype->extra_files('win32')), 'win32=this.dat;win32=foo.dll;win32=Some.dll;all=more.dll', 'win32 extra files');
is (join_files($jobtype->extra_files('os2')), 'all=more.dll', 'one os2 extra file');
is (join_files($jobtype->extra_files('linux')), 'linux=libsome.so;linux=foobar.so;all=more.dll', 'linux extra files');

# subarchs:

$jobtype->{files} = 'all: more.dll; win32:Some.dll, foo.dll, this.dat; linux:foobar.so, libsome.so; linux-i386: extrafile, foobar.so';

is (join_files($jobtype->extra_files('linux')), 'linux=libsome.so;linux=foobar.so;all=more.dll', 'linux extra files');

# files in linux-i386 take precedence, and the 'linux' version of "foobar.so" is thus dropped
is (join_files($jobtype->extra_files('linux-i386','linux')), 'linux=libsome.so;linux-i386=foobar.so;linux-i386=extrafile;all=more.dll', 'linux-i386 extra files');

# subarchs, with whitespace:

$jobtype->{files} = 'all: more.dll; win32 : Some.dll, foo.dll, this.dat; linux : foobar.so, libsome.so;  linux-i386 : extrafile, foobar.so ';
# files in linux-i386 take precedence, and the 'linux' version of "foobar.so" is thus dropped
is (join_files($jobtype->extra_files('linux-i386','linux')), 'linux=libsome.so;linux-i386=foobar.so;linux-i386=extrafile;all=more.dll', 'linux-i386 extra files');

sub join_files
  {
  my @files = @_;

  my $res = '';
  foreach my $f (@files)
    {
    my $file = pop @$f;
    $res .= join ('-', @$f) . "=$file;";
    }
  $res =~ s/;$//;
  $res;
  }

