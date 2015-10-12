package interface::nsd4;
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

    my $cmd = "sudo nsd-control reconfig";

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

    # if it's the first time we get the configuration, fresh start
    $data .= "\n## BEGIN_GENERATED" if( $data !~ /BEGIN_GENERATED/);

    my $v4 = get_v4_from_cfg($$self{primarydnsserver});
    my $v6 = get_v6_from_cfg($$self{primarydnsserver});

    my $debut = "## BEGIN_GENERATED";

    my $nouveau = '';
    my $dnsslavekey = get_dnsslavekey_from_cfg($$self{primarydnsserver});

#    $nouveau .= "
#remote-control:
#    control-enable: yes
#    control-interface: 127.0.0.1
#    control-port: 8952
#    server-key-file: '/etc/nsd/nsd_server.key'
#    server-cert-file: '/etc/nsd/nsd_server.pem'
#    control-key-file: '/etc/nsd/nsd_control.key'
#    control-cert-file: '/etc/nsd/nsd_control.pem'
#
#key:
#
## pattern : configuration to reproduce on every slaves
    $nouveau .= "
pattern:
\tname: 'slavepattern'
    ";

    if($v4) {
        # allow notify & request xfr, v4 & v6
        $nouveau .= "\tallow-notify: $v4 \"$dnsslavekey\" \n"
        . "\trequest-xfr: $v4 \"$dnsslavekey\" \n";
    }

    if($v6) {
        $nouveau .= "\tallow-notify: $v6 \"$dnsslavekey\" \n"
        . "\trequest-xfr: $v6 \"$dnsslavekey\" \n";
    }

    $nouveau .= "\n";

    for(@{$slavedzones}) {

        $nouveau .= "zone:\n\tname: \"$$_{domain}\"\n"
        . "\tzonefile: \"slave/$$_{domain}\"\n";
        $nouveau .= "\tinclude-pattern: 'slavepattern'\n\n";
    }

    $data =~ s/$debut.*/$debut\n$nouveau/gsm;

    write_file $f, $data;
    copycat $f, $remote;

    my $cmd = "sudo nsd-control reconfig";

    remotecmd $user, $host, $port, $cmd
}

sub reconfig {
    my ($self, $zname) = @_;

    my $user = get_user_from_cfg($$self{mycfg});
    my $host = get_host_from_cfg($$self{mycfg});
    my $port = get_port_from_cfg($$self{mycfg});
    my $cmd = "sudo nsd-control reconfig";
    remotecmd $user, $host, $port, $cmd
}

sub delzone {
    my ($self) = @_;

    my $user = get_user_from_cfg($$self{mycfg});
    my $host = get_host_from_cfg($$self{mycfg});
    my $port = get_port_from_cfg($$self{mycfg});
    my $cmd = "sudo nsd-control reconfig";
    remotecmd $user, $host, $port, $cmd;
    #die "nsd4 delzone not implemented.";
}

1;
