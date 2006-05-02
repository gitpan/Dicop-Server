#############################################################################
# Dicop/Data/Charset.pm - represents a character set
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Charset;
use vars qw($VERSION);
$VERSION = 1.02;	# Current version of this package
require  5.005;		# requires this Perl version or later

use base qw(Exporter Dicop::Item);
use strict;

use Dicop::Base qw/h2a/;
use Math::String::Charset;
use Math::String;

#############################################################################
# private, initialize self 

sub _init
  {
  my ($self,$args) = @_;

  $self->SUPER::_init($args,$self);

  $self->{type} = 'grouped' if exists $self->{cpos0};	# came via webform
  # a fake key, that might be accidentily set from old data
  delete $self->{set} if $self->{type} eq 'grouped';
  $self;
  }

sub type
  {
  my $self = shift;
  $self->{type};
  }

sub _construct
  {
  my ($self,$args) = @_;
 
  if ($self->{type} eq 'grouped')
    {
    my $sets = $self->{sets};
    # convert a list of keys like 'cpos0', 'cpos1' etc to a hash containing
    # cposx => csetx,
    foreach my $key (keys %$self)
      { 
      # cpos0 => -1, cset0 => 2
      next if $key !~ /^cpos[0-9]{1,2}$/;
      my $i = $key; $i =~ s/^cpos//;		# index, leave only number
      my $pos = $self->{$key} || 0;
      next if $pos == 0 && $i != 0;		# only c(set|pos)0 == default
      $sets->{$pos} = $self->{"cset$i"} || 1;	# default set 1
      }
    foreach my $key (keys %$self)
      {
      next if $key !~ /^c(set|pos)[0-9]+$/;
      delete $self->{$key};
      }
    $self->{sets} = $sets;
    }

  if (ref($self->{_charset}) !~ /^Math::String::Charset/)
    {
    if ($self->{type} eq 'simple')
      {
      # check that the charset does not contain double characters
      my @chars = split //, h2a ( $self->{set} );
      # insert into hash
      my %ch; foreach my $c (@chars) { $ch{$c} = 1; }
      if (scalar @chars != scalar keys %ch)
        {
        $self->{_error} = "Simple charset is not unique, contains some characters twice.";
        return;
        }
      $self->{_charset} = 
        Math::String::Charset->new ( split //, h2a( $self->{set}) );
      }
    else
      # grouped charset
      {
      my $hash = {};
      foreach my $key (keys %{$self->{sets}})
        {
        $self->{sets}->{$key} =
         $self->{_parent}->get_charset ( $self->{sets}->{$key} );
        # construct a hash containing only pos => Math::String::Charset
        $hash->{$key} = $self->{sets}->{$key}->{_charset};
        }
      $self->{_charset} = 
        Math::String::Charset::Grouped->new ( { sets => $hash } );
      }
    }
  }

#############################################################################
# public stuff

sub check_strings
  {
  # check that start and end are valid strings
  my ($me, $hash, @strings) = @_;

  my $cs = $me->{_charset};
  Dicop::Item::_from_string_form($hash, $cs, @strings);

  return $hash->{_error} || '';
 
  }

sub can_change
  {
  # return whether a field can be changed or not
  my $self = shift;
  my $field = shift || return 1;

  return 1 if (($field =~ /^(set)$/) && ($self->{dirty} != 0));
  return 1 if ($field eq 'description');
  0;
  }

sub _check_field
  {
  # check field value for valid
  my $self = shift;
  my $field = shift || "";
  my $val = shift || 0;

  $self->SUPER::_check_field($field,$val);
 
  if ($field eq 'set')
    {
    $val =~ s/[\`\=\n\t\r\b]//g;
    $val = substr($val,0,128) if length($val) > 256;
    if ($val =~ /[^0-9a-fA-F]/)
      {
      $val =~ s/[^a-zA-Z0-9 "\\'.,]//g;
      my $array; 
      
      # replace "'a' .. 'b', '0'..'9', ..." with the proper sequence
      if ($val =~ /^(['"](.)['"]\s*\.\.\s*['"](.)["'],?\s*)/)
        {
        my $v = $val; $val = '';
        # as long as we still have a sequence part, replace it
        while ($v =~ /^(['"](.)['"]\s*\.\.\s*['"](.)["'],?\s*)/)
          {
          $v =~ s/^(['"](.)['"]\s*\.\.\s*['"](.)["'],?\s*)//;
          for ("$2" .. "$3") { $val .= unpack('H2', $_); }
          }
        }

      # replace '\x12' .. '\x12' or '0x12 .. 0x15' with a sequence
      elsif ($val =~ /^[\\0](x..)\s*\.\.\s*[\\0](x..)\s*$/)
	{
        $val = '';
        for (hex('0' . $1) .. hex('0' . $2)) { $val .= unpack('H2', chr($_)); }
        }
      elsif ($val =~ /[^a-fA-F0-9]/)
	{
	$self->{_error} = "Invalid character sequence '$val'"; 
	}
      else
        {
        $val = '';
        foreach my $char (@$array)
          {
          $val .= unpack ('H2',$char);
          }
        }
      }
    }
  if ($field =~ /cpos[0-9]{1,2}/)
    {
    $val =~ s/[^0-9-]//g;				# pos can be < 0
    $val = substr($val,0,3) if length($val) > 3;
    $val = 0 if $val eq '';
    }
  if ($field =~ /cset[0-9]{1,2}/)
    {
    $val =~ s/[^0-9]//g;				# set id is positive
    $val = substr($val,0,3) if length($val) > 3;
    $val = 0 if $val eq '';
    }
  $val;
  }

sub put
  {
  # convert data item from string back to internal representation
  my $self = shift;
  my ($key,$val) = @_;

  if ($key eq 'sets')
    {
    my @vals = split /,/,$val; $val = {};
    for (my $i = 0; $i < @vals; $i += 2)
      {
      $val->{$vals[$i]||0} = $vals[$i+1]||1;
      } 
    }
  if ($key eq 'type')
    {
    $self->{type} = 'simple' unless defined $self->{type};
    # XXX TODO: check for one of the valid types
    }
  $self->{$key} = $val;
  }

sub get
  {
  # return an internal key-value as string representation suited for saving
  my $self = shift;
  my $key = shift || '';

  if ($key eq 'sets')
    {
    my $str = "";
    foreach my $k (sort { $a <=> $b } keys %{$self->{sets}})
      {
      $str .= "$k,$self->{sets}->{$k}->{id},";
      }
    $str =~ s/,$//;				# remove last ','
    return $str;
    }
  $self->SUPER::get($key);
  }

sub get_as_string
  {
  # return an internal key-value as string representation suited for display
  my $self = shift;

  my $key = lc(shift || '');

  # fake key
  if ($key eq 'set')
    {
    if ($self->{type} eq 'simple')
      {
      # break the set into 80-wide columns for better display
      my $line = "As hex:\n "; my $rc = "";
      my $l = length($self->{$key});
      for (my $i = 0; $i < $l; $i += 2)
        {
        $line .= substr($self->{$key},$i,2). ' ';
        if (length($line) > 80)
          {
          $rc .= "$line\n"; $line = ' ';
          }
        }
      return $rc.$line;
      }
    my $rc = '';
    foreach my $pos (keys %{$self->{sets}})
      {
      my $p = 'pos'; $p = 'def' if $pos == 0;
      $rc .= "$p $pos\t=> set $self->{sets}->{$pos}->{id}\t"; 
      $rc .= "($self->{sets}->{$pos}->{description})\n"; 
      }
    return $rc;
    }
  # fake key
  if ($key eq 'stringlengths')
    {
    my $txt = '';
    my $cs = $self->{_charset};
    for (my $i = 1; $i < 9; $i++)
      {
      $txt .= "For length <b>$i</b> there are <b>";
      $txt .= $cs->class($i) . "</b> different strings:\n";
      my $f = Math::String->first($i,$cs);
      $txt .= " First string is: '$f' (" . $f->as_number() . ")\n";
      $f = Math::String->last($i,$cs);
      $txt .= " Last string is : '$f' (" . $f->as_number() . ")\n";

      }
    return $txt;
    }
  $self->{$key};
  }

sub charset
  {
  # return the internal Math::String::Charset object
  my $self = shift;
  $self->{_charset};
  }

sub check
  {
  # perform self-check
  my $self = shift;
  my $error = '';

  return $self->{_error} if $self->{_error};
 
  return "type must be 'simple' or 'grouped'" 
    if ($self->{type} !~ /^(simple|grouped)$/);

  if ($self->{type} eq 'simple')
    {
    $error = "Internal charset isn't a Math::String::Charset"
      if ref($self->{_charset}) ne 'Math::String::Charset';
    }
  else
    {
    $error = "Internal charset isn't a Math::String::Charset::Grouped"
      if ref($self->{_charset}) ne 'Math::String::Charset::Grouped';
    }
  $error;
  }

1;

__END__
#############################################################################

=pod

=head1 NAME

Dicop::Data::Charset - a charset

=head1 SYNOPSIS

    use Dicop::Data::Charset;

=head1 REQUIRES

perl5.005, Exporter, Dicop::Item, Dicop, Math::String, Math::String::Charset

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

For a description of fields a charset has, see C<doc/Objects.pod>.

=head1 METHODS

=over 2

=item check()

Perform an internal check and return '' for okay, otherwise an error message.

=item check_strings()

	my $error = $charset->check_string();

Check that start and end are valid strings. Returns error message or empty
string.

=item charset()

Return the internal Math::String::Charset object.

=item type()

Return the type of the charset as string.

=item check_strings()

	$error = $self->check_strings ($hash, @keys);

Take a hash reference and a list of keys. For each of the keys in the hash,
check that it is an object of the underlying charset (Math::String, usually).

If not, create an object out of it.

=back

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

