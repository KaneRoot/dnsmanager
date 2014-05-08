use v5.14;
package app::zone::knot_interface;
use Moose;

# on suppose que tout est déjà mis à jour dans le fichier
sub reload {
    my ($self, $zname) = @_;
    die "knot ns not implemented yet";
}

sub addzone {
    die "knot primary ns not implemented yet";
}

# add a domain on a secondary ns
sub addzone_sec {
    my ($self, $zdir, $zname, $opt) = @_;
    die "knot secondary ns not implemented yet";
}

sub delzone {
    my ($self, $zdir, $zname) = @_;
    die "knot ns not implemented yet";
}

1;
