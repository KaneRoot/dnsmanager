#!/usr/bin/perl -w
use v5.14;
use autodie;
use utf8;
use Modern::Perl;

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
    my $users = $app->get_all_users();
    dump($users);
    my @keys = keys %$users;
    say " $keys[0] is_utf8 : " . (utf8::is_utf8($keys[0]) ? "oui" : "non");
};


if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
