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
    my @z = grep { $_->plain ne $rr->plain } @$zones;
    [ @z ]
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
    my $rr = Net::DNS::RR->new($rrline);
    $self->rr_del($rr)
}

sub rr_del {
    my ($self, $rr) = @_;
    $$self{zone} = rr_array_del $$self{zone}, $rr
}

# add a raw line that represents the RR
sub rr_add_raw {
    my ($self, $rrline) = @_;
    my $rr = Net::DNS::RR->new($rrline);
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

        if($list[3] =~ /SOA/) {
            $$rr{ns} = $list[4];
            $$rr{postmaster} = $list[5];
            $$rr{serial} = $list[6];
            $$rr{refresh} = $list[7];
            $$rr{retry} = $list[8];
            $$rr{expire} = $list[9];
            $$rr{minimum} = $list[10];
        }
        elsif($list[3] =~ /^(A(AAA)?|CNAME|NS)$/) {
            $$rr{rdata} = $list[4];
        }
        elsif($list[3] =~ /^MX$/) {
            $$rr{priority} = $list[4];
            $$rr{rdata} = $list[5];
        }
        elsif($list[3] =~ /^TXT$/) {
            $$rr{rdata} = $_->rdstring;
        }
        else {
            die "This RR is not available : " . $_->plain;
        }

        push @$rr_list, $rr;

    }

    $rr_list
}

1;
