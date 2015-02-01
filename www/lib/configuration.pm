package configuration;
use YAML::XS;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/get_cfg/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/get_cfg/] ); 

sub get_cfg {
    my ($cfgdir) = @_;
    return undef unless defined $cfgdir;
    YAML::XS::LoadFile($cfgdir.'/config.yml');
}

1;
