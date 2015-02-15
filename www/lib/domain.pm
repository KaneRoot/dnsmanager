package domain;
use v5.14;
use autodie;
use DBI;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/delete_domain add_domain/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/delete_domain add_domain/] ); 

sub delete_domain {
    my ($dbh, $domain) = @_;
    my $sth;

    $sth = $dbh->prepare('delete from domain where domain=?');
    unless ( $sth->execute($domain) ) {
        $sth->finish();
        die "Impossible to delete the $domain.";
    }

    $sth->finish();
}

# TODO check if the domain is reserved

sub add_domain {
    my ($dbh, $login, $domain) = @_;
    my ($sth);

    $sth = $dbh->prepare('select domain from domain where domain=?');
    unless ( $sth->execute($domain) ) {
        $sth->finish();
        die 'Impossible to search if the domain already exists.';
    }

    # if the domain already exists
    if (my $ref = $sth->fetchrow_arrayref) {
        $sth->finish();
        die 'The domain already exists.';
    }

    $sth = $dbh->prepare('insert into domain VALUES(?,?,?)');
    unless ( $sth->execute($domain, $login, 0) ) {
        $sth->finish();
        die 'Impossible to add a domain.';
    }

    $sth->finish();
}

1;
