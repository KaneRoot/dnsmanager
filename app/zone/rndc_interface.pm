use v5.14;
package app::zone::rndc_interface;
use Moose;

# on suppose que tout est déjà mis à jour dans le fichier
sub reload {
    my ($self, $zname) = @_;
    system("rndc reload $zname 2>/dev/null 1>/dev/null");
}

sub addzone {
    my ($self, $zdir, $zname, $opt) = @_;

    my $command = "rndc addzone $zname ";

    if(defined $opt) {
        $command .= "'$opt'";
    }
    else {
        $command .= "'{ type master; file \"$zdir/$zname\"; };'"
    }


    $command .= " 2>/dev/null 1>/dev/null";
    system($command);

}

sub reconfig {
    my ($self, $zname) = @_;
    system("rndc reconfig 2>/dev/null 1>/dev/null");
}

sub delzone {
    my ($self, $zdir, $zname) = @_;
    system("rndc delzone $zname 2>/dev/null 1>/dev/null");
    unlink("$zdir/$zname");
}

1;
