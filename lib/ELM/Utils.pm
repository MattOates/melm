package ELM::Utils v1.4.1;
require Exporter;
=encoding UTF-8
=head1 NAME

ELM::Utils - Common helper functions

=head1 VERSION

Version v1.4.1

=cut

use v5.20.0;
use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_www);

use LWP::UserAgent;

=head1 SYNOPSIS

This module exports common helper functions

=head1 FUNCTIONS

=head2 get_www

Get the source of a webpage

=cut
sub get_www($url) {
    if (not eval { require LWP::UserAgent }) {
        say STDERR "On first execution and when updating melm requires your Perl installation to have LWP::UserAgent to contact ELM servers for data.";
        say STDERR "You might be able to install this module using `cpanm -i LWP::UserAgent`.";
        say STDERR "Another alternative is to download the latest ELM data from the melm repository at: https://raw.githubusercontent.com/MattOates/melm/master/.elm.dat";
        say STDERR "Place the .elm.dat file into your home directory: /Users/username (OSX), /home/username (Linux) or C:\\Users\\username (Windows)";
        exit 1;
    }
    if ($url =~ /^https/ and not eval { require LWP::Protocol::https }) {
        say STDERR 'Sorry $url requires HTTPS support and your Perl does not have LWP::Protocol::https installed.';
        say STDERR 'Try `cpanm -i LWP::Protocol::https` to install this module.';
        say STDERR 'If you are running this code from an official release distribution please raise a GitHub issue.';
        exit 1;
    }
    #Decided to localise this and just handle checking for deps properly
    my $ua = LWP::UserAgent->new;

    my $response = $ua->get($url);
    if ($response->is_success) {
       return $response->decoded_content;
    } else {
        die "Failed whilst contacting $url: " . $response->status_line;
    }
}

=head1 AUTHOR

Matt Oates, C<< <mattoates at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<mattoates@gmail.com>, or through
GitHub issues at L<https://github.com/MattOates/melm/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ELM::Utils


You can also look for information at:

=over 4

=item * GitHub L<https://github.com/MattOates/melm>

=back


=head1 ACKNOWLEDGEMENTS

Please make sure to cite the original ELM authors when using mELM results:
    Holger Dinkel, Kim Van Roey, Sushama Michael, Norman E. Davey, 
    Robert J. Weatheritt, Diana Born, Tobias Speck, Daniel Krüger, 
    Gleb Grebnev, Marta Kubań, Marta Strumillo, Bora Uyar, 
    Aidan Budd, Brigitte Altenberg, Markus Seiler, Lucía B. Chemes,
    Juliana Glavina, Ignacio E. Sánchez, Francesca Diella, 
    and Toby J. Gibson (2014)
    The eukaryotic linear motif resource ELM: 10 years and counting
    Nucl. Acids Res. 42(D1): D259-D266 
    doi:10.1093/nar/gkt1047

If you have used mELM with ANCHOR predictions please cite the following:
    Bálint Mészáros, István Simon and Zsuzsanna Dosztányi (2009) 
    Prediction of Protein Binding Regions in Disordered Proteins
    PLoS Comput Biol 5(5): e1000376. 
    doi:10.1371/journal.pcbi.1000376

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Matt Oates.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


=cut

1;