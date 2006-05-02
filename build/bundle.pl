#!/usr/bin/perl -w

use strict;

use lib 'lib';
use lib '../lib';
use Dicop;

# bundle the client together
my $ver =  'Dicop-Client-' . $Dicop::VERSION;
$ver .= '_' . $Dicop::BUILD  if $Dicop::BUILD > 0;
  
my $VERSION = {
 	CLIENT => $ver,
  };

my $base_dir = '../Dicop-Base-' . $Dicop::VERSION;

# cdup unless we are already

`cd ..` unless -d 'build';

# clean
`rm -Rf bundle/` if -d 'bundle';

$| = 1;		# output buffer off
foreach my $bundle (keys %$VERSION)
  {
  my $file = "build/BUNDLE_$bundle";
  print "Working on $bundle...";
  my $ddir = 'bundle/';
  mkdir ($ddir);
  $ddir .= $VERSION->{$bundle};
  mkdir ($ddir);
  open FILE, "$file" or die "Can't read '$file': $!";
  while (my $src = <FILE>)
    {
    chomp $src;
    next if $src =~ /^#[^#]/;		# skip comment lines
    $src =~ s/\s.*$//;			# remove spaces after the filename
    my $dst = $src; 
    $src =~ s/##base##/$base_dir/;	# insert Dicop-Base dir
    $dst =~ s/##base##//;		# remove Dicop-Base dir

    my $dir = "$ddir/$dst"; $dir =~ s/\/[^\/]*$//;
    my @parts = split /\//,$dir;
    $dir = "";
    foreach my $p (@parts)
      {
      $dir .= "$p/"; mkdir ($dir) unless -d $dir;
      }
    `cp $src $ddir/$dst`;
    }
  close FILE;

  my $bundle_name = $VERSION->{$bundle};

  # add MANIFEST, sign, then package up
  chdir "bundle/";

  `cp ../build/MANIFEST $bundle_name/MANIFEST`;
  `cd $bundle_name/; cpansign --sign; cd ..`;

  `tar -cf $bundle_name.tar *`;
  `gzip -9 $bundle_name.tar`;
  `mv $bundle_name.tar.gz ..`;
  chdir '..';
  `rm -fR bundle`;
  print "done\n";
  }

