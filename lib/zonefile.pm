package zonefile;
use v5.14;
use Net::DNS::RR;
use Net::DNS::ZoneFile;
use Moo;
use utf8;
use URI;
use Data::Dumper;

has zone => qw/is rw/ ;
has [ qw/zonefile/ ] => qw/ is rw required 1/;

# Simple functions to manipulate lists of Net::DNS::RR

sub rr_array_del {
    my ($zones, $rr) = @_;
    my $todel = $rr->plain;
    utf8::decode($todel);

    [grep { my $v = $_->plain; utf8::decode($v); $v ne $rr->plain } @$zones]
}

sub rr_array_add {
    my ($zone, $rr) = @_;
    my @already_present = grep { $_->plain eq $rr->plain } @$zone;
    push @$zone, $rr unless @already_present;
    $zone
}

sub rr_array_new_serial {
    my $zones = shift;

    for(@{$zones}) {
        if($_->type =~ /SOA/) {
            my $serial = $_->serial;
            $_->serial($serial + 1);
        }
    }

    $zones
}

sub rr_array_serial {
    my $zones = shift;

    for(@{$zones}) {
        if($_->type =~ /SOA/) {
            return $_->serial;
        }
    }

    die "Impossible to get the zone serial."
}

sub rr_array_dump {
    my $zone = shift;
    my $dump = '';

    #  write the SOA record first
    for(@{$zone}) {
        if($_->type =~ /SOA/i) {
            $dump .= $_->string . "\n";
        }
    }

    for(@{$zone}) {
        if($_->type !~ /SOA/i) {
            $dump .= $_->string . "\n";
        }
    }

    utf8::decode($dump);

    $dump
}


sub BUILD {
    my ($self) = @_;

    my $path = $$self{zonefile};

    # zonefile is the filename
    if($$self{zonefile} =~ "://") {
        my $fileuri = URI->new($$self{zonefile});
        $path = $fileuri->path;
    }

    my $zonefile = Net::DNS::ZoneFile->new( $path );
    my @zone = $zonefile->read;
    $$self{zone} = [ @zone ];
}

sub new_serial {
    my $self = shift;
    $$self{zone} = rr_array_new_serial $$self{zone}
}

sub dump {
    my $self = shift;
    rr_array_dump $$self{zone}
}

sub serial {
    my ($self, $rr) = @_;
    rr_array_serial $$self{zone}
}

# remove a raw line that represents the RR
sub rr_del_raw {
    my ($self, $rrline) = @_;
    utf8::decode($rrline);
    say "to delete raw : $rrline";
    my $rr = Net::DNS::RR->new($rrline);
    say "to delete reformed : " . $rr->plain;
    $self->rr_del($rr)
}

sub rr_del {
    my ($self, $rr) = @_;
    $$self{zone} = rr_array_del $$self{zone}, $rr
}

# add a raw line that represents the RR
sub rr_add_raw {
    my ($self, $rrline) = @_;
    utf8::decode($rrline);
    say "to add raw : $rrline";
    my $rr = Net::DNS::RR->new($rrline);
    say "to add reformed : " . $rr->plain;
    $self->rr_add($rr)
}

sub rr_add {
    my ($self, $rr) = @_;
    $$self{zone} = rr_array_add $$self{zone}, $rr
}

sub rr_mod {
    my ($self, $rrline_old, $rrline_new) = @_;

    $self->rr_del_raw($rrline_old);
    $self->rr_add_raw($rrline_new);
}

sub rr_array_to_array {
    my ($self) = shift;
    my $rr_list;

    for(@{$$self{zone}}) {

        my @list = split / /, $_->plain;

        my $rr;
        $$rr{name} = $list[0];
        $$rr{ttl} = $list[1];
        $$rr{class} = $list[2];
        $$rr{type} = $list[3];

        utf8::decode($$rr{name});
        utf8::decode($$rr{ttl});
        utf8::decode($$rr{class});
        utf8::decode($$rr{type});

        if($list[3] =~ /SOA/) {
            $$rr{ns} = $list[4];
            $$rr{postmaster} = $list[5];
            $$rr{serial} = $list[6];
            $$rr{refresh} = $list[7];
            $$rr{retry} = $list[8];
            $$rr{expire} = $list[9];
            $$rr{minimum} = $list[10];

            utf8::decode($$rr{ns});
            utf8::decode($$rr{postmaster});
            utf8::decode($$rr{serial});
            utf8::decode($$rr{refresh});
            utf8::decode($$rr{retry});
            utf8::decode($$rr{expire});
            utf8::decode($$rr{minimum});
        }
        elsif($list[3] =~ /^(A(AAA)?|CNAME|NS)$/) {
            $$rr{rdata} = $list[4];
            utf8::decode($$rr{rdata});
        }
        elsif($list[3] =~ /^MX$/) {
            $$rr{priority} = $list[4];
            $$rr{rdata} = $list[5];

            utf8::decode($$rr{priority});
            utf8::decode($$rr{rdata});
        }
        elsif($list[3] =~ /^TXT$/) {
            $$rr{rdata} = $_->rdstring;
            utf8::decode($$rr{rdata});
        }
        elsif($list[3] =~ /^SRV$/) {
            # _service._proto.name.     TTL   class SRV priority weight port target.
            # _sip._tcp.example.com.    86400 IN    SRV 10       60     5060 bigbox.example.com.
            $$rr{priority} = $list[4];
            $$rr{weight} = $list[5];
            $$rr{port} = $list[6];
            $$rr{rdata} = $list[7];

            utf8::decode($$rr{priority});
            utf8::decode($$rr{weight});
            utf8::decode($$rr{port});
            utf8::decode($$rr{rdata});
        }
        else {
            $$rr{rdata} = $_->rdstring;
            utf8::decode($$rr{rdata});
            say "This RR is not available : " . $_->plain;
        }

        push @$rr_list, $rr;

    }

    $rr_list
}

1;
