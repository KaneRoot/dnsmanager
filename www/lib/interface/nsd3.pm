package interface::nsd3;
use v5.14;
use Moo;
use URI;
use fileutil ':all';
use remotecmd ':all';
use copycat ':all';

has [ qw/user host port v4 v6/ ] => qw/is rw/;
has [ qw/mycfg data/ ] => qw/is ro required 1/;

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
    my ($self) = @_;

    $self->_reload_conf();

    my $cmd = "sudo nsdc rebuild 2>/dev/null 1>/dev/null && "
    . " sudo nsdc restart 2>/dev/null 1>/dev/null ";

    remotecmd $$self{user}, $$self{host}, $$self{port}, $cmd;
}

# get, modify, push the file

sub _reload_conf {
    my ($self) = @_;

    my $f = "file://$$self{data}{tmpdir}/nsd.conf";
    my $remote = ($$self{mycfg}{cfg}) ? $$self{mycfg}{cfg} : undef;

    $remote //= "ssh://$user". '@' . "$host/etc/nsd3/nsd.conf";

    copycat $remote, $f;

    my $slavedzones = $self->data->get_all_domains();

    my $data = read_file $f;
    my $debut = "## BEGIN_GENERATED";
    my $nouveau = '';

    for(keys %$slavedzones) {
        $nouveau .= "zone:\n\n\tname: \"$_\"\n"
        . "\tzonefile: \"slave/$_\"\n\n";

        # allow notify & request xfr, v4 & v6
        $nouveau .=
        "\tallow-notify: $$self{data}{primarydnsserver}{v4} " 
        . "$$self{data}{primarydnsserver}{dnsslavekey} \n"
        . "\trequest-xfr: $$self{data}{primarydnsserver}{v4} " 
        . "$$self{data}{primarydnsserver}{dnsslavekey} \n\n";


        $nouveau .=
        "\tallow-notify: $$self{data}{primarydnsserver}{v6} " 
        . "$$self{data}{primarydnsserver}{dnsslavekey} \n"
        . "\trequest-xfr: $$self{data}{primarydnsserver}{v6} " 
        . "$$self{data}{primarydnsserver}{dnsslavekey} \n\n";
    }

    $data =~ s/$debut.*/$debut\n$nouveau/gsm;

    write_file $f, $data;

    my $cmd = "sudo nsdc patch 2>/dev/null 1>/dev/null && "
    . " sudo rm /var/nsd3/ixfr.db";

    remotecmd $$self{user}, $$self{host}, $$self{port}, $cmd;
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
