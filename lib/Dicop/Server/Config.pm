#############################################################################
# Dicop::Server::Config - define valid config keys
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 2003-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Server::Config;
use vars qw($VERSION);
$VERSION = 0.05;	# Current version of this package
require  5.008;		# requires this Perl version or later

use strict;

sub allowed_keys
  {
  # setup the allowed keys and their type

  my $ALLOWED_KEYS = {};
  foreach my $key (qw/ 
   hand_out_work background
   verify_solved_chunks_with_trusted
   /)
    { $ALLOWED_KEYS->{$key} = 'flag'; }

  foreach my $key (qw/ 
   flush
   min_chunk_size
   max_chunk_size
   resend_test
   /)
    { $ALLOWED_KEYS->{$key} = 'minutes'; }

  foreach my $key (qw/ 
   max_request_time
   initial_sleep
   /)
    { $ALLOWED_KEYS->{$key} = 'seconds'; }


  foreach my $key (qw/ 
   client_check_time
   client_offline_time
   /)
    { $ALLOWED_KEYS->{$key} = 'hours'; }

  foreach my $key (qw/ 
   chroot
   charset_definitions
   charsets_list
   clients_list
   client_architectures
   allow_admin allow_status allow_stats allow_work
   deny_admin deny_status deny_stats deny_work
   default_style
   error_log
   groups_list
   group
   host
   proto
   jobs_list
   cases_list
   jobtypes_list
   log_level
   msg_file
   name
   objects_def_file
   patterns_file
   proxies_list
   results_list
   server_log
   testcases_list
   title
   users_list
   user
   /)
    { $ALLOWED_KEYS->{$key} = 'string'; }
  
  foreach my $key (qw/ 
   mail_admin
   mail_from
   mail_to
   mail_errors
   /)
    { $ALLOWED_KEYS->{$key} = 'email'; }
  
  foreach my $key (qw/ 
   self
   file_server
   mail_server
   send_event_url_format
   case_url_format
   /)
    { $ALLOWED_KEYS->{$key} = 'URL'; }

  foreach my $key (qw/ 
   port
   verify_every_done_chunk
   verify_done_chunks
   verify_solved_chunks
   verify_trusted_done_chunks
   verify_trusted_solved_chunks
   reference_client_id
   minimum_rank_percent
   require_client_version
   require_client_build
   max_requests
   debug_level
   /)
    { $ALLOWED_KEYS->{$key} = 'int'; }

  foreach my $key (qw/ 
   log_dir def_dir msg_dir tpl_dir data_dir worker_dir
   target_dir mailtxt_dir eventtxt_dir
   scripts_dir
   /)
    { $ALLOWED_KEYS->{$key} = 'dir'; }

  # obsolete keys
  foreach my $key (qw/
    is_proxy
    /) 
    { $ALLOWED_KEYS->{$key} = undef; }

  $ALLOWED_KEYS;
  }

1; 

__END__

#############################################################################

=pod

=head1 NAME

Dicop::Server::Config - define valid config keys

=head1 SYNOPSIS

	use Dicop::Server::Config;
	use Dicop::Config;

	my $config = Dicop::Config->new('data/server.cfg', Dicop::Server::Config::allowed_keys() );

=head1 REQUIRES

perl5.008

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

This module contains a method to create the list of allowed config keys.

=head1 METHODS

=head2 allowed_keys()

	$allowed_keys = Dicop::Server::Config::allowed_keys();

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 2003-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

