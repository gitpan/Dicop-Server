#############################################################################
# Dicop/Data/Result.pm -- a result for a job
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Result;
use vars qw($VERSION);
$VERSION = 1.03;	# Current version of this package

use base Dicop::Item;
use strict;

use Dicop::Base qw/h2a/;

#############################################################################
# public stuff

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);

  # store the time the result was created, since _modified will not be stored
  $self->{time} = $self->{_modified} unless $self->{time};

  $self;  
  }

BEGIN
  {
  *get_as_hex = \&get_as_string;
  }

sub get_as_string
  {
  my ($self,$key) = @_;

  die ('Undefined key in get_as_string') if !defined $key;
  # fake key result_ascii
  return h2a($self->{result_hex}) if $key eq 'result_ascii';
  return localtime($self->{$key}) if $key eq 'time';
  $self->{$key};
  }

1;

__END__
#############################################################################

=pod

=head1 NAME

Dicop::Data::Result - a result for a job

=head1 SYNOPSIS

    use Dicop::Data::Result;

=head1 REQUIRES

perl5.005, Exporter, Dicop, Dicop::Item

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

For a description of fields a result has, see C<doc/Objects.pod>.

=head1 METHODS

=head2 get_as_string

Return a field of the object as an ASCII string suitable for HTML output:

	$result->get_as_string('client_name');

=head2 get_as_hex

Return a field of the object as an hexified string, or as a fallback, as normal
string via get_as_string. The hexify happens only for certain special fields,
all other are returned as simple strings:

	$result->get_as_hex('client_name');

=head2 get

Return the value of a specified field of the object:

	$result->geT('client_name');

=head2 change

Change a field's value after checking that the field can be changed (via
L<can_change>) and checking the new value. If the new value does not conform
to the expected format, it will be silently modifed (f.i. invalid characters
might be removed) and then the change will happen:

	$object->change('foo','bar');   # will change $object->{foo} to bar
					# if foo can be changed

=head2 can_change

Return true if the field's value can be changed.

	die ("Can not change field $field\n") if !$object->can_change($field);

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

