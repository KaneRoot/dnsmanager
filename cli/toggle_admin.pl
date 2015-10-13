#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;

use Data::Dump qw( dump );

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;
use utf8;

if( @ARGV != 1 ) {
    say "usage : ./$0 login";
    exit 1;
}

my $login = $ARGV[0];

eval {
    my $app = app->new(get_cfg());
    $app->toggle_admin($login);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
