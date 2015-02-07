package interface::bind9;
use v5.14;
use Moo;

has [ qw/data/ ] => qw/is ro required 1/;

sub reload {
    my ($self, $domain) = @_;
    system("rndc reload $domain 2>/dev/null 1>/dev/null");
    system("rndc notify $domain 2>/dev/null 1>/dev/null");
}

sub addzone {
    my ($self, $zdir, $domain, $opt) = @_;

    my $command = "rndc addzone $domain ";

    if(defined $opt) {
        $command .= "'$opt'";
    }
    else {

        $command .= "'{ type master; file \"$zdir/$domain\"; allow-transfer { ";
        my $sec = $$self{data}{secondarydnsserver};
        for(@$sec) {
            $command .= $$_{domain}{v4} . '; ' if $$_{domain}{v4}; 
            $command .= $$_{domain}{v6} . '; ' if $$_{domain}{v6};
        }
        . " }; notify yes; };'";
    }

    $command .= " 2>/dev/null 1>/dev/null";
    system($command);

}

sub reconfig {
    my ($self, $domain) = @_;
    system("rndc reconfig 2>/dev/null 1>/dev/null");
}

sub delzone {
    my ($self, $zdir, $domain) = @_;
    system("rndc delzone $domain 2>/dev/null 1>/dev/null");
}

1;
