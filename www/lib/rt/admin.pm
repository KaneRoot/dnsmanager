package rt::admin;

use configuration ':all';
use app;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/rt_admin/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/rt_admin/] ); 

sub rt_admin {
    my ($session, $param, $request) = @_;
    my $res;

    my $app = app->new(get_cfg());
    my $user = $app->auth($$session{login}, $$session{passwd});

    unless ($user && $user->is_admin()) {
        $$res{errmsg} = q{Donnée privée, petit coquin. ;) };
        $$res{route} = '/';
        return $res;
    }

    my $alldomains = $app->get_all_domains;
    my $allusers = $app->get_all_users;
    my $domains = $app->get_domains( $$session{login} );

    $$res{template} = 'administration'; 
    $$res{params} = {
        login => $$session{login}
        , admin => 1 # we know it, or we couldn't reach this
        , domains => $domains
        , alldomains => $alldomains
        , allusers => $allusers 
    };

    $res;
}

1;
