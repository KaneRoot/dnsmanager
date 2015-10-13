#!/usr/bin/perl -w
use v5.14;
use strict;
use warnings;

use File::Basename;
use utf8;
use YAML::XS;
use configuration ':all';
use util ':all';
use app;

use rt::root ':all';
use rt::domain ':all';
use rt::user ':all';
use rt::admin ':all';

#my $test_updateraw = sub {
#    rt_dom_updateraw 
#    get_session( qw/login passwd/ )
#    , get_param( qw/domain zoneupdated/ ); # TODO verify this
#};

my $test_update = sub {
    rt_dom_update
    { qw/login test passwd test/ }
    , { qw/type A
        name www
        value 10.0.0.1
        ttl 100
        priority 1
        domain test.netlib.re./ };
};

#my $test_detail = sub {
#    rt_dom_details
#    get_session( qw/login passwd/ )
#    , get_param( qw/domain expert/ )
#    , get_request( qw/address referer/ );
#};

my $test_add_domain = sub {
    rt_dom_add
    { qw/login test passwd test/}
    , { qw/domain test tld .netlib.re./ };
};

my $test_del_domain = sub {
    rt_dom_del
    { qw/login test passwd test/ }
    , { qw/domain test.netlib.re./ }
    , { qw/address referer/ }; # TODO
};

#my $test_del_entry = sub {
#    rt_dom_del_entry
#    get_session( qw/login passwd/ )
#    , get_param( qw/domain name type host ttl/ )
#    , get_request( qw/address referer/ );
#};

#my $test_mod_entry = sub {
#    rt_dom_mod_entry
#    get_session( qw/login passwd/ )
#    , get_param( qw/domain name type host ttl/ )
#    , get_request( qw/address referer/ );
#};

my $test_cli_mod_entry = sub {
    rt_dom_cli_mod_entry
    get_session( qw/login/ )
    , get_param( qw/passwd domain name type host ttl ip/ );
};

#any ['get', 'post'] => '/admin' => sub {
#    rt_admin
#    get_session( qw/login passwd/ );
#};

#get '/home' => sub {
#    rt_user_home
#    get_session( qw/login passwd/ )
#    , get_param( qw// )
#    , get_request( qw// );
#};

my $test_del_user = sub {
    rt_user_del
    get_session( qw/login passwd/ )
    , { qw/user test/ }
    , { qw/referer/ };
};

my $test_add_user = sub {
    rt_user_add
    { qw// }
    , { qw/login test password test password2 test/ }
    , { qw// };
};

say "Tests - ";

#    get '/subscribe' => sub {
#        rt_user_subscribe
#        get_session( qw/login/ );
#    };

#my $test_toggle_admin = sub {
#    rt_user_toggleadmin
#    { qw/login passwd/ }
#    , get_param( qw/user/ )
#    , get_request( qw/referer/ );
#};
