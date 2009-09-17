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

our $VERSION = '0.01';

__PACKAGE__->mk_classdata(qw/_session_redis_storage/);
__PACKAGE__->mk_classdata(qw/_session_redis_expires/);

sub get_session_data {
    my ($c, $key) = @_;

    $c->log->error('get: '.$key);
    if(my ($sid) = $key =~ /^expires:(.*)/) {

        # return $c->_session_redis_storage->get($key);
        my $ttl = $c->_session_redis_storage->ttl('session:'.$sid);
        $c->log->error("get expire for $key ($sid) = $ttl");
        return time;
    } else {
        my $data = $c->_session_redis_storage->get($key);
        if(defined($data)) {
            return thaw( decode_base64($data) )
        }
    }

    return;
}

sub store_session_data {
    my ($c, $key, $data) = @_;

    $c->log->error("set: $key : $data");
    if(my ($sid) = $key =~ /^expires:(.*)/) {
        my $ttl = $data - time;
        $c->log->error("set expire for $sid ($ttl)");
        $c->_session_redis_storage->expire('session:'.$sid, $ttl);
        # $c->_session_redis_storage->set($sid, $data);
    } else {
        $c->_session_redis_storage->set($key, encode_base64(nfreeze($data)));
    }

    return;
}

sub delete_session_data {
    my ($c, $sid) = @_;

    $c->log->error('del: '.$sid);
    $c->_session_redis_storage->del($sid);
}

sub setup_session {
    my ($c) = @_;

    $c->maybe::next::method(@_);

    $c->_session_redis_storage(
        Redis->new(server => '127.0.0.1:6379', debug => 1)
    );
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
