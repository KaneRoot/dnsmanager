package remotecmd;
use v5.14;

use URI;
use Net::OpenSSH;
use Net::SSH q<sshopen2>;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/remotecmd/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/remotecmd/] );

sub remotecmd {
    my ($user, $host, $port, $cmd) = @_;

    Net::SSH::sshopen2("$user\@$host:$port", *READER, *WRITER, "$cmd") 
    || die "ssh: $!";

    #system("ssh -p '$port' '$user". '@'. "$host' '$cmd'");

    close(READER);
    close(WRITER);
}

1;
