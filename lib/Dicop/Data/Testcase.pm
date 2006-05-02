#############################################################################
# Dicop/Data/Testcase.pm -- a test job
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Testcase;
use vars qw($VERSION);
$VERSION = '1.02';	# Current version of this package

use strict;
use base qw/Dicop::Item/;

use Dicop::Base qw/a2h h2a/;
use Dicop::Data::Job;
use Math::String;

#############################################################################
# private, initialize self 

sub _construct
  {
  my $self = shift;

  $self->SUPER::_construct();

  # flag charset to be in use
  $self->{charset}->dirty();

  my $cs = $self->{charset}; 
  $self->_from_string_form($cs, qw/start end result/);

  return $self if $self->{_error};

  $self->{end} = $self->{start} if
    !$self->{start}->is_nan() && !$self->{end}->is_nan() &&
    $self->{end} < $self->{start};

  my $val = $self->{target};
  if (-f $val && -e $val && $val !~ /\.tgt$/)
    {
    Dicop::Data::Job::_convert_target($self,'test');
    }
  $self;
  }

#############################################################################
# public stuff

sub _check_field
  {
  # check field value for valid
  my $self = shift;
  my $field = shift || "";
  my $val = shift; $val = 0 unless defined $val;

  $self->SUPER::_check_field($field,$val);

  if ($field =~ /^(target)$/)
    {
    # target is in hex, or a path to a .tgt file
    if (!-f $val && !-e $val && $val !~ /\.tgt$/)
      {
      $val =~ s/[^a-fA-F0-9]//g;
      $val = substr($val,0,256) if length($val) > 256;
      }
    }
  $val;
  }

sub check
  {
  # check yourself
  my $self = shift;

  return $self->{_error} if $self->{_error};	# already had an error?
  
  $self->_construct();

  return $self->{_error} if $self->{_error};	# error on construct?

  return "Field 'charset' is not a valid charset id" unless ref($self->{charset});
  return "Field 'jobtype' is not a valid jobtype id" unless ref($self->{jobtype});

  foreach my $key (qw/start end result/)
    {
    return "Field '$key' is not a valid Math::String"
     unless ref($self->{$key}) =~ /^Math::String/;
    }

  return $self->{_error} if $self->{_error};

  my $cs = $self->{charset}->charset(); 
  my $csid = $self->{charset}->{id};

  my $fixed = $self->{jobtype}->{fixed}; 
  my $fixedstr = ''; $fixedstr = $cs->char(0) x $fixed if $fixed != 0;

  foreach my $k (qw/start end result/)
    {
    # no result? so don't check it
    next if $k eq 'result' && $self->{result} eq '';

    return 
     "Field '$k' is not a valid Math::String with set id '$csid'"
     if $self->{$k}->is_nan();

    next if $fixed == 0 || $k eq 'result';
    # check end/start for fixed chars
    return "Field '$k' shorter than ".($fixed+1)." chars"
     if (length("$self->{$k}") < $fixed+1);
    return "Field '$k' ends not in '$fixedstr'"
     if ((substr("$self->{$k}",-$fixed,$fixed) ne $fixedstr));
    }

  my $res = $self->{result};
  if ($self->{prefix})
    {
    # remove fixed prefix and try between start/end
    $res .= ''; 
    my $pre = h2a($self->{prefix});
    $res =~ s/^$pre//;
    $res = Math::String->new($res,$cs);
    }
   
  return "'result' must be between 'start' and 'end'"
   if (!$res->is_nan()) && ($res ne "") && (($res < $self->{start}) || ($res > $self->{end}));

  0;
  }

sub get_as_hex
  {
  my $self = shift;

  my $key = lc(shift || '');

  return a2h($self->{$key}->bstr()) if $key =~ /^(start|end|result)$/;
  $self->{$key};
  }

sub get_as_string
  {
  my $self = shift;
  my $key = lc(shift) || return;

  return a2h($self->{$key}->bstr())
   if $key =~ /^(start|end|result)$/;

  my $f = $key; $f =~ s/_.*$//;
  return $self->{$f}->{description}
   if $key =~ /^(jobtype|charset)_description$/;

  return $self->{$1}->length()
   if $key =~ /^(start|end)len$/;
 
  # fake key 'extras'
  if ($key eq 'extras')
    {
    # get the names of the extra fields from our jobtype
    return '' unless ref $self->{jobtype}->{extrafields} eq 'ARRAY';
    my @extras = @{$self->{jobtype}->{extrafields}};
    my $txt = ''; my $i = 0;
    foreach my $extra (@extras)
      {
      my $p = $self->{"extra$i"}; $p = '<b>not set!</b>' unless defined $p;
      $txt .= "$extra => \"$p\", ";
      $i++;
      }
    $txt =~ s/, $//;	# remove last ','
    return $txt;
    }

  $self->SUPER::get_as_string($key);

  }

BEGIN
  {
  # reuse the routines from a Job.pm

  *extra_fields = \&Dicop::Data::Job::extra_fields;
  *extra_params = \&Dicop::Data::Job::extra_params;
  }

sub extra_files
  {
  my ($self,$arch) = @_;

  return;
  }

1;

__END__
#############################################################################

=pod

=head1 NAME

Dicop::Data::Testcase - a test case for a job

=head1 SYNOPSIS

    use Dicop::Data::Testcase;

=head1 REQUIRES

perl5.005, Dicop, Dicop::Item, Dicop::Base, Math::String

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

For a description of fields a testcase has, see C<doc/Objects.pod>.

=head1 METHODS

=head2 get_as_string

Return a field of the object as an ASCII string suitable for HTML output:

        $object->get_as_string('client_name');

=head2 get_as_hex

Return a field of the object as an hexified string, or as a fallback, as normal
string via get_as_string. The hexify happens only for certain special fields,
all other are returned as simple strings:

        $object->get_as_hex('client_name');

=head2 get

Return the value of a specified field of the object:
        
	$object->get('foo');

=head2 extra_fields

        $txt = $job->extra_fields();

If the jobtype for that job mandates extra fields, will return a text listing.

See C<Dicop::Data::Job>.

This routine is used to include them into the chunk description file.

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

