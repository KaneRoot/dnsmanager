use lib '../../';
use app::zone::rndc_interface;
use app::zone::knot_interface;
use app::zone::nsdc_interface;
package app::zone::interface;
use Moose;

sub get_interface {
    my ($self, $type, $data) = @_;
    return 1, app::zone::rndc_interface->new(data => $data) if $type eq 'rndc';
    return 1, app::zone::knot_interface->new(data => $data) if $type eq 'knot';
    return 1, app::zone::nsdc_interface->new(data => $data) if $type eq 'nsdc';
    return 0;
}

1;
