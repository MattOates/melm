requires 'LWP::UserAgent', '6.15';
requires 'BioPerl';
requires 'Class::Tiny', '1.004';

on 'test' => sub {
  requires 'Pod::Usage', '1.69';
  requires 'Test::Pod::Coverage', '1.10';
  requires 'Test::Pod', '1.51';
  requires 'Devel::Cover', '1.23';
  requires 'Devel::Cover::Report::Coveralls', '0.11';
};
