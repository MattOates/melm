package ELM::Anchor v1.4.1;
=encoding UTF-8
=head1 NAME

ELM::Anchor - Class to wrap ANCHOR and get assignments

=head1 VERSION

Version v1.4.1

=cut

use v5.20.0;
use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';

use File::Basename;
use IPC::Cmd qw(
    can_run
    run_forked
);

use subs 'anchor_datapath';
use Class::Tiny { anchor_datapath => sub {dirname(can_run('anchor'))} };

=head1 SYNOPSIS

This class is responsible for executing and parsing output from ANCHOR

To create an ELM::Anchor explicitly.

    use ELM::Anchor;

    my $anchor = ELM::Anchor->new();
    $anchor->assign($seq);
    ...

=head1 METHODS

=head2 anchor_datapath

Get/Set the ANCHOR datapath, default to install directory

=cut
sub anchor_datapath($self) {
    my $defaults = Class::Tiny->get_all_attribute_defaults_for( ref $self );
    if (@_) {
        my $path = shift;
        $path = $defaults->{anchor_datapath}->() unless $path;
        return $self->{anchor_datapath} = $path;
    }
    elsif ( exists $self->{anchor_datapath} ) {
        return $self->{anchor_datapath};
    }
    else {
        return $self->{anchor_datapath} = $defaults->{anchor_datapath}->();
    }
}

=head2 check_anchor_installation

Test if ANCHOR is installed and get the directory where it's located assuming this is the datapath

=cut
sub check_anchor_installation($self) {
    die "ANCHOR is not installed on this machine, you can get it from http://anchor.enzim.hu/" unless $self->anchor_datapath ;
}

=head2 assign

Get anchor morf and disorder assignments for a sequence

=cut
sub assign($self,$sequence) {

    #Run ANCHOR
    my $results = run_forked( "anchor -d $self->anchor_datapath -v /dev/stdin", { child_stdin => ">test\n$sequence\n", timeout => 600} );
    my @lines = split /\n/, $results->{stdout};

    #Return values
    my @iupred_probs = ();
    my @anchor_probs = ();
    my @anchor_ranges = ();

    #   Columns:
    #   1 - Amino acid number
    #   2 - One letter code
    #   3 - ANCHOR probability value
    #   4 - ANCHOR output
    #   5 - IUPred probability value
    #   6 - ANCHOR score 
    #   7 - S 
    #   8 - Eint 
    #   9 - Egain

    my $line = shift @lines;
    my $nextline;
    while ($line) {
        
        #Look a single line ahead to work out when we are at the end of a record
        $nextline = shift @lines;

        #If we are at the start of the file get the binding regions
        if ($line =~ /^# ANCHOR/) {
            #Then skip to the Predicted binding regions table
            while ($line !~ /^# Predicted binding regions/) { $line = $nextline; $nextline = shift @lines; }
            $line = $nextline;
            $nextline = shift @lines;
            #If we have some predicted binding sites add them to the list
            if ($line !~ /none/i) {
                while ($line !~ /^#$/) {
                    $line = $nextline;
                    $nextline = shift @lines;
                    last if $line =~ /^#$/;
                    $line =~ s/^#\s+//;
                    my (undef, $start, $end) = split /\s+/, $line;
                    push @anchor_ranges, [$start,$end];
                }
            }
        }

        #Ignore blank lines
        if ($line eq '') {
            $line = $nextline;
            next;
        }

        #If a line doesn't start with a hash assume it's model output
        if ($line !~ /^#/) {
            $line =~ s/^\s+//; #Trim any leading white space
            #Only bother to store the probability columns for this protein
            my (undef,undef,$anchor_prob,undef,$iupred_prob) = split /\s+/, $line;
            #Push these onto the list
            $anchor_prob =~ s/\s//g;
            $anchor_prob =~ s/0+$//g;
            $iupred_prob =~ s/\s//g;
            $iupred_prob =~ s/0+$//g;
            push @anchor_probs, $anchor_prob;
            push @iupred_probs, $iupred_prob;
        }

        $line = $nextline;
    }

    return (\@anchor_ranges,\@anchor_probs,\@iupred_probs);
}

=head1 AUTHOR

Matt Oates, C<< <mattoates at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<mattoates@gmail.com>, or through
GitHub issues at L<https://github.com/MattOates/melm/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ELM::Anchor


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