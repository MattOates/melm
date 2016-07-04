use warnings;
use strict;
use autodie;
use feature 'say';
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec;

use Test::More tests => 5;

BEGIN {
    use_ok( 'ELM::Library' ) || say 'Bailing out, cannot find main ELM Library in the path';
}

diag( "Testing ELM::Library $ELM::Library::VERSION, Perl $], $^X" );

#Tests written for the 1.4.X API
like $ELM::Library::VERSION, qr/^v1.4/, 'We are testing the 1.4 API';

#Use the local distribution ELM data
my $lib = ELM::Library->new(elm_lib_path => File::Spec->catfile(dirname(abs_path(__FILE__)), '..', '.elm.dat'));

isa_ok $lib, 'ELM::Library', 'Managed to instantiate a library object';

ok $lib->classes_version eq '1.4', 'Parsed the classes version correctly';

ok $lib->instances_version eq '1.4', 'Parsed the instances version correctly';
