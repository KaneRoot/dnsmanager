package bdd::user;
use Moo;
use v5.14;
use autodie;
use DBI;

use lib '../';
use domain;

has qw/domains is rw/;
has [ qw/login dbh/ ] => qw/is ro required 1/;
has passwd => (is => 'rw', trigger => \&_update_passwd );

sub is_admin { 0 }

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

sub delete_domain {
    my ($self, $domain) = @_;

    # check if we are the owner then delete
    if ((grep { $domain eq $_ } @{ $self->domains }) == 0) {
        die "The user $self->login don't have the domain $domain.";
    }

    delete_domain($$self{dbh}, $domain);

    @{ $self->domains } = grep { $_ ne $domain } @{ $self->domains };
}

sub add_domain {
    my ($self, $domain) = @_;
    add_domain($$self{dbh}, $$self{login}, $domain);
    push @{ $self->domains }, $domain;
}

1;
