#!/usr/bin/perl -w

#############################################################################
# Dicop -- check a dictionary file for being well-sorted and generate a
# checksum file for this dictionary
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2003
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

use strict;
use Digest::MD5;

my $dict = shift || '';

die ("Usage: gen_dict.pl dictionaryfile\n") if $dict eq '';

print "Opening dictionary, and check it for being well sorted...\n";
print "Please wait, this can take a moment...\n";

my $FH;
open ($FH, $dict) or die ("Cannot read $dict: $!");
my $last = undef;
my $n = 0;
while (my $line = <$FH>)
  {
  if ($line eq '')
    {
    die ("Error: Line $n is empty.\n");
    }
  if ($line =~ /0x0d/)
    {
    die ("Error: File contains 0x0d0x0a line endings. Convert first with dos2unix.");
    }
  if (defined $last && $last gt $line)
    {
    print
     "Error: Dictionary not properly sorted, line $n ".
     "greater than previous line\n" .
     die("Use 'sort -u' to sort dictionary file.\n");
    }
  if (defined $last && $line eq $last)
    {
    print
     "Error: Dictionary contains duplicated, line $n equals previous line\n";
    die("Use 'sort -u' to sort dictionary file.");
    }
  $last = $line; $n++;
  }
close $FH;

print "Dictionary $dict is properly sorted. Generating checksum file.\n";
my $check = $dict;
$check =~ s/\..*$//;		# remove extension
$check .= '.md5';

print "Making MD5 checksum...\n";
open $FH, $dict or die ("Cannot read $dict: $!");
my $md5 = Digest::MD5->new();
$md5->addfile($FH);
$md5 = $md5->hexdigest();

open $FH, ">$check" or die ("Cannot write $check: $!");
print $FH '# Dictionary checksum file generated ' . scalar localtime() . "\n";
print $FH "file = $dict\n";
print $FH "md5 = ",$md5,"\n";
close $FH;

# make dictionary read-only, to try to prevent later changes
# (the server will not load a changed dictionary)
chmod 0444, $dict;

print "Done.\n";


