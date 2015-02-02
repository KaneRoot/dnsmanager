package db;
use v5.14;
use Moo;

use Modern::Perl;
use autodie;
use DBI;

use bdd::lambda;
use bdd::admin;
use getiface ':all';

has [qw/dbh/] => qw/is rw required 1/;

# ($success, $user, $admin) auth_user($login, $passwd)
sub auth {
    my ($self, $login, $passwd) = @_;
    my ($sth, $success, $user, $isadmin);

    $sth = $self->dbh->prepare('SELECT * FROM user WHERE login=? and passwd=?');
    unless ($sth->execute($login, $passwd)) {
        $sth->finish();
        return 0;
    }

    if (my $ref = $sth->fetchrow_arrayref) {
        # if this user exists and is auth
        ($success, $user, $isadmin) = $self->get_user($login);
    }
    else {
        $success = 0;
    }

    $sth->finish();
    return ($success, $user, $isadmin);
}

# ($success) register_user
sub register_user {
    my ($self, $login, $pass) = @_;

    my $sth = $self->dbh->prepare('select * from user where login=?');
    unless ( $sth->execute($login) ) {
        $sth->finish();
        return 0;
    }

    # if an user already exists
    if (my $ref = $sth->fetchrow_arrayref) {
        $sth->finish();
        return 0;
    }

    # if not
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

    # TODO : vérifier que ça renvoie la bonne valeur
    $sth = $self->dbh->prepare('delete from user where login=?');
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

        while(my $ref2 = $sth->fetchrow_arrayref) {
            push @domains, @$ref2[0];
        }

        # si admin
        if(@$ref[2]) {
            $user = bdd::admin->new(login => @$ref[0]
                , passwd => @$ref[1]
                , dbh => $self->dbh
                , domains => [@domains]); 

        }
        else {
            $user = bdd::lambda->new(login => @$ref[0]
                , passwd => @$ref[1]
                , dbh => $self->dbh
                , domains => [@domains]); 
        }

        $sth->finish();
        return (1, $user, @$ref[2]);
    }

    $sth->finish();
    return 0;
}

sub get_domains {
    my ($self, $login) = @_; 
    my ($sth, @domains);

    $sth = $self->dbh->prepare('SELECT domain FROM domain where login=?');
    unless ($sth->execute($login)) {
        $sth->finish();
        return (0, @domains);
    }

    while(my $ref = $sth->fetchrow_arrayref) {
        push @domains, @$ref[0];
    }

    $sth->finish();

    return (1, @domains);
}

sub get_all_domains {
    my ($self) = @_; 
    my ($sth, %domains);

    $sth = $self->dbh->prepare('SELECT domain, login FROM domain');
    unless ( $sth->execute()) {
        $sth->finish();
        undef;
    }

    while( my $ref = $sth->fetchrow_arrayref) {
        $domains{@$ref[0]} = @$ref[1];
    }

    $sth->finish();
    %domains;
}

sub get_all_users {
    my ($self) = @_; 
    my ($sth, %users);

    $sth = $self->dbh->prepare('SELECT login, admin FROM user');
    unless ( $sth->execute()) {
        $sth->finish();
        undef;
    }

    while( my $ref = $sth->fetchrow_arrayref) {
        $users{@$ref[0]} = @$ref[1];
    }

    $sth->finish();
    %users;
}

sub set_admin {
    my ($self, $login, $val) = @_;

    my $sth = $self->dbh->prepare('update user set admin=? where login=?');
    unless ( $sth->execute( $val, $login) ) {
        $sth->finish();
        return 0;
    }

    $sth->finish();
    return 1;
}

1;

1;
