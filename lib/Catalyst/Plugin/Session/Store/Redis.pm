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

our $VERSION = '0.10';

__PACKAGE__->mk_classdata(qw/_session_redis_storage/);

sub get_session_data {
    my ($c, $key) = @_;

    $c->_verify_redis_connection;

    if(my ($sid) = $key =~ /^expires:(.*)/) {
        $c->log->debug("Getting expires key for $sid") if $c->debug;
        return $c->_session_redis_storage->get($key);
    } else {
        $c->log->debug("Getting $key") if $c->debug;
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
        $c->log->debug("Setting expires key for $sid: $data") if $c->debug;
        $c->_session_redis_storage->set($key, $data);
    } else {
        $c->log->debug("Setting $key") if $c->debug;
        $c->_session_redis_storage->set($key, encode_base64(nfreeze($data)));
    }

    my $exp = $c->session_expires;
    my $duration = $exp - time;
    $c->_session_redis_storage->expire($key, $duration);
    return;
}

sub delete_session_data {
    my ($c, $key) = @_;

    $c->_verify_redis_connection;

    $c->log->debug("Deleting: $key") if $c->debug;
    $c->_session_redis_storage->del($key);

    return;
}

sub delete_expired_sessions {
    my ($c) = @_;

    # Null op, Redis handles this for us!
}

sub setup_session {
    my ($c) = @_;

    $c->maybe::next::method(@_);

    $c->_verify_redis_connection;
}

sub _verify_redis_connection {
    my ($c) = @_;

    my $cfg = $c->_session_plugin_config;

    try {
        $c->_session_redis_storage->ping or die "failed to ping";
    } catch {
        # Exract redis options
        my %redisCfg = map {
            (my $k = $_) =~ s/^redis_//;
            ($k => $cfg->{$_})
        } grep{ $_ =~ m/^redis_/ } keys %$cfg;

        $redisCfg{server} ||= '127.0.0.1:6379' if (!exists $redisCfg{sock});
        $redisCfg{debug} ||= 0;
        $redisCfg{redis_reconnect} ||= 60;


        $c->_session_redis_storage(
            Redis->new(%redisCfg)
        );
    };
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Session::Store::Redis - Redis Session store for Catalyst

=head1 SYNOPSIS

    use Catalyst qw/
        Session
        Session::Store::Redis
        Session::State::Foo
    /;

    MyApp->config->{Plugin::Session} = {
        expires => 3600,
        redis_server => '127.0.0.1:6379',
        redis_debug => 0, # or 1!
        redis_reconnect => 60 # 60 is default
    };

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::Redis> is a session storage plugin for
Catalyst that uses the Redis (L<http://redis.io>) key-value
database.

=head1 CONFIGURATION

By default it will use 127.0.0.1:6379 as server, and enables autoreconnect after 60 if the connection fails. In addition
you can use any configuration parameter of C<Redis> prefixing "redis_"  in the hash under the C<Plugin::Session>


=head1 WARNING

This module is currently untested, outside of the unit tests it ships with.
It will eventually be used with a busy site, but is currently unproven.
Patches are welcome!

=head1 AUTHORS

Cory G Watson, C<< <gphat at cpan.org> >>
Yusuke Watase
luma
Gerard Ribugent Navarro << <ribugent at cpan.org> a>>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
