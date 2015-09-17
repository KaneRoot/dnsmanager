#!/usr/bin/perl -w
use v5.14;
use autodie;
use Modern::Perl;

use Data::Dump qw( dump );

use lib './lib/';
use configuration ':all';
use encryption ':all';
use app;

if( @ARGV != 2 ) {
    say "usage : ./$0 userid newpasswd";
    exit 1;
}

my ($login, $passwd) = ($ARGV[0], $ARGV[1]);

eval {
    my $app = app->new(get_cfg());
    $app->update_passwd($login, encrypt($passwd));
};

if( $@ ) {
    say q{Une erreur est survenue. } . $@;
}
