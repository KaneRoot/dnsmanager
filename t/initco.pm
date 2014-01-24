use strict;
use warnings;
use v5.14;
use autodie;
use Modern::Perl;
use DNS::ZoneParse;
use Config::Simple;
use Data::Dump qw( dump );

package initco;

sub initco {
    my ($cfgfile) = @_;

    $cfgfile = defined $cfgfile ? $cfgfile : './config.ini';

    my $cfg = new Config::Simple($cfgfile);
    my $app = app->new( zdir => $cfg->param('zones_path'),
        dbname => $cfg->param('dbname'),
        dbhost => $cfg->param('host'),
        dbport => $cfg->param('port'),
        dbuser => $cfg->param('user'),
        dbpass => $cfg->param('passwd'),
        sgbd => $cfg->param('sgbd'),
        dnsapp => $cfg->param('dnsapp') );

    $app->init();

    return $app;
}

1;
