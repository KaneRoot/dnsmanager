use v5.14;
package app::zone::nsdc_interface;
use Moose;

has [ qw/data/ ] => qw/is ro required 1/;

# on suppose que tout est déjà mis à jour dans le fichier
sub reload_sec {
    my ($self) = @_;

    $self->_reload_conf();

    system('ssh -p ' . $self->data->sshportsec . ' '
        . $self->data->sshusersec . '@' . $self->data->sshhostsec
        . ' "sudo nsdc rebuild 2>/dev/null 1>/dev/null && sudo nsdc restart 2>/dev/null 1>/dev/null "');
}

sub _reload_conf {
    my ($self) = @_;

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
    my $nouveau = '';

    for(keys %slavedzones) {
        $nouveau .= "zone:\n\n\tname: \"$_\"\n"
        . "\tzonefile: \"slave/$_\"\n\n";

        # allow notify & request xfr, v4 & v6
        $nouveau .=
        "\tallow-notify: " . $self->data->nsmasterv4 . ' ' . $self->data->dnsslavekey . "\n"
        . "\trequest-xfr: " . $self->data->nsmasterv4 . ' ' . $self->data->dnsslavekey . "\n\n";

        $nouveau .=
        "\tallow-notify: " . $self->data->nsmasterv6. ' ' . $self->data->dnsslavekey . "\n"
        . "\trequest-xfr: " . $self->data->nsmasterv6. ' ' . $self->data->dnsslavekey . "\n\n";
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
    my ($user, $host, $port, $src, $dest) = @_;

    my $co = $user . '@' . $host . ':' . $port;
    my $ssh = Net::OpenSSH->new($co);
    $ssh->scp_get($src, $dest) or die "scp failed: " . $ssh->error;
}

sub _scp_put {
    my ($user, $host, $port, $src, $dest) = @_;

    my $co = $user . '@' . $host . ':' . $port;
    my $ssh = Net::OpenSSH->new($co);
    $ssh->scp_put($src, $dest) or die "scp failed: " . $ssh->error;
}

sub reconfig {
    my ($self, $zname) = @_;
    die "not implemented";
    #system("nsdc reconfig 2>/dev/null 1>/dev/null");
}

sub delzone {
    my ($self) = @_;
    die "not implemented";
    #system("nsdc delzone $zname 2>/dev/null 1>/dev/null");
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
