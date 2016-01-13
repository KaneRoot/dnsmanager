package rt::adminfake;

use configuration ':all';
use app;
use utf8;

use Data::Dump qw( dump );

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/rt_admin_fake/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/rt_admin_fake/] ); 

sub rt_admin_fake {
    my ($session, $param, $request) = @_;
    my $res;
    my $alldomains = [ { qw/domain toto.netlib.re login toto/ } ];
    my $allusers = [ { qw/  login toto admin 0 / }
        , { qw/login bidule admin 1/ }
        , { qw/login machin admin 0 / } ];
    my $domains = [ { qw/toto.netlib.re/ } ];
    $$res{template} = 'administration'; 
    $$res{params} = {
        login => "toto"
        , admin => 1
        , domains => $domains
        , alldomains => $alldomains
        , allusers => $allusers 
    };
    $res
}

1;
