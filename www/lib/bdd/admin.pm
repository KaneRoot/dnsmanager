package bdd::admin;
use Moo;
extends 'bdd::user';

sub is_admin { 1 }

# delete_domain
sub delete_domain {
    my ($self, $domain) = @_;
    my $sth;

    $sth = $self->dbh->prepare('delete from domain where domain=?');
    unless ( $sth->execute($domain) ) {
        $sth->finish();
    }

    $sth->finish();
    # delete the domain from our domains
    @{ $self->domains } = grep { $_ ne $domain } @{ $self->domains };
    return 1;
}

1;
