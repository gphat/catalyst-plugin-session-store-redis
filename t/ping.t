#/usr/bin/env perl
#===============================================================================
#Last Modified:  2014/09/03
#===============================================================================
use strict;
use warnings;
use Test::More;
use Redis;

unless ($ENV{SESSION_STORE_REDIS_PING} ) {
    plan skip_all => 'Must set SESSION_STORE_REDIS_PING environment variable';
}
eval { require Test::RedisServer }
    or plan skip_all => "Test requires 'Test::RedisServer'";
eval { require Net::EmptyPort }
    or plan skip_all => "Test requires 'Net::EmptyPort'";

my $redis_server = eval { Test::RedisServer->new(
        conf => {
            port    => Net::EmptyPort::empty_port(),
            timeout => 1,
        }
    ) }
    or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;
$connect_info{server} =~ s/0\.0\.0\.0/localhost/;

{
    package RedisTimeoutTest;
    use Catalyst qw/Session Session::Store::Redis Session::State::Cookie/;
    RedisTimeoutTest->config(
        'Plugin::Session' => {
            expires => 20,
            redis_server => $connect_info{server},
        });
    RedisTimeoutTest->setup;
}

my $c = RedisTimeoutTest->new;
$c->session;
my $sid = $c->sessionid;
$c->store_session_data($sid, { key => 456});
sleep 2;
my $res = eval { $c->get_session_data($sid)->{key} } ;
$res = $@ if $@;
is (456, $res, 'reconnect');
done_testing;
