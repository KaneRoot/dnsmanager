package zone;
use v5.14;
use Moo;

use getiface ':all';
use copycat ':all';
use fileutil ':all';

use zonefile;

use Modern::Perl;
use Data::Dump "dump";

has [ qw/domain data/ ] => qw/is ro required 1/;

# TODO all this file is to redesign
sub get {
    my ($self) = @_;
    my $file = $$self{data}{dnsi}{zdir} . '/'. $$self{domain};
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

    my $tpl = $$self{data}{dnsi}{zdir}."/tpl.zone";
    my $tmpfile = $$self{data}{tmpdir} . '/' . $$self{domain};

    copycat ($tpl, $tmpfile); # get the template

    mod_orig_template ($tmpfile, $$self{domain}); # sed CHANGEMEORIGIN by the real origin

    my $zonefile = zonefile->new(zonefile => $tmpfile, domain => $$self{domain});
    $zonefile->new_serial(); # update the serial number

    # write the new zone tmpfile to disk 
    write_file $tmpfile, $zonefile->output();

    my $file = $$self{data}{dnsi}{zdir}.'/'.$$self{domain};
    copycat ($tmpfile, $file); # put the final zone on the server
    unlink($tmpfile); # del the temporary file

    # add new zone on the primary ns
    my $prim = zone::interface->new()
    ->get_interface($$self{data}{dnsapp}, $self->data);
    $prim->addzone($$self{data}{dnsi}{zdir}, $$self{domain});

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

    my $tmpfile = $$self{data}{tmpdir} . '/' . $$self{domain};

    # write the new zone tmpfile to disk 
    write_file $tmpfile, $zonefile->output();

    my $file = $$self{data}{dnsi}{zdir}.'/'.$$self{domain};
    copycat ($tmpfile, $file); # put the final zone on the server
    unlink($tmpfile); # del the temporary file

    my $prim = zone::interface->new()
    ->get_interface($self->data->dnsapp, $self->data);
    $prim->reload($$self{domain});
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

    my $tpl = $$self{data}{dnsi}{zdir} . "/tpl.zone";
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
    my ($self, $file, $domain) = @_;
    my $cmd = qq[sed -i "s/CHANGEMEORIGIN/$domain/" $file 2>/dev/null 1>/dev/null];
    system($cmd);
}

sub del {
    my ($self) = @_;
    my $prim = $$self{data}{dnsi};
    $prim->delzone($$prim{zdir}, $$self{domain});
    $prim->reconfig();

    my $sec = $$self{data}{dnsisec};
    $sec->reload_sec();

    # TODO not ok right now (URI not path)
    my $file = $$self{data}{dnsi}{zdir}.'/'.$$self{domain};
    my $host = $$self{data}{primarydnsserver}{host};
    my $user = $$self{data}{primarydnsserver}{user};
    my $port = $$self{data}{primarydnsserver}{port};
    my $cmd = "rm $file";

    remotecmd $user, $host, $port, $cmd;
}

1;
