#!/usr/bin/perl -w
use strict;
use warnings;
use v5.14;

our $ndd = "netlib.re";
our $domain = "montest.netlib.re";
our $name = "www";
our $ttl = "3600";
our $login = "test";
our $pass = "test";

sub get_ip {
    my @tmp_ip = split "\n", `wget -nv -O - http://t.karchnu.fr/ip.php`;
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
    my $type;

    if($ip =~ /:/) {
        $type = "AAAA";
    }
    else {
        $type = "A";
    }
    
    my $todig;
    if($name =~ '@') {
        $todig = $domain;
    }
    else {
        $todig = "$name.$domain";
    }

    my $oldhost = `dig +short $todig`;
    chomp $oldhost;

    say "domain $domain";
    say "name $name";
    say "type $type";
    say "oldhost $oldhost";
    say "ttl $ttl";
    say "ip $ip";

    #say "wget -O - https://$ndd/domain/cli/$login/$pass/$domain/$name/$type/$oldhost/$ttl/$ip --ca-certificate=ca.cert";
    say `wget -O - https://$ndd/domain/cli/$login/$pass/$domain/$name/$type/$oldhost/$ttl/$ip --ca-certificate=ca.cert`;
}

update;
