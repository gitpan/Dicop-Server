#############################################################################
# Dicop/Data/Case.pm -- a container to group jobs in the Dicop system
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Case;
use vars qw($VERSION);
$VERSION = 0.02;	# Current version of this package
require  5.006;		# requires this Perl version or later

use base qw(Dicop::Item);
use strict;

sub get_as_hex
  {
  # convert data item from internal representation to hex string
  my ($self,$var) = @_;

  $self->get_as_string($var);
  }

sub get_as_string
  {
  # return a field of yourself as plain string
  # return "" for non-existing fields
  my $self = shift;
  my $key = lc(shift||"");

  # fake key "jobs": how many jobs do we have?
  if ($key eq 'jobs')
    {
    # get parent (bad, access to internal data structure)
    my $jobs = $self->{_parent}->{jobs};
    my $count = 0;
    my $id = $self->{id};
    foreach my $job (keys %$jobs)
      {
      $count++ if $jobs->{$job}->{case}->{id} eq $id;
      }
    return $count;
    }
  # automatically fill in empty URLs
  if ($key eq 'url' && $self->{url} eq '')
    {
    return $self->{_parent}->_format_string('case_url', $self);
    }
  $self->SUPER::get_as_string($key);
  }

1;

__END__
#############################################################################

=pod

=head1 NAME

# Dicop/Data/Case - a container to group jobs in the Dicop system

=head1 SYNOPSIS

	use Dicop::Data::Case;
	use Dicop::Data::Job;

	my $case = Dicop::Data::Case->new ( $case_options );
	my $job = Dicop::Data::Job->new ( $job_options );

=head1 REQUIRES

perl5.005, Exporter, Data::Item

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

Each job belongs to exactly one case. After loading the case number on the job
is converted to a reference to the case itself.

For a description of the fields a case has, see C<doc/Objects.pod>.

=head1 METHODS

=head2 get_as_string

Return a field of the object as an ASCII string suitable for HTML output:

        $object->get_as_string('foo');

=head2 get_as_hex

Return a field of the object as an hexified string, or as a fallback, as normal
string via get_as_string. The hexify happens only for certain special fields,
all other are returned as simple strings:

	$object->get_as_hex('foo');

=head2 get

Return the value of a specified field of the object:

	$object->get('foo');

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

