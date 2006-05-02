#############################################################################
# Dicop/Data/User.pm - an administrator account
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Data::User;
use vars qw($VERSION);
$VERSION = 1.02;	# Current version of this package
require  5.005;		# requires this Perl version or later

use base qw(Exporter Dicop::Item);
use strict;

1;

__END__
#############################################################################

=pod

=head1 NAME

Dicop::Data::User - an administrator account

=head1 SYNOPSIS

    use Dicop::Data::User;

    $user = Dicop::Data::User->new( { name => 'me', pwdhash => '0123..45' });

=head1 REQUIRES

perl5.005, Exporter, Dicop::Item

=head1 EXPORTS

Exports nothing on default.

=head1 DESCRIPTION

For a description of fields a user has, see C<doc/Objects.pod>.

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

