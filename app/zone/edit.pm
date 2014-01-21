use Modern::Perl;
use Data::Dump "dump";
use DNS::ZoneParse;
use File::Copy;
use v5.14;

use lib '../../';
use app::zone::rndc_interface;
package app::zone::edit;
use Moose;

has [ qw/zname zdir/ ] => qw/is ro required 1/;

sub get {
    my ($self) = @_;
    my $file = $self->zdir.'/'.$self->zname;
    return DNS::ZoneParse->new($file, $self->zname);
}

=pod
    copie du template pour créer une nouvelle zone
    update du serial
    ajout de la zone via rndc
    retourne la zone + le nom de la zone
=cut

sub addzone {
    my ($self) = @_;

    my $tpl = $self->zdir."/tpl.zone";
    my $file = $self->zdir.'/'.$self->zname;

    $self->_cp($tpl, $file);

    my $zonefile = DNS::ZoneParse->new($file, $self->zname);
    $zonefile->new_serial(); # update the serial number

    # write the new zone file to disk 
    my $newzone;
    open($newzone, '>', $file) or die "error";
    print $newzone $zonefile->output();
    close $newzone;

    my $rndc = app::zone::rndc_interface->new();
    $rndc->addzone($self->zdir, $self->zname);

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

    my $file = $self->zdir.'/'.$self->zname;

    # write the new zone file to disk 
    my $newzone;
    open($newzone, '>', $file) or die "error";
    print $newzone $zonefile->output();
    close $newzone;

    my $rndc = app::zone::rndc_interface->new();
    $rndc->reload($self->zname);
}

=pod
    udpate via the raw content of the zonefile
=cut

sub update_raw {
    my ($self, $zonetext) = @_;

    my $file = '/tmp/'.$self->zname;

    # write the updated zone file to disk 
    my $newzone;
    open($newzone, '>', $file) or die "error";
    print $newzone $zonetext;
    close $newzone;

    my $zonefile = DNS::ZoneParse->new($file, $self->zname);
    unlink($file);

    $self->update($zonefile);
}

# sera utile plus tard, pour l'interface
sub new_tmp {
    my ($self) = @_;

    my $tpl = $self->zdir."/tpl.zone";
    my $file = '/tmp/'.$self->zname;

    $self->_cp($tpl, $file);
    my $zonefile = DNS::ZoneParse->new($file, $self->zname);
    $zonefile->new_serial(); # update the serial number

    unlink($file);

    return $zonefile;
}

sub _cp {
    my ($self, $src, $dest) = @_;

    File::Copy::copy($src, $dest) or die "Copy failed: $! ($src -> $dest)";

    my $orig = $self->zname;
    my $cmd = qq[sed -i "s/CHANGEMEORIGIN/$orig/" $dest 2>/dev/null 1>/dev/null];
    system($cmd);
}

sub del {
    my ($self) = @_;
    my $rndc = app::zone::rndc_interface->new();
    $rndc->delzone($self->zdir, $self->zname);
    $rndc->reconfig();
}

1;
