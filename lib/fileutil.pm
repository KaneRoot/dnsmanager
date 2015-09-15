package fileutil;
use v5.14;

use URI;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/read_file write_file/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/read_file write_file/] ); 

sub read_file {
    my ($filename) = @_;

    if($filename =~ "://")
    {
        my $fileuri = URI->new($filename);
        $filename = $fileuri->path;
    } 

    open my $entry, '<:encoding(UTF-8)', $filename or 
    die "Impossible d'ouvrir '$filename' en lecture : $!";
    local $/ = undef;
    my $all = <$entry>;
    close $entry;

    return $all;
}

sub write_file {
    my ($filename, $data) = @_;

    if($filename =~ "://")
    {
        my $fileuri = URI->new($filename);
        $filename = $fileuri->path;
    } 

    open my $sortie, '>:encoding(UTF-8)', $filename or 
    die "Impossible d'ouvrir '$filename' en écriture : $!";
    print $sortie $data;
    close $sortie;
}

1;
