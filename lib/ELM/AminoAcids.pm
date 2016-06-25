package ELM::AminoAcids 0.1;

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

sub amino_prob {
    my ($amino) = @_;
    if (exists $amino_probs{$amino}) {
        return $amino_probs{$amino};
    } else {
        warn "Amino acid not found: $amino";
        #Magic number, aa character is almost 0 probability, this should perhaps be 1.0 to ignore weird characters
        return 4.94065645841247e-324; 
    }
}

sub score {
    my ($sequence) = @_;
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

1;