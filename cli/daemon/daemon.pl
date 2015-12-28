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

# Your entry to change
our $name = 'www';  # here, the entry is www.test.netlib.re
our $type = 'A';    # could be AAAA

# The CA certificate, to authenticate the website (should be provided)
# Check your service provider for updates
our $cacert = "ca.cert";

sub get_ip {
    my @tmp_ip = split "\n", `wget -nv -O - $checkip`;
    my $ip;

    for(@tmp_ip) {
        if($_ =~ /^[0-9.]+$/ || $_ =~ /^[0-9a-f:]+$/) {
            $ip = $_;
        }
    }

    $ip;
}

sub update {
    my $ip = get_ip;

    say "UPDATE :: domain $name.$domain => IP $ip, type $type";
    my $passb64 = encode_base64($pass);
    chomp $passb64;

    my $cmd = "wget -O - ";
    $cmd .=
    "https://$nddservice/domain/cliup/$login/$passb64/$domain/$name/$type/$ip ";
    $cmd .= "--ca-certificate=$cacert";
    say "CMD :: $cmd";
    `$cmd`;
}

update;
