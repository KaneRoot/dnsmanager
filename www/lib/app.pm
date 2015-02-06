package app;
use v5.14;
use DBI;
use Moo;

use getiface ':all';

use db;
use bdd::admin;
use bdd::lambda;

has dbh => ( is => 'rw', builder => '_void');
has dnsi => ( is => 'rw', builder => '_void_arr');
has dnsisec => ( is => 'rw', builder => '_void');
has um => ( is => 'rw', builder => '_void');
has [qw/tmpdir database primarydnsserver secondarydnsserver/] 
=> qw/is ro required 1/;
sub _void { my $x = ''; \$x; }
sub _void_arr { [] }

### users

sub init_dns_servers {
    my ($self, $primary, @secondaries) = @_;

    my $primary_dns_server = getiface($primary, { data => $self });
    die("zone interface") unless defined $primary_dns_server;

    my @sec_dns_servers = ();
    for(@secondaries) {
        my $x = @$_[0];
        my $sec_dns_server = getiface($$x{app}, { data => $self });
        die("zone interface (secondary ns)") unless defined $sec_dns_server;
        push @sec_dns_servers, $sec_dns_server;
    }

    ($primary_dns_server, @sec_dns_servers);
}

sub BUILD {
    my ($self) = @_;

    my $db = $self->database;

    my $dsn = 'dbi:' . $$db{sgbd}
    . ':database=' . $$db{name}
    . ';host=' .  $$db{host}
    . ';port=' . $$db{port};

    ${$self->dbh} = DBI->connect($dsn, $$db{user}, $$db{pass}) 
    || die "Could not connect to database: $DBI::errstr"; 

    my ($primary_dns_server, @sec_dns_servers) = 
    $self->init_dns_servers($$self{primarydnsserver}{app}, @$self{secondarydnsserver});

    ${$self->dnsi} = $primary_dns_server;
    push @{$$self{dnsisec}}, @sec_dns_servers;

    ${$self->um} = db->new(dbh => ${$self->dbh});
}

# TODO it has to send the user if the auth is ok
sub auth {
    my ($self, $login, $passwd) = @_;
    ${$self->um}->auth($login, $passwd);
}

# TODO die if there is a problem
sub register_user {
    my ($self, $login, $passwd) = @_;
    ${$self->um}->register_user($login, $passwd);
}

# TODO
sub toggle_admin {
    my ($self, $login) = @_;
    #${$self->um}->toggle_admin($login);
}

sub set_admin {
    my ($self, $login, $val) = @_;
    ${$self->um}->set_admin($login, $val);
}

sub update_passwd {
    my ($self, $login, $new) = @_;
    my ($success, $user, $isadmin) = ${$self->um}->get_user($login);
    $user->passwd($new);
}

# TODO die if there is a problem
sub delete_user {
    my ($self, $login) = @_;
    my ($success, @domains) = $self->get_domains($login);

    if($success) {
        $self->delete_domain($login, $_) foreach(@domains);
        ${$self->um}->delete_user($login);
    }
}

### domains 

sub _get_zone_edit {
    my ($self, $domain) = @_; 

    return zone->new(
        zname => $domain
        , data => $self );
}

# TODO die if there is a problem
# return yes or no
sub add_domain {
    my ($self, $login, $domain) = @_; 
    my ($success, $user, $isadmin) = ${$self->um}->get_user($login);

    unless($success) {
        return 0;
    }

    unless ($user->add_domain($domain)) {
        return 0;
    }

    my $ze = $self->_get_zone_edit($domain);
    $ze->addzone();
}

# TODO die if there is a problem
sub delete_domain {
    my ($self, $login, $domain) = @_; 

    my ($success, $user, $isadmin) = ${$self->um}->get_user($login);

    return 0 unless $success;
    return 0 unless $user->delete_domain($domain);

    my $ze = $self->_get_zone_edit($domain);
    $ze->del();

    1;
}

sub update_domain_raw {
    my ($self, $zone, $domain) = @_; 

    my $ze = $self->_get_zone_edit($domain);
    $ze->update_raw($zone);
}

sub update_domain {
    my ($self, $zone, $domain) = @_; 
    my $ze = $self->_get_zone_edit($domain);
    $ze->update($zone);
}

sub get_domain {
    my ($self, $domain) = @_; 
    my $ze = $self->_get_zone_edit($domain);
    $ze->get();
}

sub get_domains {
    my ($self, $login) = @_; 
    ${$self->um}->get_domains($login);
}

sub get_all_domains {
    my ($self) = @_; 
    # % domain login
    ${$self->um}->get_all_domains;
}

sub get_all_users {
    my ($self) = @_; 
    # % login admin
    ${$self->um}->get_all_users;
}

sub new_tmp {
    my ($self, $domain) = @_; 
    my $ze = $self->_get_zone_edit($domain);
    $ze->new_tmp();
}

sub _is_same_record {
    my ($a, $b) = @_;
    (   $a->{name} eq $b->{name} && 
        $a->{host} eq $b->{host} &&
        $a->{priority} eq $b->{priority} &&
        $a->{ttl} ==  $b->{ttl} );
}

# returns the lists of domains of a certain type
sub _get_records {
    my ($zone, $entry) = @_;

    for( lc $entry->{type} ) {
        if      ($_ eq 'a')      { return $zone->a;     }
        elsif   ($_ eq 'aaaa')   { return $zone->aaaa;  }
        elsif   ($_ eq 'cname')  { return $zone->cname; }
        elsif   ($_ eq 'ns')     { return $zone->ns;    }
        elsif   ($_ eq 'mx')     { return $zone->mx;    }
        elsif   ($_ eq 'ptr')    { return $zone->ptr;   }
    }
    
    undef;
}

sub delete_entry {
    my ($self, $domain, $entryToDelete) = @_;

    my $zone = $self->get_domain($domain);
    my $dump = $zone->dump;

    my $records = _get_records $zone, $entryToDelete;

    if( defined $records ) {
        foreach my $i ( 0 .. scalar @{$records}-1 ) {
            if(_is_same_record($records->[$i], $entryToDelete)) {
                delete $records->[$i];
            }
        }

        $self->update_domain( $zone, $domain );
    }

}

sub modify_entry {
    my ($self, $domain, $entryToModify, $newEntry) = @_;

    my $zone = $self->get_domain($domain);
    my $dump = $zone->dump;

    my $records = _get_records $zone, $entryToModify;

    if( defined $records ) {

        foreach my $i ( 0 .. scalar @{$records}-1 ) {

            if(_is_same_record($records->[$i], $entryToModify)) {

                $records->[$i]->{name} = $newEntry->{newname};
                $records->[$i]->{host} = $newEntry->{newhost};
                $records->[$i]->{ttl}  = $newEntry->{newttl};
                $records->[$i]->{type}  = $newEntry->{newtype};

                if( defined $newEntry->{newpriority} ) {
                    $records->[$i]->{priority} = $newEntry->{newpriority};
                }
            }
        }
        $self->update_domain( $zone, $domain );
    }

}

1;
