package ELM::Calc v1.4.3;
require Exporter;
=encoding UTF-8
=head1 NAME

ELM::Calc - Functions for calculating sequence assignment specific tasks

=head1 VERSION

Version v1.4.3

=cut

use v5.20.0;
use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(coverage any_overlap runencode);

=head1 SYNOPSIS

This module exports functions for calculating common sequence assignment tasks

=head1 FUNCTIONS

=head2 coverage

Efficiently calculate the coverage between two number line segments

=cut
sub coverage($a, $b, $x, $y) {
    return max(min((1+$b-$a),(1+$y-$x),(1+abs($b-$a)+abs($y-$x))-(max($a,$b,$x,$y)-min($a,$b,$x,$y))),0);
}

=head2 any_overlap

Report if there is any overlap between a single defined region and a set of regions

=cut
sub any_overlap($start, $end, $pairs) {
    foreach my $pair (@$pairs) {
        return 1 if coverage($start,$end,$pair->[0],$pair->[1]);
    }
    return 0;
}

=head2 runencode

Take an arrayref of numbers or a delimited string and returns a list of start-end pairs for runs of values above a threshold

=cut
sub runencode($probs, %opts) {

        unless (defined $probs) {
            warn "undef passed to runencode!";
            return;
        }

        #Some default optional parameters
        $opts{delimiter} //= ','; 
        $opts{threshold} //= 0.5;
        $opts{cmp} //= sub {$_[0] >= $_[1]};

        #If a string was passed split it into values
        $probs = [split /$opts{delimiter}/, $probs] if (ref $probs ne 'ARRAY');
        my @ranges = ();
        my $index = 1;
        my $start = undef;
        my $end = undef;

        foreach my $prob (@$probs) {
                if ($opts{cmp}->($prob, $opts{threshold})) {
                        $start = $index unless defined $start;
                } else {
                        $end = $index-1;
                        push @ranges, [$start, $end] if defined $start;
                        $start = undef;
                }
                $index++;
        }

        #Deal with the edge case where there is a region at the end of the sequence
        if ($probs->[-1] >= 0.5) {
                        $end = $index-1;
                        push @ranges, [$start, $end] if defined $start;
        }

        return \@ranges;
}

=head1 AUTHOR

Matt Oates, C<< <mattoates at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<mattoates@gmail.com>, or through
GitHub issues at L<https://github.com/MattOates/melm/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ELM::Calc


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

Copyright 2022 Matt Oates.

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