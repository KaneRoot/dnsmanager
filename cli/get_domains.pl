#!/usr/bin/perl -w
use v5.14;
use autodie;
use utf8;
use open qw/:std :utf8/;
use Modern::Perl;

#use DNS::ZoneParse;
#use Config::Simple;
use Data::Dump qw( dump );

use lib './lib/';
use configuration ':all';
use app;

if( @ARGV != 0 ) {
    say "usage : ./$0";
    exit 1;
}

eval {
    my $app = app->new(get_cfg());
    my $domains = $app->get_all_domains();
    dump($domains);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
