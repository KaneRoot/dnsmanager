package configuration;
use YAML::XS;
use URI;

use fileutil ':all';
use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
get_cfg is_reserved 
get_zonedir_from_cfg
get_dnsslavekey_from_cfg
get_v4_from_name
get_v6_from_name
get_v4_from_cfg
get_v6_from_cfg
get_host_from_cfg
get_user_from_cfg
get_port_from_cfg
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
get_cfg is_reserved 
get_zonedir_from_cfg
get_dnsslavekey_from_cfg
get_v4_from_name
get_v6_from_name
get_v4_from_cfg
get_v6_from_cfg
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
    YAML::XS::LoadFile($f)
}

sub is_reserved {
    my ($domain) = @_;

    my $filename = 'conf/reserved.zone';
    is_conf_file $filename;

    my $data = read_file $filename;
    $data =~ /^$domain$/m;
}

# TODO : tests
sub get_v6_from_name {
    my $name = shift;

    my $val = qx/host -t AAAA $name | grep -oE '[^[:space:]]+\$'/;
    chomp $val;

    #die q{There is no available v6. TODO.} if($val =~ 'NXDOMAIN');
    return undef if($val =~ 'NXDOMAIN');

    $val
}

sub get_v4_from_name {
    my $name = shift;

    my $val = qx/host -t A $name | grep -oE '[^[:space:]]+\$'/;
    chomp $val;

    die q{There is no available v4. TODO.} if($val =~ 'NXDOMAIN');

    $val
}

sub get_v6_from_cfg {
    my $cfg = shift;
    $$cfg{domain}{v6} // get_v6_from_name($$cfg{domain}{name})
}

sub get_v4_from_cfg {
    my $cfg = shift;
    $$cfg{domain}{v4} // get_v4_from_name($$cfg{domain}{name})
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

    die "Impossible to get the host from the configuration."
}

sub get_dnsslavekey_from_cfg {
    my $cfg = shift;

    if($$cfg{dnsslavekey}) {
        return $$cfg{dnsslavekey};
    }

    die "Impossible to get the dns slave key from the configuration."
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

    die "Impossible to get the user from the configuration."
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

    die "Impossible to get the port from the configuration."
}

1;
