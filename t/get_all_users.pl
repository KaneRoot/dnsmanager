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
use initco;

if( @ARGV != 0 ) {
    say "usage : ./get_all_domains.pl";
    exit 1;
}

my $app = initco::initco();

my %users = $app->get_all_users();

dump(%users);

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
