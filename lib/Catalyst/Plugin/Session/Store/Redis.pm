package Catalyst::Plugin::Session::Store::Redis;
use warnings;
use strict;

use base qw/
    Class::Data::Inheritable
    Catalyst::Plugin::Session::Store
/;
use MRO::Compat;
use MIME::Base64 qw(encode_base64 decode_base64);
use Redis;
use Storable qw/nfreeze thaw/;
use Try::Tiny;

our $VERSION = '0.01';

__PACKAGE__->mk_classdata(qw/_session_redis_storage/);

sub get_session_data {
    my ($c, $key) = @_;

    $c->_verify_redis_connection;

    if(my ($sid) = $key =~ /^expires:(.*)/) {
        $c->log->debug("Getting expires key for $sid");
        return $c->_session_redis_storage->get($key);
    } else {
        $c->log->debug("Getting $key");
        my $data = $c->_session_redis_storage->get($key);
        if(defined($data)) {
            return thaw( decode_base64($data) )
        }
    }

    return;
}

sub store_session_data {
    my ($c, $key, $data) = @_;

    $c->_verify_redis_connection;

    if(my ($sid) = $key =~ /^expires:(.*)/) {
        $c->log->debug("Setting expires key for $sid");
        $c->_session_redis_storage->set($key, $data);
    } else {
        $c->log->debug("Getting $key");
        $c->_session_redis_storage->set($key, encode_base64(nfreeze($data)));
    }

    return;
}

sub delete_session_data {
    my ($c, $key) = @_;

    $c->_verify_redis_connection;

    $c->log->debug("Deleting: $key");
    $c->_session_redis_storage->del($key);

    return;
}

sub delete_expired_sessions {
    my ($c) = @_;

    $c->_verify_redis_connection;

    $c->log->debug("Deleting expired session.");
    my @expires = $c->_session_redis_storage->keys('expires:*');
    my $now = time;
    foreach my $exp (@expires) {
        my $time = $c->_session_redis_storage->get($exp);
        if($time < $now) {
            $c->_session_redis_storage->del($exp);
        }
    }
}

sub setup_session {
    my ($c) = @_;

    $c->maybe::next::method(@_);

    my $cfg = $c->_session_plugin_config;

    $c->_session_redis_storage(
        Redis->new(
            server => $cfg->{redis_server} || '127.0.0.1:6379',
            debug => $cfg->{redis_debug} || 0
        )
    );
}

sub _verify_redis_connection {
    my ($c) = @_;

    my $cfg = $c->_session_plugin_config;

    try {
        $c->_session_redis_storage->ping;
    } catch {
        $c->_session_redis_storage(
            Redis->new(
                server => $cfg->{redis_server} || '127.0.0.1:6379',
                debug => $cfg->{redis_debug} || 0
            )
        );
    };
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Session::Store::Redis - The great new Catalyst::Plugin::Session::Store::Redis!

=head1 SYNOPSIS

    use Catalyst qw/
        Session
        Session::Store::Redis
        Session::State::Foo
    /;
    
    MyApp->config->{Plugin::Session} = {
        expires => 3600,
        redis_server => '127.0.0.1:6379',
        redis_debug => 0 # or 1!
    };

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::Redis> is a session storage plugin for
Catalyst that uses the Redis (L<http://code.google.com/p/redis/>) key-value
database.

=head1 NOTES

=over 4

=item B<Expired Sessions>

This store does B<not> automatically expire sessions.  You can call
C<delete_expired_sessions> to clear any expired sessions.  All sessions will
then be checked, one at a time.  If a session has expired then it will be
deleted.

=back

=head1 WARNING

This module is currently untested, outside of the unit tests it ships with.
It will eventually be used with a busy site, but is currently unproven.
Patches are welcome!

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
