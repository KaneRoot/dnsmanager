package rt::root;

use configuration ':all';
use app;
use utf8;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/rt_root/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/rt_root/] ); 

sub rt_root {
    my ($session) = @_;
    my $res;

    $$res{template} = 'index';

    if( exists $$session{login} && length $$session{login} > 0) {
        eval {
            my $app = app->new(get_cfg());
            my $user = $app->auth($$session{login}, $$session{passwd});

            if( $user ) {
                $$res{params} = {
                    login   => $$session{login}
                    , admin   => $user->is_admin()
                    , domains => [ @{$$user{domains}} ]
                };
            }
            $app->disconnect();
        };
        
        if( $@ ) {
            $$res{params}{errmsg} = q{Une erreur est survenue. } . $@;
            $$res{sessiondestroy} = 1;
        }

    }

    $res
}

1;
