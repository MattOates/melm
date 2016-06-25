package ELM::Update 0.01;

#Get a webpage as a string
sub get_www {
    my ($url) = @_;

    use LWP::UserAgent;
    #Decided to localise this and just handle checking for deps properly
    my $ua = LWP::UserAgent->new;

    my $response = $ua->get($url);
    if ($response->is_success) {
       return $response->decoded_content;
    } else {
        die "Failed whilst contacting $url: " . $response->status_line;
    }
}

#Upgrade the melm script to the latest version
#TODO refactor this to get the latest release fatpack bundle!
sub upgrade {
    if (eval { require LWP::Protocol::https }) {
        say STDERR "Upgrading melm version $VERSION to latest from GitHub.";
        my $melm_path = abs_path(__FILE__);
        say STDERR "Getting latest melm script from GitHub." if $verbose;
        my $melm = get_www('https://raw.githubusercontent.com/MattOates/melm/master/bin/melm');
        say STDERR "Upgrading your copy of melm to latest version." if $verbose;
        open my $melm_fh, '>', $melm_path or die "Could not open melm script for writing.";
        binmode($melm_fh, ':utf8');
        print $melm_fh $melm;
        close $melm_fh or die "Could not close melm script.";
        `$melm_path --verbose --update`;
    } else {
        say STDERR 'Sorry GitHub requires HTTPS support and your Perl does not have LWP::Protocol::https installed.';
        say STDERR 'Try `cpanm -i LWP::Protocol::https` to install this module.';
        exit 1;
    }
}

#Update the ELM definitions
sub update {
    if (eval { require LWP::UserAgent }) {
        say STDERR "Updating ELM classes file $ENV{HOME}/.elm.dat" if $verbose;
        update_elm_classes();
        update_elm_instances();
    } else {
        say STDERR "On first execution and when updating melm requires your Perl installation to have LWP::UserAgent to contact ELM servers for data.";
        say STDERR "You might be able to install this module using `cpanm -i LWP::UserAgent`.";
        say STDERR "Another alternative is to download the latest ELM data from the melm repository at: https://raw.githubusercontent.com/MattOates/melm/master/.elm.dat";
        say STDERR "Place the .elm.dat file into your home directory: /Users/username (OSX), /home/username (Linux) or C:\\Users\\username (Windows)"
    }
}

#Refresh the cached ELM classes file and populate %elms with latest data
sub update_elm_classes {
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
        $elms{$elm_name} = {accession => $elm_id, elm_name => $elm_name, site => $name, type => $type, description => $description, regex => $regex, probability => $probability};
    }
    open my $elm_fh,'>',"$ENV{HOME}/.elm.dat";
    say $elm_fh Dumper([$classes_version,$instances_version,\%elms]);
    close $elm_fh;
    say STDERR "Updated ELM library to version $classes_version" if $verbose;
}

#Get the sequence for an instance from ELM
sub get_instance_seqs {
    say STDERR "Downloading instance protein sequences from ELM." if $verbose;
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
sub update_elm_instances {
    my %instance_logic = ('false positive' => 'FP','true negative' => 'TN','true positive', => 'TP', 'unknown' => 'U');
    my $instances_tsv = get_www('http://elm.eu.org/instances.tsv');
    my %uniprot_sequences = get_instance_seqs();
    #Each record looks like:
    #Accession, ELMType, ELMIdentifier, ProteinName, Primary_Acc, Accessions, Start, End, References, Methods, InstanceLogic, PDB, Organism
    #"ELMI000471"   "LIG"   "LIG_SH2_SRC"   "SRC_HUMAN" "P12931"    "P12931 E1P5V4 Q76P87 Q86VB9 Q9H5A8"    "530"   "533"   "10360179"  "x-ray crystallography" "true positive" ""  "Homo sapiens"
    foreach my $record (split /\n/, $instances_tsv) {
        (undef,$instances_version) = split /: /, $record if ($record =~ /^#ELM_Instance_Download_Version/);
        next if $record =~ /^(#|"Accession)/; #Ignore the header
        $record =~ s/"//g;
        my ($elm_id, $type, $elm_name, $protein_name, $up_id, $alt_up_id, $start, $end, $references, $methods, $logic, $pdb, $organism) = split /\t/, $record;
        my $seq = substr( $uniprot_sequences{$up_id}, $start-1, 1+$end-$start );
        push @{$elms{$elm_name}{instances}}, {accession => $elm_id, id => $up_id, start => $start, end => $end, logic => $instance_logic{$logic}, seq => $seq};
    }
    say STDERR "Instances data updated to version $instances_version." if $verbose;
    open my $elm_fh,'>',"$ENV{HOME}/.elm.dat";
    say $elm_fh Dumper([$classes_version,$instances_version,\%elms]);
    close $elm_fh;
}

1;