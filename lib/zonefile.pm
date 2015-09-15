package zonefile;
use v5.14;
use Moo;
use DNS::ZoneParse;

has zone => qw/is rw/ ;
has [ qw/domain zonefile/ ] => qw/ is ro required 1/;

sub BUILD {
    my ($self) = @_;

    my $filename = $$self{zonefile};
    if($filename =~ "://")
    {
        my $fileuri = URI->new($filename);
        $filename = $fileuri->path;
    } 

    $$self{zone} = DNS::ZoneParse->new($filename, $$self{domain});
}

sub new_serial {
    my $self = shift;
    $self->zone->new_serial();
}

sub origin {
    my $self = shift;
    $self->zone->origin();
}

sub output {
    my $self = shift;
    $self->zone->output();
}

sub dump {
    my $self = shift;
    $self->zone->dump();
}

# better encapsulation
sub a       { my $self = shift; $self->zone->a }
sub aaaa    { my $self = shift; $self->zone->aaaa }
sub cname   { my $self = shift; $self->zone->cname }
sub ns      { my $self = shift; $self->zone->ns }
sub mx      { my $self = shift; $self->zone->mx }
sub ptr     { my $self = shift; $self->zone->ptr }
sub txt     { my $self = shift; $self->zone->txt } # TODO TEST THIS

1;
