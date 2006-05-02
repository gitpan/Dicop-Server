#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 13;
  }

use Dicop::Event;

use Dicop::Config;
use Dicop::Server::Config;

Dicop::Event::load_messages('../msg/messages.txt');

my $class = 'Dicop::Server::Config';

#############################################################################
# should fail

my $cfg = new Dicop::Config ( 'test.cfg' );

my $allowed = Dicop::Server::Config->allowed_keys();

my $msg = $cfg->check($allowed);

is ($msg, "801 Key 'blah' invalid (typo?) in 'test.cfg' at line 2", 'key "blah" not allowed');

#############################################################################
# should fail w/ 804

$cfg = new Dicop::Config ( 'test2.cfg' );

$allowed = Dicop::Server::Config->allowed_keys();

$msg = $cfg->check($allowed);

is ($msg, "804 Key 'is_proxy' obsolete (remove it?) in 'test2.cfg' at line 4", 'is_proxy is obsolete');

#############################################################################
# should pass since the delivered sample config *should* be ok

$cfg = new Dicop::Config ( '../config/server.cfg.sample' );
# check that calling it via -> works, too
$msg = $cfg->check($allowed);

is ($msg, undef, 'no error');

is ($cfg->type('flush'), 'minutes' );
is ($cfg->type('check_clients'), undef );
is ($cfg->type('check_offline_time'), undef );
is ($cfg->type('background'), 'flag' );

is ($cfg->type('mail_server'), 'URL' );
is ($cfg->type('file_server'), 'URL' );
is ($cfg->type('self'), 'URL' );

is ($cfg->type('mail_from'), 'email' );
is ($cfg->type('mail_to'), 'email' );

is ($cfg->type('initial_sleep'), 'seconds' );

1; # EOF

