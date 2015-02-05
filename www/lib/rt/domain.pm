package rt::domain;

use configuration ':all';
use app;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
rt_dom_add
rt_dom_details
rt_dom_update
rt_dom_updateraw
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
        rt_dom_add
        rt_dom_details
        rt_dom_update
        rt_dom_updateraw
        /] ); 

sub rt_dom_add {
    my ($session, $param) = @_;
    my $res;

    # check if user is logged & if domain parameter is set
    unless( $$session{login} && $$param{domain}) {
        $$res{route} = '/';
        return $res;
    }

    $$res{route} = '/user/home';
    $$res{addsession}{domainName} = $$param{domain};

    if(is_reserved($$param{domain})) {
        $$res{errmsg} = q{Le nom de domaine est réservé.};
    }
    elsif ( ! is_domain_name($$param{domain}) ) {
        $$res{errmsg} = 
        q{Le nom de domaine entré contient des caractères invalides.};
    }
    elsif ( ! is_valid_tld($$param{tld}) ) {
        $$res{errmsg} = 
        q{Vous avez entré un mauvais TLD.};
    }
    else {

        my $domain = $$param{domain} . $$param{tld};

        my $app = app->new(get_cfg());
        my ($success) = $app->add_domain( $$session{login}, $domain );

        if ($success) {
            $$res{addsession}{creationSuccess} = 
            q{Le nom de domaine a bien été réservé ! };
        }
        else {
            $$res{errmsg} = q{Le nom de domaine est déjà pris.};
        }

    }

    $res;
}

sub rt_dom_details {
    my ($session, $param, $ip) = @_;
    my $res;

    # check if user is logged & if domain parameter is set
    unless( $$session{login} && $$param{domain}) {
        $$res{route} = '/';
        return $res;
    }

    my $app = app->new(get_cfg());

    my $user = $app->auth($$session{login}, $$session{passwd});

    unless ( $user && 
        ( $user->is_admin()
            || grep { $_ eq $$param{domain} } @{$user->domains})) {

        $$res{errmsg} = q{Auth non OK.};
        $$res{route} = '/';
        return $res;

    }

    my $zone = $app->get_domain($$param{domain});

    $$res{template} = 'details';
    $$res{params} = {
        login           => $$session{login}
        , admin         => $user->is_admin()
        , domain        => $$param{domain}
        , domain_zone   => $zone->output()
        , user_ip       => $ip
    };

    if($$param{expert}) {
        $$res{params}{expert} = true;
    }
    else {
        $$res{params}{a}        = $zone->a();
        $$res{params}{aaaa}     = $zone->aaaa();
        $$res{params}{cname}    = $zone->cname();
        $$res{params}{ptr}      = $zone->ptr();
        $$res{params}{mx}       = $zone->mx();
        $$res{params}{ns}       = $zone->ns();
    }

    $res;
}

sub rt_dom_update {
    my ($session, $param) = @_;
    my $res;

    unless( $$session{login} && $$param{domain} ) {
        $$res{route} = '/';
        return $res;
    }

    my $app = app->new(get_cfg());
    my $user = $app->auth($$session{login}, $$session{passwd});

    unless($user && ($user->is_admin() || grep { $_ eq $$param{domain} } 
            @{$user->domains}) ) {

        $$res{errmsg} = q{Donnée privée, petit coquin. ;) };
        $$res{route} = '/';
        return;
    }

    my $zone = $app->get_domain( $$param{domain} );

    # TODO better naming convention
    my $x;
    for( $$param{type} ) {
        if($_ eq 'A')           { $x = $zone->a(); }
        elsif( $_ eq 'AAAA')    { $x = $zone->aaaa; }
        elsif( $_ eq 'CNAME')   { $x = $zone->cname; }
        elsif( $_ eq 'MX')      { $x = $zone->mx; }
        elsif( $_ eq 'PTR')     { $x = $zone->ptr; }
        elsif( $_ eq 'NS')      { $x = $zone->ns; }
    }

    push(@$x, {
            name        => $$param{name}
            , class     => "IN"
            , host      => $$param{value}
            , ttl       => $$param{ttl}
            , ORIGIN    => $zone->origin} );

    $zone->new_serial();
    #Dump($zone);

    $app->update_domain( $zone , $$param{domain} );
    $$res{route} = '/domain/details/' . $$param{domain};

    $res;
}

sub rt_dom_updateraw {
    my ($session, $param) = @_;
    my $res;

    # check if user is logged & if domain parameter is set
    unless($$session{login} && $$param{domain}) {
        $$res{sessiondestroy} = 1;
        $$res{route} = '/';
        return $res;
    }

    my $app = app->new(get_cfg());
    my $user = $app->auth($$session{login}, $$session{passwd});

    # if the user exists and if 
    # he is admin or he owns the requested domain
    if($user && 
        ($user->is_admin() 
            || grep { $_ eq $$param{domain} } @{$user->domains}) ) {

        my $success = 
        $app->update_domain_raw($$param{zoneupdated}, $$param{domain});

        unless($success) {
            $$res{errmsg} = q{Problème de mise à jour du domaine.};
        }

        $$res{route} = '/domain/details/' . $$param{domain};
    }
    else {
        $$res{errmsg} = q{Donnée privée, petit coquin. ;) };
        $$res{route} = '/';
    }

    $res;
}

1;
