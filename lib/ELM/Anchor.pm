package ELM::Anchor v1.4.1;

use v5.20.0;
use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';

use File::Basename;
use IPC::Cmd qw/can_run run_forked/;

use Class::Tiny { anchor_datapath => sub {can_run('anchor')} };

#Test if ANCHOR is installed and get the directory where it's located assuming this is the datapath
sub check_anchor_installation($self) {
    die "ANCHOR is not installed on this machine, you can get it from http://anchor.enzim.hu/" unless $self->anchor_datapath ;
    $self->anchor_datapath(dirname($self->anchor_datapath));
}

sub anchor($self) {
    my ($sequence) = @_;

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

1;