package rt::root;

use configuration ':all';
use app;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/rt_root/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/rt_root/] ); 

sub rt_root {
    my ($login, $passwd) = @_;
    my $res = {};

    $$res{route} = 'index';

    if($login) {
        my $app = app->new(get_cfg('../conf/'));
        my $user = $app->get_user($login, $passwd);

        # ancienne version pour récupérer les domaines :
        #my ($success, @domains) = $app->get_domains( $login );

        if( $user ) {

            $$res{params} = {
                login   => $login
                , admin   => $user->is_admin();
                , domains => [ $user->get_domains() ] };
        }
        else {
            $$res{sessiondestroy} = 1;
            $$res{route} = 'index';
        }

    }
    else {

        $$res{route} = 'index';
    }
    
    $res;
}

1;
