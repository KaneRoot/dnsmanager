use Modern::Perl;
use Data::Dump "dump";
use DNS::ZoneParse;
use File::Copy;
use Net::OpenSSH;
use Net::SSH q<sshopen2>;
use v5.14;

use lib '../../';
use app::zone::interface;
package app::zone::edit;
use Moose;

has [ qw/zname data/ ] => qw/is ro required 1/;

sub get {
    my ($self) = @_;
    my $dest = '/tmp/' . $self->zname;
    my $file = $self->data->zdir.'/'.$self->zname;

    $self->_scp_get($file, $dest);
    DNS::ZoneParse->new($dest, $self->zname);
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
    my $tmpfile = '/tmp/'.$self->zname;

    $self->_scp_get($tpl, $tmpfile); # get the template
    $self->_sed($tmpfile); # sed CHANGEMEORIGIN by the real origin

    my $zonefile = DNS::ZoneParse->new($tmpfile, $self->zname);
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
    my $prim = app::zone::interface->new()
    ->get_interface($self->data->dnsapp, $self->data);
    $prim->addzone($self->data->zdir, $self->zname);

    # add new zone on the secondary ns
    my $sec = app::zone::interface->new()
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

    my $tmpfile = '/tmp/' . $self->zname;

    # write the new zone tmpfile to disk 
    my $newzone;
    open($newzone, '>', $tmpfile) or die "error";
    print $newzone $zonefile->output();
    close $newzone;

    my $file = $self->data->zdir.'/'.$self->zname;
    $self->_scp_put($tmpfile, $file); # put the final zone on the server
    unlink($tmpfile); # del the temporary file

    my $prim = app::zone::interface->new()
    ->get_interface($self->data->dnsapp, $self->data);
    $prim->reload($self->zname);
    1;
}

=pod
    udpate via the raw content of the zonefile
=cut

sub update_raw {
    my ($self, $zonetext) = @_;

    my $zonefile;
    my $file = '/tmp/'.$self->zname;

    # write the updated zone file to disk 
    my $newzone;
    open($newzone, '>', $file) or die "error";
    print $newzone $zonetext;
    close $newzone;

    eval { $zonefile = DNS::ZoneParse->new($file, $self->zname); };

    if( $@ ) {
        unlink($file);
        0;
    }

    unlink($file);

    $self->update($zonefile);
}

# sera utile plus tard, pour l'interface
sub new_tmp {
    my ($self) = @_;

    my $tpl = $self->data->zdir."/tpl.zone";
    my $file = '/tmp/'.$self->zname;

    $self->_scp($tpl, $file);
    $self->_sed($file);

    my $zonefile = DNS::ZoneParse->new($file, $self->zname);
    $zonefile->new_serial(); # update the serial number

    unlink($file);

    return $zonefile;
}

sub _cp {
    my ($self, $src, $dest) = @_;

    File::Copy::copy($src, $dest) or die "Copy failed: $! ($src -> $dest)";
}

sub _scp_put {
    my ($self, $src, $dest) = @_;

    my $co = $self->data->sshuser . '@' . $self->data->sshhost . ':' . $self->data->sshport;
    my $ssh = Net::OpenSSH->new($co);
    $ssh->scp_put($src, $dest) or die "scp failed: " . $ssh->error;
}

sub _scp_get {
    my ($self, $src, $dest) = @_;

    my $co = $self->data->sshuser . '@' . $self->data->sshhost . ':' . $self->data->sshport;
    my $ssh = Net::OpenSSH->new($co);
    $ssh->scp_get($src, $dest) or die "scp failed: " . $ssh->error;
}

sub _sed {
    my ($self, $file) = @_;
    my $orig = $self->zname;
    my $cmd = qq[sed -i "s/CHANGEMEORIGIN/$orig/" $file 2>/dev/null 1>/dev/null];

    system($cmd);
}

sub del {
    my ($self) = @_;
    my $prim = app::zone::interface->new()
    ->get_interface($self->data->dnsapp, $self->data);
    $prim->delzone($self->data->zdir, $self->zname);
    $prim->reconfig();

    my $sec = app::zone::interface->new()
    ->get_interface($self->data->dnsappsec, $self->data);
    $sec->reload_sec();

    my $file = $self->data->zdir.'/'.$self->zname;
    my $host = $self->data->sshhost;
    my $user = $self->data->sshuser;
    my $cmd = "rm $file";

    Net::SSH::sshopen2("$user\@$host", *READER, *WRITER, "$cmd") || die "ssh: $!";

    close(READER);
    close(WRITER);

    1;
}

1;
