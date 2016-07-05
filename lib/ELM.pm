package ELM v1.4.1;
=encoding UTF-8
=head1 NAME

ELM - Class to do analysis with the ELM regex library

=head1 VERSION

Version v1.4.1

=cut

use v5.20.0;
use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';

use ELM::Library;
use ELM::Utils;
use ELM::Anchor;
use ELM::AminoAcids;
use ELM::Calc 'runencode';

use Class::Tiny qw/num_elms_threshold type max_class_expect min_elm_complexity morf_filter disorder_filter logic_filter/, { 
	library => sub { ELM::Library->new() },
	anchor => sub { ELM::Anchor->new() },
};

=head1 SYNOPSIS

This class is responsible for all high level analysis that can be performed with ELM

    use ELM;

    my $elm = ELM->new();
    ...

=head1 METHODS

=head2 assign_elm

Assign a single ELM class to a given sequence

=cut
sub assign_elm($self, $elm, $seq, %opt) {
	my $anchor = $opt{morf_filter} || $opt{disorder_filter};

	#Handle any disorder/morf prediction
	my ($morf_regions, $dis_regions, $iupred);
    if ($anchor) {
        ($morf_regions, $anchor, $iupred) = $self->anchor->assign($seq->seq);
        $dis_regions = runencode($iupred);
    }

    return $self->assign($elm, $self->library->elms->{$elm}{regex}, $seq->seq, $morf_regions, $dis_regions);
}

=head2 assign_all_elms

Assign all ELM classes given filter options to a sequence

=cut
sub assign_all_elms($self, $seq, %opt) {
	my $max_class_expect = $opt{max_class_expect};
	my $type = $opt{type};

	my @assignment;
    foreach my $elm (keys $self->library->elms->%*) {

    	#Ignore those ELM classes that are below the user defined probability threshold
		if ($max_class_expect) {
		    next if $self->library->elms->{$elm}{probability} >= $max_class_expect;
		}

		#Ignore all the ELM classes but the type requested
		if ($type) {
		    next if $self->library->elms->{$elm}{type} ne $type;
		}

        push @assignment, assign_elm($elm, $seq->seq, %opt);
    }

    return @assignment;
}

=head2 assign

Take a regular expression and return all of the ([start,end,substr]...) matched results

=cut
sub assign($self, $elm_name, $regex, $string, $morf_regions, $dis_regions) {
    my @ret;
    my ($start,$end,$seq,$prob,$entropy,$entrorate);
    while ($string =~ /($regex)/g) {
        ($start,$end,$seq) = ($-[0]+1, $+[0], $&);
        if ($self->logic_filter) {
            next unless $self->_logic_filter_ok($elm_name,$seq,logic => $self->logic_filter);
        }
        ($prob, $entropy, $entrorate) = score($seq);
        if ($self->max_elm_probability) {
            next if $prob > $self->max_elm_probability;
        }
        if ($self->min_elm_complexity) {
            next if $entrorate < $self->min_elm_complexity;
        }
        if ($self->morf_filter) {
            next unless any_overlap($start,$end,$morf_regions);
        }
        if ($self->disorder_filter) {
            next unless any_overlap($start,$end,$dis_regions);
        }
        push @ret, [$elm_name, $start, $end, $seq, $prob, $entropy, $entrorate];
    }
    if (@ret < 1) {
        return;
    } else {
        return \@ret;
    }
}

=head2 collapse_assignment

Collapse multiple assignments into a single list of disjoint ([start,end]...) and per residue counts of collapsed data

=cut
sub collapse_assignment($self,$sequence,$assignments,%opt) {

    #Create a list of assignment counts per residue
    my @ass = (0) x length $sequence;
    foreach my $motif (map {@$_} @$assignments) {
        $ass[$_-1]++ for $motif->[1]..$motif->[2];
    }

    #Invert the assignment counts, i.e. mark everything that wasn't asigned as being assigned
    #so [5,3,2,1,1,1,2,0,0,3] becomes [0,0,0,0,0,0,0,1,1,0]
    if ($opt{invert}) {
        $_ = abs +($_ >= 1) - 1 for @ass;
    }

    #Runlength encode the assignment flags to get paired assignments again
    #return (\runencode(\@ass), \@ass);
    return runencode(\@ass, threshold => $self->num_elms_threshold);
}

=head2 mask

Mask a string hard/soft based on a list of start,end pairs [[start,end],...]

=cut
sub mask($self,$sequence,$assignments,%opt) {
    foreach my $assignment (@$assignments) {
        if ($opt{hard_mask}) {
            substr($sequence,$assignment->[0]-1,1+$assignment->[1]-$assignment->[0]) = 'x' x (1+$assignment->[1]-$assignment->[0]);  
        } else {
            substr($sequence,$assignment->[0]-1,1+$assignment->[1]-$assignment->[0]) = lc substr($sequence,$assignment->[0]-1,1+$assignment->[1]-$assignment->[0]);  
        }
    }
    $sequence;
}

sub _logic_filter_ok($self) {
    my ($elm_name, $seq, %opt) = @_;
    my %elms = %{ $self->library->elms };
    $opt{logic} //= 'FP'; #Default to removing only False Positives
    my %filters = map {$_->{seq} => undef} grep {$_->{logic} = $opt{logic}} @{$elms{$elm_name}{instances}};
    return (not exists $filters{$seq})?1:0;
}

=head1 AUTHOR

Matt Oates, C<< <mattoates at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<mattoates@gmail.com>, or through
GitHub issues at L<https://github.com/MattOates/melm/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ELM


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
