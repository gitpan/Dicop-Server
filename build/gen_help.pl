#!/usr/bin/perl -w

# call fix_help.pl for all topics

use strict;

my $topics = {
  doc =>
   [ qw/
    config
    client
    dicop
    dicopd
    files
    glossary
    objects
    security
    server
    trouble
    worker
    / ],
  '.' =>
   [ qw/
   NEW
  / ] };

`cd ..` unless -d 'build' && -d 'lib';

my $text = '';
foreach my $dir (keys %$topics)
  {
  print "At $dir:\n";
  foreach my $topic (@{$topics->{$dir}})
    {
    print "Generating $dir/$topic...";
    my $pod = $dir . '/' . ucfirst($topic);
    $pod .= '.pod' unless -e $pod; 
    my $t = lc($topic);
      `pod2html $pod | perl build/fix_help.pl >tpl/help/$t.tpl`;

    # extract the title
    my $doc = read_file("tpl/help/$t.tpl");
    $doc =~ /<!-- topic: (.*?)-->/;
    my $title = $1 || $t;
    $title =~ s/\.\s+$//;		# remove trailing .

    $text .= 
     '<li><a href="##selfhelp_' . lc($topic) . '##">' . ucfirst($title) .  "</a>\n";

    print " done.\n";
    }
  }

print "Generating help topic include file...";
my $file = "tpl/helptopics.inc";

open FILE, ">$file" or die ("Cannot write $file: $!");
print FILE $text;
close FILE;

# clean off temp. files from pod2html
`rm *.x~~`;
unlink 'pod2htmd.tmp' if -f 'pod2htmd.tmp';
unlink 'pod2htmi.tmp' if -f 'pod2htmi.tmp';

print "All done.\n";

1;

sub read_file
  {
  my $file = shift;

  local $/ = undef,	# slurp mode
  open FILE, "$file" or die ("Cannot read $file: $!");
  my $doc = <FILE>;
  close FILE;
  $doc;
  }
