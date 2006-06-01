#############################################################################
# Dicop/Data/Proxy.pm -- a proxy (special client) in the distributed system
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Proxy;
use vars qw($VERSION);
$VERSION = 1.01;	# Current version of this package
require  5.005;		# requires this Perl version or later

use base qw(Dicop::Data::Client);
use strict;

use Dicop qw( MAX_FAILED_AGE MAX_ISSUED_AGE FAILED );
use Dicop::Base;

sub is_proxy () { 1; }

#############################################################################
# private, initialize self 

sub _init
  {
  my $self = shift;
  my $args = shift;
  
  Dicop::Item::_init($self,$args,$self);
  $self->{done_chunks} = Math::BigInt->bzero();
  $self->{done_keys} = Math::BigInt->bzero();
  $self->{lost_chunks} = Math::BigInt->bzero();
  $self->{lost_keys} = Math::BigInt->bzero();
  $self->{failed_chunks} = Math::BigInt->bzero();
  $self->{uptime} = Math::BigInt->bzero();
  $self->{last_connect} = 0;			# currently offline
  $self->{last_chunk} = 0;			# never
  $self->{send_terminate} = 0;			# currently offline
  $self->{connects} = '';                       # list of times between two c.

  $self;
  }

sub rate_limit
  {
  my $self = shift;

  # rate-limit proxy to no more than one connect per 2 seconds

  return ((@{$self->{connects}} > (Dicop::Data::Client::_MAX_CONNECTS()-2)) && ($self->{chunk_time} < 2));
  } 

#############################################################################
# public stuff

sub report
  {
  # one of our client's reported work back, so check it in 
  my ($self,$job,$chunk,$took,$last_chunk) = @_;

  $self->{last_chunk} = $last_chunk || Dicop::Base::time();
  if ($chunk->status() == FAILED)
    {
    $self->{failed_chunks} ++;
    }
  else
    {
    $self->{done_keys} += $chunk->size();
    $self->{done_chunks} ++;
    }
  $self->{uptime} += $took;
  $self->modified(1);
  $self;
  }

sub lost_chunk
  {
  # one of our client's failed to deliver a chunk, so update our stats
  my ($self,$job,$chunk) = @_;

  $self->{lost_keys} += $chunk->size();
  $self->{lost_chunks} ++;
  $self->modified(1);
  $self;
  }
  
1;

__END__
#############################################################################

=pod

=head1 NAME

Dicop::Data::Proxy - a proxy in the L<Dicop|Dicop::Dicop> system.

=head1 SYNOPSIS

    use Dicop::Data::Proxy;

=head1 REQUIRES

perl5.005, Exporter, Dicop::Server, Dicop::Data::Client, Dicop::Data

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

For a description of fields a proxy has, see C<doc/Objects.pod>.

=head1 METHODS

=head2 report

One of our clients want to report back a work result, so update our stats.

=head2 connected

Proxy connected, so update his stats.

=head2 lost_chunk

One of our clients lost a chunk, so update our stats.

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

=head2 rate_limit

        return if $self->rate_limit();

Returns true if the client's rate limit was reached, meaning no more connects
are allowed at the current time.

=head2 is_proxy

	if ($client->is_proxy())
		{
		}

Returns true if the client is a proxy, or false for normal clients.

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

