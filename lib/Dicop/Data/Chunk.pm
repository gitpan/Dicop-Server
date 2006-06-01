#############################################################################
# Dicop/Data/Chunk.pm -- a chunk/piece of a job
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::Chunk;
use vars qw($VERSION);
$VERSION = 1.05;	# Current version of this package

use base qw(Dicop::Item);
use strict;

use Digest::MD5 qw(md5_hex);
use Dicop qw(DONE SOLVED ISSUED TOBEDONE FAILED MAX_ISSUED_AGE MAX_FAILED_AGE
             VERIFY BAD
		status_code
            );
use Math::String;
use Dicop::Data::Job;
use Dicop::Event qw/crumble/;
use Dicop::Base qw/a2h h2a decode/;

#############################################################################
# private, initialize self 

sub _init
  {
  my ($self,$args) = @_;

  $self->SUPER::_init($args);
  $self->{client} = $args->{client} || 0;
  $self->{result} = $args->{result} || 0;
  $self->{created} = Dicop::Base::time();
  $self->{issued} = $self->{created};
  $self->{status} = $args->{status} || TOBEDONE;
  $self->{job} = $args->{job} || 0;
  $self->{_secret} = $args->{_secret} || "";
  $self->{checksum} = "";
  $self->{verified} = {};
  $self->{token} = "";
  if (defined $args->{size})
    {
    $self->{size} = Math::BigInt->new($args->{size});
    }
  $self;
  }

sub _construct
  {
  my $self = shift;

  $self->{result} = '' if !defined $self->{result};
  $self->{client} = '' if !defined $self->{client};
  
  delete $self->{check};	# obsolete entry

  # ignore errors on non-existant clients
  $self->SUPER::_construct( 1 );

  # convert client ids in verified list back into ref's to clients  
  foreach my $id (keys %{$self->{verified}})
    {
    $self->{verified}->{$id}->[0] = $self->{_parent}->get_client($id,'noerror')
     if $id != 0;
    if (!ref($self->{verified}->{$id}->[0]))
      {
      # verifier no longer exists?
      delete $self->{verified}->{$id};
      $self->modified(1);
      }
    }
    
  $self->{_parent} = $self->{job};		# override

  my $cs = $self->{job}->{charset};

  $self->_from_string_form($cs,qw/start end/);

  return if $self->{_error};

  $self->{end} = $self->{start} if $self->{end} < $self->{start};

  # always calculate size and compare with stored size
  my $old_size = $self->{size};
  $self->_adjust_size();
  if (defined $old_size && $old_size ne $self->{size})
    {
    print STDERR "Warning: chunk $self->{id} (job $self->{job}->{id}) size mismatch:\n";
    print STDERR " Old size stored on disk: $old_size\n Using new size: $self->{size}\n";
    $self->modified(1);
    }
  $self->_checksum();
  }

sub _checksum
  {
  # set time of last modification to now, then calculate your checksum
  my $self = shift;
 
  crumble ("Can't modify chunk $self->{id} without secret\n")
    if !defined $self->{_secret};  
  $self->{modified} = Dicop::Base::time();
  $self->{checksum} = "";
  foreach my $k (sort keys %$self)
    {
    next if $k =~ /^(_|checksum$|token$|verified$)/;	# no internal vars
    $self->{checksum} .= "$k=$self->{$k}";
    }
  $self->{checksum} = md5_hex($self->{checksum} . $self->{_secret});
  $self->modified(1) if defined $_[0];
  $self;
  }

#############################################################################
# public stuff

sub issue
  {
  # issue this chunk to a client
  my ($self,$client,$secret) = @_;

  crumble ("$client is not a valid client.") if !ref $client;
  $self->{client} = $client;
  $self->{issued} = Dicop::Base::time();
  $self->{status} = ISSUED;
  $self->{_secret} = a2h($secret || '');
  $self->_checksum(1);			# set self and parents to modified
  $self->{token} = $self->{checksum};	# store checksum for later checks
  $self;	# return self
  }

sub is_open
  {
  # return true if chunk is open (e.g. work on it needs still to be done)
  # also returns true for ISSUED, because we don't know yet if the ISSUED
  # chunk will be DONE or SOLVED afterwards or not (maybe it will fail etc)
  my $self = shift;

  return 1 if 
    $self->{status} == TOBEDONE ||
    $self->{status} == FAILED ||
    $self->{status} == BAD ||
    $self->{status} == VERIFY ||
    $self->{status} == ISSUED;
  0;			# DONE, SOLVED and anything else
  }

sub start
  {
  my $self = shift;
  $self->{start};
  }

sub end
  {
  my $self = shift;
  $self->{end};
  }

sub client_in_verifier_list
  {
  # return true if the client is in the list of verifiers
  my ($self,$client) = @_;

  exists $self->{verified}->{$client};
  }

sub verify
  {
  # Take a client id, client status (DONE, SOLVED etc), client result (only
  # necc. for status == SOLVED, otherwise should be ''), and the crc as
  # reported by the client. Then set add client to list of verified and set
  # chunk status to VERIFY. Then check whether we have enough verifiers, and
  # if they all agree on result and crc. If they do, set chunk to DONE or
  # SOLVED. If they don't agree, convert chunk back to TOBEDONE, "punish"
  # clients. Returns new status of chunk.
  my ($self, $client, $status, $result, $crc,
      $needed_done, $needed_solved,$reason) = @_;

  # we only accept solutions for chunks that are currently in the ISSUED
  # or VERIFY state
  return ($self->{status},-6)
     if $self->{status} != ISSUED && $self->{status} != VERIFY;

  $self->status(VERIFY);

  # for FAILED, or TIMEOUT
  if (($status != DONE) && ($status != SOLVED))
    {
    # only set to FAILED or TIMEOUT when not already in VERIFY state, else
    # it stays converted to VERIFY
    if ($self->verifiers() == 0)
      {
      # chunk could be split at the border to save the already done parts
      $self->status(FAILED);
      $self->reason($reason);
      }
    # TODO: really?
    return ($self->{status}, 0);	# stay in VERIFY state
    }

  my $rc = $self->add_verifier($client,$status,$result,$crc);
  if ($rc < 0)					# error?
    {
    # notify caller, he is also responsible setting the status to BAD!
    my $msg = "Need Client ref";				# -1
    $msg = "Status must be DONE or SOLVED" if $rc == -2;
    $msg = "Client already verified this - need somebody else." if $rc == -3;
    $msg = "DONE chunks can't carry result" if $rc == -4;
    $msg = "SOLVED chunks must carry result" if $rc == -5;
    $msg = "Unknown error" if $rc < -5;
    $self->reason($msg);
    return (BAD,$rc,$msg);
    }

  my $error = 0;				# no error
  foreach my $v (keys %{$self->{verified}})
    {
    my $c = $self->{verified}->{$v};
    $error++ if $c->[1] != $status;		# status differ?
    $error++ if $c->[2] ne $result;		# results differ?
    $error++ if $c->[3] ne $crc;		# CRCs differ?
    last if $error != 0;			# some error?
    }
  # If there was an error, then something went wrong. Either the clients
  # computed a wrong checksum, or their results or status results did differ.
  # None of this should happen.
  if ($error != 0)
    {
    foreach my $v (keys %{$self->{verified}})
      {
      # <tweaty>baad pusssy client!</tweaty>
      $self->{verified}->{$v}->[0]->punish(); 
      }
    # notify caller, he is also responsible setting the status to BAD!
    return (BAD,0);
    }
  else
    {
    # do we have enough verifiers for the current result? If yes, set chunk
    # finally to the now successfully verified $status
    my $v = $self->verifiers() || 0;
    if ( ($status == DONE && $v >= $needed_done) ||
         ($status == SOLVED && $v >= $needed_solved))
      {
      $self->status($status);
      }
    # otherwise the chunk is not in the VERIFY state
    }
  ($self->{status},0);
  }

sub reason
  {
  my $self = shift;

  if (@_ > 0)
    {
    $self->{reason} = substr($_[0] || '',0,4096);	# max. 4096 chars
    }
  $self->{reason};
  }

sub dump_verifierlist
  {
  # return verifierlist as test dump  
  my $self = shift;

  my $list = "";
  foreach my $id (keys %{$self->{verified}})
    {
    my $v = $self->{verified}->{$id};		# shortcut
    # [ $client, $status, $result, $crc, Dicop::Base::time() ];
    $list .= $v->[0]->{id} . "\t" .		# client 
             $v->[1] . "\t" . 			# status
               $v->[2] . "\t" .			# result (already in hex)
               $v->[3] . "\t" .			# crc is already in hex
               "$v->[4]\n";			# time
    }
  $list;
  }

sub clear_verifiers
  { 
  my $self = shift;

  $self->{verified} = {};
  $self;
  }

sub check_age
  {
  # when an chunk was issued too long ago, free it
  # The time the chunk should linger around is taken from the client, so that
  # some (off-line) clients can have a longer linger time than others.
  # return true for modified chunk, undef for not.
  my ($self,$client) = @_;
 
  return -1 if (($self->{status} != ISSUED) && 
                ($self->{status} != FAILED) && 
                ($self->{status} != BAD) &&
                ($self->{status} != VERIFY) 
               );

  my $now = Dicop::Base::time();
  my $maxage = $client->{max_failed_age} || 3600*6;
  $maxage = ($client->{max_issued_age} || 3600*6) if $self->{status} == ISSUED;
  if ($now - $self->{issued} > $maxage)
    {
    $client->lost_chunk($self);		# update client's counters 
    $self->{status} = TOBEDONE; 
    $self->clear_verifiers();		# clear list now 
    $self->_checksum(1);
    return 1;
    }
  0;
  }

sub merge
  {
  # merge a second chunk into ourself
  my ($self,$other) = @_;

  return unless ref($self) && ref($other);	# only for objects
  # if not two consecutive chunks
  my $a = 0; 					# 1 : other follows self
						# -1: self follows other
						# 0 : neither does
  $a = 1 if $self->{end} == $other->{start};
  $a = -1 if $self->{start} == $other->{end};
  return if $a == 0;
 
  if ($a > 0) 
    {
    $self->{end} = $other->{end};	
    }
  else
    {
    $self->{start} = $other->{start};	
    }
  $self->_adjust_size();
  $self->clear_verifiers();
  $self->_checksum(1);
  }

sub _adjust_size
  {
  my $self = shift;

  $self->SUPER::_adjust_size();
  $self->{size} = $self->{_size};	# for write (_size would get skipped)
  $self;
  }

sub split
  {
  # Splice a chunk into two, the size given is either relatively (<1.0) or
  # absolutely. Return new chunk, aka the second one of the two.
  # [2] => [1][2] and returns [2]

  my $self = shift;
  my $size = shift;
  my $border = shift || 0;	# how many digits to keep fixed

  my $limit = $size;
  $limit = Math::BigInt->new($limit) unless ref($limit);

  my $r = 0;				# round up
  if (ref($size) eq 'Math::String')
    {
    $r = 1; $limit -= $self->{start}->as_number(); # never round up
    }
  elsif ($size <= 1)
    {
    $limit = $self->{_size} * $size; 	# relative size
    }
  # print ref($size)," ",ref($limit)," $limit $size\n";
  # correct limit to be on a "border" of $border 'fixed' chars
  # by making sure it is a multiple of the size of the "border" string
  # it does not matter whether limit is "$limit + $start" or just "$limit",
  # since this is math with modulo (chars ** border), and $start is already
  # without remainder.
  $limit = $self->border($border,$limit,$r) if $border > 0;

  if ($limit->is_zero())
    {
    return if ref($size);				# can't round up
    my $cs = $self->charset();
    # chunk of size 1 (0), retry split with fixed=1
    $limit = Math::BigInt->new( $cs->length() ** ($border || 1)); # not zero
    } 
  return if $limit->is_negative();

  # calculate split border from start + length
  $limit = $self->{start} + $limit;

  return if $limit >= $self->{end};
  # can only happen if $limit was negative
  # return if $limit <= $self->{start};

  my $other = new Dicop::Data::Chunk ( start => $limit, end => $self->{end},
    job => $self->{job}, 
     secret => $self->{_secret}, 
    _parent => $self->{_parent},
    id => $self->{job}->new_chunk_id(), );
  $other->_construct();

  $self->{end} = $limit->copy();
  $self->_adjust_size();
  $self->_checksum(1);
  $other;
  }

sub border
  {
  # correct a string to be on a border of $cnt chars
  # aka: aaa => babc becomes 'aaa' => 'baaa' when rounding down or
  # 'aaa' => 'caaa' when rounding up
  # it ensures that the given limit of keys is a multiple of the size of the
  # border string
  my $self = shift;

  my $cnt = shift || 3;
  my $limit = shift || 0;
  my $round_up = shift || 0;

  $limit = Math::BigInt->new($limit) unless ref($limit) eq 'Math::BigInt';
  my $cs = $self->charset();
  my $border = $cs->length() ** Math::BigInt->new($cnt);

  my ($div,$rem) = $limit->copy()->bdiv($border);
  # correct to higher or lower border if not already
  $div++ if $round_up == 0;	
  $limit = $border * $div if !$rem->is_zero();
  $limit;
  }

sub charset
  {
  # return Math::String::Charset object for start/end
  my $self = shift;
  $self->{job}->charset();
  }

sub size
  {
  my $self = shift;
  $self->{_size};
  }

sub checksum
  {
  my $self = shift;

  $self->{checksum};
  }

sub status
  {
  my $self = shift;
  my $status = shift;

  if (defined $status)
    {
    $self->{status} = $status; $self->_checksum(1);
    }
  $self->{status};
  }

sub result
  {
  my $self = shift;
  my $result = shift;

  if (defined $result)
    {
    $self->{result} = $result; $self->_checksum(1);
    }
  $self->{result};
  }

sub get_as_string
  {
  # return a field of yourself as plain string (for web display)
  # return "" for non-existing fields
  # this might call time quite a lot, so use cache in Dicop
  my $self = shift;
  my $key = lc(shift||"");

  my $time = Dicop::Base::time();
  return $self->{_size} if $key eq 'size';
  return a2h($self->{$key}->bstr()) if ($key =~ /^(start|end)$/);
  if ($key eq 'status')
    {
    # unknown
    return 'unknown' if $self->{status} == ISSUED 
      && $time - $self->{issued} > 3600;
    # or issued, tobedone, done, failed, bad, verify
    return Dicop::status($self->{status});
    }
  if ($key =~ /^(issued)$/)
    {
    if ($self->{status} == SOLVED)
      {
      my $txt = 'Solved by <B><A HREF="##selfstatus_client##;'
           . "id_$self->{client}->{id}\">$self->{client}->{name}</A></B>";
      $txt .= 
            ' (<B><A HREF="##selfstatus_results##;'
           . "id_".$self->{result}->{id}.'\">'
           . $self->{result}->get('result_hex')||''."</A></B>)"
        if ref($self->{result}) eq 'Dicop::Data::Result';
      return $txt;
      } 
    return Dicop::status($self->{status}) 
      if ($self->{status} != ISSUED && $self->{status} != FAILED);
    my $dist = $time - $self->{$key};
    return "Issued to unknown client " . Dicop::Base::ago($dist) . ' ago'
      if ($self->{status} == ISSUED && !ref $self->{client});
    return unless ref $self->{client};
    return "Issued to <B><A HREF=\"##selfstatus_client##;"
      . "id_$self->{client}->{id}\">"
      . "$self->{client}->{name}</A></B>, " . Dicop::Base::ago($dist) . ' ago'
      if ($self->{status} == ISSUED);
    my $r = "Failed (<B><A HREF=\"##selfstatus_client##;"
      . "id_$self->{client}->{id}\">"
      . "$self->{client}->{name}</A></B>), " . Dicop::Base::ago($dist) . ' ago';
    my $res = decode($self->{reason} || 'Unknown reason.');
    # XXX TODO: use a generic routine
    $res =~ s/&/&amp;/g; $res =~ s/>/&gt/g; $res =~ s/</&lt/g;	# safe for web
    $r .= '<br>Reason: ' . $res;
    return $r;
    }
  my $val = $self->{$key};
  return "Error: $key undefined!" if !defined $val;

  $val = $val->{id} if ref $val && exists $val->{id};
  $val = "$val" if ref $val;
  $val;
  }

sub get
  {
  # return an internal key-value as string representation suited for saving
  my $self = shift;
  my $key = lc(shift || '');

  return $self->{_size} if $key eq 'size';	# fake key
  $self->SUPER::get($key);
  }

sub put
  {
  # convert data item from string back to internal represantation
  my $self = shift;
  my ($var,$data) = @_;

  if ($var eq 'verified')
    {
    # create if not yet exists
    $self->{verified} = {} unless ref $self->{verified} eq 'HASH';

    return if ($data || '') eq '';	# not defined
    # split into parts at ','
    my @parts = split /,/, $data;
    foreach my $part (@parts)
      {
      # split at '_' into pieces
      my @client = split /_/, $part;
      # [ $client, $status, $result, $crc, Dicop::Base::time() ];
      $self->{verified}->{$client[0]} = [ @client ];
      }
    }
  elsif ($var eq 'status')
    {
    $self->{$var} = $data;
    $self->{$var} = status_code($data) unless $data =~ /^\d+$/;
    }
  else
    {
    $self->{$var} = $data;
    }
  }

sub get_as_hex
  {
  my $self = shift;

  my $key = lc(shift || '');

  #return a2h($self->{$key}->bstr()) if $key =~ /^(start|end)$/;
  return a2h($self->{$key}) if $key =~ /^(start|end)$/;
  $self->{$key};
  }

sub token
  {
  # get/set a token
  my $self = shift;
  my $token = shift;
  
  if (defined $token)
    {
    $self->{token} = $token;
    }
  $self->{token};
  }

sub add_verifier
  {
  # add a client id, status (DONE or SOLVED), the result ('' or real result)
  # and crc to chunk's verify list. Returns < 0 for some error, otherwise the
  # new number of verifiers of this chunk.

  my ($self, $client, $status, $result, $crc) = @_;

  return -1 unless ref($client);			# need client ref

  # not for failed or timeouts nor anything else
  return -2 if $status != DONE && $status != SOLVED;
 
  # somebody else needs to verify the result!
  return -3 if exists $self->{verified}->{$client->{id}};

  $result = '' if !defined $result;

  # only SOLVED chunks should have a result
  return -4 if $result ne '' && $status == DONE;
  return -5 if $result eq '' && $status == SOLVED;

  $self->{verified}->{$client->{id}} = 
   [ $client, $status, $result, $crc, Dicop::Base::time() ];
  
  scalar keys %{$self->{verified}}; 
  }
  
sub verified_by
  {
  my ($self,$client) = @_;

  # proxies never work themselves
  return if ref($client) eq 'Dicop:Data::Proxy' || !defined $client;
  (exists $self->{verified}->{$client->{id}}) <=> 0;
  }

sub del_verifier
  {
  my ($self,$client) = @_;

  delete $self->{verified}->{$client->{id}};
  }

sub verifiers
  {
  # return number of entries in chunk's verify list
  my $self = shift;

  scalar keys %{$self->{verified}} || 0;
  }

1;

__END__

#############################################################################

=pod

=head1 NAME

Dicop::Data::Chunk - a chunk/piece of a L<Job|Dicop::Data::Job> in
the L<Dicop|Dicop::Dicop> system. 

=head1 SYNOPSIS

	use Dicop::Data::Chunk;
	use Dicop qw(TOBEDONE);

	$chunk = new Dicop::Data::Chunk (
			start => 'aaa', end => 'zzz',
			job => $job, status => TOBEDONE, ); 

=head1 REQUIRES

perl5.005, Exporter, Dicop, Dicop::Event, Dicop::Data, Math::BigInt, Math::String, Digest::MD5

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

For a description of fields a chunk has, see C<doc/Objects.pod>.

=head1 METHODS

=head2 new()

Create a new chunk object.

=head2 merge()

	$self->merge($other_chunk);

Merge second chunk into the first one, fusing them together. Does only work
if both chunks are adjacent to each other, e.g. the second one starts where
the first one ends, or vice versa.

=head2 token()

Get/set the (secret) token of the chunk.

=head2 check_age()

When an chunk was issued too long ago, free it so that other clients can tackle
it.

The time the chunk should linger around is taken from the client, so that
some (off-line) clients can have a longer linger time than others.

Returns true when the chunk was modified (set to TOBEDONE), otherwise undef.

=head2 is_open()

	if ($chunk->is_open())
	  {
	  $open_chunks++;
	  }

Returns true if the chunk is open, e.g. not DONE nor SOLVED.

=head2 status()

Return the status code.

=head2 result()

Return the result or undef for no result yet.

=head2 start()

Return the first key in this chunk.

=head2 end()

Return the last key in this chunk.

=head2 size()

Return the size in keys/passwords from start to end.

=head2 checksum()

Return the checksum.

=head2 charset()

Return the Math::String::Charset object that is used for the start
and end key.

=head2 border()

	$self->border($fixed_chars,$key,$round_up);

Correct a string to be on a border of $cnt chars. This is used to force the
borders between chunks to be in a certain granularity.

For instance, if the chunk goes from 'aaa' to 'babc', the chunk end will be
adjusted to 'baaa' when rounding down, or 'caaa' when rounding up (both
taking three characters at the end as fixed). C<$round_up == 0> means rounding
up, C<$round_up != 0> means rounding down.

Or in other words, it ensures that the given limit of keys is a multiple of
the size of the border string.

=head2 verify()

	$new_chunk_status =
          $chunk->verify ($client, $result, $crc, $need_done, $need_solved);

Take a client id, chunk result (DONE, SOLVED etc), and the client-supplied
CRC and try to verifiy the client's work. (This is done only when there
were more than one client returning work for this chunk).

When enough verifiers for the chunk exist (in the simplest case only one),
and all of them agreed on the chunk result, then we set the chunk to DONE
or SOLVED, depending on the outcome.

Returns the new chunk status. Possible results are:

	DONE		enough verifiers, all said DONE (and all CRCs matched)
	SOLVED		enough verifiers, all said SOLVED (and CRCs matched)
	BAD		the result of the verifiers or their CRCs did differ
	VERIFY		not enough verifiers, but the current ones all
			agreed on result and CRC
	FAILED		chunk was issued to first client and this one FAILED
	TIMEOUT		chunk was issued to first client and this did time out

In the case of BAD, for each of the verifiers (clients), their punish()
routine will be called. The status BAD must be reversed to TOBEDONE by the
caller after taking appropriate action by logging or whatever needs to be
done. Actually, status BAD can linger around for some hours to let the admin
see the BAD chunks and the clients that caused that smell...

=head2 verifiers()

	my $count = $chunk->verifiers();

Returns the number of entries in the verifier list. Each client that works
on this chunk will be added to this list, including his result and CRC.

=head2 add_verifier()

	$chunk->add_verifier($client,$status,$crc);

Add an client to the list of verifiers, along with the result (SOLVED, DONE)
and the crc (as returned by the client) for the chunk. Does nothing if the
result is not DONE or SOLVED (e.g. it was FAILED or TIMEOUT).

=head2 del_verifier()

	$chunk->del_verifier($client);

Remove the client from the list of verifiers. The client does not necc. to
be in the list, in this case nothing will be done.

=head2 clear_verifiers()

	$chunk->clear_verifiers();

Clear the list of verifiers. Done when a chunk failed verification, or was
merged with another chunk.

=head2 dump_verifierlist()

	my $text  =  $chunk->dump_verifierlist();

Return verifierlist as text dump suitable for logging, or embedding in a mail.  

=head2 client_in_verifier_list()

	if ($chunk->client_in_verifier_list($client))
	  {
	  ...
	  }

Return true if the given client is in the list of verifiers for this
chunk.

=head2 verified_by()

	if ($chunk->verified_by($client))
	  {
	  ...
	  }

Returns true if the client is already in the verifier list of that chunk. Used
to avoid giving a chunk twice to a client.

=head2 reason()

	my $reason = $chunk->reason();

Return the error message in case the chunk was marked as FAILED.

=head2 split()

Splice a chunk into two, the size given is either relatively (<1.0) or
absolutely. Return new chunk, aka the second one of the two.

=head2 issue()

Issue a chunk to a specific client, e.g. mark it as issued and note
the client ID for a later verify.

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut
