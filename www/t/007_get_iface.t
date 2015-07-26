use Test::More;
use Modern::Perl;
use YAML::XS;
use URI;
use lib 'lib';
use getiface':all';

my $x = getiface("bind9", { mycfg => '', data => '' });
say Dump $x;
