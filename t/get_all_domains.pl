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

if( @ARGV != 0 ) {
    say "usage : ./get_all_domains.pl";
    exit 1;
}

my $app = initco();

my %domains = $app->get_all_domains();

dump(%domains);

#if( $domains ) {
#    if( scalar(@$domains) != 0) {
#        say join ", ", @{$domains};
#    }
#    else {
#        say "tableau vide";
#    }
#}
#else {
#    say "domains undef";
#}
