package MyWeb::App;

use v5.14;
use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::Deferred;
use File::Basename;
#use Storable qw( freeze thaw );
#$Storable::Deparse = true;
#$Storable::Eval=true;
use utf8;

use YAML::XS;
use configuration ':all';
use util ':all';
use rt::root ':all';
use rt::domain ':all';
use rt::user ':all';
use rt::admin ':all';
use app;

our $VERSION = '0.1';

sub what_is_next {
    my ($res) = @_;

    if($$res{sessiondestroy}) {
        app->destroy_session;
    }

    for(keys %{$$res{deferred}}) {
        deferred $_ => $$res{deferred}{$_};
    }

    for(keys %{$$res{addsession}}) {
        session $_ => $$res{addsession}{$_};
    }

    for(keys %{$$res{delsession}}) {
        session $_ => undef;
    }

    if(exists $$res{route}) {
        redirect $$res{route};
    }
    elsif(exists $$res{template}) {
        template $$res{template} => $$res{params};
    } else {
        redirect '/';
    }
}

sub get_param {
    my $param_values;
    for(@_) {
        $$param_values{$_} = param "$_";
    }
    $param_values;
}

sub get_request {
    my $request_values;
    for(@_) {
        if(/^address$/)     { $$request_values{$_} = request->address; }
        elsif(/^referer$/)  { $$request_values{$_} = request->referer; }
    }
    $request_values;
}

sub get_session {
    my $session_values;
    for(@_) {
        $$session_values{$_} = session "$_";
    }
    $session_values;
}

get '/' => sub { 
    what_is_next rt_root 
    get_session( qw/login passwd/ );
};

prefix '/domain' => sub {

    post '/updateraw/:domain' => sub {
        what_is_next rt_dom_updateraw 
        get_session( qw/login passwd/ )
        , get_param( qw/domain zoneupdated/)
        , get_request( qw/address referer/ );
    };

    post '/update/:domain' => sub {
        what_is_next rt_dom_update
        get_session( qw/login passwd/ )
        , get_param( qw/domain name type priority rdata ttl/ );
    };

    get '/details/:domain' => sub {
        what_is_next rt_dom_details
        get_session( qw/login passwd/ )
        , get_param( qw/domain expert/ )
        , get_request( qw/address referer/ );
    };

    post '/add/' => sub {
        what_is_next rt_dom_add
        get_session( qw/login passwd/ )
        , get_param( qw/domain tld/ );
    };

    get '/del/:domain' => sub {
        what_is_next rt_dom_del
        get_session( qw/login passwd/ )
        , get_param( qw/domain/ )
        , get_request( qw/address referer/ );
    };

    get '/del/:domain/:name/:ttl/:type/:rdata' => sub {
        what_is_next rt_dom_del_entry
        get_session( qw/login passwd/ )
        , get_param( qw/domain name type ttl rdata/ )
        , get_request( qw/address referer/ );
    };

    post '/mod/:domain' => sub {
        what_is_next rt_dom_mod_entry
        get_session( qw/login passwd/ )
        , get_param( qw/domain 
            oldpriority oldtype oldname oldttl oldrdata
            newpriority newtype newname newttl newrdata/ )
        , get_request( qw/address referer/ );
    };

    get '/cli/:login/:pass/:domain/:name/:type/:rdata/:ttl/:ip' => sub {
        what_is_next rt_dom_cli_mod_entry
        get_session( qw/login/ )
        , get_param( qw/passwd domain name type rdata ttl ip/ );
    };
};

any ['get', 'post'] => '/admin' => sub {
    what_is_next rt_admin
    get_session( qw/login passwd/ );
};

prefix '/user' => sub {

    get '/home' => sub {
        what_is_next rt_user_home
        get_session( qw/login passwd/ )
        , get_param( qw// )
        , get_request( qw// );
    };

    get '/logout' => sub {
        app->destroy_session;
        redirect '/';
    };

    get '/del/:user' => sub {
        what_is_next rt_user_del
        get_session( qw/login passwd/ )
        , get_param( qw/user/ )
        , get_request( qw/referer/ );
    };

    # add a user => registration
    post '/add/' => sub {
        what_is_next rt_user_add
        get_session( qw// )
        , get_param( qw/login password password2/ )
        , get_request( qw// );
    };

    get '/subscribe' => sub {
        what_is_next rt_user_subscribe
        get_session( qw/login/ );
    };

    get '/toggleadmin/:user' => sub {
        what_is_next rt_user_toggleadmin
        get_session( qw/login passwd/ )
        , get_param( qw/user/ )
        , get_request( qw/referer/ );
    };

    post '/login' => sub {
        what_is_next rt_user_login
        get_session( qw/login/ )
        , get_param( qw/login password/ )
        , get_request( qw/referer/ );
    };
};

true;
