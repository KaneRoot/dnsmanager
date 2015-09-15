package interface::bind9;
use v5.14;
use Moo;
use configuration ':all';

has [ qw/mycfg data/ ] => qw/is ro required 1/;

sub reload {
    my ($self, $domain) = @_;
    system("rndc reload $domain 2>/dev/null 1>/dev/null");
    system("rndc notify $domain 2>/dev/null 1>/dev/null");
}

sub addzone {
    my ($self, $domain, $opt) = @_;

    my $command = "rndc addzone $domain ";

    if(defined $opt) {
        $command .= "'$opt'";
    }
    else {

        my $dir = get_zonedir_from_cfg($$self{mycfg});
        $command .= "'{ type master; file \"$dir/$domain\"; allow-transfer { ";
        my $sec = $$self{data}{secondarydnsserver};
        for(@$sec) {
            $command .= $$_{domain}{v4} . '; ' if $$_{domain}{v4}; 
            $command .= $$_{domain}{v6} . '; ' if $$_{domain}{v6};
        }
        $command .= " }; notify yes; };'";
    }

    $command .= " 2>/dev/null 1>/dev/null";
    system($command);

}

sub reconfig {
    my ($self, $domain) = @_;
    system("rndc reconfig 2>/dev/null 1>/dev/null");
}

sub delzone {
    my ($self, $domain) = @_;
    system("rndc delzone $domain 2>/dev/null 1>/dev/null");
}

1;
