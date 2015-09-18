package interface::bind9;
use v5.14;
use Moo;
use configuration ':all';
use remotecmd ':all';

has [ qw/mycfg primarydnsserver secondarydnsserver/ ] => qw/is ro required 1/;

sub reload {
    my ($self, $domain) = @_;
    system("rndc reload $domain 2>/dev/null 1>/dev/null");
    system("rndc notify $domain 2>/dev/null 1>/dev/null");
}

sub primary_addzone {
    my ($self, $domain, $opt) = @_;

    my $command = "rndc addzone $domain ";

    if(defined $opt) {
        $command .= "'$opt'";
    }
    else {
        my $dir = get_zonedir_from_cfg($$self{mycfg});
        $command .= "'{ type master; file \"$dir/$domain\"; allow-transfer { ";

        my $sec = $$self{secondarydnsserver};
        for(@$sec) {
            my $v4 = get_v4_from_cfg($_);
            my $v6 = get_v6_from_cfg($_);

            $command .= $v4 . '; ' if $v4; 
            $command .= $v6 . '; ' if $v6;
        }
        $command .= " }; notify yes; };'";
    }

    $command .= " 2>/dev/null 1>/dev/null";
    system($command)
}

sub reconfig {
    my ($self, $domain) = @_;
    system("rndc reconfig 2>/dev/null 1>/dev/null")
}

sub delzone {
    my ($self, $domain) = @_;
    system("rndc delzone $domain 2>/dev/null 1>/dev/null")

    my $file = get_zonedir_from_cfg($$self{mycfg});
    $file .= "/$domain";

    my $host = get_host_from_cfg($$self{mycfg});
    my $user = get_user_from_cfg($$self{mycfg});
    my $port = get_port_from_cfg($$self{mycfg});
    my $cmd = "rm $file";

    remotecmd $user, $host, $port, $cmd
}

1;
