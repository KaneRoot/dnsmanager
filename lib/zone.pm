package zone;
use v5.14;
use Moo;

use Modern::Perl;

# TODO all this file is to redesign

use getiface ':all';
use copycat ':all';
use fileutil ':all';
use configuration ':all';
#use Data::Dump qw( dump );

use zonefile;

# primary dns interface 
has dnsi => ( is => 'rw', builder => '_void_arr');

# dns interface for secondary name servers
has dnsisec => ( is => 'rw', builder => '_void');

has [ qw/tld tmpdir domain primarydnsserver secondarydnsserver slavedzones/ ]
=> qw/is ro required 1/;

sub _void { my $x = ''; \$x; }
sub _void_arr { [] }

sub get_ztmp_file_  {my $s = shift; "$$s{tmpdir}/$$s{domain}" }
sub get_ztpl_dir_  {my $s = shift; "$$s{dnsi}{mycfg}{zonedir}" }
sub get_ztpl_file_ {
    my $s = shift;

    # for each TLD
    for(@{$$s{tld}}) {
        # if our domain is part of this TLD, get the right template
        if($$s{domain} =~ $_) {
            return $s->get_ztpl_dir_() . '/' . $_ . '.tpl';
        }
    }

    die "There is no template for $$s{domain}.";
}

sub get_dnsserver_interface {
    my ($self, $dnsserver) = @_;
    my $cfg = {
        mycfg => $dnsserver
        , primarydnsserver => $$self{primarydnsserver}
        , secondarydnsserver => $$self{secondarydnsserver}
        , tmpdir => $$self{tmpdir}
    };

    getiface $$dnsserver{app}, $cfg
}

sub get_dns_server_interfaces {
    my $self = shift;
    my $primary = $$self{primarydnsserver};
    my $s = $$self{secondarydnsserver};

    my $prim = $self->get_dnsserver_interface($primary);

    my @sec;
    for(@{$s}) {
        push @sec, $self->get_dnsserver_interface($_);
    }

    ($prim, [ @sec ])
}

sub BUILD {
    my $self = shift;
    ($$self{dnsi}, $$self{dnsisec}) = $self->get_dns_server_interfaces()
}

# change the origin in a zone file template
sub mod_orig_template {
    my ($file, $domain) = @_;
    say "s/CHANGEMEORIGIN/$domain/ on $file";
    qx[sed -i "s/CHANGEMEORIGIN/$domain/" $file];
}

sub get_remote_zf_ { 
    my $self = shift; 
    "$$self{dnsi}{mycfg}{zonedir}/$$self{domain}"
}

sub reload_secondary_dns_servers {
    my $self = shift;
    $_->reload_sec($$self{slavedzones}) for(@{$$self{dnsisec}})
}

sub get_zonefile {
    my $self = shift;
    my $file = $self->get_remote_zf_();
    my $dest = $self->get_ztmp_file_();

    my $path = $dest;

    # dest is the filename
    if($dest =~ "://") {
        my $fileuri = URI->new($dest);
        $path = $fileuri->path;
    }

    if( -f $path ) {
        say "FILE $path already exists : do not copy from ns server";
    }
    else {
        copycat ($file, $dest);
    }

    zonefile->new(domain => $$self{domain}, zonefile => $dest);
}

=pod
    copie du template pour créer une nouvelle zone
    update du serial
    ajout de la zone via dnsapp (rndc, knot…)
    retourne la zone + le nom de la zone
=cut

sub addzone {
    my ($self) = @_;

    my $tpl = $self->get_ztpl_file_();
    my $tmpfile = $self->get_ztmp_file_();

    copycat ($tpl, $tmpfile); # get the template

    # get the file path
    my $f = URI->new($tmpfile);

    # sed CHANGEMEORIGIN by the real origin
    mod_orig_template ($f->path, $$self{domain});

    my $zonefile = zonefile->new(zonefile => $f->path
        , domain => $$self{domain});
    $zonefile->new_serial(); # update the serial number

    # write the new zone tmpfile to disk 
    write_file $f->path, $zonefile->dump();

    my $file = $self->get_remote_zf_();
    copycat ($tmpfile, $file); # put the final zone on the server
    unlink($f->path); # del the temporary file

    # add new zone on the primary ns
    $self->dnsi->primary_addzone($$self{domain});

    # add new zone on secondary ns
    $self->reload_secondary_dns_servers()
}

=pod
    màj du serial
    push reload de la conf
=cut

sub update {
    my ($self, $zonefile) = @_;

    # update the serial number
    $zonefile->new_serial();

    my $tmpfile = $self->get_ztmp_file_();

    # write the new zone tmpfile to disk 
    write_file $tmpfile, $zonefile->dump();

    my $file = $self->get_remote_zf_();
    copycat ($tmpfile, $file); # put the final zone on the server
    unlink($tmpfile); # del the temporary file

    $self->dnsi->reload($$self{domain});
}

=pod
    udpate via the raw content of the zonefile
=cut

sub update_raw {
    my ($self, $zonetext) = @_;

    my $zonefile;
    my $file = $self->get_ztmp_file_();

    # write the updated zone file to disk
    write_file $file, $zonetext;

    eval { $zonefile = zonefile->new(zonefile => $file); };

    if( $@ ) {
        unlink($file);
        die 'zone update_raw, zonefile->new error. ' . $@;
    }

    unlink($file);

    $zonefile
}

sub del {
    my ($self) = @_;
    $self->dnsi->delzone($$self{domain});
    $self->dnsi->reconfig();
    $self->reload_secondary_dns_servers()
}

1;
