package db;
use v5.14;
use Moo;

use Modern::Perl;
use autodie;
use DBI;

use bdd::user;
use bdd::admin;
use getiface ':all';

# db handler
has dbh => ( is => 'rw', builder => '_void');

sub _void { my $x = ''; \$x; }

# reference to the application
has data => qw/is ro required 1/;

sub BUILD {
    my $self = shift;

    my $db = $$self{data}{database};

    my $dsn = "DBI:$$db{sgbd}:database=$$db{name};"
    . "host=$$db{host};port=$$db{port}";

    $$self{dbh} = DBI->connect($dsn, $$db{user}, $$db{passwd}) 
    || die "Could not connect to database: $DBI::errstr"; 
    $$self{dbh}->{mysql_enable_utf8} = 1;
    $$self{dbh}->do('SET NAMES \'utf8\';') || die;

}

sub auth {
    my ($self, $login, $passwd) = @_;
    my $sth;

    $sth = $self->dbh->prepare('SELECT * FROM user WHERE login=? and passwd=?');
    unless ($sth->execute($login, $passwd)) {
        $sth->finish();
        die q{Can't authenticate.};
    }

    # if we can't find the user with this password
    unless (my $ref = $sth->fetchrow_arrayref) {
        $sth->finish();
        die q{The user can't be authenticated.};
    }
    $sth->finish();

    # if this user exists and is auth
    $self->get_user($login);
}

# register_user
sub register_user {
    my ($self, $login, $pass) = @_;

    my $sth = $self->dbh->prepare('select * from user where login=?');
    unless ( $sth->execute($login) ) {
        $sth->finish();
        die "Impossible to check if the user $login exists.";
    }

    # if an user already exists
    if (my $ref = $sth->fetchrow_arrayref) {
        $sth->finish();
        die "The user $login already exists.";
    }

    # if not
    $sth = $self->dbh->prepare('insert into user VALUES(?,?,?)');
    unless ($sth->execute($login, $pass, 0)) {
        $sth->finish();
        die "Impossible to register the user $login.";
    }
    $sth->finish();
}

# delete_user
sub delete_user {
    my ($self, $login) = @_;
    my $sth;

    # TODO : vérifier que ça renvoie la bonne valeur
    $sth = $self->dbh->prepare('delete from user where login=?');
    unless ( $sth->execute($login) ) {
        $sth->finish();
        die "Impossible to delete the user $login.";
    }
    $sth->finish();
}

sub get_user {
    my ($self, $login) = @_;
    my ($sth, $user, @domains);

    $sth = $self->dbh->prepare('SELECT * FROM user WHERE login=?');
    unless ( $sth->execute($login)) {
        $sth->finish();
        die "Impossible to check if the user $login exists.";
    }

    my $ref;
    unless ($ref = $sth->fetchrow_arrayref) {
        $sth->finish();
        die "User $login doesn't exist.";
    }

    $sth = $self->dbh->prepare('SELECT domain FROM domain WHERE login=?');
    unless ( $sth->execute($login)) {
        $sth->finish();
        die "Impossible to check if the user $login has domains.";
    }

    # the user gets all his domains
    while(my $ref2 = $sth->fetchrow_arrayref) {
        push @domains, @$ref2[0];
    }

    # if the user is an admin
    if(@$ref[2]) {
        $user = bdd::admin->new(login => @$ref[0]
            , passwd => @$ref[1]
            , dbh => $$self{dbh}
            , domains => [@domains]); 
    }
    else {
        $user = bdd::user->new(login => @$ref[0]
            , passwd => @$ref[1]
            , dbh => $$self{dbh}
            , domains => [@domains]); 
    }

    $sth->finish();

    $user;
}

sub get_domains {
    my ($self, $login) = @_; 
    my ($sth);
    my $domains = [];

    $sth = $self->dbh->prepare('SELECT domain FROM domain where login=?');
    unless ($sth->execute($login)) {
        $sth->finish();
        die 'Impossible to list the domains.';
    }

    while(my $ref = $sth->fetchrow_arrayref) {
        push @$domains, @$ref[0];
    }

    $sth->finish();

    $domains;
}

sub get_all_domains {
    my ($self) = @_; 
    my ($sth, $domains);

    $sth = $self->dbh->prepare('SELECT domain, login FROM domain');
    unless ( $sth->execute()) {
        $sth->finish();
        die q{Impossible to list the domains.};
    }

    while( my $ref = $sth->fetchrow_arrayref) {
        $$domains{@$ref[0]} = @$ref[1];
    }

    $sth->finish();
    $domains;
}

sub get_all_users {
    my ($self) = @_; 
    my ($sth, $users);

    $sth = $self->dbh->prepare('SELECT login, admin FROM user');
    unless ( $sth->execute()) {
        $sth->finish();
        die q{Impossible to list the users.};
    }

    while( my $ref = $sth->fetchrow_arrayref) {
        $$users{@$ref[0]} = @$ref[1];
    }

    $sth->finish();
    $users;
}

sub toggle_admin {
    my ($self, $login) = @_;

    my $user = $self->get_user($login);
    my $val = ($user->is_admin()) ? 0 : 1;

    my $sth = $self->dbh->prepare('update user set admin=? where login=?');
    unless ( $sth->execute( $val, $login ) ) {
        $sth->finish();
        die "Impossible to toggle admin the user $login.";
    }

    $sth->finish();
}

1;
