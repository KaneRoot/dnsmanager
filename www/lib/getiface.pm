package getiface;
use v5.14;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/getiface/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/getiface/] ); 

sub getiface {
    my ($type, $params) = @_;
    given($type) {
        when /bind9/ { interface::bind9->new($params) }
        when /knot/  { interface::knot->new($params) }
        when /nsd/   { interface::nsd3->new($params) }
        default { undef }
    }
}

1;
