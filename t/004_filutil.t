use Test::More;
use Modern::Perl;
use URI;
use lib 'lib';
use fileutil ':all';

my $f1 = "lib/fileutil.pm";
my $p1 = "read_file";
my $f2 = "/tmp/test";
my $d2 = "DATA";

sub t_read_file {
    my ($f, $pattern) = @_;
    my $data = read_file $f;
    $data =~ /$pattern/;
}

sub t_write_file {
    my ($f, $data) = @_;
    write_file $f, $data;
    my $d = read_file $f;
    $d =~ /$data/;
}

ok ((t_read_file $f1, $p1) , "read_file avec $f1 / $p1" );
ok ((t_write_file $f2, $d2) , "write_file" );

done_testing;
