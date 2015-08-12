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

if( @ARGV != 0 && @ARGV != 2 ) {
    say "usage : ./$0 [ login passwd ]";
    exit 1;
}

my ($login, $passwd) = qw/test test/;
($login, $passwd) = ($ARGV[0], $ARGV[1]) if ( @ARGV == 2 );

eval {
    my $app = app->new(get_cfg());
    my $user = $app->auth($login, encrypt($passwd));
    dump($user);
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
