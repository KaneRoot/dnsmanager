use Test::More;
use Modern::Perl;
use lib 'lib';
use util ':all';
use zonefile;

chdir 'lib'; # TODO hack at 2am

#map {
#    ok
#    ( ( is_domain_name $_ ), "is '$_' a domain name" )
#} qw( foo.bar bar localhost. localhost ); 
#
#done_testing;

my $zf = zonefile->new( zonefile => "../t/zonefile.txt" );
$zf->new_serial();
print $zf->dump();
