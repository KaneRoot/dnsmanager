#!/usr/bin/env perl

package app;
use v5.14;
use DBI;
use Moo;

use lib '../';
use app::zone::interface;
use app::zone::edit;
use app::zone::rndc_interface;
use app::bdd::management;
use app::bdd::admin;
use app::bdd::lambda;

has dbh => ( is => 'rw', builder => '_void');
has dnsi => ( is => 'rw', builder => '_void');
has dnsisec => ( is => 'rw', builder => '_void');
has um => ( is => 'rw', builder => '_void');
has [ qw/
    dns_servers
    zdir dbname dbhost dbport dbuser dbpass sgbd dnsapp dnsappsec
    sshhost sshhostsec sshuser sshusersec sshport sshportsec
    nsmasterv4 nsmasterv6 nsslavev4 nsslavev6
    dnsslavekey/ ] => qw/is ro required 1/;
sub _void { my $x = ''; \$x; }

### users

sub get_interface {
    my ($self, $type, $data) = @_;
    given($type) {
        when /rndc/ { simplebind9->new(data => $data) }
        when /knot/ { simpleknot->new(data => $data) }
        when /nsdc/ { simplensd->new(data => $data) }
        default { undef }
    }
}

sub init {
    my ($self) = @_;

    my $success;

    my $dsn = 'dbi:' . $self->sgbd
    . ':database=' . $self->dbname
    . ';host=' .  $self->dbhost
    . ';port=' . $self->dbport;

    ${$self->dbh} = DBI->connect($dsn
        , $self->dbuser
        , $self->dbpass) 
    || die "Could not connect to database: $DBI::errstr"; 

    ($success, ${$self->dnsi}) = get_interface($self->dnsapp, $self);

    die("zone interface") unless $success;

    ($success, ${$self->dnsisec}) = get_interface($self->dnsappsec, $self);

    die("zone interface (secondary ns)") unless $success;

    ${$self->um} = app::bdd::management->new(dbh => ${$self->dbh});
}

sub auth {
    my ($self, $login, $passwd) = @_;
    ${$self->um}->auth($login, $passwd);
}

sub register_user {
    my ($self, $login, $passwd) = @_;
    ${$self->um}->register_user($login, $passwd);
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

    return app::zone::edit->new(
        zname => $domain
        , data => $self );
}

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

    given( lc $entry->{type} ) {
        when ('a')      { return $zone->a;     }
        when ('aaaa')   { return $zone->aaaa;  }
        when ('cname')  { return $zone->cname; }
        when ('ns')     { return $zone->ns;    }
        when ('mx')     { return $zone->mx;    }
        when ('ptr')    { return $zone->ptr;   }
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
