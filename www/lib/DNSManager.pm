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
use Crypt::Digest::SHA256 qw( sha256_hex ) ;
use Storable qw( freeze thaw );
$Storable::Deparse = true;
$Storable::Eval=true;
use encoding 'utf-8'; # TODO check if this works well

# Include other libs relative to current path
use Find::Lib '../../'; # TODO remove it when it won't be usefull anymore
use app::app;

our $VERSION = '0.1';

# TODO we can check if dn matches our domain name
sub is_domain_name {
    my ($dn) = @_;
    my $ndd = qr/^([a-zA-Z0-9]+[a-zA-Z0-9-]*[a-zA-Z0-9]*.)*[a-zA-Z0-9]+[a-zA-Z0-9-]*[a-zA-Z0-9]$/;
    return $dn =~ $ndd;
}

# eventually change place
sub initco {

    my $cfg = new Config::Simple(dirname(__FILE__).'/../conf/config.ini');
    my $app = app->new( zdir => $cfg->param('zones_path')
        , dbname => $cfg->param('dbname')
        , dbhost => $cfg->param('host')
        , dbport => $cfg->param('port')
        , dbuser => $cfg->param('user')
        , dbpass => $cfg->param('passwd')
        , sgbd => $cfg->param('sgbd')
        , nsmasterv4 => $cfg->param('nsmasterv4')
        , nsmasterv6 => $cfg->param('nsmasterv6')
        , sshhost => $cfg->param('sshhost')
        , sshhostsec => $cfg->param('sshhostsec')
        , sshuser => $cfg->param('sshuser')
        , sshusersec => $cfg->param('sshusersec')
        , sshport => $cfg->param('sshport')
        , sshportsec => $cfg->param('sshportsec')
        , dnsapp => $cfg->param('dnsapp')
        , dnsappsec => $cfg->param('dnsappsec') );

    $app->init();

    return $app;
}

sub get_errmsg {
    my $err = session 'errmsg';
    session errmsg => '';
    $err;
}

# TODO check if the referer was from our website
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
            my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
                session('password') );

            if($auth_ok && ($isadmin || grep { $_ eq param('domain') } 
                    @{$user->domains}) ) {

                my $success = $app->update_domain_raw( param('zoneupdated')
                    , param('domain'));

                unless($success) {
                    session errmsg => q{Problème de mise à jour du domaine.};
                }

                redirect '/domain/details/' . param('domain');
            }
            else {
                session errmsg => q{Donnée privée, petit coquin. ;) };
                redirect '/';
            }
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
            my $priority   = param('priority');

            my $app = initco();
            my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
                session('password') );

            unless($auth_ok && ($isadmin || grep { $_ eq param('domain') } 
                    @{$user->domains}) ) {

                session errmsg => q{Donnée privée, petit coquin. ;) };
                redirect '/';
                return;
            }

            my $zone = $app->get_domain( param('domain') );
            given( $type )
            {

                when ('A') { 
                    my $a = $zone->a();
                    push( @$a, {name  => $name
                            , class => "IN"
                            , host  => $value
                            , ttl   => $ttl
                            , ORIGIN => $zone->origin} );
                }

                when ('AAAA') { 
                    my $aaaa = $zone->aaaa;
                    push(@$aaaa, {name  => $name
                            , class => "IN"
                            , host  => $value
                            , ttl   => $ttl
                            , ORIGIN => $zone->origin} );
                }

                when ('CNAME') { 
                    my $cname = $zone->cname;
                    push(@$cname,
                        {name  => $name
                            , class => "IN"
                            , host  => $value
                            , ttl   => $ttl
                            , ORIGIN => $zone->origin} );
                }

                when ('MX') { 
                    my $mx = $zone->mx;
                    push(@$mx, { name  => $name
                            , class => "IN"
                            , host  => $value
                            , priority  => $priority
                            , ttl   => $ttl
                            , ORIGIN => $zone->origin} );
                }

                when ('PTR') { 
                    my $ptr = $zone->ptr;
                    push(@$ptr, {name  => $name
                            , class => "IN"
                            , host  => $value
                            , ttl   => $ttl
                            , ORIGIN => $zone->origin} );
                }

                when ('NS') { 
                    my $ns = $zone->ns;
                    push(@$ns, {name  => $name
                            , class => "IN"
                            , host  => $value
                            , ttl   => $ttl
                            , ORIGIN => $zone->origin} );
                }

            }

            $zone->new_serial();
            dump($zone);

            $app->update_domain( $zone , param('domain'));

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

            my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
                session('password') );

            unless ( $auth_ok && ( $isadmin 
                    || grep { $_ =~ param('domain') } @{$user->domains})) {

                session errmsg => q{Auth non OK.};
                redirect '/ ';
                return;

            }

            my $zone = $app->get_domain(param('domain'));

            if( param( 'expert' ) )
            {
                template details => {
                    login           => session('login')
                    , admin         => session('admin')
                    , domain        => param('domain')
                    , domain_zone   => $zone->output()
                    , expert        => true	};
            }
            else
            {
                # say dump( $zone->cname());
                template details => {
                    login           => session('login')
                    , admin         => session('admin')
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
            redirect '/user/home';

        }

    };

    get '/del/:domain' => sub {

        my $app = initco();
        my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
            session('password') );

        unless ( $auth_ok && ( $isadmin 
                || grep { $_ =~ param('domain') } @{$user->domains})) {

            session errmsg => q{Auth non OK.};
            redirect '/ ';
            return;
        }

        unless( defined param('domain') ) {
            session errmsg => q<Domaine non renseigné.>;
            redirect get_route;
            return;
        }

        if( ! is_domain_name(param('domain'))) {
            session errmsg => q<Domaine non conforme.>;
            redirect get_route;
            return;
        }

        my $success = $app->delete_domain(session('login'), param('domain'));

        unless($success) {
            session errmsg => q{Impossible de supprimer le domaine.};
        }

        if( request->referer =~ "/domain/details" ) {
            redirect '/user/home';
        }
        else {
            redirect request->referer;
        }

    };

    get '/del/:domain/:name/:type/:host/:ttl' => sub {

        # Load :domain and search for corresponding data
        my $app = initco();

        my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
            session('password') );

        unless ( $auth_ok && ( $isadmin 
                || grep { $_ =~ param('domain') } @{$user->domains})) {

            session errmsg => q{Auth non OK.};
            redirect '/ ';
            return;
        }

        unless( session( 'user' ) and defined param('domain') ) {
            session errmsg => q<Domaine non renseigné.>;
            redirect get_route;
            return;
        }

        $app->delete_entry( param('domain'),
            {
                type => param('type'),
                name => param('name'),
                host => param('host'),
                ttl  => param('ttl')
            });

        redirect '/domain/details/'. param('domain');
    };

    get '/mod/:domain/:name/:type/:host/:ttl' => sub {

        my $app = initco();
        my ($auth_ok, $user, $isadmin) = $app->auth(session('login'),
            session('password') );

        unless ( $auth_ok && ( $isadmin 
                || grep { $_ =~ param('domain') } @{$user->domains})) {

            session errmsg => q{Auth non OK.};
            redirect '/ ';
            return;
        }

        unless( session( 'user' ) and defined param('domain') ) {
            session errmsg => q<Domaine non renseigné.>;
            redirect get_route;
            return;
        }

        $app->modify_entry( param('domain'),
            {
                type => param('type'),
                name => param('name'),
                host => param('host'),
                ttl  => param('ttl')
            },
            {
                newtype     => param('newtype'),
                newname     => param('newname'),
                newhost     => param('newhost'),
                newttl      => param('newttl'),
                newpriority => param('newpriority')
            });

        redirect '/domain/details/'. param('domain');
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

        my $pass = sha256_hex(param('password'));

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
                my $pass = sha256_hex(param('password'));
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
