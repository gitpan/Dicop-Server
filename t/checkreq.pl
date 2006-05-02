#/usr/bin/perl -w

# little helper utility to check a given Request against the patterns

use lib '../lib';
require "common.pl";

my $request = shift || 'cmd_help;type_security';

my $r = Dicop::Request->new( id => 'req0001', data => $request);

if ($r->error)
  {
  print $r->error(),"\n";
  }
else
  {
  print $r->as_request_string()," is valid\n";

  foreach my $k (qw/auth form request info/)
    {
    my $o = 'is_' . $k;
    print "Is $k: " . $r->$o() . " " if $r->$o;
    }
  print "\n";
  foreach my $k (qw/template type output title auth class/)
    {
    my $j = "$k:"; $j .= ' ' while length($j) < 12;
    print "$j ", $r->$k(),"\n";
    }
  }
  

