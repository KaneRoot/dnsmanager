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

if( @ARGV != 0 ) {
    say "usage : echo ndd | ./$0";
    exit 1;
}

eval {
    my $app = app->new(get_cfg());

    while (<>) {
        chomp ;
        say "zone to delete: $_";

        $app->delete_domain( $_ );
    }
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
