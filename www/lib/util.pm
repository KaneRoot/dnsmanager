package util;
use v5.10;

use Config::Simple;
use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/ is_domain_name is_reserved initco/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/is_domain_name is_reserved initco/] ); 

use Find::Lib '../../'; # TODO remove it when it won't be usefull anymore
use app::app;

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

# eventually change place
sub initco {

    my $cfg = new Config::Simple(dirname(__FILE__).'/../conf/config.ini');
    my $app = app->new( zdir => $cfg->param('zones_path')
        , dbname => $cfg->param('dbname')
        , dbhost => $cfg->param('host')
        , dbport => $cfg->param('port')
        , dbuser => $cfg->param('user')
        , dbpass => $cfg->param('passwd')
        , sgbd => $cfg->param('sgbd')
        , nsmasterv4 => $cfg->param('nsmasterv4')
        , nsmasterv6 => $cfg->param('nsmasterv6')
        , nsslavev4 => $cfg->param('nsslavev4')
        , nsslavev6 => $cfg->param('nsslavev6')
        , sshhost => $cfg->param('sshhost')
        , sshhostsec => $cfg->param('sshhostsec')
        , sshuser => $cfg->param('sshuser')
        , sshusersec => $cfg->param('sshusersec')
        , sshport => $cfg->param('sshport')
        , sshportsec => $cfg->param('sshportsec')
        , dnsslavekey => $cfg->param('dnsslavekey')
        , dnsapp => $cfg->param('dnsapp')
        , dnsappsec => $cfg->param('dnsappsec') );

    $app->init();

    return $app;
}

1;
