#############################################################################
# Dicop/Data/Charset/Dictionary.pm -- represents a dictionary character set
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Charset::Dictionary;
use vars qw($VERSION);
$VERSION = 1.02;	# Current version of this package
require  5.005;		# requires this Perl version or later

use base qw(Exporter Dicop::Data::Charset);
use strict;

use Dicop::Base qw/read_file/;
use Math::String::Charset::Wordlist;
use Math::String;
use File::Spec;

use constant LOWER			=> 1;	# lowercase
use constant UPPER			=> 2;	# UPPERCASE
use constant LOWER_FIRST		=> 4;	# lOWERFIRST
use constant UPPER_FIRST		=> 8;	# Upperfirst
use constant LOWER_LAST			=> 16;	# LOWERLASt
use constant UPPER_LAST			=> 32;	# upperlasT
use constant UPPER_ODD			=> 64;	# uPpErOdD
use constant UPPER_EVEN			=> 128;	# UpPeReVEn	
use constant UPPER_VOWELS		=> 256;	# UppErvOwEls
use constant UPPER_CONSONANTS		=> 512;	# uPPeRCoNSoNaNTS

# stages (that are later mutated as LOWER, UPPER etc)
use constant FORWARD			=> 1;	# forward
use constant REVERSE			=> 2;	# esrever

# not used yet:
use constant SHIFT_LEFT			=> 2;
use constant SHIFT_RIGHT		=> 4;
use constant SHIFT_LEFT_UP		=> 8;
use constant SHIFT_RIGHT_UP		=> 16;
use constant SHIFT_LEFT_DOWN		=> 16;
use constant SHIFT_RIGHT_DOWN		=> 16;

my $mutations = {
  lower => 1,
  upper => 2,
  lowerfirst => 4,
  upperfirst => 8,
  lowerlast => 16,
  upperlast => 32,
  upperodd => 64,
  uppereven => 128,
  uppervowels => 256,
  upperconsonants => 512,
  };

my $stages = {
  forward => 1,
  reverse => 2,
  };

#############################################################################
# private, initialize self 

sub _init
  {
  my $self = shift;
  my $args = shift;

  $self->SUPER::_init($args,$self);

  $self->SUPER::_default( {
    description => "dictionary set",
    type => 'dictionary',
    file => 'wordlist.lst',
    sets => '',
    }, $self );
  delete $self->{set};	# a fake key, that might be accidentily set from old data
  $self->{type} = 'dictionary';
  $self;
  }

sub _construct
  {
  my ($self,$args,$other) = @_;
 
  $self->{stages} = 0 if !defined $self->{stages};
  $self->{mutations} = 0 if !defined $self->{mutations};

  # convert a list of keys like 'lower', 'upper' etc to mutations
  foreach my $key (keys %$self)
    {
    next if $key !~ /^(lower|upper)/;
    my $value = $mutations->{$key};
    $self->{_error} = "Unknown key $key", return if !defined $value;
    $self->{mutations} |= $value;
    delete $self->{$key};
    }
  
  # convert a list of keys like 'forward', 'reverse' etc to stages
  foreach my $key (keys %$self)
    {
    next if $key !~ /^(forward|reverse)$/;
    my $value = $stages->{$key};
    $self->{_error} = "Unknown key $key", return if !defined $value;
    $self->{stages} |= $value;
    delete $self->{$key};
    }
 
  # convert a list of keys like 'cpos0', 'cpos1' etc to an array containing
  # the sets to append/prepend

  $self->{sets} = [] unless ref($self->{sets}) eq 'ARRAY';
  my $sets = $self->{sets};
  foreach my $key (sort keys %$self)
    {
    next if $key !~ /^cpos[0-9]{1,2}$/;		# for each posX
    next if ($self->{$key} || 0) == -1;		# don't use this one

    my $i = $key; $i =~ s/^cpos//;		# index, leave only number
    next if ($self->{"cset$i"} || 0) == 0;	# Huh? no set selected?
    
    push @$sets,
      [ 
	($self->{"cpos$i"} || 0) & 1,		# append or prepend?
	$self->{"cset$i"},			# set id
	$self->{"cstart$i"} || 1,		# start len
	$self->{"cend$i"} || 1,			# end len
      ];
    $sets->[-1]->[3] = $sets->[-1]->[2]
     if $sets->[-1]->[3] <= $sets->[-1]->[2];	# end >= start!
    }

  # remove the now unnecc. keys
  foreach my $key (keys %$self)
    {
    next if $key !~ /^c(set|pos|start|end)[0-9]+$/;
    delete $self->{$key};
    }

  # For each append/prepend, calculate how many password we do and add
  my $append_prepend = Math::BigInt->bzero();
  foreach my $set (@$sets)
    {
    my $charset = $self->{_parent}->get_charset($set->[1]);

    die ("Can't find charset $set->[1]") unless ref $charset;
    
    die ("Can only append/prepend simple or grouped charsets")
      if $charset->type() !~ /^simple|grouped$/;

    # append or prepend does not matter, but we need all the pwds from
    #  start to len
    my $sum = Math::BigInt->bzero();
    my $cs = $charset->charset();	# get Math::String::Charset
    for my $i ($set->[2] .. $set->[3])
      {
      # get from the charset how many pwds are in class($i) and sum them up
      $sum += $cs->class($i);	 	# 1..2 => class(1) + class(2)
      }
    $append_prepend += $sum;
    }

  my $bits = sprintf("%b",$self->{stages});
  my $sta = $bits =~ tr/1//;
  $bits = sprintf("%b",$self->{mutations});
  my $mut = $bits =~ tr/1//;

  $self->{stages} = 1 if $self->{stages} == 0;
  $self->{mutations} = 1 if $self->{mutations} == 0;

  # re-calc scale factor from stages * mutations
  $self->{scale} = Math::BigInt->new($sta * $mut);
  
  # and add the different appended/prepended pwds per combination
  $self->{scale} += $self->{scale} * $append_prepend;

  if ($self->{scale}->is_zero())
    {
    $self->{_error} = 
      "Cannot have dictionary charset with no combinations at all.";
    return;
    }

  my $file = File::Spec->catfile('target','dictionaries',$self->{file});
  if (!-e $file || !-f $file)
    {
    $self->{_error} = "Cannot open dictionary file '$file': $!";
    }

  if (defined $other)
    {
    # we have another charset with the same file, so just make a copy
    $self->{_charset} = $other->{_charset}->copy();
    }
  else
    {
    # check that the dictionary file is still intact
    my $check = $file; $check =~ s/\..*$//; $check .= '.md5';
    # XXX TODO
    my $md5 = read_file($check);

    # don't have seen this file already, so create a new one
    $self->{_charset} = Math::String::Charset::Wordlist->new( 
       { file => $file } );
    }
 
  if (ref($self->{_charset}) !~ /^Math::String::Charset::Wordlist/)
    {
    $self->{_error} = 
      "Couldn't construct internal Math::String::Charset::Wordlist object";
    return;
    }
  $self->{_charset}->scale( $self->{scale} ) unless $self->{scale}->is_one();
  }

#############################################################################
# public stuff

sub appends
  {
  # return the number of sets that appended/prepended to each stage
  my $self = shift;

  scalar @{$self->{sets}};
  }

sub can_change
  {
  # return whether a field can be changed or not
  my $self = shift;
  my $field = shift || return 1;

  return 1 if (($field =~ /^(description|stages|mutations)$/)
   && ($self->{dirty} != 0));
  0;
  }

# 
#  if ($field eq 'description')
##    {
#    $val =~ s/[\"\`\=\n\t\r\b]//g;
#    $val = substr($val,0,128) if length($val) > 128; 
#    }
#  if ($field =~ /^(stages|mutations)$/)
#    {
#    $val =~ s/[^0-9]//g;
#    $val = 1 if $val <= 0 or $val > 3;
#    }
#  if ($field eq 'file')
#    {
#    $val =~ s/[^a-zA-Z\\\/._0-9-]//g;
#    $val = substr($val,0,250) if length($val) > 250; 
#    }
#  $val;
#  }

sub get_as_string
  {
  # return an internal key-value as string representation suited for display
  my $self = shift;

  my $key = lc(shift || '');

  my $txt = $self->{$key};
  # fake key
  if ($key eq 'set')
    {
    $txt = "Dictionary file:\n  '$self->{file}'\n";
    $txt .= "Scale factor (stages*mutations + ";
    $txt .="stages*mutations*(prepended+appended)):\n  $self->{scale}\n";
    my $s = $self->{stages};
    $txt .= "Stages:\n";
    $txt .= "  forward\n" if ($s & FORWARD) != 0;
    $txt .= "  reversed\n" if ($s & REVERSE) != 0;
    $s = $self->{mutations};
    $txt .= "Mutations:\n";
    $txt .= "  lower\n" if ($s & LOWER) != 0;
    $txt .= "  UPPER\n" if ($s & UPPER) != 0;
    $txt .= "  lOWERFIRST\n" if ($s & LOWER_FIRST) != 0;
    $txt .= "  Upperfirst\n" if ($s & UPPER_FIRST) != 0;
    $txt .= "  LOWERFIRSt\n" if ($s & LOWER_LAST) != 0;
    $txt .= "  upperfirsT\n" if ($s & UPPER_LAST) != 0;
    $txt .= "  uPpErOdD\n" if ($s & UPPER_ODD) != 0;
    $txt .= "  UpPeReVeN\n" if ($s & UPPER_EVEN) != 0;
    $txt .= "  UppErvOwEls\n" if ($s & UPPER_VOWELS) != 0;
    $txt .= "  uPPeRCoNSoNaNTS\n" if ($s & UPPER_CONSONANTS) != 0;
    if (scalar @{$self->{sets}} > 0)
      {
      $txt .= "And to each stage/mutation:\n";
      $s = $self->{sets};
      foreach my $set (@$s)
	{
	$txt .= '  Append ' if $set->[0] eq '0';
	$txt .= '  Prepend ' if $set->[0] ne '0';
	$txt .= "$set->[2] to $set->[3] chars of set $set->[1]\n";
	}
      }
    }
  # fake key
  if ($key eq 'stringlengths')
    {
    $txt = "The first word in the dictionary is:\n";
    $txt .= " <b>'".$self->{_charset}->first(1)."'</b>\n";
    $txt .= "The first tried stage/mutation of that would be:\n";
    $txt .= " not ready yet: <b>'".$self->{_charset}->first(1)."'</b>\n\n";

    $txt .= "The last word in the dictionary is:\n";
    $txt .= " <b>'".$self->{_charset}->last(1)."'</b>\n";
    $txt .= "The first tried stage/mutation of that would be:\n";
    $txt .= " not ready yet: <b>'".$self->{_charset}->last(1)."'</b>\n\n";

    $txt .= "There are <b>". $self->{_charset}->length() . 
            "</b> words in the dictionary.\n";
    $txt .= "Since each word is tried in <b>" . $self->{scale} . 
            "</b> different combinations,\n".
	    "this makes the character set contain <b>" .
            $self->{_charset}->length(1) * $self->{scale} .
	    "</b> different strings.\n";
    }
  $txt;
  }

sub keys
  {
  # return the names of the keys used to display this object
  return (qw/set type id description/);
  }

sub charset
  {
  # return the internal Math::String::Charset::Wordlist object
  my $self = shift;
  $self->{_charset};
  }

sub check
  {
  # perform self-check
  my $self = shift;
  my $error = '';

  return $self->{_error} if defined $self->{_error} && $self->{_error} ne '';
 
  return
   "stages must be > 0 and < 4 but is $self->{stages}" 
    if $self->{stages} <= 0 || $self->{stages} > 3;

  return 
   "mutations must be > 0 and < 1024 but is $self->{mutations}" 
    if $self->{mutations} <= 0 || $self->{mutations} > 1023;

  $error;
  }

sub type { 'dictionary' }

sub offset
  {
  # return the offset into the dictionary file of the n'th word
  my ($self,$n) = @_;

  $self->{_charset}->offset($n-1);
  }

sub get
  {
  Dicop::Item::get(@_);
  }

sub put
  {
  # convert data item from string back to internal representation
  my $self = shift;
  my ($key,$val) = @_;

  if ($key eq 'sets')
    {
    # format "1_2_3_4,1_2_3_4," etc
    my @vals = split /,/,$val; $val = [];
    foreach my $v (@vals)
      {
      push @$val, [ split /_/, $v ];
      }
    }
  if ($key eq 'type')
    {
    $self->{type} = 'dictionary' unless defined $self->{type};
    # XXX TODO: check for one of the valid types
    }
  $self->{$key} = $val;
  }

1;

__END__
#############################################################################

=pod

=head1 NAME

Dicop::Data::Charset::Dictionary - a dictionary charset

=head1 SYNOPSIS

    use Dicop::Data::Charset::Dictionary;

=head1 REQUIRES

perl5.005, Exporter, Dicop::Item, Dicop, Dicop::Event, Math::String::Charset

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

A dictionary charset has the following fields, most of them can be set
via C<new>.
The rest (shown with a *) is automatically initialized/overwritten/maintained:

=over 2

=item stages

A bitfield containing the different stages a word is mutated through first.

=item mutations

A bitfield containing the different mutations each stage is mutated throughi
further.

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

=over 2

=item check()

Perform an internal check and return '' for okay, otherwise an error message.

=item type()

Returns the type, in this case the string 'dictionary'.

=item appends()

	$set->appends();

Returns the number of sets that appended/prepended to each stage of each word.

=item offset()

	$set->offset($N);

Returns the offset into the dictionary file of the n'th word. 0 means the very
first word.

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

