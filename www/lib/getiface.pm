package getiface;
use v5.20;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/getiface/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/getiface/] ); 

sub getiface {
    my ($type, $params) = @_;
    for($type) {
        if (/bind9/)    { interface::bind9->new($params) }
        elsif (/knot/)  { interface::knot->new($params) }
        elsif (/nsd/)   { interface::nsd3->new($params) }
        default         { die "Interface for the $_ dns type not found."; }
    }
}

1;
