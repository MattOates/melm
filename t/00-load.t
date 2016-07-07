#!/usr/bin/env perl
use v5.20.0;
use strict;
use warnings;
use autodie;
use feature 'say';
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec;

use Test::More tests => 2;

BEGIN {
	use_ok( 'ELM' ) || say 'Bailing out, cannot find ELM in the path';
}

diag( "Testing ELM $ELM::VERSION, Perl $], $^X" );

#Tests written for the 1.4.X API
like $ELM::VERSION, qr/^v1.4/, 'We are testing the 1.4 API';