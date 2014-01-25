#!/usr/bin/perl -w
use strict;
use warnings;
use v5.14;
use autodie;
use Modern::Perl;
use Net::SCP;

my $hostname = "pizza";
my $username = "karchnu";

my $scp = Net::SCP->new( { host => $hostname, user => $username } );
$scp->get("/etc/resolv.conf", "kikoo") or die $scp->{errstr};
$scp->put("kikoo", "lolwat") or die $scp->{errstr};

# $scp->put("filename") or die $scp->{errstr};
