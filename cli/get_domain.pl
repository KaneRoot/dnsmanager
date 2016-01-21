#!/usr/bin/perl -w
use v5.14;
use autodie;
use utf8;
use open qw/:std :utf8/;
use Modern::Perl;

use Data::Dump qw( dump );

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;

if( @ARGV != 1 ) {
    say "usage : ./$0 domain";
    exit 1;
}

my $dom = $ARGV[0];

eval {
    my $app = app->new(get_cfg());
    my $domain = $app->get_domain($dom);
    dump($domain);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
