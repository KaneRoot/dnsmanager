package zone;
use v5.14;
use Moo;

# TODO all this file is to redesign

use getiface ':all';
use copycat ':all';
use fileutil ':all';

use zonefile;

use Modern::Perl;

# primary dns interface 
has dnsi => ( is => 'rw', builder => '_void_arr');

# dns interface for secondary name servers
has dnsisec => ( is => 'rw', builder => '_void');

has [ qw/domain data/ ] => qw/is ro required 1/;

sub _void { my $x = ''; \$x; }
sub _void_arr { [] }

sub _get_ztpl_file { my $s = shift; "$$s{dnsi}{mycfg}{zonedir}/tpl.zone" }
sub _get_ztmp_file { my $s = shift; "$$s{data}{tmpdir}/$$s{domain}" }

sub _is_same_record {
    my ($a, $b) = @_;
    (   $a->{name} eq $b->{name} && 
        $a->{host} eq $b->{host} &&
        $a->{priority} eq $b->{priority} &&
        $a->{ttl} ==  $b->{ttl} );
}

# returns the lists of domains of a certain type
sub _get_records {
    my ($zone, $entry) = @_;

    for( lc $entry->{type} ) {
        if      ($_ eq 'a')      { return $zone->a;     }
        elsif   ($_ eq 'aaaa')   { return $zone->aaaa;  }
        elsif   ($_ eq 'cname')  { return $zone->cname; }
        elsif   ($_ eq 'ns')     { return $zone->ns;    }
        elsif   ($_ eq 'mx')     { return $zone->mx;    }
        elsif   ($_ eq 'ptr')    { return $zone->ptr;   }
    }

    die 'Impossible to get the entry type.';
}

sub get_dns_server_interfaces {
    my $self = shift;
    my $primary = $$self{data}{primarydnsserver};
    my $s = $$self{data}{secondarydnsserver};

    my $prim = getiface($$primary{app}, { mycfg => $primary, data => $self });

    my $sec = [];
    for(@$s) {
        my $x = @$_[0];
        push @$sec, getiface($$x{app}, { mycfg => $x, data => $self });
    }

    ($prim, $sec);
}

sub BUILD {
    my $self = shift;
    ($$self{dnsi}, $$self{dnsisec}) = $self->get_dns_server_interfaces();
}

sub delete_entry {
    my ($self, $entryToDelete) = @_;

    my $zone = $self->get();

    my $records = _get_records $zone, $entryToDelete;

    if( defined $records ) {
        foreach my $i ( 0 .. scalar @{$records}-1 ) {
            if(_is_same_record($records->[$i], $entryToDelete)) {
                delete $records->[$i];
            }
        }

        $self->update_domain( $zone, $$self{domain} );
    }

}

sub modify_entry {
    my ($self, $entryToModify, $newEntry) = @_;

    my $zone = $self->get();

    my $records = _get_records $zone, $entryToModify;

    if( defined $records ) {

        foreach my $i ( 0 .. scalar @{$records}-1 ) {

            if(_is_same_record($records->[$i], $entryToModify)) {

                $records->[$i]->{name} = $newEntry->{newname};
                $records->[$i]->{host} = $newEntry->{newhost};
                $records->[$i]->{ttl}  = $newEntry->{newttl};
                $records->[$i]->{type}  = $newEntry->{newtype};

                if( defined $newEntry->{newpriority} ) {
                    $records->[$i]->{priority} = $newEntry->{newpriority};
                }
            }
        }
        $self->update_domain( $zone, $$self{domain} );
    }

}

sub get {
    my ($self) = @_;
    my $file = $$self{dnsi}{mycfg}{zonedir} . '/' . $$self{domain};
    my $dest = $$self{data}{tmpdir} . '/' . $$self{domain};

    copycat ($file, $dest);

    zonefile->new(domain => $$self{domain}, zonefile => $dest);
}

=pod
    copie du template pour créer une nouvelle zone
    update du serial
    ajout de la zone via dnsapp (rndc, knot…)
    retourne la zone + le nom de la zone
=cut

sub addzone {
    my ($self) = @_;

    my $tpl = $self->_get_ztpl_file();
    my $tmpfile = $self->_get_ztmp_file();

    copycat ($tpl, $tmpfile); # get the template

    mod_orig_template ($tmpfile, $$self{domain}); # sed CHANGEMEORIGIN by the real origin

    my $zonefile = zonefile->new(zonefile => $tmpfile, domain => $$self{domain});
    $zonefile->new_serial(); # update the serial number

    # write the new zone tmpfile to disk 
    write_file $tmpfile, $zonefile->output();

    my $file = $$self{dnsi}{mycfg}{zonedir}.'/'.$$self{domain};
    copycat ($tmpfile, $file); # put the final zone on the server
    unlink($tmpfile); # del the temporary file

    # add new zone on the primary ns
    $self->dnsi->addzone($$self{dnsi}{mycfg}{zonedir}, $$self{domain});

    # add new zone on the secondary ns
    my $sec = zone::interface->new()
    ->get_interface($$self{data}{dnsappsec}, $self->data);
    $sec->reload_sec();

    #return $zonefile;
}

=pod
    màj du serial
    push reload de la conf
=cut

sub update {
    my ($self, $zonefile) = @_;

    # update the serial number
    $zonefile->new_serial();

    my $tmpfile = $self->_get_ztmp_file();

    # write the new zone tmpfile to disk 
    write_file $tmpfile, $zonefile->output();

    my $file = $$self{dnsi}{mycfg}{zonedir}.'/'.$$self{domain};
    copycat ($tmpfile, $file); # put the final zone on the server
    unlink($tmpfile); # del the temporary file

    $self->dnsi->reload($$self{domain});
}

=pod
    udpate via the raw content of the zonefile
=cut

sub update_raw {
    my ($self, $zonetext) = @_;

    my $zonefile;
    my $file = $$self{data}{tmpdir} . '/' . $$self{domain};

    # write the updated zone file to disk 
    write_file $file, $zonetext;

    eval { $zonefile = zonefile->new(zonnefile => $file
            , domain => $$self{domain}); };

    if( $@ ) {
        unlink($file);
        die "app::zone update_raw : app::zonefile->new error";
    }

    unlink($file);

    $self->update($zonefile);
}

# sera utile plus tard, pour l'interface
sub new_tmp {
    my ($self) = @_;

    my $tpl = $self->_get_ztpl_file();
    my $file = $$self{data}{tmpdir} . '/' . $$self{domain};

    copycat ($tpl, $file);
    mod_orig_template ($file, $$self{domain});

    my $zonefile = zonefile->new(zonefile => $file, domain => $$self{domain});
    $zonefile->new_serial(); # update the serial number

    unlink($file);

    return $zonefile;
}

# change the origin in a zone file template
sub mod_orig_template {
    my ($file, $domain) = @_;
    my $cmd = qq[sed -i "s/CHANGEMEORIGIN/$domain/" $file 2>/dev/null 1>/dev/null];
    system($cmd);
}

sub del {
    my ($self) = @_;
    $self->dnsi->delzone($$self{domain});
    $self->dnsi->reconfig();

    my $sec = $$self{data}{dnsisec};
    $sec->reload_sec();

    my $file = get_zpath_from_primary_server($$self{dnsi}{mycfg});
    $file .= "/$$self{domain}";

    my $host = $$self{data}{primarydnsserver}{host};
    my $user = $$self{data}{primarydnsserver}{user};
    my $port = $$self{data}{primarydnsserver}{port};
    my $cmd = "rm $file";

    remotecmd $user, $host, $port, $cmd;
}

1;
