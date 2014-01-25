package app::bdd::admin;
use Moose;
extends 'app::bdd::lambda';

# ($success) activate_zone($domain)
sub activate_zone {
    my ($self, $domain) = @_; 
}

# ($success) delete_zone($file_path)
sub delete_zone {
    my ($self, $domain) = @_;
}

# $success delete_domain
sub delete_domain {
    my ($self, $domain) = @_;
    my $sth;

    $sth = $self->dbh->prepare('delete from domain where domain=?');
    unless ( $sth->execute($domain) ) {
        $sth->finish();
        return 0;
    }

    $sth->finish();
    # delete the domain from our domains
    @{ $self->domains } = grep { $_ ne $domain } @{ $self->domains };
    return 1;
}


1;
