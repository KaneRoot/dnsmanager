#!/usr/bin/perl -w
use strict;
use warnings;
use v5.14;

use MIME::Base64 qw(encode_base64);

# the website sending your current IP address
our $checkip = "http://t.karchnu.fr/ip.php";

# Domain name of the service provider (like netlib.re)
our $nddservice = "netlib.re";

# Your domain
our $domain = "test.netlib.re";

# Login and password to connect to the website
our $login = "idtest";
our $pass = "mdptest";

# Saving our previous IP to update only on change
our $filename = 'saved_ip.txt';
our $saved_ip = "0.0.0.0";

# Your entry to change
#
# here, the entry is www.test.netlib.re
# put "@" in $name to change your $type record on $domain directly
our $name = 'www';
our $type = 'A';    # could be AAAA

our $wget = `which wget`; chomp $wget;
die "There is no wget on this computer." unless $wget;

sub get_ip {
    my $typeip = ($type =~ /AAAA/) ? '-6' : '-4';
    my $cmd = "wget $typeip -nv -O - $checkip";
    say "get IP : $cmd";
    for (split "\n", `$cmd`) {
        /^[0-9.]+$/ || /^[0-9a-f:]+$/ and return $_
    }
    undef
}

# Saving IP to file
sub save_ip {
    open(my $fhw, '>', $filename) or die "Could not open file '$filename' $!";
    $saved_ip = get_ip;
    print $fhw "$saved_ip";
    close $fhw;
}

# Loading IP from file
sub load_ip {
    open(my $fho, '<:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";
    $saved_ip = <$fho>;
}

sub update {
    my $ip = get_ip;
    die "Can't get your IP address !" unless $ip;
    
    load_ip;
    if ($saved_ip ne $ip) {

    say "UPDATE :: domain $name.$domain => IP $ip, type $type";
    my $passb64 = encode_base64($pass);
    chomp $passb64;

    my $cmd = "$wget -O - ";
    $cmd .=
    "https://$nddservice/domain/cliup/$login/$passb64/$domain/$name/$type/$ip";
    say "CMD :: $cmd";
    `$cmd`;
    save_ip;
    }
}

update;
