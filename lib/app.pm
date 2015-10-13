package app;
use v5.14;
use Moo;

use db;
use zone;
use configuration ':all';

has db => ( is => 'rw', builder => '_void');

has [qw/tld tmpdir database primarydnsserver secondarydnsserver/] 
=> qw/is ro required 1/;

sub _void { my $x = ''; \$x; }

sub BUILD {
    my ($self) = @_;
    $$self{db} = db->new(data => $self);

    my $tmpdir = get_tmpdir_from_uri($$self{tmpdir});
    -f $tmpdir || qx/mkdir -p $tmpdir/;

    my $db = $$self{database};
    unless(exists $$db{sgbd} && exists $$db{name}
        && exists $$db{host} && exists $$db{port}
        && exists $$db{user} && exists $$db{passwd})
    {
        die "Unable to connect to the database.\n"
        . "Check the existance of theses parameters in the config file :\n"
        . "\tsgbd name host port user passwd";
    }
}

# USER

sub auth {
    my ($self, $login, $passwd) = @_;
    $self->db->auth($login, $passwd)
}

sub update_passwd {
    my ($self, $login, $newpass) = @_;
    $self->db->update_passwd($login, $newpass)
}

sub register_user {
    my ($self, $login, $passwd) = @_;
    $self->db->register_user($login, $passwd)
}

sub toggle_admin {
    my ($self, $login) = @_;
    $self->db->toggle_admin($login)
}

sub delete_user {
    my ($self, $login) = @_;
    $self->db->delete_user($login)
}

sub get_all_users {
    my ($self) = @_; 
    $self->db->get_all_users
}

sub is_owning_domain {
    my ($self, $login, $domain) = @_; 
    $self->db->is_owning_domain($login, $domain)
}

# DOMAIN

sub _get_zone {
    my ($self, $domain) = @_; 

#    say "";
#    say "GET ZONE";
#    say "";
#    say "";
#    say "domain $domain";
#    say "tmpdir $$self{tmpdir}";
#    say "tld $$self{tld}";

    zone->new( domain => $domain
        , tmpdir => $$self{tmpdir}
        , tld => $$self{tld}
        , primarydnsserver => $$self{primarydnsserver}
        , secondarydnsserver => $$self{secondarydnsserver}
        , slavedzones => $self->get_all_domains()
    )
}

sub add_domain {
    my ($self, $login, $domain) = @_;
    $self->db->add_domain($login, $domain);
    $self->_get_zone($domain)->addzone()
}

sub delete_domain {
    my ($self, $domain) = @_; 
    $self->db->delete_domain($domain);
    $self->_get_zone($domain)->del()
}

sub modify_entry {
    my ($self, $domain, $entryToModify, $newEntry) = @_;
    my $zone = $self->_get_zone($domain)->modify_entry( 
        $entryToModify, $newEntry );
    $self->update_domain($zone, $domain)
}

sub delete_entry {
    my ($self, $domain, $entryToDelete) = @_;
    my $zone = $self->_get_zone($domain)->delete_entry( $entryToDelete );
    $self->update_domain($zone, $domain)
}

sub update_domain_raw {
    my ($self, $zone, $domain) = @_; 
    $self->_get_zone($domain)->update_raw($zone)
}

sub update_domain {
    my ($self, $zone, $domain) = @_; 
    $self->_get_zone($domain)->update($zone)
}

sub get_domain {
    my ($self, $domain) = @_; 
    $self->_get_zone($domain)->get()
}

sub get_domains {
    my ($self, $login) = @_; 
    $self->db->get_domains($login)
}

sub get_all_domains {
    my ($self) = @_; 
    $self->db->get_all_domains
}

sub disconnect {
    my ($self) = @_; 
    $self->db->disconnect
}

1;
