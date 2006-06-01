######################################################################
# Dicop/Data/Jobtype.pm - a job type in the dicop system
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Jobtype;
use vars qw($VERSION);
$VERSION = 1.02;    # Current version of this package
require  5.005;     # requires this Perl version or later

use strict;
use Dicop;
use Dicop::Item;
use Dicop::Hash;

use base qw(Dicop::Item);

sub extra_files
  {
  # return 'files'-field as list of files
  my ($self, @client_archs) = @_;

  # "win32: foo, bar; linux: something.so, libfoo.so"

  my @archs = split /;/, $self->{files};
  my $file_names = {};

  for my $arch (sort {
    # We sort the arch depending on their number of '-'
    # Thus 'linux-i386-amd' comes first, then 'linux-i386', and last 'linux'

    my $am = $a; $am =~ /^\s*([\w+-]+)\s*:/; $am = $1; my $an = ($am =~ /-/) || 0;
    my $bm = $b; $bm =~ /^\s*([\w+-]+)\s*:/; $bm = $1; my $bn = ($bm =~ /-/) || 0;
    #print STDERR "$a <=> $b == $an <=> $bn\n";
    $bn <=> $an || $bm cmp $am;

    } @archs)
    {
    # For each arch 'linux-i386-amd' comes first, then 'linux-i386', and last
    # 'linux'. We check all the subarch-strings from the client (linux-i386,
    # linux etc) against these. As soon as one matches, we store the file.
    # Further files represent more general matches and are discared (client
    # 'linux-i386' only gets file from 'linux' if it wasn't already present
    # in 'linux-i386', and a generic 'linux' client would only get the
    # linux-variant ever.

    my $arch_stripped = $arch;
    $arch_stripped =~ s/^\s+//;		# spaces at front
    $arch_stripped =~ s/\s+$//;		# and end
    for my $client_arch (@client_archs)
      {
      if ($arch_stripped =~ /^\s*($client_arch|all)\s*:\s*(.*)/i)
        {
        my $a = $1;		# $architecture or all
        # found it:
        my @f = split /\s*,\s*/, $2 || '';
        foreach my $file (@f)
	  {
	  # generate things like "[ 'linux', 'this.file' ]" or "[ 'all', 'that.file' ]"
	  # if arch is something like 'linx-i386', split it to result in:
	  # [ 'linux', 'i386', $file ]
          # if a more specific file was already found, ignore the more generic version
          if (!defined $file_names->{$file})
	    {
            $file_names->{$file} = [ split(/-/, $a) , $file ];
	    }
          }
        }
      }
    }
  # enfore a certain sort order so the testsuite gets always the same result
  my @files = (); 
  foreach my $file (sort { 
      join ('-', @{$file_names->{$b}}) cmp 
      join ('-', @{$file_names->{$a}}); 
     } keys %$file_names)
    {
    push @files, $file_names->{$file};
    }
  @files;
  }

sub extra_fieldnames
  {
  # return extra field names as array
  my $self = shift;

  my $ef = $self->{extrafields};
  
  return @{$ef} if ref $ef eq 'ARRAY';

  (  split (/\s*,\s*/, $ef) );
  }

sub get_as_string
  {
  my $self = shift;
  my $key = lc(shift) || return;

  if ($key eq 'charset_description')
    {
    my $f = $key; $f =~ s/_.*$//;
    return $self->{$f}->{description} if ref $self->{$f};
    return 'unknown charset';
    }

  $self->SUPER::get_as_string($key);
  }

1;

__END__
#############################################################################

=pod

=head1 NAME

Dicop::Data::Jobtype - a job type in the dicop system

=head1 SYNOPSIS

    use Dicop::Data::Jobtype;

=head1 REQUIRES

perl5.005, Exporter, Dicop::Item, Dicop

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

For a description of fields a jobtype has, see C<doc/Objects.pod>.

=head1 METHODS

=head2 extra_fieldnames

	@fields = $jobtype->extra_fieldnames();

Returns the names of the extra fields nec. for jobs of this
type as an array.

=head2 extra_files

	@files = $jobtype->extra_files($architecture);

Return list of extra filenames necc. for this jobtype, the files
are relative to the worker dir, e.g. read C<linux/this.file>.

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

