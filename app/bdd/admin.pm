package app::bdd::admin;
use Moose;
extends 'app::bdd::lambda';

# ($success) activate_zone($domain)
sub activate_zone {
    my ($self, $domain) = @_; 
}

# ($success) delete_zone($file_path)
sub delete_zone {
    my ($self, $domain) = @_;
}

1;
