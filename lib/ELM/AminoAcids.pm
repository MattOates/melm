package ELM::AminoAcids v1.4.3;
require Exporter;
=encoding UTF-8
=head1 NAME

ELM::AminoAcids - Functions for dealing with amino acid specific calculations

=head1 VERSION

Version v1.4.3

=cut

use v5.20.0;
use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(amino_prob score);

#Amino acids probabilities used for expect scoring, calculated from looking at all eukaryotic sequences in the SUPERFAMILY database.
my %amino_probs = ('A' => 0.074253,
                   'C' => 0.009697,
                   'D' => 0.050147,
                   'E' => 0.089011,
                   'F' => 0.018359,
                   'G' => 0.073955,
                   'H' => 0.025784,
                   'I' => 0.026977,
                   'K' => 0.061170,
                   'L' => 0.073093,
                   'M' => 0.019150,
                   'N' => 0.033851,
                   'P' => 0.094297,
                   'Q' => 0.056396,
                   'R' => 0.063802,
                   'S' => 0.104119,
                   'T' => 0.059547,
                   'V' => 0.045399,
                   'W' => 0.006850,
                   'Y' => 0.014141);

#Ambiguous amino acids are just as expected as the combination they represent
$amino_probs{B} = $amino_probs{N} + $amino_probs{D};
$amino_probs{Z} = $amino_probs{E} + $amino_probs{Q};
$amino_probs{J} = $amino_probs{I} + $amino_probs{L};

#Probability of an amino acid given an amino acid, maximum confusion minimum self information
$amino_probs{X} = 1.0;

=head1 SYNOPSIS

This module exports functions related to amino acid specific calculation

=head1 FUNCTIONS

=head2 amino_prob

Get the amino acid probability

=cut
sub amino_prob($amino) {
    if (exists $amino_probs{$amino}) {
        return $amino_probs{$amino};
    } else {
        warn "Amino acid not found: $amino";
        #Magic number, aa character is almost 0 probability, this should perhaps be 1.0 to ignore weird characters
        return 4.94065645841247e-324; 
    }
}

=head2 score

Get the scores for a whole amino acid sequence

=cut
sub score($sequence) {
    #my @aminos = unpack 'C*', $sequence;
    warn "Sequence was empty" and return (0.0,0.0) if $sequence eq '';
    my @aminos = split //, $sequence;
    my $a = shift(@aminos);
    while ($a eq 'U' or $a eq 'O') { $a = shift(@aminos); }
    my $prob = amino_prob($a);
    my $log = log(2.0);
    my $entropy = $prob * (log(1/$prob)/$log);
    #$prob *= amino_prob($_) for @aminos;
    foreach my $amino (@aminos) {
        if ( (uc $amino eq 'U') or (uc $amino eq 'O') ) { next; }
        $prob *= amino_prob($amino);
        $entropy += amino_prob($amino) * (log(1.0/amino_prob($amino))/$log);
    }
    
    return ($prob,$entropy,$entropy / length $sequence);
}

=head1 AUTHOR

Matt Oates, C<< <mattoates at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<mattoates@gmail.com>, or through
GitHub issues at L<https://github.com/MattOates/melm/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ELM::AminoAcids


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

Copyright 2019 Matt Oates.

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