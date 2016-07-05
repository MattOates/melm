#!/usr/bin/env perl
use v5.20.0;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

pod_coverage_ok('ELM', {trustme => [
					qr/num_elms_threshold/,
				    qr/type/,
				    qr/max_class_expect/,
				    qr/min_elm_complexity/,
				    qr/morf_filter/,
				    qr/disorder_filter/,
				    qr/logic_filter/,
				    qr/library/,
				    qr/anchor/,
	    ]}, 'ELM well documented');

pod_coverage_ok('ELM::Library', {trustme => [
					qr/elms/,
					qr/elm_lib_path/,
					qr/instances_version/,
					qr/classes_version/,
		]}, 'ELM::Library well documented');

pod_coverage_ok('ELM::Anchor', {trustme => [
					qr/anchor_datapath/,
		]}, 'ELM::Anchor well documented');

pod_coverage_ok('ELM::AminoAcids', 'ELM::AminoAcids well documented');

pod_coverage_ok('ELM::Calc', 'ELM::Calc well documented');

pod_coverage_ok('ELM::Utils', 'ELM::Utils well documented');

done_testing();
