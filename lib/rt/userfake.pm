package rt::userfake;

use v5.14;
use configuration ':all';
use encryption ':all';
use app;
use utf8;
use open qw/:std :utf8/;

use YAML::XS;

use Exporter 'import';
# what we want to export eventually
our @EXPORT_OK = qw/
rt_user_login_fake
rt_user_del_fake
rt_user_toggleadmin_fake
rt_user_subscribe_fake
rt_user_changepasswd_fake
rt_user_add_fake
rt_user_home_fake
/;

# bundle of exports (tags)
our %EXPORT_TAGS = ( all => [qw/
        rt_user_login_fake
        rt_user_del_fake
        rt_user_toggleadmin_fake
        rt_user_subscribe_fake
        rt_user_changepasswd_fake
        rt_user_add_fake
        rt_user_home_fake
        /] ); 

sub rt_user_login_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = '/admin';
    $res
}

sub rt_user_del_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = $$request{referer};
    $res
}

sub rt_user_toggleadmin_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = $$request{referer};
    $res
}

sub rt_user_subscribe_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = '/user/home';
    $res
}

sub rt_user_changepasswd_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = '/user/home';
    $res
}

sub rt_user_add_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{route} = '/user/home';
    $res
}

sub rt_user_home_fake {
    my ($session, $param, $request) = @_;
    my $res;
    $$res{template} = 'home';
    $$res{params} = {
        login               => "toto"
        , admin             => 1
        , domains           => [ {qw/domain toto.netlib.re/} ]
        , provideddomains   => [ qw/netlib.re. codelib.re./ ]
        , domainName        => ''
    };
    $res
}

1;
