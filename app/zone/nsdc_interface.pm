use v5.14;
package app::zone::nsdc_interface;
use Moose;

has [ qw/data/ ] => qw/is ro required 1/;

# on suppose que tout est déjà mis à jour dans le fichier
sub reload {
    my ($self, $zname) = @_;
    system("ssh "
        . $self->data->sshsec 
        . " nsdc reload $zname 2>/dev/null 1>/dev/null");
}

sub addzone_sec {
    my ($self, $zdir, $zname, $opt) = @_;

    # get the file
    # modify the file
    # push the file
    my $f = "/tmp/nsd.conf";

    _scp_get($self->data->sshusersec
        , $self->data->sshhostsec
        , $self->data->sshportsec
        , "/etc/nsd3/nsd.conf"
        , $f);

    my %slavedzones = $self->data->get_all_domains();

    my $data = read_file($f);
    my $debut = "## BEGIN_GENERATED";
    my $nouveau = ''; # TODO

    for(keys %slavedzones) {
        $nouveau .= "zone:\n\tname: \"$_\"\n"
        . "\tzonefile: \"slave/$_\"\n";

        # allow notify & request xfr, v4 & v6
        $nouveau .=
        "\tallow-notify: " . $self->data->nsmasterv4. "\n"
        . "\trequest-xfr: " . $self->data->nsmasterv4 . "\n";

        $nouveau .=
        "\tallow-notify: " . $self->data->nsmasterv6. "\n"
        . "\trequest-xfr: " . $self->data->nsmasterv6 . "\n\n";
    }

    $data =~ s/$debut.*/$debut\n$nouveau/gsm;

    write_file($f, $data);

    _scp_put($self->data->sshusersec
        , $self->data->sshhostsec
        , $self->data->sshportsec
        , $f
        , "/etc/nsd3/");
}

sub _scp_get {
    my ($self, $user, $host, $port, $src, $dest) = @_;

    my $co = $user . '@' . $host . ':' . $port;
    my $ssh = Net::OpenSSH->new($co);
    $ssh->scp_get($src, $dest) or die "scp failed: " . $ssh->error;
}

sub _scp_put {
    my ($self, $user, $host, $port, $src, $dest) = @_;

    my $co = $user . '@' . $host . ':' . $port;
    my $ssh = Net::OpenSSH->new($co);
    $ssh->scp_put($src, $dest) or die "scp failed: " . $ssh->error;
}

sub reconfig {
    my ($self, $zname) = @_;
    system("nsdc reconfig 2>/dev/null 1>/dev/null");
}

sub delzone {
    my ($self, $zdir, $zname) = @_;
    system("nsdc delzone $zname 2>/dev/null 1>/dev/null");
}

sub read_file {
    my ($filename) = @_;

    open my $entree, '<:encoding(UTF-8)', $filename or 
    die "Impossible d'ouvrir '$filename' en lecture : $!";
    local $/ = undef;
    my $tout = <$entree>;
    close $entree;

    return $tout;
}

sub write_file {
    my ($filename, $data) = @_;

    open my $sortie, '>:encoding(UTF-8)', $filename or die "Impossible d'ouvrir '$filename' en écriture : $!";
    print $sortie $data;
    close $sortie;

    return;
}

1;
