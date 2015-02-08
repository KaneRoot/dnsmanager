package bdd::user;
use Moo;
use v5.14;
use autodie;
use DBI;

use lib '../../';
use Data::Dump "dump";

has qw/domains is rw/;
has [ qw/login dbh/ ] => qw/is ro required 1/;
has passwd => (is => 'rw', trigger => \&_update_passwd );

sub is_admin { 0 }

# $success delete_domain
sub delete_domain {
    my ($self, $domain) = @_;
    my $sth;

    # check if we are the owner then delete
    if ((grep { $domain eq $_ } @{ $self->domains }) == 0) {
        die "The user $self->login don't have the domain $domain.";
    }

    $sth = $self->dbh->prepare('delete from domain where domain=?');
    unless ( $sth->execute($domain) ) {
        $sth->finish();
        die "Impossible to delete the $domain of the user $self->login.";
    }

    $sth->finish();
    # delete the domain from our domains
    @{ $self->domains } = grep { $_ ne $domain } @{ $self->domains };
}


# $success add_domain
sub add_domain {
    my ($self, $domain) = @_;
    my ($sth);

    $sth = $self->dbh->prepare('select domain from domain where domain=?');
    unless ( $sth->execute($domain) ) {
        $sth->finish();
        die 'Impossible to search if the domain already exists.';
    }

    # if the domain already exists
    if (my $ref = $sth->fetchrow_arrayref) {
        $sth->finish();
        die 'The domain already exists.';
    }

    $sth = $self->dbh->prepare('insert into domain VALUES(?,?,?)');
    unless ( $sth->execute($domain, $self->login, 0) ) {
        $sth->finish();
        die 'Impossible to add a domain.';
    }

    $sth->finish();
    push @{ $self->domains }, $domain;
}

sub _update_passwd {
    my ($self, $new) = @_;
    my $sth;

    $sth = $self->dbh->prepare('update user set passwd=? where login=?');
    unless ( $sth->execute($new, $self->login) ) {
        $sth->finish();
        die q{The password can't be updated.};
    }
    $sth->finish();
}

1;
