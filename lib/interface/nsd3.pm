package interface::nsd3;
use v5.14;
use Moo;
use URI;
use fileutil ':all';
use remotecmd ':all';
use copycat ':all';

has [ qw/user host port v4 v6/ ] => qw/is rw/;
has [ qw/mycfg primarydnsserver secondarydnsserver/ ] => qw/is ro required 1/;

sub BUILD {
    my $self = shift;

    if($$self{mycfg}{domain}) {
        if($$self{mycfg}{domain}{v4}) {
            $$self{v4} = $$self{mycfg}{domain}{v4};
        }
        if($$self{mycfg}{domain}{v6}) {
            $$self{v6} = $$self{mycfg}{domain}{v6};
        }

        if($$self{mycfg}{domain}{name}) {
            $$self{host} = $$self{mycfg}{domain}{name};
        }
    }

    my $cfg = URI->new($$self{mycfg}{cfg});

    $$self{host} //= $cfg->host;
    $$self{port} //= $cfg->port;
    $$self{user} //= $cfg->user;

}

# on suppose que tout est déjà mis à jour dans le fichier
sub reload_sec {
    my ($self, $slavedzones) = @_;

    $self->_reload_conf($slavedzones);

    my $cmd = "sudo nsdc rebuild 2>/dev/null 1>/dev/null && "
    . " sudo nsdc restart 2>/dev/null 1>/dev/null ";

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

    $remote //= "ssh://$$self{user}@" . "$$self{host}/etc/nsd3/nsd.conf";

    copycat $remote, $f;

    my $data = read_file $f;
    my $debut = "## BEGIN_GENERATED";
    my $nouveau = '';
    my $dnsslavekey = get_dnsslavekey_from_cfg($$self{primarydnsserver});

    for(keys %$slavedzones) {

        $nouveau .= "zone:\n\n\tname: \"$_\"\n"
        . "\tzonefile: \"slave/$_\"\n\n";

        my $v4 = get_v4_from_cfg($$self{primarydnsserver});
        my $v6 = get_v6_from_cfg($$self{primarydnsserver});

        if($v4) {
            # allow notify & request xfr, v4 & v6
            $nouveau .=
            "\tallow-notify: $v4 " 
            . "$dnsslavekey \n"
            . "\trequest-xfr: $v4 " 
            . "$dnsslavekey \n\n";
        }

        if($v6) {
            $nouveau .=
            "\tallow-notify: $v6 " 
            . "$dnsslavekey \n"
            . "\trequest-xfr: $v6 " 
            . "$dnsslavekey \n\n";
        }
    }

    $data =~ s/$debut.*/$debut\n$nouveau/gsm;

    write_file $f, $data;

    my $user = get_user_from_cfg($$self{mycfg});
    my $host = get_host_from_cfg($$self{mycfg});
    my $port = get_port_from_cfg($$self{mycfg});

    my $cmd = "sudo nsdc patch 2>/dev/null 1>/dev/null && "
    . " sudo rm /var/nsd3/ixfr.db";

    remotecmd $user, $host, $port, $cmd;
    copycat $f, $remote;
}

sub reconfig {
    my ($self, $zname) = @_;
    die "nsd3 reconfig not implemented.";
    #system("nsdc reconfig 2>/dev/null 1>/dev/null");
}

sub delzone {
    my ($self) = @_;
    die "nsd3 delzone not implemented.";
    #system("nsdc delzone $zname 2>/dev/null 1>/dev/null");
}

1;
