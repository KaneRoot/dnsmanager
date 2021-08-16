#!/usr/bin/perl -w
use strict;
use warnings;
use v5.14;

use MIME::Base64 qw(encode_base64);

#################
# CONFIGURATION #
#################

# the website sending your current IP address
our $checkip = "http://t.karchnu.fr/ip.php";

# Domain name of the service provider (like netlib.re)
our $nddservice = "netlib.re";

# Your domain
our $domain = ""; # Example: "home.netlib.re"

# Login and password to connect to the website
our $login = "";
our $pass = "";

# The name of the actual machine in your domain to be updated.
#   Updated record: $machine.$domain
#   Following the examples, updated record will be: www.home.netlib.re
# You can put "@" to change your $type record on $domain directly.
our $machine = "";   # example: www
our $type = 'A';  # could also be AAAA (IPv6)

# Should we force a secure connection to netlib.re?
# In case you don't have an updated list of certificates
# from certification authorities, you _could_ change this to "0".
# This would imply: any man-in-the-middle attack with a wrong certificate
# could see a hash of your password. Please, consider updating your OS before
# trying this option.
our $is_secure = 1;

# Saving our previous IP to update only on change
# (you can just ignore those lines)
our $filename = 'saved_ip.txt';
our $saved_ip = "0.0.0.0";

# FOR DEBUG PURPOSES
# In case you want always to try to update the IP address, even in case it
# didn't change from the last time you run the script.
our $ignore_saved_address = 0;

########################
# END OF CONFIGURATION #
########################

# Test the configuration.
die "You did not enter your domain. (ex: home.netlib.re)" if $domain eq "";
die "You did not enter your machine name. (ex: www)"      if $machine eq "";

die "You did not enter your login."    if $login eq "";
die "You did not enter your password." if $pass eq "";


# Test the environment.
our $wget = `which wget`; chomp $wget;
die "There is no wget on this computer." unless $wget;

our $ip_version_opt = ($type =~ /AAAA/) ? '-6' : '-4';
sub get_ip {
	my $cmd = "wget $ip_version_opt -nv -O - $checkip";
	say "get your current IP: $cmd";
	for (split "\n", `$cmd 2>/dev/null`) {
		/^[0-9.]+$/ || /^[0-9a-f:]+$/ and return $_
	}
	undef
}

# Saving IP to file
sub save_ip {
	my ($ip) = @_;
	open(my $fhw, '>', $filename) or die "Could not open file '$filename' $!";
	print $fhw "$ip";
	close $fhw;
}

# Loading IP from file
sub load_ip {
	if (open(my $fho, '<:encoding(UTF-8)', $filename)) {
		$saved_ip = <$fho>;
	}
	else {
		say "no $filename -> default IP is $saved_ip";
		$saved_ip;
	};
}

sub update {
	my $ip = get_ip;
	die "Can't get your IP address !" unless $ip;

	load_ip;
	if ($saved_ip ne $ip || $ignore_saved_address) {
		say "DEBUG: ignoring saved address" if $ignore_saved_address;
		say "UPDATE :: domain $machine.$domain";
		say "          old ip ($type): $saved_ip";
		say "          new ip ($type): $ip";
		my $passb64 = encode_base64($pass);
		chomp $passb64;

		my $opts = "";
		$opts = "--no-check-certificate" unless $is_secure;
		my $cmd = "$wget $opts -O - ";
		$cmd .= "https://$nddservice/domain/cliup/";
		$cmd .= "$login/$passb64/$domain/$machine/$type/$ip";
		say "CMD :: $cmd";
		`$cmd`;
		save_ip $ip;
	}
}

update;
