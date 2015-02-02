package app::zonefile;
use v5.14;
use Moo;
use DNS::ZoneParse;

has zone => qw/is rw/ ;
has [ qw/domain zonefile/ ] => qw/ is ro required 1/;

sub BUILDARGS {
    my ($class, @args) = @_;

    $$self{zone} = DNS::ZoneParse->new($$self{zonefile}, $$self{domain});

    return { @args };
}

sub new_serial {
    my $self = shift;
    $self->zone->new_serial();
}

sub output {
    my $self = shift;
    $self->zone->output();
}

1;
