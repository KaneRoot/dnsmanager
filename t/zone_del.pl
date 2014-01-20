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

my $ed = app::zone::edit->new( zname => $ARGV[0], zdir => "/srv/named/");

say "suppression de ". $ARGV[0];

$ed->del();
