package rt::root;

use configuration ':all';
use app;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/rt_root/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/rt_root/] ); 

sub rt_root {
    my ($session, $param) = @_;
    my $res;

    $$res{template} = 'index';

    if($login) {
        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        # ancienne version pour récupérer les domaines :
        #my ($success, @domains) = $app->get_domains( $login );

        if( $user ) {
            $$res{params} = {
                login   => $$session{login}
                , admin   => $user->is_admin()
                , domains => [ $user->get_domains() ]
            };
        }
        else {
            $$res{sessiondestroy} = 1;
        }

    }
    
    $res;
}

1;
