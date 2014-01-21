#!/usr/bin/env perl

use v5.14;
use DBI;

use lib '../';
use app::zone::interface;
use app::zone::edit;
use app::zone::rndc_interface;
use app::bdd::management;
use app::bdd::admin;
use app::bdd::lambda;

package app;
use Moose;

has dbh => ( is => 'rw', builder => '_void');
has dnsi => ( is => 'rw', builder => '_void');
has um => ( is => 'rw', builder => '_void');
has [ qw/zdir dbname dbhost dbport dbuser dbpass sgbd dnsapp/ ] => qw/is ro required 1/;
sub _void { my $x = ''; \$x; }

### users

sub init {
    my ($self) = @_;

    my $success;

    my $dsn = 'DBI:' . $self->sgbd
    . ':database=' . $self->dbname
    . ';host=' .  $self->dbhost
    . ';port=' . $self->dbport;

    ${$self->dbh} = DBI->connect($dsn
        , $self->dbuser
        , $self->dbpass) 
    || die "Could not connect to database: $DBI::errstr"; 

    ($success, ${$self->dnsi}) = app::zone::interface ->new()
    ->get_interface($self->dnsapp, $self->zdir);

    die("zone interface") unless $success;

    ${$self->um} = app::bdd::management->new(dbh => ${$self->dbh});
}

sub auth {
    my ($self, $login, $passwd) = @_;
    return ${$self->um}->auth($login, $passwd);
}

sub register_user {
    my ($self, $login, $passwd) = @_;
    return ${$self->um}->register_user($login, $passwd);
}

# TODO
sub set_admin {
    my ($self, $login) = @_;
    return ${$self->um}->set_admin($login);
}

sub update_passwd {
    my ($self, $login, $new) = @_;
    my $user = ${$self->um}->get_user($login);
    return $user->passwd($new);
}

sub delete_user {
    my ($self, $login) = @_;
    return ${$self->um}->delete_user($login);
}

### domains 

# return yes or no
sub add_domain {
    my ($self, $login, $domain) = @_; 
    my $user = ${$self->um}->get_user($login);
    $user->add_domain($domain);

    my $ze = app::zone::edit->new(zname => $domain, zdir => $self->zdir);
    $ze->addzone();
}

sub delete_domain {
    my ($self, $login, $domain) = @_; 
    my $user = ${$self->um}->get_user($login);
    $user->delete_domain($domain);
    my $ze = app::zone::edit->new(zname => $domain, zdir => $self->zdir);
    $ze->del();
}

sub update_domain_raw {
    my ($self, $login, $zone, $domain) = @_; 
    my $ze = app::zone::edit->new(zname => $domain, zdir => $self->zdir);
    $ze->update_raw($zone);
}

sub update_domain {
    my ($self, $login, $zone, $domain) = @_; 
    my $ze = app::zone::edit->new(zname => $domain, zdir => $self->zdir);
    $ze->update($zone);
}

sub get_domain {
    my ($self, $login, $domain) = @_; 
    my $ze = app::zone::edit->new(zname => $domain, zdir => $self->zdir);
    $ze->get();
}

sub get_domains {
    my ($self, $login) = @_; 

    my $user = ${$self->um}->get_user($login);
    return $user->domains;
}

sub activate_domain {
    my ($self, $domain) = @_; 
}

sub new_tmp {
    my ($self, $login, $domain) = @_; 
    my $ze = app::zone::edit->new(zname => $domain, zdir => $self->zdir);
    $ze->new_tmp();
}

1;
