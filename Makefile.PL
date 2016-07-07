use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'ELM',
    AUTHOR           => q{Matt Oates <mattoates@gmail.com>},
    VERSION_FROM     => 'lib/ELM.pm',
    ABSTRACT_FROM    => 'lib/ELM.pm',
    LICENSE          => 'lgpl_3',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.020,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'ELM-*' },
);
