package DNSManager;

use Dancer ':syntax';
use strict;
use warnings;
use v5.14;
use Modern::Perl;
use Data::Dump qw( dump );
use Data::Structure::Util qw ( unbless );
use File::Basename;
use Config::Simple;
use Storable qw( freeze thaw );
$Storable::Deparse = true;
$Storable::Eval=true;

# Include other libs relative to current path
use Find::Lib '../../'; # TODO remove it when it won't be usefull anymore
use app::app;

our $VERSION = '0.1';

# eventually change place
sub initco {

    my $cfg = new Config::Simple(dirname(__FILE__).'/../conf/config.ini');
    my $app = app->new( zdir => $cfg->param('zones_path'),
        dbname => $cfg->param('dbname'),
        dbhost => $cfg->param('host'),
        dbport => $cfg->param('port'),
        dbuser => $cfg->param('user'),
        dbpass => $cfg->param('passwd'),
        sgbd => $cfg->param('sgbd'),
        dnsapp => $cfg->param('dnsapp') );

    $app->init();

    return $app;
}

sub get_errmsg {
    my $err = session 'errmsg';
    session errmsg => '';
    $err;
}

sub get_route {
    my $route = '/';
    $route = request->referer if (defined request->referer);
    $route;
}

get '/' => sub {
    if( session('login') )
    {

        my $app = initco();
        my ($success, @domains) = $app->get_domains( session('login') );

        if( $success ) {

            template index => {
                login   => session('login')
                , admin   => session('admin')
                , errmsg => get_errmsg
                , domains => [ @domains ] };
        }
        else {
            session->destroy;
            template 'index';
        }

    }
    else
    {

        template 'index' => {
            errmsg => get_errmsg
        };
    }
};


get '/home' => sub {

    unless( session('login') )
    {
        redirect '/';
    }
    else
    {
        my $app = initco();

        my ($success, @domains) = $app->get_domains( session('login') );

        if( $success ) {

            my (%zone_properties, %domains);
            my $cs = session('creationSuccess');
            my $dn = session('domainName');

            session creationSuccess => '';
            session domainName => '';

            template home => {
                login             => session('login')
                , admin           => session('admin')
                , domains         => [@domains]
                , zones_domains   => \%domains
                , zone_properties => \%zone_properties
                , creationSuccess => $cs
                , errmsg => get_errmsg
                , domainName      => $dn  };

        }
        else {
            session->destroy;
            redirect '/ ';
        }

    }
};

prefix '/domain' => sub {

    any ['post', 'get'] => '/updateraw/:domain' => sub {

        # check if user is logged & if domain parameter is set
        unless( session('login') && param('domain'))
        {
            redirect '/';
        }
        else
        {

            my $app = initco();
            my ($auth_ok, $user, $isadmin) = $app->auth(param('login'),
                param('password') );

            $app->update_domain_raw(session('login')
                , param('zoneupdated')
                , param('domain'));

            redirect '/domain/details/' . param('domain');
		}

	};

    any ['post', 'get'] => '/update/:domain' => sub {
		unless( session('login') && param('domain') )
		{
            redirect '/';
        }
        else
        {
			my $type  = param('type');
			my $name  = param('name');
			my $value = param('value');
			my $ttl   = param('ttl');

			my $app = initco();
			my ($auth_ok, $user, $isadmin) = $app->auth(param('login'),
				param('password') );
			my $zone = $app->get_domain( session('login') , param('domain') );
			given( $type )
			{

				when ('A') { my $a=$zone->a();
				             push( @$a, {name  => $name,
				                         class => "IN",
				                         host  => $value,
				                         ttl   => $ttl,
				                         ORIGIN => $zone->origin} );
				           }

				when ('AAAA') { my $aaaa=$zone->aaaa;
				                push(@$aaaa, {name  => $name,
				                              class => "IN",
				                              host  => $value,
				                              ttl   => $ttl,
                                              ORIGIN => $zone->origin} );
				              }

				when ('CNAME') { my $cname=$zone->cname;
				                 push(@$cname,
                                      {name  => $name,
				                       class => "IN",
				                       host  => $value,
				                       ttl   => $ttl,
                                       ORIGIN => $zone->origin} );
				               }

				when ('MX') { my $ptr=$zone->ptr;
				              push(@$ptr, {name  => $name,
				                           class => "IN",
				                           host  => $value,
				                           ttl   => $ttl,
                                           ORIGIN => $zone->origin} );
				            }

				when ('PTR') { my $ptr=$zone->ptr;
				               push(@$ptr, {name  => $name,
				                           class => "IN",
				                           host  => $value,
				                           ttl   => $ttl,
                                           ORIGIN => $zone->origin} );
				             }

				when ('NS') { my $ns=$zone->ns;
				               push(@$ns, {name  => $name,
				                           class => "IN",
				                           host  => $value,
				                           ttl   => $ttl,
                                           ORIGIN => $zone->origin} );
				             }

			}
			$zone->new_serial();
			my $cfg = new Config::Simple(dirname(__FILE__).'/../conf/config.ini');
			my $ed = app::zone::edit->new(zdir=>$cfg->param('zones_path'), zname => param('domain'));
			$ed->update($zone);
			redirect '/domain/details/'.param('domain');
		}
	};

    get '/details/:domain' => sub {

        # check if user is logged & if domain parameter is set
        unless( session('login') && param('domain'))
        {
            redirect '/';
        }
        else
        {
            my $app = initco();
            my ($auth_ok, $user, $isadmin) = $app->auth(param('login'),
                param('password') );

            my $zone = $app->get_domain(session('login') , param('domain'));

			if( param( 'expert' ) )
			{
				template details => {
					login           => session('login')
					, domain        => param('domain')
					, domain_zone   => $zone->output()
					, expert        => true	};
			}
			else
			{
				# say dump( $zone->cname());
				template details => {
					login           => session('login')
					, domain        => param('domain')
					, domain_zone   => $zone->output()
					, a             => $zone->a()
					, aaaa          => $zone->aaaa()
					, cname         => $zone->cname()
					, ptr			=> $zone->ptr()
					, mx			=> $zone->mx()
					, ns			=> $zone->ns()	};
			}

        }

    };

    post '/add/' => sub {

        # check if user is logged & if domain parameter is set
        unless( session('login') && param('domain'))
        {
            redirect '/';
        }
        else
        {

            my $creationSuccess = '';

            if( param('domain') =~ /^[a-zA-Z0-9]+[a-zA-Z0-9-]+[a-zA-Z0-9]+$|^[a-zA-Z0-9]+$/ )
            {

                my $cfg = new Config::Simple(dirname(__FILE__).'/../conf/config.ini');
                my $domain = param('domain').$cfg->param('tld');
                my $app = initco();
                my ($success) = $app->add_domain( session('login'), $domain );

                if ($success) {
                    $creationSuccess = q{Le nom de domaine a bien été réservé ! };
                }
                else {
                    session errmsg => q{Le nom de domaine est déjà pris.};
                }

            }
            else
            {
                session errmsg =>
                q{Le nom de domaine entré contient des caractères invalides};
            }

            session creationSuccess => $creationSuccess;
            session domainName => param('domain');
            redirect '/home';

        }

    };

    get '/del/:domain' => sub {

        unless( defined param('domain') ) {
            session errmsg => q<Domaine non renseigné.>;
            redirect get_route;
        }
        else {
            my $app = initco();

            # TODO tests des droits
            if( session('login') ) {

                if($app->delete_domain(session('login'), param('domain'))) {

                    if( request->referer =~ "/domain/details" ) {
                        redirect '/home';
                    }
                    else {
                        redirect request->referer;
                    }

                }
                else {

                    session errmsg => "Impossible de supprimer le domaine "
                    . param 'domain'
                    . '.' ;
                    redirect request->referer;

                }
            }
        }

    };

};

any ['get', 'post'] => '/admin' => sub {

    unless( session('login') )
    {
        redirect '/';
    }
    else
    {
        my $app = initco();
        my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
            session('password') );

        unless ( $auth_ok && $isadmin ) {
            redirect '/ ';
        }
        else {

            my %alldomains = $app->get_all_domains;
            my %allusers = $app->get_all_users;
            my ($success, @domains) = $app->get_domains( session('login') );

            template administration => {
                login => session('login')
                , admin => session('admin')
                , errmsg => get_errmsg
                , domains => [ @domains ]
                , alldomains => { %alldomains }
                , allusers => { %allusers } };
        }
    }
};

prefix '/user' => sub {

    get '/logout' => sub {
        session->destroy;
        redirect '/';
    };

    post '/add/' => sub {

        if ( param('login') && param('password') )
        {

            my $app = initco();
            my ($success) = $app->register_user(param('login')
                , param('password'));

            if($success) {
                session login => param('login');
                session password => param('password');
                redirect '/home';
            }
            else {
                session errmsg => q/Ce pseudo est déjà pris./;
                redirect '/user/subscribe';
            }

        }
        else {
            session errmsg => q/login ou password non renseignés/;
            redirect '/user/subscribe';
        }

    };

    get '/subscribe' => sub {

        if( defined session('login') )
        {
            redirect '/home';
        }
        else {

            template subscribe => {
                errmsg => get_errmsg
            };
        }

    };

    get '/unsetadmin/:user' => sub {

        unless( defined param('user') )
        {

            # TODO ajouter une erreur à afficher
            session errmsg => "L'administrateur n'est pas défini." ;
            redirect request->referer;

        }
        elsif(! defined session('login') )
        {

            session errmsg => "Vous n'êtes pas connecté." ;
            redirect '/';

        }
        else {

            my $app = initco();

            my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
                session('password') );

            if ( $auth_ok && $isadmin ) {
                $app->set_admin(param('user'), 0);
            }
            else {
                session errmsg => q/Vous n'êtes pas administrateur./;
            }

            if( request->referer =~ "/admin" ) {
                redirect request->referer;
            }
            else {
                redirect '/';
            }

        }

    };

    get '/setadmin/:user' => sub {

        unless( defined param('user') )
        {

            # TODO ajouter une erreur à afficher
            session errmsg => "L'utilisateur n'est pas défini." ;
            redirect request->referer;

        }
        elsif(! defined session('login') )
        {

            session errmsg => "Vous n'êtes pas connecté." ;
            redirect '/';

        }
        else {

            my $app = initco();

            my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
                session('password') );

            if ( $auth_ok && $isadmin ) {
                $app->set_admin(param('user'), 1);
            }

            if( request->referer =~ "/admin" ) {
                redirect request->referer;
            }
            else {
                redirect '/';
            }

        }

    };

    get '/del/:user' => sub {

        if(defined param 'user') {

            my $app = initco();

            my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
                session('password') );

            if ( $auth_ok && $isadmin || session('login') eq param('user')) {
                unless ( $app->delete_user(param('user'))) {
                    session errmsg => "L'utilisateur " 
                    . param 'user'
                    . " n'a pas pu être supprimé.";
                }
            }
        }
        else {
            session errmsg => q{Le nom d'utilisateur n'est pas renseigné.};
        }

        if( defined request->referer) {
            redirect request->referer;
        }
        else {
            redirect '/';
        }

    };

    post '/login' => sub {

        # Check if user is already logged
        unless ( session('login') )
        {
            # Check user login and password
            if ( param('login') && param('password') )
            {

                my $app = initco();
                my ($auth_ok, $user, $isadmin) = $app->auth(param('login'),
                    param('password') );

                if( $auth_ok )
                {

                    session login => param('login');
                    # TODO : change password storage…
                    session password => param('password');
                    session user  => freeze( $user );
                    session admin => $isadmin;

                    if( $isadmin ) {
                        redirect '/admin';
                        return;
                    }

                }
                else
                {

                    session errmsg => q<Impossible de se connecter (login ou mot de passe incorrect).>;
                    redirect '/';

                }
            }
        }

        redirect '/home';

    };

};
