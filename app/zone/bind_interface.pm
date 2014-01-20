use Modern::Perl;
use strict;
use warnings;
use Data::Dump "dump";
use v5.14;
use re '/x'; # very important

use lib '../../';
package app::zone::bind_interface;
use Moose;
#use Sudo;
# to know where the zone files are stored / to execute a sudo command
# has [ qw/zone_path sudo_pass/ ] => qw/is ro required 1/;
has [ qw/zone_path/ ] => qw/is ro required 1/;

sub activate_zone {
	my ($self, $domain, $admin_file) = @_;
	open(my $file, ">>", $admin_file) 
		or die("error : impossible to open admin file");
}

=pod
zone "karchnu.fr" {
	type master;
	file "/srv/named/karchnu.fr";
	forwarders { 8.8.8.8; };
	allow-update { key DDNS\_UPDATER ; };
	allow-transfer { any; };
	allow-query { any; };
};

zone "0.0.1.0.0.0.0.0.0.0.0.0.0.0.f.c.ip6.arpa" {
	type master;
	file "/srv/named/karchnu.fr.rv";
	allow-update { key DDNS\_UPDATER ; };
	allow-transfer { any; };
	allow-query { any; };
};

=cut

# TODO
sub update {
	my ($self) = @_;

	#open(my $process, "service bind9 reload|");
	#say while(<$process>);
	#close($process);
	#my $su = Sudo->new(
	#	{
	#		sudo         => '/usr/bin/sudo',
	#		username     => 'root',
	#		password     => $self->sudo_pass,
	#		program      => '/usr/bin/service',
	#		program_args => 'bind9 reload', 
	#	}
	#);

#	my $result = $su->sudo_run();
#	if (exists($result->{error})) {
#		return 0;
#	}
#
#	printf "STDOUT: %s\n",$result->{stdout};
#	printf "STDERR: %s\n",$result->{stderr};
#	printf "return: %s\n",$result->{rc};
#	return 1;
}

sub parse {
	my ($self, $file) = @_;
	my $fh;
	open($fh, "<", $self->zone_path . $file) or return;
	my %zone = $self->parse_zone_file($fh) ;
	close($fh);
	return %zone;
}

sub comment {
	my $self = shift;
	m{ ^ \s* ; \s* ( .+ ) }
		and return { comment => $1 };
}

sub SOA {
	my $self = shift;
	m{ ^\s* (?<addr> \S+)
		\s+ (?<domain> \S+)	
		\s+ SOA
		\s+(?<primary> \S+)
		\s+(?<admin> \S+)
		\s+ \(
		\s*(?<serial> \d+)
		\s+(?<refresh> \d+)
		\s+(?<retry> \d+)
		\s+(?<expire> \d+)
		\s+(?<serial> \d+)
		\s*
		\)
	} and return {%+}
}

sub TTL {
	my $self = shift;
	m{ ^ \s* \$TTL \s+ (\d+) \s* $ }
		and return { TTL => $1 }
}

# rocoto IN A 192.168.0.180
# karchnu.fr. IN MX 5 rocoto

# exemple:
# karchnu.fr. IN MX 5 rocoto
sub entry {
	my $self = shift;
	m{ ^
		\s* (?<host> \S+)
		\s+ (?<domain> \S+)
		(?:
		\s+ (?<type> MX)
		\s+ (?<check> \S+)
		\s+ (?<addr> \S+)
		|
		\s+ (?<type> A | AAAA | CNAME)
		\s+ (?<addr> \S+)
		|
		\s+ TXT
		\s+ "(?<text> \\. | [^"]+)"
		)
	} and return {%+};
}

sub empty_line {
	my $self = shift;
	/^ \s* $/x 
}
# element must be used without args
# () is very important

sub alias {
	my $self = shift;
	m{^
		\s* \@
		\s+ (?<domain> IN )
		\s+ (?<type> A | AAAA | NS | MX | SOA )
		\s+ (?<alias> .* )
	} and return {%+}
}

sub element () {
	my $self = shift;
	return if empty_line || comment;
	SOA || TTL
	|| alias
	|| entry
	|| die "unparsable $_";
}

sub parse_zone_file {
	my ($self, $fh) = @_;
	map element, <$fh>;
}


1;
