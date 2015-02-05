package DNSManager;

use v5.14;
use strict;
use warnings;

use Dancer ':syntax';
use File::Basename;
use Storable qw( freeze thaw );
$Storable::Deparse = true;
$Storable::Eval=true;
use encoding 'utf-8'; # TODO check if this works well

use configuration ':all';
use util ':all';
use rt::root ':all';
use rt::domain ':all';
use app;

our $VERSION = '0.1';

sub get_errmsg {
    my $err = session 'errmsg';
    session errmsg => '';
    $err;
}

sub what_is_next {
    my ($res) = @_;

    if($$res{sessiondestroy}) {
        session->destroy;
    }

    unless($$res{params}{errmsg}) {
        $$res{params}{errmsg} = get_errmsg;
    }

    for(keys $$res{addsession}) {
        session $_ => $$res{addsession}{$_};
    }

    if($$res{route}) {
        redirect $$res{route} => $$res{params};
    }
    elsif($$res{template}) {
        template $$res{template} => $$res{params};
    }
}

sub get_param {
    my $param_values;
    for(@_) {
        $$param_values{$_} = param "$_";
    }
    $param_values;
}

sub get_request {
    my $request_values;
    for(@_) {
        if(/^address$/)     { $$request_values{$_} = request->address; }
        elsif(/^referer$/)  { $$request_values{$_} = request->referer; }
    }
    $request_values;
}

sub get_session {
    my $session_values;
    for(@_) {
        $$session_values{$_} = session "$_";
    }
    $session_values;
}

get '/' => sub { 
    what_is_next 
    rt_root session('login') , session('passwd'); 
};

prefix '/domain' => sub {

    any ['post', 'get'] => '/updateraw/:domain' => sub {
        what_is_next rt_dom_updateraw 
        get_session qw/login passwd/
        , get_param qw/domain zoneupdated/; # TODO verify this
    };

    any ['post', 'get'] => '/update/:domain' => sub {
        what_is_next rt_dom_update
        get_session qw/login passwd/
        , get_param qw/type name value ttl priority domain/;
    };

    get '/details/:domain' => sub {
        what_is_next rt_dom_details
        get_session qw/login passwd/
        , get_param qw/domain expert/
        , get_request qw/address referer/;
    };

    post '/add/' => sub {
        what_is_next rt_dom_add
        get_session qw/login passwd/
        , get_param qw/domain tld/;
    };

    get '/del/:domain' => sub {
        what_is_next rt_dom_del
        get_session qw/login passwd/
        , get_param qw/domain/
        , get_request qw/address referer/;
    };

    get '/del/:domain/:name/:type/:host/:ttl' => sub {
        what_is_next rt_dom_del_entry
        get_session qw/login passwd/
        , get_param qw/domain name type host ttl/
        , get_request qw/address referer/;
    };

    get '/mod/:domain/:name/:type/:host/:ttl' => sub {
        what_is_next rt_dom_mod_entry
        get_session qw/login passwd/
        , get_param qw/domain name type host ttl/
        , get_request qw/address referer/;
    };

    get '/cli/:login/:pass/:domain/:name/:type/:host/:ttl/:ip' => sub {
        what_is_next rt_dom_cli_mod_entry
        get_session qw/login/
        , get_param qw/passwd domain name type host ttl ip/;
    };
};

any ['get', 'post'] => '/admin' => sub {

    unless( session('login') )
    {
        redirect '/';
        return;
    }

    my $app = initco();
    my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
        session('password') );

    unless ( $auth_ok && $isadmin ) {
        session errmsg => q{Donnée privée, petit coquin. ;) };
        redirect '/ ';
        return;
    }

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
};

prefix '/user' => sub {

    get '/home' => sub {

        unless( session('login') ) {
            redirect '/';
            return;
        }

        my $app = initco();

        my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
            session('password') );

        unless( $auth_ok ) {
            session errmsg => q/problème de connexion à votre compte/;
            redirect '/';
            return;
        }

        my ($success, @domains) = $app->get_domains( session('login') );

        if( $success ) {

            my $cs = session('creationSuccess');
            my $dn = session('domainName');

            session creationSuccess => '';
            session domainName => '';

            template home => {
                login             => session('login')
                , admin           => session('admin')
                , domains         => [@domains]
                , creationSuccess => $cs
                , errmsg => get_errmsg
                , domainName      => $dn  };

        }
        else {
            session->destroy;
            redirect '/ ';
        }

    };


    get '/logout' => sub {
        session->destroy;
        redirect '/';
    };

    # add a user => registration
    post '/add/' => sub {

        unless ( param('login') && param('password') && param('password2') ) {
            session errmsg => q/Identifiant ou mot de passe non renseigné./;
            redirect '/user/subscribe';
            return;
        }

        unless ( param('password') eq param('password2')) {
            session errmsg => q/Les mots de passes ne sont pas identiques./;
            redirect '/user/subscribe';
            return;
        }

        my $pass = encrypt(param('password'));

        my $app = initco();
        my ($success) = $app->register_user(param('login'), $pass);

        if($success) {
            session login => param('login');
            session password => $pass;
            redirect '/user/home';
        }
        else {
            session errmsg => q/Ce pseudo est déjà pris./;
            redirect '/user/subscribe';
        }

    };

    get '/subscribe' => sub {

        if( defined session('login') ) {
            redirect '/user/home';
        }
        else {

            template subscribe => {
                errmsg => get_errmsg
                , admin         => session('admin')
            };
        }

    };

    get '/unsetadmin/:user' => sub {

        unless( defined param('user') ) {

            session errmsg => "L'administrateur n'est pas défini." ;
            redirect request->referer;
            return;

        }

        if(! defined session('login') ) {

            session errmsg => "Vous n'êtes pas connecté." ;
            redirect '/';
            return;
        }

        my $app = initco();

        my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
            session('password') );

        unless ( $auth_ok && $isadmin ) {
            session errmsg => q/Vous n'êtes pas administrateur./;
        }
        else {
            $app->set_admin(param('user'), 0);
        }

        if( request->referer =~ "/admin" ) {
            redirect request->referer;
        }
        else {
            redirect '/';
        }

    };

    get '/setadmin/:user' => sub {

        unless( defined param('user') ) {

            session errmsg => "L'utilisateur n'est pas défini." ;
            redirect request->referer;
            return;
        }

        if(! defined session('login') ) {

            session errmsg => "Vous n'êtes pas connecté." ;
            redirect '/';
            return;
        }

        my $app = initco();

        my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
            session('password') );

        unless ( $auth_ok && $isadmin ) {
            session errmsg => q/Vous n'êtes pas administrateur./;
        }
        else {
            $app->set_admin(param('user'), 1);
        }

        if( request->referer =~ "/admin" ) {
            redirect request->referer;
        }
        else {
            redirect '/';
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
                my $pass = encrypt(param('password'));
                my ($auth_ok, $user, $isadmin) = $app->auth(param('login'),
                    $pass );

                if( $auth_ok )
                {

                    session login => param('login');
                    session password => $pass;
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

        redirect '/user/home';

    };
};

1;
