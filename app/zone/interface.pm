use lib '../../';
use app::zone::bind_interface;
use app::zone::rndc_interface;
package app::zone::interface;
use Moose;

sub get_interface {
	my ($self, $type, $zp) = @_;
	return 1, app::zone::bind_interface->new(zone_path => $zp) if $type eq 'bind';
	return 1, app::zone::rndc_interface->new(zdir => $zp) if $type eq 'rndc';
	return 0;
}

1;
