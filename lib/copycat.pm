package copycat;
use v5.14;

use File::Copy;
use URI;
use Net::OpenSSH;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/copycat/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/copycat/] ); 

sub _cp {
    my ($src, $dest) = @_;
    say "cp $src $dest";
    File::Copy::copy($src, $dest) or die "Copy failed: $! ($src -> $dest)";
}

sub _scp_put {
    my ($co, $src, $dest) = @_;

    my $ssh = Net::OpenSSH->new($co);
    say "scp put $src $dest";
    $ssh->scp_put($src, $dest) or die "scp failed: " . $ssh->error;
    undef $ssh;
}

sub _scp_get {
    my ($co, $src, $dest) = @_;

    my $ssh = Net::OpenSSH->new($co);
    say "scp get $src $dest";
    $ssh->scp_get($src, $dest) or die "scp failed: " . $ssh->error;
    undef $ssh;
}

# SUPPORT
#   local to local
#   distant to local
#   local to distant

sub copycat {
    my ($source, $destination) = @_;

    # TODO if it's not URI

    my $src = URI->new($source);
    my $dest = URI->new($destination);

    if($src->scheme eq 'file' && $dest->scheme eq 'file') {
        _cp $src->path, $dest->path;
    }
    elsif($src->scheme eq 'ssh' && $dest->scheme eq 'file') {

        my $co = $src->userinfo . '@' . $src->host . ':' . $src->port;
        _scp_get $co, $src->path, $dest->path;

    }
    elsif($src->scheme eq 'file' && $dest->scheme eq 'ssh') {

        my $co = $dest->userinfo . '@' . $dest->host . ':' . $dest->port;
        _scp_put $co, $src->path, $dest->path;

    }
    else {

        die "CopyCat : wrong arguments";
    }

}

1;
