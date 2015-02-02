package util;
use v5.10;

use YAML::XS;
use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/ is_domain_name is_reserved/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/is_domain_name is_reserved/] ); 

# TODO we can check if dn matches our domain name
sub is_domain_name {
    my ($dn) = @_;
    my $ndd = qr/^
        ([a-zA-Z0-9]+[a-zA-Z0-9-]*[a-zA-Z0-9]*.)*
        [a-zA-Z0-9]+[a-zA-Z0-9-]*[a-zA-Z0-9]
    $/x;
    return $dn =~ $ndd;
}

sub is_reserved {
    my ($domain) = @_;

    my $filename = "conf/reserved.zone";
    open my $entree, '<:encoding(UTF-8)', $filename or 
    die "Impossible d'ouvrir '$filename' en lecture : $!";

    while(<$entree>) {
        if(m/^$domain$/) {
            return 1;
        }
    }

    return 0;
}

1;
