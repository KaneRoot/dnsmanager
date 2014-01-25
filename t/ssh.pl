#!/usr/bin/perl -w
use strict;
use warnings;
use v5.14;
use autodie;
use Modern::Perl;
use Data::Dump qw( dump );
use DNS::ZoneParse;

my $hostname = "pizza";
my $username = "karchnu";

use Net::SSH2;

my $ssh = Net::SSH2->new();

$ssh->connect($hostname);
$ssh->auth( username => $username);

my $chan = $ssh->channel();
$chan->exec('ls /');

my $buf = '';
say $buf while $chan->read($buf, 1500);

$ssh->disconnect();
