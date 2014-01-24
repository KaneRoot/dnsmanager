use autodie;
use v5.14;
use DBI;

use Data::Dump "dump";

use lib '../../';
package app::bdd::lambda;
use Moose;

has qw/domains is rw/;
has [ qw/login dbh/ ] => qw/is ro required 1/;
has passwd => (is => 'rw', trigger => \&_update_passwd );
#has qw/dbh is ro required 1/; # database handler

# $success delete_domain
sub delete_domain {
    # check if we are the owner then delete
    my ($self, $domain) = @_;
    my $sth;
    return 0 if (grep { $domain eq $_ } @{ $self->domains }) == 0;

    $sth = $self->dbh->prepare('delete from domain where domain=?');
    unless ( $sth->execute($domain) ) {
        $sth->finish();
        return 0;
    }
    $sth->finish();
    @{ $self->domains } = grep { $_ ne $domain } @{ $self->domains };
    return 1;
}


# $success add_domain
sub add_domain {
    my ($self, $domain) = @_;
    my ($sth);

    $sth = $self->dbh->prepare('select domain from domain where domain=?');
    unless ( $sth->execute($domain) ) {
        $sth->finish();
        return 0;
    }

    # if the domain already exists
    if (my $ref = $sth->fetchrow_arrayref) {
        $sth->finish();
        return 0;
    }

    $sth = $self->dbh->prepare('insert into domain VALUES(?,?,?)');
    unless ( $sth->execute($domain, $self->login, 0) ) {
        $sth->finish();
        return 0;
    }

    $sth->finish();
    push @{ $self->domains }, $domain;
    return 1;
}

sub _update_passwd {
    my ($self, $new) = @_;
    my $sth;

    $sth = $self->dbh->prepare('update user set passwd=? where login=?');
    unless ( $sth->execute($new, $self->login) ) {
        $sth->finish();
        return 0;
    }
    $sth->finish();
    return 1;
}

1;
