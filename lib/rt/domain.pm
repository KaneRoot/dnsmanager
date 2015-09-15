package rt::domain;

use v5.14;
use configuration ':all';
use encryption ':all';
use util ':all';
use app;
use utf8;
use Dancer ':syntax';

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
rt_dom_cli_mod_entry
rt_dom_mod_entry
rt_dom_del_entry
rt_dom_del
rt_dom_add
rt_dom_details
rt_dom_update
rt_dom_updateraw
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
rt_dom_cli_mod_entry
rt_dom_mod_entry
rt_dom_del_entry
rt_dom_del
rt_dom_add
rt_dom_details
rt_dom_update
rt_dom_updateraw
        /] ); 

sub rt_dom_cli_mod_entry {
    my ($session, $param, $request) = @_;
    my $res;

    eval {
        my $pass = encrypt($$param{pass});
        my $app = app->new(get_cfg());

        my $user = $app->auth($$session{login}, $pass);

        unless ( $user &&
            ( $user->is_admin()
                || grep { $_ eq $$param{domain} } @{$user->domains})) {
            $$res{params}{errmsg} = q{Auth non OK.};
            return $res;
        }

        $app->modify_entry( $$param{domain}
            , {
                type    => $$param{type}
                , name  => $$param{name}
                , host  => $$param{host}
                , ttl   => $$param{ttl}
            }
            , {
                newtype         => $$param{type}
                , newname       => $$param{name}
                , newhost       => $$param{ip}
                , newttl        => $$param{ttl}
                , newpriority   => ''
            });

        $app->disconnect();
    };

    $res
}

sub rt_dom_mod_entry {
    my ($session, $param, $request) = @_;
    my $res;

    eval {
        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && 
            ( $user->is_admin()
                || grep { $_ eq $$param{domain} } @{$user->domains})) {
            $$res{params}{errmsg} = q{Auth non OK.};
            $$res{route} = '/';
            return $res;
        }

        unless( $$param{domain} ) {
            $$res{params}{errmsg} = q<Domaine non renseigné.>;
            $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
            return $res;
        }

        $app->modify_entry( $$param{domain}
            , {
                type => $$param{type}
                , name => $$param{name}
                , host => $$param{host}
                , ttl  => $$param{ttl}
            }
            , {
                newtype       => $$param{newtype}
                , newname     => $$param{newname}
                , newhost     => $$param{newhost}
                , newttl      => $$param{newttl}
                , newpriority => $$param{newpriority}
            });
        $app->disconnect();
    };

    $$res{route} = '/domain/details/'. $$param{domain};

    $res
}

sub rt_dom_del_entry {
    my ($session, $param, $request) = @_;
    my $res;

    eval {
        # Load :domain and search for corresponding data
        my $app = app->new(get_cfg());

        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && 
            ( $user->is_admin()
                || grep { $_ eq $$param{domain} } @{$user->domains})) {
            $$res{params}{errmsg} = q{Auth non OK.};
            $$res{route} = '/';
            return $res;
        }

        unless( $$param{domain} ) {
            $$res{params}{errmsg} = q{Domaine non renseigné.};
            $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
            return $res;
        }

        $app->delete_entry( $$param{domain}, {
                type => $$param{type},
                name => $$param{name},
                host => $$param{host},
                ttl  => $$param{ttl}
            });
        $app->disconnect();
    };

    $$res{route} = '/domain/details/'. $$param{domain};

    $res
}

sub rt_dom_del {
    my ($session, $param, $request) = @_;
    my $res;

    unless( $$param{domain} ) {
        $$res{params}{errmsg} = q<Domaine non renseigné.>;
        $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
        return $res;
    }

    if( ! is_domain_name($$param{domain})) {
        $$res{params}{errmsg} = q<Domaine non conforme.>;
        $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
        return $res;
    }

    eval { 
        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && 
            ( $user->is_admin()
                || grep { $_ eq $$param{domain} } @{$user->domains})) {
            $$res{params}{errmsg} = q{Auth non OK.};
            $$res{route} = '/';
            return $res;
        }

        $app->delete_domain($$param{domain}); 
        $app->disconnect();
    };

    if($@) {
        $$res{params}{errmsg} = q{Impossible de supprimer le domaine. } . $@;
        $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
        return $res;
    }

    if( $$request{referer} =~ "/domain/details" ) {
        $$res{route} = '/user/home';
    }
    else {
        $$res{route} = $$request{referer};
    }

    $res
}

sub rt_dom_add {
    my ($session, $param) = @_;
    my $res;

    $$res{route} = '/user/home';

    # check if user is logged
    unless( exists $$session{login}) { 
        $$res{params}{errmsg} = q{Vous n'êtes pas enregistré. };
        $$res{sessiondestroy} = 1;
        $$res{route} = '/';
        return $res;
    }

    # check if domain parameter is set
    unless( exists $$param{domain} && length $$param{domain} > 0) {
        $$res{params}{errmsg} = 
        q{Domaine personnel non renseigné correctement. };
        return $res;
    }

    # check if tld parameter is set
    unless( exists $$param{tld} && length $$param{tld} > 0) {
        $$res{params}{errmsg} = q{Choix du domaine non fait. };
        return $res;
    }

    if(is_reserved($$param{domain})) {
        $$res{params}{errmsg} = q{Nom de domaine réservé. };
    }
    elsif ( ! is_domain_name($$param{domain}) ) {
        $$res{params}{errmsg} = 
        q{Nom de domaine choisi comportant des caractères invalides. };
    }
    elsif ( ! is_valid_tld($$param{tld}) ) {
        $$res{params}{errmsg} = 
        q{Mauvais choix de domaine. };
    }
    else {

        my $domain = $$param{domain} . $$param{tld};

        eval {
            my $app = app->new(get_cfg());
            my $user = $app->auth($$session{login}, $$session{passwd});
            $app->add_domain( $user, $domain );

            $$res{addsession}{domainName} = $$param{domain};
            $$res{addsession}{creationSuccess} = 
            q{Le nom de domaine a bien été réservé ! };

            $app->disconnect();
        };

        if( $@ ) {
            $$res{params}{errmsg} = q{Une erreur est survenue. } . $@;
        }

    }

    $res
}

sub rt_dom_details {
    my ($session, $param, $request) = @_;
    my $res;

    # check if user is logged & if domain parameter is set
    unless( $$session{login} && $$param{domain}) {
        $$res{route} = '/';
        return $res;
    }

    eval {
        my $app = app->new(get_cfg());

        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && 
            ( $user->is_admin()
                || grep { $_ eq $$param{domain} } @{$user->domains})) {

            $$res{params}{errmsg} = q{Auth non OK.};
            $$res{route} = '/';
            return $res;

        }

        my $zone = $app->get_domain($$param{domain});

        $app->disconnect();

        $$res{template} = 'details';
        $$res{params} = {
            login           => $$session{login}
            , admin         => $user->is_admin()
            , domain        => $$param{domain}
            , domain_zone   => $zone->output()
            , user_ip       => $$request{address}
        };

        if($$param{expert}) {
            $$res{params}{expert} = 1;
        }
        else {
            $$res{params}{a}        = $zone->a();
            $$res{params}{aaaa}     = $zone->aaaa();
            $$res{params}{cname}    = $zone->cname();
            $$res{params}{ptr}      = $zone->ptr();
            $$res{params}{mx}       = $zone->mx();
            $$res{params}{ns}       = $zone->ns();
        }
    };

    $res;
}

sub rt_dom_update {
    my ($session, $param) = @_;
    my $res;

    unless( $$session{login} && $$param{domain} ) {
        $$res{route} = '/';
        return $res;
    }

    eval {
        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        unless($user && ($user->is_admin() || grep { $_ eq $$param{domain} } 
                @{$user->domains}) ) {

            $$res{params}{errmsg} = q{Donnée privée, petit coquin. ;) };
            $$res{route} = '/';
            return $res;
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
            elsif( $_ eq 'TXT')      { $x = $zone->txt; } # TODO verify this
        }

        push(@$x, {
                name        => $$param{name}
                , class     => "IN"
                , host      => $$param{value}
                , ttl       => $$param{ttl}
                , ORIGIN    => $zone->origin} );

        $zone->new_serial();

        #debug(Dump $zone);

        $app->update_domain( $zone , $$param{domain} );
        $app->disconnect();
    };

    $$res{route} = '/domain/details/' . $$param{domain};

    $res
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

    eval {
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
                $$res{params}{errmsg} = q{Problème de mise à jour du domaine.};
            }

            $$res{route} = '/domain/details/' . $$param{domain};
        }
        else {
            $$res{params}{errmsg} = q{Donnée privée, petit coquin. ;) };
            $$res{route} = '/';
        }

        $app->disconnect();
    };

    $res
}

1;
