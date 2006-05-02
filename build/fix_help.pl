#!/usr/bin/perl -w

# input: pod2html's output
# oputput: fixed up HTML source code

# does:
#  * remove empty paragraphs
#  * remove the ugly <hr>

# Example usage: pod2html doc/Client.pod | perl fix_help.pl > tpl/help/client.tpl

# slurp mode, no output buffer
$/ = undef; $| = 1;

use strict;

my $doc = '';
# read in input
while (<>) { $doc .= $_; }

# extract title
$doc =~ /title>((.|\n)*?)<\/\s*title>/;
my $title = $1 || 'no title';

$title =~ s/\s*([A-Z]+)\s+--?\s+//;		# 'NAME - foo' => 'foo'

my $topic = $title;
$title = ucfirst(lc($1));

# remove <header>
$doc =~ s/<!DOC(.|\n)*?<body.*//g;

# remove: <p><a name="__index__"></a></p>
$doc =~ s/<p><a name="__index__"><\/a><\/p>\n//;

# remove <hr>
$doc =~ s/<hr\s*\/?>//g;

# remove </pre><pre>
$doc =~ s/<\/pre>\n<pre>/\n/g;

## add \n after </p>
#$doc =~ s/<\/p>/<\/p>\n/g;

# add \n before <p>
$doc =~ s/<p>/\n<p>/g;

# remove multiple \n
$doc =~ s/\n\n\n+/\n/g;

# remove multiple \n
$doc =~ s/\n\n\n+/\n/g;

# <li></li>\n by <li>
$doc =~ s/<li><\/li>\n/<li>/g;

# replace all <hX> by <h(X-1)>
$doc =~ s/<(\/?)h([1-3])>/'<'. $1 . 'h' . ($2+1) . '>'/eg;

# insert title as headline
$doc =~ s/<!-- INDEX BEGIN -->/<h1><a class="h" href="##selfhelp_list##" title="Back to help overview">DiCoP<\/a> - $title<\/h1>\n\n<!-- topic: $topic -->\n\n<div class="text">\n\n<p>\n$topic\n<\/p>/;
$doc =~ s/<!-- INDEX END -->/<\/div>/;

# remove the NAME section:
#<h2><a name="name">NAME</a></h2>
#
#<p>GLOSSAR - This documentations contains often used acronyms or words along with a short and lightweight explanation.</p>

$doc =~ s/<h2><a name="name".*<\/h2>\n\n<p>.*\n\n//;

$doc =~ s/(Last update.*)/$1\n<\/div>/;

# add \n after </p>
$doc =~ s/<\/p>\n([^\n])/<\/p>\n\n$1/g;

# change </h2>..</h2> to </h2><div class="text">..</div><h2>
for (2..3)
  {
  $doc =~ s/(<\/h$_>)((.|\n)+?)(<h[234]>|$)/$a = ''; $a= "$1\n\n<div class=\"text\">$2<\/div>\n\n$4" unless $2 eq "\n\n\n"; $a/eg;
  }

# remove empty <div>
$doc =~ s/<div class="text">(\n+)<\/div>//g;

# remove empty paragraphs
$doc =~ s/<p>\n?<\/\s?p>//g;

# remove these because we add a header/footer later
$doc =~ s/<\/(body|html)>//g;

print $doc;
