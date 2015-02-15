package bdd::admin;
use Moo;
extends 'bdd::user';

use domain;

sub is_admin { 1 }

# delete_domain
sub delete_domain {
    my ($self, $domain) = @_;

    domain::delete_domain($$self{dbh}, $domain);

    # delete the domain from our domains
    @{ $self->domains } = grep { $_ ne $domain } @{ $self->domains };

}

1;
