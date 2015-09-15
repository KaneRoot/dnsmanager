package util;
use v5.10;

use configuration ':all';
use YAML::XS;
use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/is_domain_name is_valid_tld/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/is_domain_name is_valid_tld/] );

# TODO we can check if dn matches our domain name
sub is_domain_name {
    my ($dn) = @_;
    my $ndd = qr/^
        ([a-zA-Z0-9]+[a-zA-Z0-9-]*[a-zA-Z0-9]*[.])*
        [a-zA-Z0-9]+[a-zA-Z0-9-]*[a-zA-Z0-9]([.])?
    $/x;
    return $dn =~ $ndd;
}

sub is_valid_tld {
    my ($tld) = @_;

    my $cfg = get_cfg;

    grep { $_ eq $tld } @{$$cfg{tld}};
}

1;
