package interface::bind9;
use v5.14;
use Moo;
use configuration ':all';
use remotecmd ':all';

has [ qw/mycfg tmpdir primarydnsserver secondarydnsserver/ ] => qw/is ro required 1/;

sub reload {
    my ($self, $domain) = @_;

    my $cmd = "rndc reload $domain";
    say "CMD: $cmd";
    qx/$cmd/;
    $cmd = "rndc notify $domain";
    say "CMD: $cmd";
    qx/$cmd/;

    #my $cmd = "rndc reload $domain ";
    #my $user = get_user_from_cfg($$self{mycfg});
    #my $host = get_host_from_cfg($$self{mycfg});
    #my $port = get_port_from_cfg($$self{mycfg});

    #remotecmd $user, $host, $port, $cmd;

    #$cmd = "rndc notify $domain ";
    #remotecmd $user, $host, $port, $cmd;
}

sub primary_addzone {
    my ($self, $domain, $opt) = @_;

    my $cmd = "rndc addzone $domain ";

    if(defined $opt) {
        $cmd .= "'$opt'";
    }
    else {
        my $dir = get_zonedir_from_cfg($$self{mycfg});
        $cmd .= "\"{ type master; file \\\"$dir/$domain\\\"; allow-transfer { ";

        my $sec = $$self{secondarydnsserver};
        for(@$sec) {
            my $v4 = get_v4_from_cfg($_);
            my $v6 = get_v6_from_cfg($_);

            $cmd .= $v4 . '; ' if $v4; 
            $cmd .= $v6 . '; ' if $v6;
        }
        $cmd .= " }; notify yes; };\"";
    }

    # if remote rndc
    #my $user = get_user_from_cfg($$self{mycfg});
    #my $host = get_host_from_cfg($$self{mycfg});
    #my $port = get_port_from_cfg($$self{mycfg});

    #remotecmd $user, $host, $port, $cmd;

    qx/$cmd/;
}

sub reconfig {
    my ($self, $domain) = @_;

    my $cmd = "rndc reconfig ";

    #my $user = get_user_from_cfg($$self{mycfg});
    #my $host = get_host_from_cfg($$self{mycfg});
    #my $port = get_port_from_cfg($$self{mycfg});

    #remotecmd $user, $host, $port, $cmd;

    qx/$cmd/;
}

sub delzone {
    my ($self, $domain) = @_;

    my $cmd = "rndc delzone $domain ";

    my $user = get_user_from_cfg($$self{mycfg});
    my $host = get_host_from_cfg($$self{mycfg});
    my $port = get_port_from_cfg($$self{mycfg});

    #remotecmd $user, $host, $port, $cmd;
    qx/$cmd/;

    my $file = get_zonedir_from_cfg($$self{mycfg});
    $file .= "/$domain";

    $cmd = "rm $file";

    remotecmd $user, $host, $port, $cmd
}

1;
