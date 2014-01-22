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
        my ($success, @domains) = $app->get_domains( session('login') );

        if( $success ) {

            template index => {
                login   => session('login')
                , admin   => session('admin')
                , domains => [ @domains ] };
        }
        else {
            session->destroy;
            template 'index';
        }
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

        my ($success, @domains) = $app->get_domains( session('login') );

        if( $success ) {

            my (%zone_properties, %domains);
            my $cs = session('creationSuccess');
            my $cf = session('creationFailure');
            my $dn = session('domainName');

            session creationSuccess => '';
            session creationFailure => '';
            session domainName => '';

            template home => {
              login             => session('login')
              , admin           => session('admin')
              , domains         => [@domains]
              , zones_domains   => \%domains
              , zone_properties => \%zone_properties
              , creationSuccess => $cs
              , creationFailure => $cf
              , domainName      => $dn  };

        }
        else {
            session->destroy;
            redirect '/ ';
        }

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

            my $creationSuccess = false;
            my $creationFailure = false;
            if( param('domain') =~ /^[a-zA-Z0-9]+[a-zA-Z0-9-]+[a-zA-Z0-9]+$|^[a-zA-Z0-9]+$/ )
            {

                my $cfg = new Config::Simple(dirname(__FILE__).'/../conf/config.ini');
                my $domain = param('domain').$cfg->param('tld');
                # $domain =~ s/\.{2,}/\./g;
                # say "domain after sed : $domain";
                # create domain
                my $app = initco();
                # Add tld
                # create domain
                $app->add_domain( session('login'), $domain );
                $creationSuccess = true;

            }
            else
            {
                # say param('domain')." contains a char not valid";
                $creationFailure = true;
            }

            session 'creationSuccess' => $creationSuccess;
            session 'creationFailure' => $creationFailure;
            session 'domainName' => param('domain');
            redirect '/home';

        }

    };

    get '/del/:domain' => sub {

        # TODO tests des droits
        my $app = initco();
        $app->delete_domain(session('login'), param('domain'));

        redirect request->referer;

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
            my ($success, @domains) = $app->get_domains( session('login') );

            template administration => {
                login => session('login')
                , admin => session('admin')
                , domains => [ @domains ]
                , alldomains => { %alldomains } };
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
            $app->register_user(param('login'), param('password'));
            session login => param('login');
            session password => param('password');
            redirect '/home';

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

            my $errmsg = session 'errmsg' ;
            session errmsg => '';

            template subscribe => {
                errmsg => $errmsg
            };
        }


    };

    get '/del/:user' => sub {

        my $app = initco();

        my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
            session('password') );

        if ( $auth_ok && $isadmin || session('login') eq param('user')) {
            $app->delete_user(param('user'));
        }

        redirect request->referer;

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
                    # User login and/or password are incorrect
                    redirect '/';
                }
            }
        }

        redirect '/home';

    };

};
