package ELM::Library 0.1;

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

use Class::Tiny qw/elms classes_version instances_version/, { 
    elm_lib_path => sub {
        $ENV{HOME} . '/.elm.dat';
    }
};

#Load the ELM classes when we instantiate
sub BUILD($self, $args) {
    $self->load_elm_classes;
}

#Check to see if the library exists
sub exists($self) {
    return -e $self->elm_lib_path;
}

#Load the cached ELM classes/instances data
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
        say STDERR "Could not find an ELM library so auto-fetching a fresh one for the first time";
        $self->update;
    }
}

#Update the ELM definitions
sub update($self) {
    say STDERR "Updating ELM classes file " . $self->elm_lib_path;
    $self->_update_elm_classes();
    $self->_update_elm_instances();
    open my $elm_fh,'>', $self->elm_lib_path;
    say $elm_fh Dumper([$self->classes_version, $self->instances_version, $self->elms]);
    close $elm_fh;
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
    my $fasta = get_www("http://elm.eu.org/instances.fasta");
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
    my $instances_tsv = get_www('http://elm.eu.org/instances.tsv');
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

1;