use Test::More;
use Modern::Perl;
use lib 'lib';
use util ':all';

chdir 'lib'; # TODO hack at 2am

map {
    ok
    ( ( is_domain_name $_ ), "is '$_' a domain name" )
} qw( foo.bar bar localhost. localhost ); 

map {
    ok
    ( ( is_valid_tld $_ ), "is '$_' a tld in the cfg file" )
} qw( .netlib.re ); 

map {
    ok
    ( ( ! is_valid_tld $_ ), "is '$_' a tld in the cfg file" )
} qw( example.com ); 

done_testing;
