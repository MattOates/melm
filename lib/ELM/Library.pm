package ELM::Library v1.4.2;
=encoding UTF-8
=head1 NAME

ELM::Library - Class to hold the ELM regex library

=head1 VERSION

Version v1.4.2

=cut

use v5.20.0;
use strict;
use warnings;
use autodie;
no warnings 'experimental::signatures';
use feature 'signatures';

use ELM::Utils 'get_www';

use Cwd qw/abs_path/;
use Data::Dumper;
#Make eval of dump simpler
$Data::Dumper::Terse=1;

use Class::Tiny qw(
    elms
    classes_version
    instances_version),{ 
    elm_lib_path => sub { $ENV{HOME} . '/.elm.dat' }
};

=head1 SYNOPSIS

This class is responsible for all high level operations on creating and maintaining a local ELM library.
Data is automatically downloaded from elm.eu.org and can be updated programatically.

To create an ELM::Library explicitly.

    use ELM::Library;

    my $lib = ELM::Library->new();
    ...

=head1 METHODS

=head2 BUILD

Load the ELM classes when we instantiate

=cut
sub BUILD($self, $args) {
    $self->load_elm_classes;
}

=head2 exists

Check to see if the library exists

=cut
sub exists($self) {
    return -e $self->elm_lib_path;
}

=head2 load_elm_classes

Load the cached ELM classes/instances data

=cut
sub load_elm_classes($self) {
    if ($self->exists) {
        #Load the cached ELM classes/instances data
        local $/; #slurp
        open my $elm_fh, '<', $self->elm_lib_path;
        my ($classes_version, $instances_version, $classes) =  @{ eval <$elm_fh> };
        close $elm_fh;
        $self->elms($classes);
        $self->classes_version($classes_version);
        $self->instances_version($instances_version);
    } else {
        say STDERR "Could not find an ELM library at " . $self->elm_lib_path . " so auto-fetching a fresh one for the first time";
        $self->update;
    }
}

=head2 update

Update the ELM definitions from elm.eu.org

=cut
sub update($self) {
    say STDERR "Updating ELM classes file " . $self->elm_lib_path;
    $self->_update_elm_classes();
    $self->_update_elm_instances();
    open my $elm_fh,'>', $self->elm_lib_path;
    say $elm_fh Dumper([$self->classes_version, $self->instances_version, $self->elms]);
    close $elm_fh;
}

=head2 list_classes

Print out all of the ELM classes in a simple TSV format

=cut
sub list_classes($self) {
    my %elms = %{ $self->elms };
    say "#Cached melm data for version $self->classes_version of the ELM classes library";
    say "#" . join "\t", 'Accession', 'Type', 'Name', 'Description', 'Regex', 'Expectation';
    foreach my $elm (keys %elms) {
        say "$elms{$elm}{accession}\t$elms{$elm}{type}\t$elm\t$elms{$elm}{description}\t$elms{$elm}{regex}\t$elms{$elm}{probability}";
    }
}

=head2 list_instances

Print out all of the ELM instances in a simple TSV format

=cut
sub list_instances($self) {
    my %elms = %{ $self->elms };
    say "#Cached melm data for version $self->instances_version of the ELM instances library";
    say "#" . join "\t", 'Accession', 'Name', 'Primary UniProt Accession', 'Start', 'End', 'Sequence', 'Assignment Logic';
    foreach my $elm (keys %elms) {
        foreach my $instance (@{$elms{$elm}{instances}}) {
            say "$instance->{accession}\t$elm\t$instance->{id}\t$instance->{start}\t$instance->{end}\t$instance->{seq}\t$instance->{logic}";
        }
    }
}

#Refresh the cached ELM classes file and populate %elms with latest data
sub _update_elm_classes($self) {
    my $classes_version;
    $self->elms({}); #Wipe out existing elms
    my $class_tsv = get_www('http://elm.eu.org/elms/elms_index.tsv');
    #Each record looks like:
    #Pre 1.4
    #Accession  ELMIdentifier   Description Regex   Probability #Instances  #Instances_in_PDB
    #Post 1.4
    #Accession ELMIdentifier FunctionalSiteName Description Regex Probability #Instances #Instances_in_PDB
    #ELME000080"    "TRG_PEX_1" "Wxxx[FY] motifs present in N-terminal half of Pex5 bind to Pex13 and Pex14 at peroxisomal and glycosomal membranes to facilitate entrance of PTS1 cargo proteins into the organellar lumen. =>"W...[FY] =>"0.000222625 =>"27"  "1"
    foreach my $record (split /\n/, $class_tsv) {
        (undef,$classes_version) = split /: /, $record if ($record =~ /^#ELM_Classes_Download_Version/);
        next if $record =~ /^(#|"Accession)/; #Ignore the header
        $record =~ s/"//g;
        my ($elm_id,$elm_name,$name,$description,$regex,$probability,$instances,$instances_in_pdb) = split /\t/, $record;
        my ($type) = split /_/, $elm_name;
        $self->elms->{$elm_name} = {accession => $elm_id, elm_name => $elm_name, site => $name, type => $type, description => $description, regex => $regex, probability => $probability};
    }
    $self->classes_version($classes_version);
    say STDERR "Updated ELM library to version $classes_version";
}

#Get the sequence for an instance from ELM
sub _get_instance_seqs($self) {
    say STDERR "Downloading instance protein sequences from ELM.";
    my $fasta = get_www("http://elm.eu.org/instances.fasta?q=*");
    my %sequences;
    #Hard assumption, ELM gives out sequences as a single line (appears true)
    foreach my $record (split />/, $fasta) {
        next if $record =~ /^\s*$/;
        my ($id,$seq) = split /\n/, $record;
        my (undef, $up_id) = split /\|/, $id;
        $sequences{$up_id} = $seq;
    }
    return %sequences;
}

#Refresh the cached ELM instances data
sub _update_elm_instances($self) {
    my $instances_version;
    my %instance_logic = ('false positive' => 'FP','true negative' => 'TN','true positive', => 'TP', 'unknown' => 'U');
    my $instances_tsv = get_www('http://elm.eu.org/instances.tsv?q=*');
    my %uniprot_sequences = $self->_get_instance_seqs();
    #Each record looks like:
    #Accession, ELMType, ELMIdentifier, ProteinName, Primary_Acc, Accessions, Start, End, References, Methods, InstanceLogic, PDB, Organism
    #"ELMI000471"   "LIG"   "LIG_SH2_SRC"   "SRC_HUMAN" "P12931"    "P12931 E1P5V4 Q76P87 Q86VB9 Q9H5A8"    "530"   "533"   "10360179"  "x-ray crystallography" "true positive" ""  "Homo sapiens"
    foreach my $record (split /\n/, $instances_tsv) {
        (undef, $instances_version) = split /: /, $record if ($record =~ /^#ELM_Instance_Download_Version/);
        next if $record =~ /^(#|"Accession)/; #Ignore the header
        $record =~ s/"//g;
        my ($elm_id, $type, $elm_name, $protein_name, $up_id, $alt_up_id, $start, $end, $references, $methods, $logic, $pdb, $organism) = split /\t/, $record;
        my $seq = substr( $uniprot_sequences{$up_id}, $start-1, 1+$end-$start );
        push @{$self->elms->{$elm_name}{instances}}, {accession => $elm_id, id => $up_id, start => $start, end => $end, logic => $instance_logic{$logic}, seq => $seq};
    }
    say STDERR "Instances data updated to version $instances_version.";
    $self->instances_version($instances_version);
}

=head1 AUTHOR

Matt Oates, C<< <mattoates at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<mattoates@gmail.com>, or through
GitHub issues at L<https://github.com/MattOates/melm/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ELM::Library


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