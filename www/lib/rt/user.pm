package rt::user;

use v5.14;
use configuration ':all';
use encryption ':all';
use app;
use utf8;

use YAML::XS;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
rt_user_login
rt_user_del
rt_user_toggleadmin
rt_user_subscribe
rt_user_add
rt_user_home
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
        rt_user_login
        rt_user_del
        rt_user_toggleadmin
        rt_user_subscribe
        rt_user_add
        rt_user_home
        /] ); 

sub rt_user_login {
    my ($session, $param, $request) = @_;
    my $res;

    # Check if user is already logged
    if ( exists $$session{login} && length $$session{login} > 0 ) {
        $$res{params}{errmsg} = q{Vous êtes déjà connecté.};
        $$res{route} = '/';
        return $res;
    }

    # Check user login and password
    unless ( exists $$param{login} 
        && exists $$param{password} 
        && length $$param{login} > 0
        && length $$param{password} > 0 ) {
        $$res{params}{errmsg} = q{Vous n'avez pas renseigné tous les paramètres.};
        $$res{route} = '/';
        return $res;
    }

    eval {
        my $app = app->new(get_cfg());
        my $pass = encrypt($$param{password});
        my $user = $app->auth($$param{login}, $pass);

        unless( $user ) {
            $$res{params}{errmsg} = 
            q{Impossible de se connecter (login ou mot de passe incorrect).};
            $$res{route} = '/';
            return $res;
        }

        $$res{addsession}{login}  = $$param{login};
        $$res{addsession}{passwd} = $pass;
        # TODO adds a freeze feature, not used for now
        # $$res{addsession}{user}     = freeze( $user );

        if( $user->is_admin() ) {
            $$res{route} = '/admin';
        }
        else {
            $$res{route} = '/user/home';
        }
    };

    if( $@ ) {
        $$res{params}{errmsg} = q{Impossible de se connecter ! } . $@;
        $$res{sessiondestroy} = 1;
        $$res{route} = '/';
    }

    $res;
}

sub rt_user_del {
    my ($session, $param, $request) = @_;
    my $res;

    unless ( $$param{user} ) {
        $$res{params}{errmsg} = q{Le nom d'utilisateur n'est pas renseigné.};
        return $res;
    }

    my $app = app->new(get_cfg());

    my $user = $app->auth($$session{login}, $$session{passwd});

    if ( $user && $user->is_admin() || $$session{login} eq $$param{user} ) {

        eval { $app->delete_user($$param{user}); };

        if ( $@ ) {
            $$res{params}{errmsg} = 
            "L'utilisateur $$res{user} n'a pas pu être supprimé. $@";
        }
    }

    if( $$request{referer} ) {
        $$res{route} = $$request{referer};
    }
    else {
        $$res{route} = '/';
    }

    $res;
}

sub rt_user_toggleadmin {
    my ($session, $param, $request) = @_;
    my $res;

    unless( $$param{user} ) {
        $$res{params}{errmsg} = q{L'utilisateur n'est pas défini.};
        $$res{route} = $$request{referer};
        return $res;
    }

    my $app = app->new(get_cfg());

    my $user = $app->auth($$session{login}, $$session{passwd});

    unless ( $user && $user->is_admin() ) {
        $$res{params}{errmsg} = q{Vous n'êtes pas administrateur.};
        return $res;
    }

    $app->toggle_admin($$param{user});

    if( $$request{referer} =~ '/admin' ) {
        $$res{route} = $$request{referer};
    }
    else {
        $$res{route} = '/';
    }

    $res;
}

sub rt_user_subscribe {
    my ($session, $param, $request) = @_;
    my $res;

    if( $$session{login} ) {
        $$res{route} = '/user/home';
    }
    else {
        $$res{template} = 'subscribe';
    }

    $res;
}

sub rt_user_add {
    my ($session, $param, $request) = @_;
    my $res;

    unless ( $$param{login} && $$param{password} && $$param{password2} ) {
        $$res{params}{errmsg} = q{Identifiant ou mot de passe non renseigné.};
        $$res{route} = '/user/subscribe';
        return $res;
    }

    unless ( $$param{password} eq $$param{password2} ) {
        $$res{params}{errmsg} = q{Les mots de passes ne sont pas identiques.};
        $$res{route} = '/user/subscribe';
        return $res;
    }

    my $pass = encrypt($$param{password});

    my $app = app->new(get_cfg());

    eval { $app->register_user($$param{login}, $pass); };

    if($@) {
        $$res{params}{errmsg} = q{Ce pseudo est déjà pris.} . $@;
        $$res{route} = '/user/subscribe';
        return $res;
    }

    $$res{addsession}{login} = $$param{login};
    $$res{addsession}{passwd} = $pass;
    $$res{route} = '/user/home';

    $res;
}

sub rt_user_home {
    my ($session, $param, $request) = @_;
    my $res;

    $$res{template} = 'home';

    eval {
        my $app = app->new(get_cfg());

        my $user = $app->auth($$session{login}, $$session{passwd});

        unless( $user ) {
            $$res{params}{errmsg} = q{Problème de connexion à votre compte.};
            $$res{sessiondestroy} = 1;
            $$res{route} = '/';
            return $res;
        }

        my @domains = @{$user->domains};

        my $cs = $$session{creationSuccess};
        my $dn = $$session{domainName};

        $$res{delsession}{creationSuccess};
        $$res{delsession}{domainName};

        $$res{params} = {
            login               => $$session{login}
            , admin             => $user->is_admin()
            , domains           => [@domains]
            , provideddomains   => $$app{tld}
            , creationSuccess   => $cs
            , domainName        => $dn  
        };
    };

    if( $@ ) {
        $$res{sessiondestroy} = 1;
        $$res{params}{errmsg} = q{On a chié quelque-part.} . $@;
        $$res{route} = '/';
    }

    $res;
}

1;
