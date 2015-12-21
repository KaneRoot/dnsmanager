package rt::domain;

use v5.14;
use configuration ':all';
use encryption ':all';
use util ':all';
use app;
use utf8;
use Dancer ':syntax';
use Data::Dump qw( dump );

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

        my $zone = $app->get_zone( $$param{domain} );
        my $zf = $zone->get_zonefile();
        $zf->rr_mod(
            "$$param{name} $$param{ttl} $$param{type} $$param{rdata}"
            , "$$param{name} $$param{ttl} $$param{type} $$param{ip}"
        );
        $zone->update( $zf );

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

    for(qw/domain 
        oldtype oldname oldrdata oldttl
        newtype newname newrdata newttl/) {
        push @missingitems, $_ unless($$param{$_});
    }

    if($$param{oldtype} eq 'MX' && ! $$param{newpriority}) {
        push @missingitems, "newpriority";
    }

    if(@missingitems != 0) {
        $$res{deferred}{errmsg} = "Il manque : " . join ', ', @missingitems;
        return $res;
    }

    for(qw/domain 
        oldtype oldname oldrdata oldttl
        newtype newname newrdata newttl/) {
        say "$_ : $$param{$_}" if $$param{$_};
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

        my $zone = $app->get_zone( $$param{domain} );
        my $zf = $zone->get_zonefile();
        my $str_old = 
        "$$param{oldname} $$param{oldttl} $$param{oldtype} $$param{oldrdata}";
        my $str_new = "$$param{newname} $$param{newttl} $$param{newtype} ";
        if($$param{newtype} eq "MX") {
            $str_new .= "$$param{newpriority} $$param{newrdata}";
        }
        else {
            $str_new .= "$$param{newrdata}";
        }

        say "old : $str_old";
        say "new : $str_new";
        $zf->rr_mod( $str_old, $str_new);
        $zone->update( $zf );

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

        my $zone = $app->get_zone( $$param{domain} );
        my $zf = $zone->get_zonefile();
        $zf->rr_del_raw(
            "$$param{name} $$param{ttl} $$param{type} $$param{rdata}"
        );
        $zone->update( $zf );

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

        my $zone = $app->get_zone( $$param{domain} );
        my $zf = $zone->get_zonefile();

        $app->disconnect();

        $$res{template} = 'details';
        $$res{params} = {
            login           => $$session{login}
            , admin         => $$user{admin}
            , domain        => $$param{domain}
            , domain_zone   => $zf->dump()
            , user_ip       => $$request{address}
        };

        if($$param{expert}) {
            $$res{params}{expert} = 1;
        }
        else {
            $$res{params}{zone} = $zf->rr_array_to_array();
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

    for(qw/name ttl type rdata domain/) {
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

        my $zone = $app->get_zone( $$param{domain} );
        my $zf = $zone->get_zonefile();

        my $name = $$param{name};
        $name .= ".$$param{domain}" unless $name =~ /$$param{domain}$/;
        my $str_new = "$name $$param{ttl} $$param{type} ";

        my $rdata = $$param{rdata};

        if($$param{type} =~ /^(CNAME|MX|NS|PTR)$/ && $rdata !~ /\.$/) {
            $rdata .= ".$$param{domain}";
        }

        if($$param{type} eq "MX") {
            $str_new .= "$$param{priority} $$param{rdata}";
        }
        else {
            $str_new .= "$$param{rdata}";
        }
        $zf->rr_add_raw($str_new);
        $zf->new_serial();
        $zone->update( $zf );

        $app->disconnect();
    };

    if ( $@ ) {
        $$res{deferred}{errmsg} = q{Problème de mise à jour du domaine. }. $@;
    }

    $res
}

sub rt_dom_updateraw {
    my ($session, $param, $request) = @_;
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
            my $zone = $app->get_zone( $$param{domain} );
            my $zf = $zone->update_raw( $$param{zoneupdated} );
            $zone->update( $zf );
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
