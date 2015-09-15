use Test::More;
use Modern::Perl;
use URI;
use lib 'lib';
use fileutil ':all';
use copycat ':all';

my $l1 = "file:///etc/hosts";
my $l2 = "file:///tmp/truc";

sub t_local_local {
    my ($f1, $f2) = @_;
    copycat $f1, $f2;

    my $file = URI->new($f2);
    my $d = read_file $file->path;
    $d =~ /localhost/;
}

ok ((t_local_local $l1, $l2) , "copycat local local avec $l1 / $l2" );

done_testing;
