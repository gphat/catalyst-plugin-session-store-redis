# NAME

Catalyst::Plugin::Session::Store::Redis - Redis Session store for Catalyst

# SYNOPSIS

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

# DESCRIPTION

`Catalyst::Plugin::Session::Store::Redis` is a session storage plugin for
Catalyst that uses the Redis ([http://redis.io](http://redis.io)) key-value
database.

# CONFIGURATION

By default it will use 127.0.0.1:6379 as server, and enables autoreconnect after 60 if the connection fails. In addition
you can use any configuration parameter of `Redis` prefixing "redis\_"  in the hash under the `Plugin::Session`

# WARNING

This module is currently untested, outside of the unit tests it ships with.
It will eventually be used with a busy site, but is currently unproven.
Patches are welcome!

# AUTHORS

Cory G Watson, `<gphat at cpan.org>`
Yusuke Watase
luma
Gerard Ribugent Navarro << &lt;ribugent at cpan.org> a>>

# COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
