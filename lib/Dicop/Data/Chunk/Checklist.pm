#############################################################################
# Dicop/Data/Chunk/Checklist.pm -- a chunk of a job in the jobs checklist
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Chunk::Checklist;
use vars qw($VERSION);
$VERSION = 1.01;	# Current version of this package
require  5.005;		# requires this Perl version or later

use base qw(Exporter Dicop::Data::Chunk);
use strict;

use Digest::MD5 qw(md5_hex);
use Dicop qw(DONE SOLVED ISSUED TOBEDONE FAILED MAX_ISSUED_AGE MAX_FAILED_AGE
             VERIFY BAD
            );
use Math::String;
use Dicop::Data::Job;
use Dicop::Event qw/crumble/;
use Dicop::Base qw/a2h h2a/;

#############################################################################
# public stuff

sub shrink
  {
  # take $self and a result between start and end and shrink the chunk around
  # the result to 1/Nth of the size. Also takes care to round the new borders
  # up and down, respectively, so that the new chunk size is always smaller or
  # equal to the old one. Also takes care of "fixed chars" at the two new
  # borders.

  my ($self,$result,$factor,$border) = @_;

  if ($factor <= 1)
    {
    return "Shrink factor must be greater than 1";
    }
  if ($border < 0)
    {
    return "Count of fixed chars must be greater than or equal to 0";
    }

  my $factor_limit = $factor * 2;
  $factor_limit = Math::BigInt->new($factor_limit) unless ref $factor_limit;
  $factor_limit = Math::String->from_number($factor_limit,
    $self->{start}->charset());
  $factor = Math::BigInt->new($factor) unless ref $factor;
  $factor = Math::String->from_number($factor, $self->{start}->charset());

  if ($result < $self->{start} || $result > $self->{end})
    {
    return "Result is not between start and end";
    }
  if ($self->{end} - $self->{start} < $factor_limit)
    {
    # no shrink necessary, chunk not big enough
    return $self;
    }

  my $lower = $result - $self->{start}; 
  my $upper = $self->{end} - $result;
  my ($lower_border,$upper_border);

  my $recalc = 0;			# no shrunk, no need to recalc size

  if ($lower > $factor_limit)
    {
    # lower part of chunk is big enough to be shrunk
    $lower /= $factor;
    $lower_border = $result - $lower;
    $lower_border = $self->border($border,$lower_border,0) if $border > 0;

    if ($lower_border > $self->{start})
      {
      $self->{start} = $lower_border;
      $recalc = 1;
      }
    }
  if ($upper > $factor_limit)
    {
    # upper part of chunk is big enough to be shrunk
    $upper /= $factor;
    $upper_border = $result + $upper;
    $upper_border = $self->border($border,$upper_border,1) if $border > 0;

    if ($upper_border < $self->{end})
      {
      $self->{end} = $upper_border;
      $recalc = 1;
      }
    }
  
  if ($recalc != 0)
    {
    $self->_adjust_size();
    # assume chunk to shrink was cloned from chunk with verifiers, so clear
    $self->clear_verifiers();	
    $self->_checksum(1);
    }
  $self;
  }

1;

__END__

#############################################################################

=pod

=head1 NAME

Dicop::Data::Chunk::Checklist - a chunk in the checklist of a L<Job|Dicop::Data::Job> in the L<Dicop|Dicop::Dicop> system. 

=head1 SYNOPSIS

	use Dicop::Data::Chunk::Checklist;
	use Dicop qw(TOBEDONE);

	$chunk = Dicop::Data::Chunk::Checklist->new (
			start => 'aaa', end => 'zzz',
			job => $job, status => TOBEDONE, ); 

=head1 REQUIRES

perl5.005, Exporter, Dicop, Dicop::Event, Dicop::Data, Math::BigInt, Math::String, Digest::MD5

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

This is a subclass of Dicop::Data::Chunk and used to store in the checklist
of a job. These chunks are mostly like all other chunks, but are marked as
belonging to the checklist by their classname.

In addition, they also have some additional methods that are only
necessary for chunks in the checklist, namely L<shrink()>.

=head1 METHODS

In addition to the normal methods of Dicop::Data::Chunk, the following methods
are overwritten or new:
 
=head2 B<shrink>

	$self->shrink($result,$factor,$fixed);

Takes the chunk and a result between C<start> and C<end> and shrinks the chunk
around the result to 1/$factor of the original size. Also takes care to round
the new borders up and down, respectively, so that the new chunk size is
always smaller or equal to the old one. Also takes care of "fixed chars" at
the two new borders.

Example for C<$factor == 10>:

	original start	<--|
			   | 9/20
	new start       <--|		<---|
			   | 1/20	    | new size:
	result		<--|		    | 2/20 == 1/10
			   | 1/20    	    |
	new end		<--|		<---|
			   | 9/20
	original end	<--|

Return error string on error, otherwise C<$self>.

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut
