use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Session::Store::Redis',
    AUTHOR              => q{Cory G Watson <gphat@cpan.org>},
    VERSION_FROM        => 'lib/Catalyst/Session/Store/Redis.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Session/Store/Redis.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Session-Store-Redis-*' },
);
