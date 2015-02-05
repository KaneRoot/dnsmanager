package configuration;
use YAML::XS;

use fileutil ':all';
use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/get_cfg is_reserved/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/get_cfg is_reserved/] ); 

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

1;
