#!/usr/bin/perl -w
use v5.14;
use autodie;
use utf8;
use open qw/:std :utf8/;
use Modern::Perl;

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;

if( @ARGV != 2 ) {
    say "usage : ./$0 login ndd ";
    exit 1;
}

my ($login, $dom) = ($ARGV[0], $ARGV[1]);

eval {
    my $app = app->new(get_cfg());
    $app->add_domain( $login, $dom );
    my $zone = $app->get_domain($dom);
    say $zone->output();
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
