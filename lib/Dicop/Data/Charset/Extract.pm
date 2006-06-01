#############################################################################
# Dicop/Data/Charset/Extract.pm -- extract strings from a file
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Charset::Extract;
use vars qw($VERSION);
$VERSION = 0.01;	# Current version of this package
require  5.008001;	# requires this Perl version or later

use base qw(Dicop::Data::Charset Exporter);
use strict;

use Dicop::Base qw/h2a/;
use Math::BigInt lib => 'GMP';		# prefer GMP library
use Math::String::Charset;
use Math::String;
use File::Spec;

#############################################################################
# private, initialize self 

sub _init
  {
  my $self = shift;
  my $args = shift;

  $self->SUPER::_init($args,$self);

  $self->SUPER::_default( {
    description => "extract set",
    set => 0,
    minlen => 1,
    maxlen => 1,
    }, $self );
  $self->{type} = 'extract';
  
  # create a Math::String object. 'start' and 'end' are here literal numbers,
  # but the later code expects them to be Math::String objects. So we create
  # them as string '123' with set 0..9, meaning we can convert them back to
  # the same string without problems.
  $self->{_charset} = Math::String::Charset->new( ['0' .. '9'] );

  $self;
  }

sub _construct
  {
  my ($self,$args,$other) = @_;

  # find the ID for our simple set from our parent
  $self->{set} = $self->{_parent}->get_charset($self->{set})
    if $self->{_parent} && $self->{set} != 0;
 
  $self;
  }

sub image_file_name
  {
  # Set the image file and start/end from the image file size.
  my ($self, $file) = @_;
 
  $self->{file} = File::Spec->catfile('target','images',$file);
  if (!-e $self->{file} || !-f $self->{file})
    {
    # open my $FILE, $file;
    $self->{_error} = "Cannot open image file '$self->{file}': $!";
    warn ( "Cannot open image file '$self->{file}': $!");
    return;
    }

  # get file size of image
  my @stat = stat($self->{file});
  # ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
  #  $atime,$mtime,$ctime,$blksize,$blocks)
  $self->{image_file_size} = $stat[7];
 
  $self->{start} = Math::String->new('', $self->{_charset});
  $self->{end} = Math::String->from_number($stat[7], $self->{_charset});

  }

#############################################################################
# public stuff

sub extract_set
  {
  # return ref of the simple set used to extract characters
  my $self = shift;

  $self->{set};
  }

sub check_strings
  {
  # check that start/end are valid
  my ($self, $hash, @strings) = @_;

  # we only work for start and end

  # store previous start/end as our minlen, maxlen
  $self->{minlen} = abs(int( h2a($hash->{start}))) unless ref($hash->{start});
  $self->{maxlen} = abs(int( h2a($hash->{end}))) unless ref($hash->{end});
  
  # start/end of hash (job) to our start/end representing image_file size
  # this makes automatically the job size calculation correct
  # Will only work if $self->image_file() was called successfully
  $hash->{start} = $self->{start};
  $hash->{end} = $self->{end};

  undef;
  }

sub can_change
  {
  # return whether a field can be changed or not
  my $self = shift;
  my $field = shift || return 1;

  return 1 if (($field =~ /^(description)$/)
   && ($self->{dirty} != 0));
  0;
  }

sub get_as_string
  {
  # return an internal key-value as string representation suited for display
  my $self = shift;

  my $key = lc(shift || '');

  my $txt = $self->{$key};
  # fake key
  if ($key eq 'set')
    {
    $txt = "Extract charset: '$self->{set}'\n";
    }
  $txt;
  }

sub keys
  {
  # return the names of the keys used to display this object
  return (qw/set type id description/);
  }

sub check
  {
  # perform self-check
  my $self = shift;

  $self->{_error} || '';
  }

sub type { 'extract' }

sub put
  {
  # convert data item from string back to internal representation
  my $self = shift;
  my ($key,$val) = @_;

  if ($key eq 'type')
    {
    $self->{type} = 'extract' unless defined $self->{type};
    # XXX TODO: check for one of the valid types
    }
  $self->{$key} = $val;
  }

1;

__END__
#############################################################################

=pod

=head1 NAME

Dicop::Data::Charset::Extract - describes string extraction from a file

=head1 SYNOPSIS

    use Dicop::Data::Charset::Extract;

=head1 REQUIRES

perl5.008001, Exporter, Dicop::Base, Dicop::Item, Dicop, Dicop::Event, Math::BigInt

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

A dictionary charset has the following fields, most of them can be set
via C<new>.
The rest (shown with a *) is automatically initialized/overwritten/maintained:

=over 2

=item set

The simple charset used to describe which characters should be extracted.

=item description

A short description.

=item id *

The identification number.

=item dirty *

If set to 1, the charset is considered 'in use' and can no longer be changed.
(Actually, only the set, the description still can be changed)

This is to prevent changes to a charset that is currently used by a job, since
that would invalidate the job's keyspace.

=back

=head1 METHODS

=head2 check()

Perform an internal check and return '' for okay, otherwise an error message.

=head2 type()

Returns the type, in this case the string 'extract'.

=head2 charset()

Return the internal Math::String::Charset object.

=head2 extract_set()

Return the internal Math::String::Charset object, that is
describing the strings that should be extracted.

=head2 check_strings()

        $error = $self->check_strings ($hash, @keys);

Take a hash reference and a list of keys. For each of the keys in the hash,
check that it is an object of the underlying charset. If not, create an object
out of it.

To satisify external code, creates Math::String objects from the keys with
a charset containing '.'..'9'.

=head2 image_file_name()
  
Store the image file name, and set start/end from the image file size.

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

