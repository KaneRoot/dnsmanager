#!/usr/bin/perl -w
use strict;
use warnings;
use v5.14;
use autodie;
use Modern::Perl;
use DNS::ZoneParse;

use lib '../';
use app::zone::rndc_interface;
use app::zone::edit;

my $nom = $ARGV[0];
my $zdir = "/srv/named/";

my $ed = app::zone::edit->new(zdir => $zdir, zname => $nom);

my $zonefile = $ed->get();

my $a_records = $zonefile->a();

push (@$a_records, { name => 'web'
        , class => 'IN'
        , host => '192.168.0.190'
        , ttl => '3600'
        , ORIGIN => $zonefile->origin });

$ed->update($zonefile);

$zonefile = $ed->get();

print $zonefile->output();
