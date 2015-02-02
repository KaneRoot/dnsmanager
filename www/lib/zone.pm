package zone;
use v5.14;
use Moo;

use getiface ':all';
use copycat ':all';

use zonefile;

use Modern::Perl;
use Data::Dump "dump";

has [ qw/tmpdir data/ ] => qw/is ro required 1/;

sub get {
    my ($self) = @_;
    my $dest = $self->tmpdir . '/' . $self->zname;
    my $file = $self->data->zdir.'/'.$self->zname;

    $self->_scp_get($file, $dest);

    zonefile->new(domain => $domain, zonefile => $dest);
}

=pod
    copie du template pour créer une nouvelle zone
    update du serial
    ajout de la zone via dnsapp (rndc, knot…)
    retourne la zone + le nom de la zone
=cut

sub addzone {
    my ($self) = @_;

    my $tpl = $self->data->zdir."/tpl.zone";
    my $tmpfile = $self->tmpdir . '/' . $self->zname;

    $self->_scp_get($tpl, $tmpfile); # get the template
    $self->_sed($tmpfile); # sed CHANGEMEORIGIN by the real origin

    my $zonefile = zonefile->new(zonefile => $tmpfile, domain => $domain);
    $zonefile->new_serial(); # update the serial number

    # write the new zone tmpfile to disk 
    my $newzone;
    open($newzone, '>', $tmpfile) or die "error";
    print $newzone $zonefile->output();
    close $newzone;

    my $file = $self->data->zdir.'/'.$self->zname;
    $self->_scp_put($tmpfile, $file); # put the final zone on the server
    unlink($tmpfile); # del the temporary file

    # add new zone on the primary ns
    my $prim = zone::interface->new()
    ->get_interface($self->data->dnsapp, $self->data);
    $prim->addzone($self->data->zdir, $self->zname);

    # add new zone on the secondary ns
    my $sec = zone::interface->new()
    ->get_interface($self->data->dnsappsec, $self->data);
    $sec->reload_sec();

    return $zonefile;
}

=pod
    màj du serial
    push reload de la conf
=cut

sub update {
    my ($self, $zonefile) = @_;

    # update the serial number
    $zonefile->new_serial();

    my $tmpfile = $self->tmpdir . '/' . $self->zname;

    # write the new zone tmpfile to disk 
    my $newzone;
    open($newzone, '>', $tmpfile) or die "error";
    print $newzone $zonefile->output();
    close $newzone;

    my $file = $self->data->zdir.'/'.$self->zname;
    $self->_scp_put($tmpfile, $file); # put the final zone on the server
    unlink($tmpfile); # del the temporary file

    my $prim = zone::interface->new()
    ->get_interface($self->data->dnsapp, $self->data);
    $prim->reload($self->zname);
}

=pod
    udpate via the raw content of the zonefile
=cut

sub update_raw {
    my ($self, $zonetext) = @_;

    my $zonefile;
    my $file = $self->tmpdir . '/' . $self->zname;

    # write the updated zone file to disk 
    my $newzone;
    open($newzone, '>', $file) or die "error";
    print $newzone $zonetext;
    close $newzone;

    eval { $zonefile = zonefile->new(zonnefile => $file
            , domain => $self->zname); };

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

    my $tpl = $self->data->zdir . "/tpl.zone";
    my $file = $self->tmpdir . '/' . $self->zname;

    $self->_scp($tpl, $file);
    $self->_sed($file);

    my $zonefile = zonefile->new(zonefile => $file, domain => $self->zname);
    $zonefile->new_serial(); # update the serial number

    unlink($file);

    return $zonefile;
}

sub _sed {
    my ($self, $file) = @_;
    my $orig = $self->zname;
    my $cmd = qq[sed -i "s/CHANGEMEORIGIN/$orig/" $file 2>/dev/null 1>/dev/null];

    system($cmd);
}

sub del {
    my ($self) = @_;
    my $prim = getiface $self->data->dnsapp, {data => $self->data };
    $prim->delzone($self->data->zdir, $self->zname);
    $prim->reconfig();

    my $sec = getiface $self->data->dnsappsec, {data => $self->data };
    $sec->reload_sec();

    my $file = $self->data->zdir.'/'.$self->zname;
    my $host = $self->data->sshhost;
    my $user = $self->data->sshuser;
    my $cmd = "rm $file";

    remotecmd $user, $host, $port, $cmd;
}

1;
