package ELM::Calc v1.4.1;
require Exporter;

use v5.20.0;
use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(coverage any_overlap runencode);

#Efficiently calculate the coverage between two number line segments
sub coverage($a, $b, $x, $y) {
    return max(min((1+$b-$a),(1+$y-$x),(1+abs($b-$a)+abs($y-$x))-(max($a,$b,$x,$y)-min($a,$b,$x,$y))),0);
}

#Report if there is any overlap between a single defined region and a set of regions
sub any_overlap($start, $end, $pairs) {
    foreach my $pair (@$pairs) {
        return 1 if coverage($start,$end,$pair->[0],$pair->[1]);
    }
    return 0;
}

#Take an arrayref of numbers or a delimited string and returns a list of start-end pairs for runs of values above a threshold
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

1;