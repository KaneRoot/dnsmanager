package interface::nsd3;
use v5.14;
use Moo;
use URI;
use fileutil ':all';
use remotecmd ':all';
use copycat ':all';
use configuration ':all';

has [ qw/mycfg tmpdir primarydnsserver secondarydnsserver/ ] => qw/is ro required 1/;

# on suppose que tout est déjà mis à jour dans le fichier
sub reload_sec {
    my ($self, $slavedzones) = @_;

    $self->_reload_conf($slavedzones);

    my $cmd = "sudo nsdc rebuild && "
    . " sudo nsdc restart ";

    my $user = get_user_from_cfg($$self{mycfg});
    my $host = get_host_from_cfg($$self{mycfg});
    my $port = get_port_from_cfg($$self{mycfg});

    remotecmd $user, $host, $port, $cmd
}

# get, modify, push the file

sub _reload_conf {
    my ($self, $slavedzones) = @_;

    my $f = "file://$$self{tmpdir}/nsd.conf";
    my $remote = ($$self{mycfg}{cfg}) ? $$self{mycfg}{cfg} : undef;

    my $user = get_user_from_cfg($$self{mycfg});
    my $host = get_host_from_cfg($$self{mycfg});
    my $port = get_port_from_cfg($$self{mycfg});

    $remote //= "ssh://$user". '@' . "$host/etc/nsd/nsd.conf";

    copycat $remote, $f;

    my $data = read_file $f;
    my $debut = "## BEGIN_GENERATED";
    my $nouveau = '';
    my $dnsslavekey = get_dnsslavekey_from_cfg($$self{primarydnsserver});

    for(@{$slavedzones}) {

        $nouveau .= "zone:\n\n\tname: \"$_\"\n"
        . "\tzonefile: \"slave/$_\"\n\n";

        my $v4 = get_v4_from_cfg($$self{primarydnsserver});
        my $v6 = get_v6_from_cfg($$self{primarydnsserver});

        if($v4) {
            # allow notify & request xfr, v4 & v6
            $nouveau .= "\tallow-notify: $v4 $dnsslavekey \n"
            . "\trequest-xfr: $v4 $dnsslavekey \n\n";
        }

        if($v6) {
            $nouveau .= "\tallow-notify: $v6 $dnsslavekey \n"
            . "\trequest-xfr: $v6 $dnsslavekey \n\n";
        }
    }

    $data =~ s/$debut.*/$debut\n$nouveau/gsm;

    write_file $f, $data;
    copycat $f, $remote;

    my $cmd = "sudo nsdc patch && "
    . " sudo rm /var/nsd3/ixfr.db";

    remotecmd $user, $host, $port, $cmd;
}

sub reconfig {
    my ($self, $zname) = @_;
    die "nsd3 reconfig not implemented.";
}

sub delzone {
    my ($self) = @_;
    die "nsd3 delzone not implemented.";
}

1;
