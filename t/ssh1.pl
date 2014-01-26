#!/usr/bin/perl -w
use strict;
use warnings;
use v5.14;
use autodie;
use Modern::Perl;
use Data::Dump qw( dump );
use DNS::ZoneParse;
use Net::SSH q<sshopen2>;

my $host = "pizza";
my $user = "karchnu";
my $cmd = "ls /";

sshopen2("$user\@$host", *READER, *WRITER, "$cmd") || die "ssh: $!";

while (<READER>) {
    chomp();
    print "$_\n";
}

close(READER);
close(WRITER);

