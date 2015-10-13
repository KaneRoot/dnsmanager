#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;
use utf8;

if( @ARGV != 1 ) {
    say "usage : ./$0 ndd ";
    exit 1;
}

my $dom = $ARGV[0];

eval {
    my $app = app->new(get_cfg());
    $app->delete_domain( $dom );
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
