#!/usr/bin/perl -w
use v5.14;
use autodie;
use utf8;
use open qw/:std :utf8/;
use Modern::Perl;

use Data::Dump qw( dump );

use lib './lib/';
use configuration ':all';
use app;

if( @ARGV != 0 ) {
    say "usage : echo user | ./$0";
    exit 1;
}

eval {
    my $app = app->new(get_cfg());

    while (<>) {
        chomp;
        say "delete user: $_";
        $app->delete_user($_);
    }
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
