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

get '/' => sub {
    if( session('login') )
    {
        my $app = initco();
        $app->get_domains( session('login') );
        template index => { 
            logged  => true
            , login   => session('login')
            , admin   => session('admin')
            , domains => $app->get_domains(session('login')) };
    }
    else
    {
        template 'index';
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
        my %domains = ();
        my %zone_properties = ();

        my @d = @{$app->get_domains( session('login') )};

        template home => { 
            login           => session('login')
            , domains         => $app->get_domains(session('login'))
            , zones_domains   => \%domains
            , zone_properties => \%zone_properties
            , admin           => session('admin') };

    }
};

prefix '/domain' => sub {

    any ['post', 'get'] => '/update/:domain' => sub {

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

            template details => {
                login           => session('login')
                , domain        => param('domain')
                , domain_zone   => $zone->output() };

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

            my $app = initco();
            $app->add_domain( session('login'), param('domain') );
            redirect '/home';

        }

    };

    get '/del/:domain' => sub {

        # TODO tests des droits
        my $app = initco();
        $app->delete_domain(session('login'), param('domain'));
        redirect '/home';

    };


};

any ['get', 'post'] => '/admin' => sub {
    unless( session('login') )
    {
        redirect '/';
    }
    else
    {
        template administration => { 
            login => session('login')
            , admin => session('admin')  };
    }
};

prefix '/user' => sub {

    get '/logout' => sub {
        session->destroy;
        redirect '/';
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

                }
                else
                {
                    # User login and/or password are incorrect
                }
            }
        }

        redirect '/home';

    };

};
