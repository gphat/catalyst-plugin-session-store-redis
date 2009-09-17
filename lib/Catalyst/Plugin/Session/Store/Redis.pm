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

    $c->_verify_redis_connection($c);

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

    $c->_verify_redis_connection($c);

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

    $c->_verify_redis_connection($c);

    $c->log->error("Deleting: $key");
    $c->_session_redis_storage->del($key);

    return;
}

sub setup_session {
    my ($c) = @_;

    $c->maybe::next::method(@_);

    $c->_session_redis_storage(
        Redis->new(server => '127.0.0.1:6379', debug => 0)
    );
}

sub _verify_redis_connection {
    my ($self, $c) = @_;

    try {
        $c->_session_redis_storage->ping;
    } catch {
        $self->_session_redis_storage(
            Redis->new(server => '127.0.0.1:6379', debug => 0)
        );
    };
}

1;

__END__

=head1 NAME

Catalyst::Session::Store::Redis - The great new Catalyst::Session::Store::Redis!

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Catalyst::Session::Store::Redis;

    my $foo = Catalyst::Session::Store::Redis->new();
    ...

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
