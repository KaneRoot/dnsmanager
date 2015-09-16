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

        unless ( $user && ( $$user{admin} || 
                $app->is_owning_domain($$user{login}, $$param{domain}))) {
            $app->disconnect();
            $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
            $$res{route} = '/';
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

    $$res{route} = '/domain/details/'. $$param{domain};

    # check if user is logged
    unless( $$session{login}) { 
        $$res{deferred}{errmsg} = q{Vous n'êtes pas enregistré. };
        $$res{sessiondestroy} = 1;
        return $res;
    }

    my @missingitems;

    for(qw/type name ttl domain name type host ttl 
            newhost newname newttl/) {
        push @missingitems, $_ unless($$param{$_});
    }

    if($$param{type} eq 'MX' && ! $$param{newpriority}) {
        push @missingitems, "newpriority";
    }

    if(@missingitems != 0) {
        $$res{deferred}{errmsg} = "Il manque : " . join ', ', @missingitems;
        return $res;
    }


    eval {
        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && ( $$user{admin} || 
                $app->is_owning_domain($$user{login}, $$param{domain}))) {
            $app->disconnect();
            $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
            return $res;
        }

        unless( $$param{domain} ) {
            $$res{deferred}{errmsg} = q<Domaine non renseigné.>;
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

    $res
}

sub rt_dom_del_entry {
    my ($session, $param, $request) = @_;
    my $res;

    eval {
        # Load :domain and search for corresponding data
        my $app = app->new(get_cfg());

        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && ( $$user{admin} || 
                $app->is_owning_domain($$user{login}, $$param{domain}))) {
            $app->disconnect();
            $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
            $$res{route} = '/';
            return $res;
        }

        unless( $$param{domain} ) {
            $$res{deferred}{errmsg} = q{Domaine non renseigné.};
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
        $$res{deferred}{errmsg} = q<Domaine non renseigné.>;
        $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
        return $res;
    }

    if( ! is_domain_name($$param{domain})) {
        $$res{deferred}{errmsg} = q<Domaine non conforme.>;
        $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
        return $res;
    }

    eval { 
        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && ( $$user{admin} || 
                $app->is_owning_domain($$user{login}, $$param{domain}))) {
            $app->disconnect();
            $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
            $$res{route} = '/';
            return $res;
        }

        $app->delete_domain($$param{domain}); 
        $app->disconnect();
    };

    if($@) {
        $$res{deferred}{errmsg} = q{Impossible de supprimer le domaine. } . $@;
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
    unless( $$session{login}) { 
        $$res{deferred}{errmsg} = q{Vous n'êtes pas enregistré. };
        $$res{sessiondestroy} = 1;
        $$res{route} = '/';
        return $res;
    }

    # check if domain parameter is set
    unless( $$param{domain} && length $$param{domain} > 0) {
        $$res{deferred}{errmsg} = 
        q{Domaine personnel non renseigné correctement. };
        return $res;
    }

    # check if tld parameter is set
    unless( $$param{tld} && length $$param{tld} > 0) {
        $$res{deferred}{errmsg} = q{Choix du domaine non fait. };
        return $res;
    }

    if(is_reserved($$param{domain})) {
        $$res{deferred}{errmsg} = q{Nom de domaine réservé. };
    }
    elsif ( ! is_domain_name($$param{domain}) ) {
        $$res{deferred}{errmsg} = 
        q{Nom de domaine choisi comportant des caractères invalides. };
    }
    elsif ( ! is_valid_tld($$param{tld}) ) {
        $$res{deferred}{errmsg} = 
        q{Mauvais choix de domaine. };
    }
    else {

        my $domain = $$param{domain} . $$param{tld};

        eval {
            my $app = app->new(get_cfg());
            my $user = $app->auth($$session{login}, $$session{passwd});
            $app->add_domain( $$user{login}, $domain );

            $$res{addsession}{domainName} = $$param{domain};
            $$res{deferred}{succmsg} = 
            q{Le nom de domaine a bien été réservé ! };

            $app->disconnect();
        };

        if( $@ ) {
            $$res{deferred}{errmsg} = q{Une erreur est survenue. } . $@;
        }

    }

    $res
}

sub rt_dom_details {
    my ($session, $param, $request) = @_;
    my $res;

    # check if user is logged & if domain parameter is set
    unless($$session{login}) {
        $$res{deferred}{errmsg} = q{Session inactive.};
        $$res{route} = '/';
        return $res;
    }

    unless($$param{domain}) {
        $$res{deferred}{errmsg} = q{Domaine non renseigné.};
        $$res{route} = '/';
        return $res;
    }

    my $app;
    eval {
        $app = app->new(get_cfg());

        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && ( $$user{admin} || 
                $app->is_owning_domain($$user{login}, $$param{domain}))) {
            $app->disconnect();
            $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
            $$res{route} = '/';
            return $res;
        }

        my $zone = $app->get_domain($$param{domain});

        $app->disconnect();

        $$res{template} = 'details';
        $$res{params} = {
            login           => $$session{login}
            , admin         => $$user{admin}
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

    if($@) {
        $app->disconnect() if $app;
        $$res{deferred}{errmsg} = $@;
        $$res{route} = '/';
        return $res;
    }

    $res
}

sub rt_dom_update {
    my ($session, $param) = @_;
    my $res;

    unless( $$session{login} && $$param{domain} ) {
        $$res{route} = '/';
        return $res;
    }

    $$res{route} = '/domain/details/'. $$param{domain};

    my @missingitems;

    for(qw/type name value ttl domain/) {
        push @missingitems, $_ unless($$param{$_});
    }
    
    if($$param{type} eq 'MX' && ! $$param{priority}) {
        push @missingitems, "priority";
    }

    if(@missingitems != 0) {
        $$res{deferred}{errmsg} = "Il manque : " . join ', ', @missingitems;
        return $res;
    }

    eval {
        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && ( $$user{admin} || 
                $app->is_owning_domain($$user{login}, $$param{domain}))) {
            $app->disconnect();
            $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
            $$res{route} = '/';
            return $res;
        }

        my $zone = $app->get_domain( $$param{domain} );

        # TODO better naming convention
        my $entries;
        for( $$param{type} ) {
            if($_ eq 'A')           { $entries = $zone->a }
            elsif( $_ eq 'AAAA')    { $entries = $zone->aaaa }
            elsif( $_ eq 'CNAME')   { $entries = $zone->cname }
            elsif( $_ eq 'MX')      { $entries = $zone->mx }
            elsif( $_ eq 'PTR')     { $entries = $zone->ptr }
            elsif( $_ eq 'NS')      { $entries = $zone->ns }
            elsif( $_ eq 'TXT')     { $entries = $zone->txt } # TODO verify this
        }

        my $new_entry = {
            name        => $$param{name}
            , class     => "IN"
            , host      => $$param{value}
            , ttl       => $$param{ttl}
            , ORIGIN    => $zone->origin
        };

        $$new_entry{priority} = $$param{priority} if $$param{type} eq 'MX';
        push @$entries, $new_entry;

        $zone->new_serial();

        $app->update_domain( $zone , $$param{domain} );
        $app->disconnect();
    };

    if ( $@ ) {
        $$res{deferred}{errmsg} = q{Problème de mise à jour du domaine. }. $@;
    }

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

    my @missingitems;

    for(qw/domain zoneupdated/) {
        push @missingitems, $_ unless($$param{$_});
    }

    if(@missingitems != 0) {
        $$res{deferred}{errmsg} = "Il manque : " . join ', ', @missingitems;
        $$res{route} = '/user/home';
        return $res;
    }

    eval {
        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        # if the user exists and if 
        # he is admin or he owns the requested domain
        unless ( $user && ( $$user{admin} || 
                $app->is_owning_domain($$user{login}, $$param{domain}))) {
            $app->disconnect();
            $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
            $$res{route} = '/';
            return $res;
        }
        else {
            my $success = 
            $app->update_domain_raw($$param{zoneupdated}, $$param{domain});

            unless($success) {
                $$res{deferred}{errmsg} = q{Problème de mise à jour du domaine.};
            }

            $$res{route} = '/domain/details/' . $$param{domain};
        }

        $app->disconnect();
    };

    if($@) {
        $$res{deferred}{errmsg} = $@;
        $$res{route} = '/user/home';
    }

    $res
}

1;
