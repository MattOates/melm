package ELM v1.4.1;

use v5.20.0;
use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';

use ELM::Library;
use ELM::Utils;
use ELM::Anchor;
use ELM::AminoAcids;

use Class::Tiny qw/type max_class_expect morf_filter disorder_filter logic_filter/, { 
	library => sub { ELM::Library->new() },
	anchor => sub { ELM::Anchor->new() },
};

sub list_classes($self) {
	my %elms = %{ $self->library->elms };
	say "#Cached melm data for version $classes_version of the ELM classes library";
    say "#" . join "\t", 'Accession', 'Type', 'Name', 'Description', 'Regex', 'Expectation';
    foreach my $elm (keys %elms) {
        say "$elms{$elm}{accession}\t$elms{$elm}{type}\t$elm\t$elms{$elm}{description}\t$elms{$elm}{regex}\t$elms{$elm}{probability}";
    }
}

sub list_instances($self) {
	my %elms = %{ $self->library->elms };
	say "#Cached melm data for version $instances_version of the ELM instances library";
    say "#" . join "\t", 'Accession', 'Name', 'Primary UniProt Accession', 'Start', 'End', 'Sequence', 'Assignment Logic';
    foreach my $elm (keys %elms) {
        foreach my $instance (@{$elms{$elm}{instances}}) {
            say "$instance->{accession}\t$elm\t$instance->{id}\t$instance->{start}\t$instance->{end}\t$instance->{seq}\t$instance->{logic}";
        }
    }
}

sub _logic_filter_ok($self) {
    my ($elm_name, $seq, %opt) = @_;
    my %elms = %{ $self->library->elms };
    $opt{logic} //= 'FP'; #Default to removing only False Positives
    my %filters = map {$_->{seq} => undef} grep {$_->{logic} = $opt{logic}} @{$elms{$elm_name}{instances}};
    return (not exists $filters{$seq})?1:0;
}

sub assign_elm($self) {
	my ($elm, $seq, %opt) = @_;
	my $anchor = $opt{morf_filter} || $opt{disorder_filter};

	#Handle any disorder/morf prediction
	my ($morf_regions, $dis_regions, $anchor, $iupred);
    if ($anchor) {
        ($morf_regions, $anchor, $iupred) = anchor($seq->seq);
        $dis_regions = runencode($iupred);
    }

    return assign($elm, $elms{$elm}{regex}, $seq->seq, $morf_regions, $dis_regions);
}

#Assign all ELM classes given filter options to a sequence
sub assign_all_elms($self, $seq, %opt) {
	my $max_class_expect = $opt{max_class_expect};
	my $type = $opt{type};

	my @assignment;
    foreach my $elm (keys %elms) {

    	#Ignore those ELM classes that are below the user defined probability threshold
		if ($max_class_expect) {
		    next if $elms{$elm}{probability} >= $max_class_expect;
		}

		#Ignore all the ELM classes but the type requested
		if ($type) {
		    next if $elms{$elm}{type} ne $type;
		}

        push @assignment, assign_elm($elm, $seq->seq, %opt);
    }

    return @assignment;
}

#Take a regular expression and return all of the ([start,end,substr]...) matched results
sub assign($self, $elm_name, $regex, $string, $morf_regions, $dis_regions) {
    my @ret;
    my ($start,$end,$seq,$prob,$entropy,$entrorate);
    while ($string =~ /($regex)/g) {
        ($start,$end,$seq) = ($-[0]+1, $+[0], $&);
        if ($logic_filter) {
            next unless $self->_logic_filter_ok($elm_name,$seq,logic => $logic_filter);
        }
        ($prob, $entropy, $entrorate) = score($seq);
        if ($max_elm_probability) {
            next if $prob > $max_elm_probability;
        }
        if ($min_elm_complexity) {
            next if $entrorate < $min_elm_complexity;
        }
        if ($morf_filter) {
            next unless any_overlap($start,$end,$morf_regions);
        }
        if ($disorder_filter) {
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

#Collapse multiple assignments into a single list of disjoint ([start,end]...) and per residue counts of collapsed data
sub collapse_assignment {
    my ($sequence,$assignments,%opt) = @_;

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
    return runencode(\@ass, threshold => $num_elms);
}

#Mask a string hard/soft based on a list of start,end pairs [[start,end],...]
sub mask {
    my ($sequence,$assignments,%opt) = @_;
    foreach my $assignment (@$assignments) {
        if ($opt{hard_mask}) {
            substr($sequence,$assignment->[0]-1,1+$assignment->[1]-$assignment->[0]) = 'x' x (1+$assignment->[1]-$assignment->[0]);  
        } else {
            substr($sequence,$assignment->[0]-1,1+$assignment->[1]-$assignment->[0]) = lc substr($sequence,$assignment->[0]-1,1+$assignment->[1]-$assignment->[0]);  
        }
    }
    $sequence;
}

1;
