package rt::domain;

use v5.14;
use configuration ':all';
use encryption ':all';
use util ':all';
use app;
use utf8;
use Dancer ':syntax';
use Data::Dump qw( dump );
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use MIME::Base64 qw(encode_base64 decode_base64);

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
rt_dom_cli_mod_entry
rt_dom_cli_autoupdate
rt_dom_mod_entry
rt_dom_del_entry
rt_dom_del
rt_dom_add
rt_dom_details
rt_dom_add_entry
rt_dom_updateraw
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
rt_dom_cli_mod_entry
rt_dom_cli_autoupdate
rt_dom_mod_entry
rt_dom_del_entry
rt_dom_del
rt_dom_add
rt_dom_details
rt_dom_add_entry
rt_dom_updateraw
        /] ); 

sub rt_dom_cli_autoupdate {
    my ($session, $param, $request) = @_;
    my $res;

    my @missingitems;
    my @items = qw/login pass domain name type rdata/;

    for(@items) {
        push @missingitems, $_ unless($$param{$_});
    }

    if(@missingitems != 0) {
        say "Il manque : " . join ', ', @missingitems;
        return $res;
    }

    for(@items) {
        say "::::::::: $_ : $$param{$_}" if $$param{$_};
    }

    if(! is_ipv4($$param{rdata}) && ! is_ipv6($$param{rdata})) {
        say "Attention, ceci n'est pas une adresse IP :  $$param{rdata}.";
        return $res;
    }

    eval {
        my $pass = encrypt($$param{pass});
        my $app = app->new(get_cfg());

        my $user;

        eval {
            $user = $app->auth($$param{login}, $pass);
        };

        # if the mdp is in base64
        # useful for cli and http GET messages
        if( $@ ) {
            my $passb64 = decode_base64($$param{pass});
            $pass = encrypt($passb64);
            $user = $app->auth($$param{login}, $pass);
        }

        unless ( $user && ( $$user{admin} || 
                $app->is_owning_domain($$user{login}, $$param{domain}))) {
            $app->disconnect();
            say q{Donnée privée, petit coquin. ;) };
            return $res;
        }

        my $zone = $app->get_zone( $$param{domain} );
        my $zf = $zone->get_zonefile();

        my $name = $$param{name};

        $name =~ s/@/$$param{domain}./;

        if($name =~ /$$param{domain}$/) {
            $name .= '.';
        }

        if($name !~ /\.$/) {
            $name .= ".$$param{domain}."
        }

        my $rr_list = $zf->rr_search($name, $$param{type});
        my $rr;
        if(@$rr_list) {
            $rr = pop @$rr_list;
        }
        else {
            say "Pas d'entrée au nom $name de type $$param{type} trouvée.";
            return $res;
        }

        my $str_old = "$$rr{name} $$rr{ttl} $$rr{type} $$rr{rdata}";
        my $str_new = "$$rr{name} $$rr{ttl} $$rr{type} $$param{rdata}";

        say "old : $str_old";
        say "new : $str_new";
        if($$rr{rdata} eq $$param{rdata}) {
            say "SAME";
        }
        else {
            $zf->rr_mod($str_old, $str_new);
            $zone->update( $zf );
        }

        $app->disconnect();
    };

    if ($@) {
        say "Problème : $@";
    }

    $res
}

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
    my @items = qw/domain type
    oldname oldrdata oldttl
    newname newrdata newttl/;

    if($$param{type} && $$param{type} eq 'MX') {
        push @items, qw/oldpriority newpriority/;
    }

    if($$param{type} && $$param{type} eq 'SRV') {
        push @items, qw/
        oldpriority oldweight oldport
        newpriority newweight newport/;
    }

    for(@items) {
        push @missingitems, $_ unless($$param{$_});
    }

    if(@missingitems != 0) {
        $$res{deferred}{errmsg} = "Il manque : " . join ', ', @missingitems;
        return $res;
    }

    for(@items) {
        say "::::::::: $_ : $$param{$_}" if $$param{$_};
    }

    eval {

        unless( $$param{domain} ) {
            $$res{deferred}{errmsg} = q<Domaine non renseigné.>;
            $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
            return $res;
        }

        my $oldname = $$param{oldname};
        my $newname = $$param{newname};
        my $oldrdata = $$param{oldrdata};
        my $newrdata = $$param{newrdata};

        $oldname =~ s/@/$$param{domain}./g;
        $newname =~ s/@/$$param{domain}./g;

        if ($$param{type} eq 'A' && ! is_ipv4($newrdata)) {
            $$res{deferred}{errmsg} = 
            "Il faut une adresse IPv4 pour un enregistrement de type A."
            . " Ceci n'est pas une adresse IPv4 : $newrdata";
            $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
            return $res;
        }

        if ($$param{type} eq 'AAAA' && ! is_ipv6($newrdata)) {
            $$res{deferred}{errmsg} = 
            "Il faut une adresse IPv6 pour un enregistrement de type AAAA."
            . " Ceci n'est pas une adresse IPv6 : $newrdata";
            $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
            return $res;
        }

        # si le type est A, AAAA, SRV, TXT, CNAME, MX, NS
        # le name doit être un domaine
        # si ce domaine n'est pas absolu, rajouter ".domain."
        if($$param{type} =~ /^(A|AAAA|SRV|TXT|CNAME|MX|NS)$/) {
            $newname .= ".$$param{domain}." if($newname !~ /\.$/);
            $oldname .= ".$$param{domain}." if($oldname !~ /\.$/);
        }

        # si le type est CNAME, MX, NS ou PTR
        # le rdata doit être un domaine
        # si ce domaine n'est pas absolu, rajouter ".domain."
        if($$param{type} =~ /^(CNAME|MX|NS|PTR)$/) {
            $oldrdata =~ s/@/$$param{domain}./;
            $newrdata =~ s/@/$$param{domain}./;
            $oldrdata .= ".$$param{domain}." if($oldrdata !~ /\.$/);
            $newrdata .= ".$$param{domain}." if($newrdata !~ /\.$/);
        }

        if ($$param{type} =~ /^(CNAME|MX|NS|PTR|SRV)$/i
            && ! is_domain_name ($newrdata))
        {
            $$res{deferred}{errmsg} = 
            "Une entrée $$param{type} doit avoir un nom de domaine "
            . "(pas une URL, pas de http://) : '$newrdata' n'est pas correct.";
            $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
            return $res;
        }

        my $str_old = "$oldname $$param{oldttl} $$param{type} ";
        my $str_new = "$newname $$param{newttl} $$param{type} ";

        if($$param{type} eq "MX") {
            $str_old .= "$$param{oldpriority} $oldrdata";
            $str_new .= "$$param{newpriority} $newrdata";
        }
        elsif ($$param{type} eq "SRV") {
            $str_old .= "$$param{oldpriority} $$param{oldweight} "
            ."$$param{oldport} $oldrdata";
            $str_new .= "$$param{newpriority} $$param{newweight} "
            ."$$param{newport} $newrdata";
        }
        else {
            $str_old .= "$oldrdata";
            $str_new .= "$newrdata";
        }

        say "::: ___ str_old : $str_old";
        say "::: ___ str_new : $str_new";

        # Do the modification of the entry

        my $app = app->new(get_cfg());
        my $user = $app->auth($$session{login}, $$session{passwd});

        unless ( $user && ( $$user{admin} || 
                $app->is_owning_domain($$user{login}, $$param{domain}))) {
            $app->disconnect();
            $$res{deferred}{errmsg} = q{Donnée privée, petit coquin. ;) };
            return $res;
        }

        my $zone = $app->get_zone( $$param{domain} );
        my $zf = $zone->get_zonefile();

        $zf->rr_mod( $str_old, $str_new);
        $zone->update( $zf );

        $app->disconnect();
    };

    if($@) {
        $$res{deferred}{errmsg} = q{Modification impossible. } . $@;
        return $res;
    }

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

        my @missingitems;
        my @items = qw/domain name ttl type rdata/;

        if ($$param{type} && $$param{type} eq 'SRV') {
            push @items, qw/priority weight port/;
        }
        elsif ($$param{type} && $$param{type} eq 'MX') {
            push @items, qw/priority/;
        }

        for(@items) {
            push @missingitems, $_ unless($$param{$_});
        }

        for(@items) {
            say "::::::::: $_ : $$param{$_}" if $$param{$_};
        }

        if(@missingitems != 0) {
            $$res{deferred}{errmsg} = "Il manque : " . join ', ', @missingitems;
            $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
            return $res;
        }

        my $rdata = $$param{rdata};
        my $name = $$param{name};

        $name =~ s/@/$$param{domain}./;

        # si le type est A, AAAA, SRV, TXT, CNAME, MX, NS
        # le name doit être un domaine
        # si ce domaine n'est pas absolu, rajouter ".domain."
        if($$param{type} =~ /^(A|AAAA|SRV|TXT|CNAME|MX|NS)$/ && $name !~ /\.$/){
            $name .= ".$$param{domain}.";
        }

        # si le type est CNAME, MX, NS ou PTR
        # le rdata doit être un domaine
        # si ce domaine n'est pas absolu, rajouter ".domain."
        if($$param{type} =~ /^(CNAME|SRV|MX|NS|PTR)$/) {
            $rdata =~ s/@/$$param{domain}./;
            $rdata .= ".$$param{domain}." if $rdata !~ /\.$/;
        }

        my $zone = $app->get_zone( $$param{domain} );
        my $zf = $zone->get_zonefile();

        my $str_del = "$name $$param{ttl} $$param{type} ";

        if( $$param{type} eq 'SRV') {
            $str_del .=
            "$$param{priority} $$param{weight} $$param{port} $rdata";
        }
        elsif ($$param{type} eq 'MX') {
            $str_del .= "$$param{priority} $rdata";
        }
        else {
            $str_del .= "$rdata";
        }

        $zf->rr_del_raw( $str_del );
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
            $$res{params}{zone} = $zf->rr_array_to_array_stripped();
        }
    };

    if($@) {
        $app->disconnect() if $app;
        $$res{deferred}{errmsg} = q{Une erreur est survenue. } . $@;
        $$res{route} = '/';
        return $res;
    }

    $res
}

sub rt_dom_add_entry {
    my ($session, $param, $request) = @_;
    my $res;

    unless( $$session{login} && $$param{domain} ) {
        $$res{route} = '/';
        return $res;
    }

    $$res{route} = '/domain/details/'. $$param{domain};

    my @missingitems;
    my @items = qw/domain type name ttl rdata/;

    if($$param{type} && $$param{type} eq 'MX') {
        push @items, qw/priority/;
    }

    if($$param{type} && $$param{type} eq 'SRV') {
        push @items, qw/priority weight port/;
    }

    for(@items) {
        push @missingitems, $_ unless($$param{$_});
    }

    if(@missingitems != 0) {
        $$res{deferred}{errmsg} = "Il manque : " . join ', ', @missingitems;
        return $res;
    }

    eval {
        # Perform tests on the different entries

        my $name = $$param{name};

        $name =~ s/@/$$param{domain}./;

        if($name =~ /$$param{domain}$/) {
            $name .= '.';
        }

        if($name !~ /\.$/) {
            $name .= ".$$param{domain}."
        }

        my $str_new = "$name $$param{ttl} $$param{type} ";
        my $rdata = $$param{rdata};

        if($$param{type} =~ /^(CNAME|MX|NS|PTR|SRV)$/) {
            $rdata =~ s/@/$$param{domain}./;
            $rdata .= ".$$param{domain}." if( $rdata !~ /\.$/);
        }

        if ($$param{type} =~ /^(CNAME|MX|NS|PTR|SRV)$/i
            && ! is_domain_name ($rdata))
        {
            $$res{deferred}{errmsg} = 
            "Une entrée $$param{type} doit avoir un nom de domaine "
            . "(pas une URL, pas de http://) : '$rdata' n'est pas correct.";
            $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
            return $res;
        }

        if ($$param{type} eq 'A' && ! is_ipv4($rdata)) {
            $$res{deferred}{errmsg} =
            "Il faut une adresse IPv4 pour un enregistrement de type A."
            . " Ceci n'est pas une adresse IPv4 : $rdata";
            $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
            return $res;
        }

        if ($$param{type} eq 'AAAA' && ! is_ipv6($rdata)) {
            $$res{deferred}{errmsg} = 
            "Il faut une adresse IPv6 pour un enregistrement de type AAAA."
            . " Ceci n'est pas une adresse IPv6 : $rdata";
            $$res{route} = ($$request{referer}) ? $$request{referer} : '/';
            return $res;
        }

        if($$param{type} eq "MX") {
            $str_new .= "$$param{priority} $rdata";
        }
        elsif ($$param{type} eq "SRV") {
            $str_new .=
            "$$param{priority} $$param{weight} $$param{port} $rdata";
        }
        else {
            $str_new .= "$rdata";
        }

        # Add the entry

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
        $zf->rr_add_raw($str_new);
        $zf->new_serial();
        $zone->update( $zf );

        $app->disconnect();
    };

    if ( $@ ) {
        $$res{deferred}{errmsg} = q{Problème à l'ajout d'une entrée. }. $@;
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
