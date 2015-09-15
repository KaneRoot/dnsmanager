use Test::More;
use Modern::Perl;
use YAML::XS;
use URI;
use lib 'lib';
use configuration ':all';

my $x =  get_cfg();
#say Dump $x;

say $$x{database}{host};

for($$x{secondarydnsserver})
{
    for(@$_)
    {
        while( my ($k, $v) = each %$_)
        {
            say $k . ' ' . $v ;
        }
    }
}
