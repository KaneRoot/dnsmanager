package encryption;
use Crypt::Digest::SHA256 qw( sha256_hex ) ;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/encrypt/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/encrypt/] ); 

sub encrypt {
    my ($x) = @_;
    sha256_hex($x)
}

1;
