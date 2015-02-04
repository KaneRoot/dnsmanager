use Test::More;
use Modern::Perl;
use URI;
use lib 'lib';
use remotecmd ':all';

my $port = 22;
my $user = 'karchnu';
my $host = "karchnu.fr";
my $cmd = "ls /";
my $pattern = qr/etc/;

sub t_remotecmd {
    my ($user, $host, $port, $cmd, $pattern) = @_;

    my $ret = remotecmd $user, $host, $port, $cmd;

    $ret =~ $pattern;
}

ok ((t_remotecmd $user, $host, $port, $cmd, $pattern) , "remote cmd" );

done_testing;
