package rt::domainfake;

use v5.14;
use configuration ':all';
use encryption ':all';
use util ':all';
use app;
use utf8;
use Dancer ':syntax';
use Data::Dump qw( dump );
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use MIME::Base64 qw(encode_base64 decode_base64);

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
rt_dom_cli_mod_entry_fake
rt_dom_cli_autoupdate_fake
rt_dom_mod_entry_fake
rt_dom_del_entry_fake
rt_dom_del_fake
rt_dom_add_fake
rt_dom_details_fake
rt_dom_add_entry_fake
rt_dom_updateraw_fake
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
rt_dom_cli_mod_entry_fake
rt_dom_cli_autoupdate_fake
rt_dom_mod_entry_fake
rt_dom_del_entry_fake
rt_dom_del_fake
rt_dom_add_fake
rt_dom_details_fake
rt_dom_add_entry_fake
rt_dom_updateraw_fake
        /] ); 

sub rt_dom_cli_autoupdate_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $res
}

sub rt_dom_cli_mod_entry_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $res
}

sub rt_dom_mod_entry_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = '/domain/details/toto.netlib.re';
    $res
}

sub rt_dom_del_entry_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = '/domain/details/toto.netlib.re';
    $res
}

sub rt_dom_del_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = $$request{referer};
    $res
}

sub rt_dom_add_fake {
    my ($session, $param) = @_;
    my $res;
    $$res{route} = '/user/home';
    $res
}

sub rt_dom_details_fake {
    my ($session, $param, $request) = @_;
    my $res;

    $$res{template} = 'details';
    $$res{params} = {
        login           => "toto"
        , admin         => 1
        , domain        => "toto.netlib.re."
        , domain_zone   => "
example.com.  IN  SOA   ns.example.com. username.example.com. ( 2007120710 1d 2h 4w 1h )
example.com.  3600 IN  NS    ns
example.com.  3600 IN  NS    ns.somewhere.example.
example.com.  3600 IN  MX    10 mail.example.com.
@             3600 IN  MX    20 mail2.example.com.
@             3600 IN  MX    50 mail3
example.com.  3600 IN  A     192.0.2.1
example.com   3600 IN  AAAA  3600 2001:db8:10::1
ns            3600 IN  A     192.0.2.2
example.com   3600 IN  AAAA  2001:db8:10::2
www           3600 IN  CNAME example.com.
wwwtest       3600 IN  CNAME www
mail          3600 IN  A     192.0.2.3
mail2         3600 IN  A     192.0.2.4
mail3         3600 IN  A     192.0.2.5
"
        , user_ip       => $$request{address}
    };

    $$res{params}{zone} =[
        {   qw/type A name bla ttl 30 rdata 10.0.0.1/ }
        ,{  qw/type AAAA name www ttl 36 rdata fe80::de4a:3eff:fe01:3b44/ }
        ,{  qw/type CNAME name web ttl 36 rdata www/ }
        ,{  qw/type MX name mail ttl 3600 priority 10 rdata web/ }
        ,{  qw/type SRV name _sip._tcp.example.com. ttl 86400 priority 0
            weight 5 port 5060 rdata sipserver.example.com./ }
    ];

    if($$param{expert}) {
        $$res{params}{expert} = 1;
    }

    $res
}

sub rt_dom_add_entry_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = '/domain/details/toto.netlib.re';
    $res
}

sub rt_dom_updateraw_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = '/domain/details/toto.netlib.re';
    $res
}

1;
