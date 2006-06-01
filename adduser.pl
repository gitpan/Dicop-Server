#!/usr/bin/perl -w

# (c) Bundesamt fuer Sicherheit in der Informationstechnik 2002-2006. This
# file is part of the DiCoP package and falls under the same licence.

# script to add a user to data/users.lst
use strict;
use Digest::MD5;

print "DiCoP adduser v1.04 (c) by BSI 2002-2006\n\n";

use lib 'lib';
use Dicop::Base qw/read_file random a2h/;
use Dicop::Config;

my $cfg_file = shift || 'config/server.cfg';

print "Reading config $cfg_file file to find out your settings...";

my $cfg = Dicop::Config->new($cfg_file);
if (!ref($cfg) eq 'Dicop::Config')
  {
  die ("Couldn't read config file $cfg_file: $!\n Maybe you forgot to run ./setup?");
  }
print "ok.\n";

my ($file,$name,$pwd) = @ARGV;
$file = $cfg->get('users_lst') || 'data/users.lst';

print "Your administrator accounts should be stored in: '$file'\n";

if (-f $file)
  {
  my $users = read_file($file);
  die ("Can't read $file: $!") if !ref $users;
  die ("The file $file is not empty, it seems there already some users"
    ." defined\n"
    ."Use the webinterface to add new users\n") if $$users !~ /^[\n\s]*$/;
  }

print "\nEnter admin name [A-Z,a-z,0-9-_]: ";
$name = <STDIN>; chomp($name); $name = $name || '';
die ("User name must not be empty") if $name eq '';
die ("User name should contain only A-Z, a-z, 0-9 and _-")
  if $name !~ /^[A-Za-z0-9_-]/;

print "\n The password MUST contain upper- and lowercase, and be longer than 7 characters:\n";
print "\nEnter password [A-Za-z0-0.:!()<>@ -]: ";
$pwd = <STDIN>; chomp($pwd); $pwd = $pwd || '';
die ("Error: Password must be longer than 7 characters") if length($pwd) < 8;
die ("Error: Password contains illegal characters")
  if $pwd !~ /[A-Za-z0-9.:!()<>@ -]/;
die ("Erorr: Password must contain upper and lower case letters")
  if ($pwd !~ /[A-Z]/ || $pwd !~ /[a-z]/);

my $salt = a2h(random(256));
# if we ever get less
while (length($salt) < 32)
  {
  $salt .= int(rand(65537));
  }

my $md5 = Digest::MD5->new(); $md5->add("$salt$pwd\n");

open FILE, 
 ">$file" or die "Cannot append to $file: $!";
print FILE "Dicop::Data::User {\n";
print FILE "  id = 1\n";
print FILE "  name = \"$name\"\n";
print FILE "  salt = \"$salt\"\n";
print FILE '  pwdhash = "' .  $md5->hexdigest() . "\"\n";
print FILE "  }\n";
close FILE;

print "\nDone.\n";

print "Do not forget to chown and chmod $file to the group/user of dicopd!\n";
