#!/usr/bin/perl -w

=pod

=head1 NAME

TEST - Test worker for DiCoP, due to simplicity in Perl

=head1 DESCRIPTION

A simple testworker that 'walks' password rooms. This is a proof-of-concept
and also used to verify the C version. For speed reasons, real workers are
written in C, usually by using the Dicop-Workerframe library.

Modified version that prints passwords for testing in testsuite.

=head1 VERSIONS

	2.00 original rewritten in Perl
	2.01 input check relaxed (no more fixed characters at end)
	2.02 made timeout optional
	2.03 display chunksize (for debugging and checking)
	     test for end chunk > start chunk
	     less intrusive error messages
	2.04 te: adjusted (c), speling errors fixed
	     output compatible with server v2.16
	     due to improved Math::BigInt and Math::String now 3 times faster
	2.10 te: read charsets from charsets.def
	2.11 end >= start, not end > start
	     took over tests from workerframe and fixed buglets to let 'em pass	
	     trace == 2: print passwords
	2.12 support for dictionary character sets
	2.13 JDF reading from "SET" and not "../../target/SET"
	     load dictionary only if requested
	2.14 handle "test.pl cdf.txt [timeout] [trace] style"

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2004
See L<http://www.bsi.de/> for more information.

=cut

$| = 1;			# buffer off
use strict;
use lib '../../lib';	# we are inside ./worker/arch, so step up
use lib 'lib';		# but if started from client we are somewhere different

use Math::String;
use Math::String::Charset;

use Dicop::Base qw/h2a a2h/;

my @reason = (
 "Last password checked",
 "Found solution",
 "Timeout",
);

print "DiCoP Test worker 2.14 (pure-Perl) ";
print "(C) by BSI 1998-2004. All Rights Reserved.\n\n";

# get commandline parameters
my ($start,$end,$target,$set,$timeout) = @ARGV;

my $trace;
if (@ARGV == 1 or @ARGV == 2)
  {
  ($set,$timeout) = @ARGV;
  $trace = 0;
  }
else
  {
  if ((@ARGV < 4) || (@ARGV > 6))
    {
    print "Parameter format: start end target set [timeout] [trace]\n";
    print "or:               cdf.txt [timeout]\n";
    die ("Wrong parameter format");
    }
  $trace = $ARGV[5] || 0;
  }

# read in the charsets
my $sets = read_charsets('charsets.def');

my $prefix = '';
if (-f $set)
  {
  my $args = read_target($set);
  $prefix = $args->{password_prefix}; $prefix = '' unless defined $prefix;
  $prefix = h2a($prefix) if $prefix ne '';
  $start = $args->{start};
  $end = $args->{end};
  $target = $args->{target};
  $set = $args->{charset_id};
  if ($args->{dictionary_file})
    {
    require Math::String::Charset::Wordlist;
    $sets->{$set} =  Math::String::Charset::Wordlist->new(
      { file => '../../target/dictionaries/' . $args->{dictionary_file} } );
    }
  print "Done loading.\n";
  }
my $cs = $sets->{$set};
die ("$set is not a valid charset") unless defined $cs;

my $s = Math::String->new(h2a($start),$cs);
die ("'$start' is not a valid password for set $set") if $s->is_nan();
my $e = Math::String->new(h2a($end),$cs);
die ("'$end' is not a valid password for set $set") if $e->is_nan();
my $t = Math::String->new(h2a($target),$cs);
die ("'$target' is not a valid password for set $set") if $t->is_nan();

die "end ('$e') must be greater or equal than start ('$s')" unless $e >= $s;

$timeout = 0 if !defined $timeout || $timeout < 0;
$timeout = 24*3600 if $timeout > 24*3600;

my $starttime = time;				# now
my $took;

my $size = $e-$s; $size = $size->as_number();
print "Going from '$s' to '$e' (size $size) looking for '$t'\n";
print scalar localtime, " Start (timeout in $timeout seconds)\n\n";

my $pwd = $s->copy(); my $cnt = 0;
$t = "$t";					# convert to normal string
my $found = -1;					# found nothing
while ($found < 0)
  {
  if ($trace > 1)
    {
    print "At '",a2h($prefix . $pwd),"'\n";
    # only in trace mode, otherwise overshot
    $found = 0, last if $pwd >= $e;
    }
  # found target password	
  $found = 1, last if $t eq "$prefix$pwd";
  $pwd++; $cnt ++;
  $found = 0, last if $pwd >= $e;
  if ($cnt > 2000)				# not so often
    {
    $cnt = 0;
    $took = time - $starttime;
    $found = 2 if $timeout > 0 && $took > $timeout;
    if (($trace) && ($found < 0))
      {
      # prediction
      my $done = $pwd - $s; 
      my $ps = $done->as_number()->bdiv( $took||0 );
      print "\r ",$ps," pwds/s => ";
      $done = ($e-$pwd)->as_number()/$ps;
      print "will take $done more seconds (after $took seconds at '$pwd')  ";
      }
    }
  }
$took = time-$starttime;
my $result = a2h($prefix . $pwd);

print "Last tested password in hex was '$result'\n";
print "Stopcode is '$found'\n";

print "Reason: $reason[$found]\n";
my $pwds = $pwd-$s; $pwds = $pwds->as_number()/$took;
print "Took $took seconds ($pwds pwds per seconds)\n\n";
print "\n",scalar localtime, " Done.\n";

###############################################################################
# read the charsets from a file

sub read_charsets
  {
  my ($file) = @_;

  my $sets = {};
  $file = "../$file" unless -f $file;			# try one up (unport.)
  open FILE, $file or die "Cannot read $file: $!\n";
  my @set = [];
  while (my $line = <FILE>)
    {
    chomp($line);
    next if $line =~ /^[^01]/;		# ignore all lines except set def's
    $line =~ s/^([01]):([0-9]+)://;	# remove type and id
    my $id = $2;
    if ($1 eq '0')
      {
      # simple set
      @set = map ( h2a($_), split(/:/, $line));			# 41:42 => a,b
      $sets->{$id} =  Math::String::Charset->new( \@set );
      }
    elsif ($1 eq '1')
      {
      # grouped set
      @set = split(/:/, $line);			# 1=2:3=2
      my $cs = {};
      foreach (@set)
        {
        my ($i,$s) = split(/=/, $_);		# 1=2
        die ("Simple set $s not defined, but used in grouped set $id")
         if !defined $sets->{$s};
        $cs->{$i} = $sets->{$s};
        }
      $sets->{$id} =  Math::String::Charset->new( { sets => $cs } );
      }
    # do nothing for dictionary sets
    }
  close FILE;
  print "Loaded ",scalar keys %$sets, " charsets.\n";
  $sets;
  }

###############################################################################
# read the job target description file
  
sub read_target
  {
  my ($file) = @_;

  my $sets = {};
  $file = "../$file" unless -f $file;			# try one up (unport.)
  open FILE, $file or die "Cannot read $file: $!\n";
  my $args = {};
  while (my $line = <FILE>)
    {
    chomp($line);
    next if $line =~ /^#/;		# ignore comments
    next if $line !~ /=/;		# huh?
    $line =~ /^([a-zA-Z0-9_-]+)\s*=\s*\"?([a-zA-Z0-9_\.\/\\]*)\"?$/; # split
    $sets->{$1} = $2 || '';
    } 
  close FILE;
  print "Loaded ",scalar keys %$sets, " fields from '$file'.\n";
  $sets;
  }


