package ELM::Utils v1.4.1;
require Exporter;

use v5.20.0;
use strict;
use warnings;
no warnings 'experimental::signatures';
use feature 'signatures';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_www);

use LWP::UserAgent;

#Get a webpage as a string
sub get_www($url) {
    if (not eval { require LWP::UserAgent }) {
        say STDERR "On first execution and when updating melm requires your Perl installation to have LWP::UserAgent to contact ELM servers for data.";
        say STDERR "You might be able to install this module using `cpanm -i LWP::UserAgent`.";
        say STDERR "Another alternative is to download the latest ELM data from the melm repository at: https://raw.githubusercontent.com/MattOates/melm/master/.elm.dat";
        say STDERR "Place the .elm.dat file into your home directory: /Users/username (OSX), /home/username (Linux) or C:\\Users\\username (Windows)";
        exit 1;
    }
    if ($url =~ /^https/ and not eval { require LWP::Protocol::https }) {
        say STDERR 'Sorry $url requires HTTPS support and your Perl does not have LWP::Protocol::https installed.';
        say STDERR 'Try `cpanm -i LWP::Protocol::https` to install this module.';
        say STDERR 'If you are running this code from an official release distribution please raise a GitHub issue.';
        exit 1;
    }
    #Decided to localise this and just handle checking for deps properly
    my $ua = LWP::UserAgent->new;

    my $response = $ua->get($url);
    if ($response->is_success) {
       return $response->decoded_content;
    } else {
        die "Failed whilst contacting $url: " . $response->status_line;
    }
}

1;