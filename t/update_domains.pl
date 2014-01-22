#!/usr/bin/perl -w
use strict;
use warnings;
use v5.14;
use autodie;
use Modern::Perl;
use DNS::ZoneParse;
use Config::Simple;
use Data::Dump qw( dump );

use lib '../';
use app::app;

sub initco {

    my $cfg = new Config::Simple('./config.ini');
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

if( @ARGV < 2) {
    say "usage : ./auth.pl login domain";
    exit 1;
}

my $app = initco();
my ($auth_ok, $user, $isadmin) = $app->auth($ARGV[0], $ARGV[1]);

if($auth_ok) {
	say "auth $auth_ok";
	say "isadmin $isadmin";
}
else {
    say "erreur connexion";
    exit(0);
}

# TODO
my $zone = $app->get_domain($ARGV[0], $ARGV[1]);

say "origin : " . $zone->origin;

my $zcontent = $zone->output() . "\nwww IN A 10.0.0.2";

$app->update_domain_raw( $ARGV[0], $zcontent , $ARGV[1] );
