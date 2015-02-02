package interface::nsd3;
use v5.14;
use Moo;
use fileutil ':all';
use remotecmd ':all';
use copycat ':all';

has [ qw/user host port tmpdir app/ ] => qw/is ro required 1/;

# on suppose que tout est déjà mis à jour dans le fichier
sub reload_sec {
    my ($self) = @_;

    $self->_reload_conf();

    my $cmd = "sudo nsdc rebuild 2>/dev/null 1>/dev/null && "
    . " sudo nsdc restart 2>/dev/null 1>/dev/null ";

    remotecmd $user, $host, $port, $cmd;

}

# get, modify, push the file

sub _reload_conf {
    my ($self) = @_;

    my $f = "file://" . $self->tmpdir . "/nsd.conf";
    my $remote = "ssh://$user". '@' . "$host/etc/nsd3/nsd.conf";

    copycat $remote, $f;

    my %slavedzones = $self->app->get_all_domains();

    my $data = read_file $f;
    my $debut = "## BEGIN_GENERATED";
    my $nouveau = '';

    for(keys %slavedzones) {
        $nouveau .= "zone:\n\n\tname: \"$_\"\n"
        . "\tzonefile: \"slave/$_\"\n\n";

        # allow notify & request xfr, v4 & v6
        $nouveau .=
        "\tallow-notify: " . $self->app->primarydnsserver->v4
        . ' ' . $self->app->primarydnsserver->dnsslavekey . "\n"
        . "\trequest-xfr: " . $self->app->primarydnsserver->v4
        . ' ' . $self->app->primarydnsserver->dnsslavekey . "\n\n";

        $nouveau .=
        "\tallow-notify: " . $self->app->primarydnsserver->v6
        . ' ' . $self->app->primarydnsserver->dnsslavekey . "\n"
        . "\trequest-xfr: " . $self->app->primarydnsserver->v6
        . ' ' . $self->app->primarydnsserver->dnsslavekey . "\n\n";
    }

    $data =~ s/$debut.*/$debut\n$nouveau/gsm;

    write_file $f, $data;

    my $cmd = "sudo nsdc patch 2>/dev/null 1>/dev/null && "
    . " sudo rm /var/nsd3/ixfr.db";

    remotecmd $user, $host, $port, $cmd;

    copycat $f, $remote;
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

1;
