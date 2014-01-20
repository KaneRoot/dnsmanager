use Modern::Perl;
use autodie;
use v5.14;
use DBI;

use lib '../';
use app::bdd::lambda;
use app::bdd::admin;
use app::zone::interface;

package app::bdd::management;
use Moose;

has [qw/dbh/] => qw/is rw required 1/;

# ($success, $user, $admin) auth_user($login, $passwd)
sub auth {
    my ($self, $login, $passwd) = @_;
    my ($sth, $user, @domains);

    $sth = $self->dbh->prepare('SELECT * FROM user WHERE login=? and passwd=?');
    unless ( $sth->execute($login, $passwd)) {
        $sth->finish();
        return 0;
    }

    if (my $ref = $sth->fetchrow_arrayref) {
        $sth = $self->dbh->prepare('SELECT domain FROM domain WHERE login=?');
        unless ( $sth->execute($login)) {
            $sth->finish();
            return 0;
        }

        # get domains 
        #push @domains, @$_[0] while($sth->fetchrow_arrayref);

        while(my $ref2 = $sth->fetchrow_arrayref) {
            push @domains, @$ref2[0];
        }


        # si admin
        if(@$ref[2]) {

            # TODO : the admin module
            $user = app::bdd::admin->new(login => @$ref[0]
                , passwd => @$ref[1]
                , dbh => $self->dbh
                , domains => [@domains]); 
            $sth->finish();
            return 1, $user, 1;

        }
        else {
            $user = app::bdd::lambda->new(login => @$ref[0]
                , passwd => @$ref[1]
                , dbh => $self->dbh
                , domains => [@domains]); 
            $sth->finish();
            return 1, $user, 0;
        }
    }

    $sth->finish();
    return 0;
}

# ($success) register_user
sub register_user {
    my ($self, $login, $pass) = @_;

    my $sth = $self->dbh->prepare('select * from user where login=?');
    unless ( $sth->execute($login) ) {
        $sth->finish();
        return 0;
    }

    if (my $ref = $sth->fetchrow_arrayref) {
        #say join (', ', @$ref);
        $sth->finish();
        return 0;
    }

    $sth = $self->dbh->prepare('insert into user VALUES(?,?,?)');
    unless ($sth->execute($login, $pass, 0)) {
        $sth->finish();
        return 0;
    }
    $sth->finish();

    return 1;
}

# ($success) delete_user
sub delete_user {
    my ($self, $login) = @_;
    my $sth;

    $sth = $self->dbh->prepare('delete from user where login=?');
    unless ( $sth->execute($login) ) {
        $sth->finish();
        return 0;
    }
    $sth->finish();

    $sth = $self->dbh->prepare('delete from domain where login=?');
    unless ( $sth->execute($login) ) {
        $sth->finish();
        return 0;
    }
    $sth->finish();

    return 1;
}

sub get_user {
    my ($self, $login) = @_;
    my ($sth, $user, @domains);

    $sth = $self->dbh->prepare('SELECT * FROM user WHERE login=?');
    unless ( $sth->execute($login)) {
        $sth->finish();
        return 0;
    }

    if (my $ref = $sth->fetchrow_arrayref) {
        $sth = $self->dbh->prepare('SELECT domain FROM domain WHERE login=?');
        unless ( $sth->execute($login)) {
            $sth->finish();
            return 0;
        }

        # get domains 
        #push @domains, @$_[0] while($sth->fetchrow_arrayref);

        while(my $ref2 = $sth->fetchrow_arrayref) {
            push @domains, @$ref2[0];
        }

        # si admin
        if(@$ref[2]) {
            $user = app::bdd::admin->new(login => @$ref[0]
                , passwd => @$ref[1]
                , dbh => $self->dbh
                , domains => [@domains]); 

        }
        else {
            $user = app::bdd::lambda->new(login => @$ref[0]
                , passwd => @$ref[1]
                , dbh => $self->dbh
                , domains => [@domains]); 
        }
        $sth->finish();
        return 1, $user;
    }

    $sth->finish();
}

1;
