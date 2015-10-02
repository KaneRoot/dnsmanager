package remotecmd;
use v5.14;

use Net::OpenSSH;
use Net::SSH q<sshopen2>;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/remotecmd/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/remotecmd/] );

sub remotecmd {
    my ($user, $host, $port, $cmd) = @_;

    #sshopen2("-p '$port' $user\@$host", *READER, *WRITER, "$cmd") 
    #|| die "ssh: $!";

    #system("ssh -p '$port' '$user". '@'. "$host' '$cmd'");

    #my $ret = '';
    #$ret .= $_ while(<READER>);

    #close(READER);
    #close(WRITER);

    my $str = "ssh -p $port $user". '@' . "$host '$cmd'";
    say "";
    say "CMD : $str";
    say "";
    qx/$str/;
}

1;
