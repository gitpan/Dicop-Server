#############################################################################
# Dicop::Data - Files.pm - routines to create the target/charset files 
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data;
$VERSION = '1.04';	# Current version of this package
require  5.008001;	# requires this Perl version or later

use strict;

use Dicop::Base qw/a2h write_file encode/;
use Dicop::Hash;
use Dicop::Event qw/crumble msg logger/;
use File::Spec;

our $NEVER_INLINE_FILES = 0;		# set to 1 to prevent inlining
					# used by testsuite

###############################################################################

sub write_charsets_def
  {
  # generates the charset.def file for the workers, that contains all the
  # charset descriptions for their password generator
  my $self = shift;

  my $cfg = $self->{config};
  $cfg->{charset_definitions} = '' if !defined $cfg->{charset_definitions};
  my $file = $cfg->{charset_definitions};
  return if $file eq '';

  my $txt = "# This file was automatically generated. Do not edit!\n" .
            "# All changes will be lost upon next regeneration!\n" .
	    'count=' . (scalar keys %{$self->{charsets}}) ."\n";

  # first write out the simple ones
  foreach my $id (sort { $a <=> $b } keys %{$self->{charsets}})
    {
    my $set = $self->{charsets}->{$id};
    next if $set->type() ne 'simple';			# only simple ones
    $txt .= "0:$set->{id}:";				# type simple
    my @chars = map ( sprintf ("%x",ord($_)) , $set->charset()->start());
    $txt .= join (':', @chars);
    $txt .= "\n";
    }
  
  # now the grouped ones
  foreach my $id (sort { $a <=> $b } keys %{$self->{charsets}})
    {
    my $set = $self->{charsets}->{$id};
    next if $set->type() ne 'grouped';			# only grouped
    $txt .= "1:$set->{id}:";				# type grouped
    
    foreach my $pos (sort { $a <=> $b } keys %{$set->{sets}})
      {
      $txt .= "$pos=$set->{sets}->{$pos}->{id}:";
      }
    $txt =~ s/:$/\n/;	# remove trailing : and add \n
    }
  
  # now the dictionary ones
  foreach my $id (sort { $a <=> $b } keys %{$self->{charsets}})
    {
    my $set = $self->{charsets}->{$id};
    next if $set->type() ne 'dictionary';		# only dict
    $txt .= "2:$set->{id}:";				# type dict
   
    foreach my $s (@{$set->{sets}})
      {
      $txt .= join(',',@$s) . ":";
      }
    $txt =~ s/:$//;					# remove last ":"
    $txt .= "\n";
    }
  
  # now the extract ones
  foreach my $id (sort { $a <=> $b } keys %{$self->{charsets}})
    {
    my $set = $self->{charsets}->{$id};
    next if $set->type() ne 'extract';			# only extract
    $txt .= "3:$set->{id}:\n";				# type extract
    }
  
  # write back file
  my $rc = write_file($file,\$txt);
  # cannot write file, so return error
  return 'req0000 ' . msg(505,$file,$!) . "\n" if $rc;

  # hash the disk file
  $self->hash($file);

  return;
  }

sub _inline_file
  {
  # given the file contents and it's name and a type (101 or 102), will create
  # a msg 111 or 112 (depending on $type) with the file contents inlined after
  # file name
  my ($self,$type,$txt,$file,$req_id, $res) = @_;

  # hash the memory contents of $txt
  my $hash = $self->hash( $file, 'target', \$txt);
  $txt = encode($txt);			# encode the file contents
  ($type, "$req_id $type $hash \"$file\" \"$txt\"\n" . $res, $file);
  }

sub _disk_file
  {
  # given the file contents and it's name and a type (101 or 102), will create
  # a msg 101 or 102 (depending on $type) and create/hash the file on disk
  # XXX TODO: clean up neccessary
  my ($self,$type,$txt,$file,$req_id,$res) = @_;

  my $rc = write_file($file,\$txt);

  # cannot write file, so return error
  return (-1, "$req_id " . msg(505,$file,$!) . "\n") if $rc;

  my $result;
  # hash the generated file
  my $hash = $self->hash($file);
  if (ref($hash))
    {
    # something went wrong (since the file is not present at server, it
    # won't be present at client, so this request will fail, anyway)
    return (-1, "$req_id " . msg(91,$file) . "\n");     # cannot find file
    }

  ($type, "$req_id $type $hash \"$file\"\n" . $res, $file);
  }

sub _create_file
  {
  # given the file contents and it's name and a type (101 or 102), will create
  # a msg 101, 102, 111 or 112 (depending on $type) with the file contents inlined after
  my ($self,$type,$txt,$file,$req_id,$res) = @_;

  # msg 101: persistent file (lives for lifetime of the job)
  # msg 102: temporary file (lives for one chunk-life-time)
  # msg 111: like 101, but inline
  # msg 112: like 102, but inline

  # XXX TODO: could check whether client supports msg 111 or 112
  return $self->_inline_file($type+10,$txt,$file,$req_id,$res) if 
    (length($txt) < 1024) &&
    ($NEVER_INLINE_FILES == 0);

  $self->_disk_file($type,$txt,$file,$req_id,$res);
  }

sub description_file
  {
  # Checks whether a chunk description file (CDF) or a job description file (JDF)
  # is necessary for the current chunk.
  # The C<$type> is either:
  #
  # 	101 or 111	a JDF was generated
  #	102 or 112	a CDF was generated
  #	undef		no CDF or JDF is necessary
  #	-1		an error occured
  #If C<$type> is defined and positive, the file has been generated, hashed and
  #the hash was stored. In that case C<$response> contains the response that
  #must be sent to the client, and C<$filename> is the file that was generated.
  #If C<$type> is negative, C<$response> will contain the error message.

  my ($self,$job,$chunk,$req_id) = @_;
  
  # check the conditions when we need a chunk/job description file
  my $needed = 0;
  my $charset = $job->{charset};
  my $target = $job->{target};

  # always necessary for these charsets  
  $needed ++ if $charset->type() =~ /^(extract|dictionary)$/;

  # a prefix also makes it necessary 
  my $prefix = $job->get('prefix') || '';
  $needed ++ if $prefix ne '';

  # extrafields in the jobtype also make this necessary
  my $jobtype = $job->{jobtype};

  $needed ++ if scalar $jobtype->extra_fieldnames() > 0;

  # some description file necessary?
  # a target file means we need to hash it, and return a response
  # (even if we don't write a description file!)
  return (undef,'',undef) unless $needed > 0 || -f $target;

  my $cfg = $self->{config};

  my $job_id = $job->{id};
  my $chunk_id;
  my $type = 101;			# default is a JDF
  if (defined $chunk)
    {
    $chunk_id = $chunk->{id};
    }
  else
    {
    # an undefined $chunk means this is a testcase:
    # XXX TODO: the CDF should always stay the same, so we could avoid
    # writing it more than once for testcases!
    # set to 0, so that testcase 1 (resulting in '1_0') never interferes
    # with job 1 (Jobs do not have chunks with number 0...)
    # We could set type to 102, so that the client deletes the file afterwards
    $chunk_id = 0;
    }

  my ($image_file, $dict_file);

  my $txt = '';
  if ($needed > 0)
    {
    $txt = "## This file was automatically generated. Do not edit.\n" .
	   "## This is a temporary file and can safely be deleted.\n" .
           "## Chunk description file for job $job_id, chunk $chunk_id.\n\n";

    $txt .= "charset_id=$job->{charset}->{id}\n";
    
    if (ref($charset) eq 'Dicop::Data::Charset::Dictionary')
      {
      # CDF for dictionary sets
      # XXX TODO: hash dictionary file and send it to client, too!
      # $dict_file = ....

      $type = 102;		# offset changes for each chunk!
      $txt .= 'dictionary_file_offset="' . $charset->offset(). "\n";
      $txt .= "dictionary_file=\"$charset->{file}\"\n";
      $txt .= "dictionary_stages=$charset->{stages}\n";
      $txt .= "dictionary_mutations=$charset->{mutations}\n";
      }
    elsif (ref($charset) eq 'Dicop::Data::Charset::Extract')
      {
      # CDF for extract sets
      # XXX TODO: the part of the image file needs to be created by the server
      # to allow the client downloading only this part - or alternatively, the
      # the client needs to download only one part of the big file (creating all
      # the parts would cause some overhead and file space issues)    

      $type = 102;		# file part changes for each chunk!
      $image_file = File::Spec->catfile ( '..', '..', 'target', 'images',
        "image_" . $job_id . '_' . $chunk_id . ".img");
      $txt .= "image_file=\"$image_file\"\n";
      $txt .= "image_type=0\n";
      $txt .= "extract_set_id=" . $charset->extract_set() . "\n";
      $txt .= 'start=' . $charset->get('minlen') . "\n";
      $txt .= 'end=' . $charset->get('maxlen') . "\n";
      }
    else
      {
      # JDF for normal charsets (changes not per chunk)
      $txt .= 'start=' . a2h($job->{start}) . "\n";
      $txt .= 'end=' . a2h($job->{end}) . "\n";
      }

    # the prefix/target only change on a per-job basis
    if ($prefix ne '')
      {
      $txt .= "password_prefix=$prefix\n";
      }
    if (-f $target)
      {
      # add '../..'; because the worker runs in worker/linux
      # but leave $target alone for later hashing
      $txt .= "target=../../$target\n";
      }
    else
      {
      # add target as hex
      $txt .= "target=$target\n";
      }

    ###########################################################################
    # include extra params if necessary (these do not change per-chunk!):

    $txt .= $job->extra_fields();

    } #endif $needed > 0

  my $res = '';
  # if the target is a file, append hash for the client 
  my $files = { $target => 101 };
  $files->{$dict_file} = 101 if defined $dict_file;
  # XXX TODO: the image file changes from chunk to chunk (does it?)
  $files->{$image_file} = 102 if defined $image_file;
  for my $f (sort keys %$files)
    {
    if (defined $f && -f $f)
      {
      # for existing files, append hash for it. Msg 101 or 102, depending on file
      $res .= $self->hash_file($f,undef,$files->{$f});
      }
    }

  # have target file, but don't need a description file
  return (undef,$res,undef) if $needed == 0;

  ###########################################################################
  # write file to disk or create it inline, if nec.
  
  # if the file changes with each chunk, make the name unique
  my $name_prefix = ''; $name_prefix = "-$chunk_id" if $type == 102;
  my $ext = '.txt'; $ext = '.set' if $type == 101;

  my $file = File::Spec->catfile ( $cfg->{target_dir}, 'data', $job_id,  
   "$job_id$name_prefix$ext");

  # create the file on disk or inline, return the appropriate msg for the client
  $self->_create_file($type,$txt,$file,$req_id,$res);
  }

1; 

__END__

#############################################################################

=pod

=head1 NAME

Dicop::Data - Files.pm -- routines to create target/charset/chunk files

=head1 SYNOPSIS

	use Dicop::Data;

	# only used internally by Dicop::Data! 

=head1 REQUIRES

perl5.005, Dicop::Base, Dicop::Hash, Dicop::Event

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

Contains routines that write/create files like the charsets.def file. These
files are downloaded by the client and used by the workers.

=head1 METHODS

=head2 write_charsets_def

Whenever the character sets change, this routine will generate a file that
contains all the character sets. This file is checked and updated (downloaded)
by the client and then used by all the workers.

It is automatically called when you add or modify a character set, or when
the file (that would be generated) does not exist.

The default filename is C<worker/charsets.def> and can be changed in
C<server.cfg>.

=head2 description_file
  
	($type,$response,$filename) = $self->description_file
	 ($job, $chunk, $request_id);

Checks whether a chunk description file (CDF) or a job description file (JDF)
is necessary for the current chunk.

The C<$type> is either:

	101 or 111	a JDF was generated
	102 or 112	a CDF was generated
	undef		no CDF or JDF is necessary
	-1		an error occured

If C<$type> is defined and positive, the file has been generated, hashed and
the hash was stored. In that case C<$response> contains the response that
must be sent to the client, and C<$filename> is the file that was generated.

If C<$type> is negative, C<$response> will contain the error message.

If C<$type> is undef, no CDF or JDF was created. C<$response> might still
contain a response sent to the client, for instance if the job has a target
file which was hashed and needs to be sent to the client.

=head2 _create_file

	$self->_create_file($type,$txt,$filename);

Given the file contents in C<$txt> and it's name in C<$filename> and a type
(101 or 102), will create # a msg 101, 102, 111 or 112 (depending on $type).

When the file contents are smaller than a certain limit, it will inline the
file contents into the message (type 111 or 112), otherwise it will 
write the file to disk.

=head1 BUGS

Please see the L<BUGS> file.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

