package configuration;
use YAML::XS;
use URI;

use fileutil ':all';
use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/get_cfg is_reserved get_zpath_from_primary_server/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/get_cfg 
        is_reserved 
        get_zpath_from_primary_server/] ); 

sub is_conf_file {
    my $f = shift;

    unless(-f $f) {
        die "$f : not a file";
    }

    unless(-r $f) {
        die "$f : not readable";
    }

    unless(-T $f) {
        die "$f : not plain text";
    }
}

sub get_cfg {
    my ($cfgdir) = @_;

    $cfgdir //= '../conf/';
    my $f = "$cfgdir/config.yml";

    is_conf_file $f;
    YAML::XS::LoadFile($f);
}

sub is_reserved {
    my ($domain) = @_;

    my $filename = 'conf/reserved.zone';
    is_conf_file $filename;

    my $data = read_file $filename;
    $data =~ /^$domain$/m;
}

sub get_zpath_from_primary_server {
    my $primary_dns_server_cfg = shift;

    my $u;
    if($$primary_dns_server_cfg{zonedir}) {
        $u = URI->new($$primary_dns_server_cfg{zonedir});
    }
    else {
        die 'For now, the only way to get the zone path is to setup zonedir '
        . 'in the primaryserver configuration in config.yml.';
    }

    $u->path;
}

1;
