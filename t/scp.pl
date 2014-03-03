#!/usr/bin/perl -w
use strict;
use warnings;
use v5.14;
use autodie;
use Modern::Perl;
use Net::OpenSSH;

my $hostname = "ns0.arn-fai.net";
my $username = "dnsmanager";

my $co = "$username\@$hostname:2222";

say $co;

my $ssh = Net::OpenSSH->new($co);
$ssh->scp_put("tpl.zone", "/home/$username/") or die "scp failed: " . $ssh->error;

#use Net::SCP; # ne fonctionne pas avec des ports :/
#my $scp = Net::SCP->new( { host => $hostname, user => $username, port => 2222} );
#$scp->put("tpl.zone", "lolwat") or die $scp->{errstr};
# $scp->put("filename") or die $scp->{errstr};
