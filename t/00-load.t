#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Session::Store::Redis' );
}

diag( "Testing Catalyst::Session::Store::Redis $Catalyst::Session::Store::Redis::VERSION, Perl $], $^X" );
