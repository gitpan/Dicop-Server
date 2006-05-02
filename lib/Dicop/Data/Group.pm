#############################################################################
# Dicop/Data/Group.pm - a group of clients
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Group;
use vars qw($VERSION);
$VERSION = 1.02;	# Current version of this package
require  5.005;		# requires this Perl version or later

use base qw(Exporter Dicop::Item);
use strict;

#############################################################################
# public stuff

sub _check_field
  {
  # check field value for valid
  my $self = shift;
  my $field = shift || "";
  my $val = shift || 0;
 
  #print "$self $field $val\n";
  if ($field eq 'name')
    {
    $val =~ s/[\"\'\`\=\n\t\r\b]//g;
    $val = substr($val,0,32) if length($val) > 32; 
    }
  if ($field eq 'description')
    {
    $val =~ s/[\"\'\`\=\n\t\r\b]//g;
    $val = substr($val,0,128) if length($val) > 128; 
    }
  return $val;
  }

1;

__END__
#############################################################################

=pod

=head1 NAME

Dicop::Data::Group - a group of clients

=head1 SYNOPSIS

    use Dicop::Data::Group;

=head1 REQUIRES

perl5.005, Exporter, Dicop::Item

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

For a description of fields a group has, see C<doc/Objects.pod>.

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

