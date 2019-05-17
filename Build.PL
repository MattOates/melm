use strict;
use warnings;
use Module::Build;
 
use 5.008;


my $builder = Module::Build->new(
    module_name         => 'ELM',
    license             => 'lgpl_3',
    dist_author         => 'Matt Oates <mattoates@gmail.com>',
    dist_abstract       => 'CLI tool for assigning Eukaryotic Linear Motifs from the ELM.eu.org database',
    create_makefile_pl  => 0,     #'traditional',
    script_files        => 'bin/melm',
    create_readme       => 0,
    requires            => {
        'LWP::UserAgent' => '6.15',
        'BioPerl'        => '1.7.2',
        'Class::Tiny'    => '1.004',
        'Pod::Usage'     => '1.69'
    },
    build_requires      => {
        'Test::More'                      => '0.47',
        'Test::Pod::Coverage'             => '1.10',
        'Test::Pod'                       => '1.51',
        'Devel::Cover'                    => '1.23',
        'Devel::Cover::Report::Coveralls' => '0.11'
    },
);
 
$builder->create_build_script();

