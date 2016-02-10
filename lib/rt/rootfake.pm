package rt::rootfake;

use configuration ':all';
use app;
use utf8;
use open qw/:std :utf8/;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/rt_root_fake/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/rt_root_fake/] ); 

sub rt_root_fake {
    my ($session) = @_;
    my $res;

    $$res{template} = 'index';
    $$res{params} = {
        login   => "toto"
        , admin   => 1
        , domains => qw/toto.netlib.re/
    };

    $res
}

1;
