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
has [ qw/zdir dbname dbhost dbport dbuser dbpass sgbd dnsapp sshhost sshuser/ ] => qw/is ro required 1/;
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
    ${$self->um}->auth($login, $passwd);
}

sub register_user {
    my ($self, $login, $passwd) = @_;
    ${$self->um}->register_user($login, $passwd);
}

sub set_admin {
    my ($self, $login, $val) = @_;
    ${$self->um}->set_admin($login, $val);
}

sub update_passwd {
    my ($self, $login, $new) = @_;
    my ($success, $user, $isadmin) = ${$self->um}->get_user($login);
    $user->passwd($new);
}

sub delete_user {
    my ($self, $login) = @_;
    my ($success, @domains) = $self->get_domains($login);

    if($success) {
        $self->delete_domain($login, $_) foreach(@domains);
        ${$self->um}->delete_user($login);
    }
}

### domains 

# return yes or no
sub add_domain {
    my ($self, $login, $domain) = @_; 
    my ($success, $user, $isadmin) = ${$self->um}->get_user($login);

    unless($success) {
        return 0;
    }

    unless ($user->add_domain($domain)) {
        return 0;
    }

    my $ze = app::zone::edit->new(zname => $domain
        , zdir => $self->zdir
        , host => $self->sshhost
        , user => $self->sshuser );
    $ze->addzone();
}

sub delete_domain {
    my ($self, $login, $domain) = @_; 

    my ($success, $user, $isadmin) = ${$self->um}->get_user($login);

    return 0 unless $success;
    return 0 unless $user->delete_domain($domain);

    my $ze = app::zone::edit->new(zname => $domain
        , zdir => $self->zdir
        , host => $self->sshhost
        , user => $self->sshuser );
    $ze->del();

    1;
}

sub update_domain_raw {
    my ($self, $login, $zone, $domain) = @_; 
    my $ze = app::zone::edit->new(zname => $domain
        , zdir => $self->zdir
        , host => $self->sshhost
        , user => $self->sshuser );
    $ze->update_raw($zone);
}

sub update_domain {
    my ($self, $login, $zone, $domain) = @_; 
    my $ze = app::zone::edit->new(zname => $domain
        , zdir => $self->zdir
        , host => $self->sshhost
        , user => $self->sshuser );
    $ze->update($zone);
}

sub get_domain {
    my ($self, $login, $domain) = @_; 
    my $ze = app::zone::edit->new(zname => $domain
        , zdir => $self->zdir
        , host => $self->sshhost
        , user => $self->sshuser );
    $ze->get();
}

sub get_domains {
    my ($self, $login) = @_; 
    ${$self->um}->get_domains($login);
}

sub get_all_domains {
    my ($self) = @_; 
    # % domain login
    ${$self->um}->get_all_domains;
}

sub get_all_users {
    my ($self) = @_; 
    # % login admin
    ${$self->um}->get_all_users;
}

sub new_tmp {
    my ($self, $login, $domain) = @_; 
    my $ze = app::zone::edit->new(zname => $domain
        , zdir => $self->zdir
        , host => $self->sshhost
        , user => $self->sshuser );
    $ze->new_tmp();
}

sub delete_entry {
	my ($self, $login, $domain, $entryToDelete) = @_;

	my $name = $entryToDelete->{'name'};
	my $type = $entryToDelete->{'type'};
	my $ttl = $entryToDelete->{'ttl'};
	my $host = $entryToDelete->{'host'};

	my $zone = $self->get_domain($login , $domain);
	my $dump = $zone->dump;

	my $record;
	my $found = 0;

	given( lc $type )
	{
		when ('a')
		{
			$record = $zone->a;
			$found = 1;
		}
		when ('aaaa')
		{
			$record = $zone->aaaa;
			$found = 1;
		}
		when ('cname')
		{
			$record = $zone->cname;
			$found = 1;
		}
		when ('ns')
		{
			$record = $zone->ns;
			$found = 1;
		}
		when ('mx')
		{
			$record = $zone->mx;
			$found = 1;
		}
		when ('ptr')
		{
			$record = $zone->ptr;
			$found = 1;
		}
	}

	if( $found )
	{

		foreach my $i ( 0 .. scalar @{$record}-1 )
		{

			delete $record->[$i]
				if( $record->[$i]->{'name'} eq $name && 
					$record->[$i]->{'host'} eq $host &&
					$record->[$i]->{'ttl'} == $ttl );

		}

	}

	$self->update_domain( $login, $zone, $domain );

}

1;
