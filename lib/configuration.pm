package configuration;
use YAML::XS;
use URI;

use fileutil ':all';
use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
get_cfg is_reserved 
get_zonedir_from_cfg
get_host_from_cfg
get_user_from_cfg
get_port_from_cfg
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/get_cfg 
        is_reserved 
        get_zonedir_from_cfg
        get_host_from_cfg
        get_user_from_cfg
        get_port_from_cfg
        /] );

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

    $cfgdir //= './conf/';
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

sub get_zonedir_from_cfg {
    my $cfg = shift;
    unless($$cfg{zonedir}) {
        die 'For now, the only way to get the zone path is to setup zonedir '
        . 'in the primaryserver configuration in config.yml.';
    }
    URI->new($$cfg{zonedir})->path;
}

sub get_host_from_cfg {
    my $cfg = shift;

    if($$cfg{zonedir}) {
        my $u = URI->new($$cfg{zonedir});
        return $u->host;
    }
    elsif($$cfg{domain}{name}) {
        return $$cfg{domain}{name};
    }

    die "Impossible to get the host from the configuration.";
}

sub get_user_from_cfg {
    my $cfg = shift;

    if($$cfg{zonedir}) {
        my $u = URI->new($$cfg{zonedir});
        return $u->user;
    }
    elsif($$cfg{domain}{user}) {
        return $$cfg{domain}{user};
    }

    die "Impossible to get the user from the configuration.";
}

sub get_port_from_cfg {
    my $cfg = shift;

    if($$cfg{zonedir}) {
        my $u = URI->new($$cfg{zonedir});
        return $u->port;
    }
    elsif($$cfg{domain}{port}) {
        return $$cfg{domain}{port};
    }

    die "Impossible to get the port from the configuration.";
}

1;
