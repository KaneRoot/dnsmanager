package DNSManager;

use Dancer ':syntax';
use strict;
use warnings;
use v5.14;
use Modern::Perl;
use Data::Dump qw( dump );
use Data::Structure::Util qw ( unbless );
use File::Basename;
use Config::Simple;
use Storable qw( freeze thaw );
$Storable::Deparse = true;
$Storable::Eval=true;

# Include other libs relative to current path
use Find::Lib '../../';
use app::app;

my $success;
our $cfg = new Config::Simple(dirname(__FILE__).'/../conf/config.ini');

our $VERSION = '0.1';

get '/' => sub {
    if( session('login') )
    {
        # my ($auth_ok, $user, $admin) =
        #     $usermanagement->auth( session('login'), session('password') );
		my $app = app->new( zdir => $cfg->param('zones_path'),
							dbname => $cfg->param('dbname'),
							dbhost => $cfg->param('host'),
							dbport => $cfg->param('port'),
							dbuser => $cfg->param('user'),
							dbpass => $cfg->param('passwd'),
							sgbd => $cfg->param('sgbd'),
							dnsapp => $cfg->param('dnsapp') );
        $app->init();
        $app->get_domains( session('login') );
        template 'index' =>
        { 'logged'  => true,
            'login'   => session('login'),
            'admin'   => session('admin'),
            'domains' => $app->get_domains(session('login'))
        };
    }
    else
    {
        template 'index';
    }
};

post '/login' => sub {

    # Check if user is already logged
    unless ( session('login') )
    {
        # Check user login and password
        if ( param('login') && param('password') )
        {
            my $app = app->new( zdir => $cfg->param('zones_path'),
                                dbname => $cfg->param('dbname'),
                                dbhost => $cfg->param('host'),
                                dbport => $cfg->param('port'),
                                dbuser => $cfg->param('user'),
                                dbpass => $cfg->param('passwd'),
                                sgbd => $cfg->param('sgbd'),
                                dnsapp => $cfg->param('dnsapp') );
            $app->init();
            my ($auth_ok, $user, $isadmin) = $app->auth(param('login'),
                                                 param('password') );
            if( $auth_ok )
            {

                session login => param('login');
                # TODO : change password storage…
                session password => param('password');
                session user  => freeze( $user );
                session admin => $isadmin;

            }
            else
            {
                # User login and/or password are incorrect
            }
        }
    }
    redirect '/';
};


get '/mapage' => sub {
    unless( session('login') )
    {
        redirect '/';
    }
    else
    {
        # my ($auth_ok, $user, $admin) =
        # $usermanagement->auth( session('login'), session('password') );
		my $app = app->new( zdir => $cfg->param('zones_path'),
							dbname => $cfg->param('dbname'),
							dbhost => $cfg->param('host'),
							dbport => $cfg->param('port'),
							dbuser => $cfg->param('user'),
							dbpass => $cfg->param('passwd'),
							sgbd => $cfg->param('sgbd'),
							dnsapp => $cfg->param('dnsapp') );
        $app->init();
        my %domains = ();
        my %zone_properties = ();


        my @d = @{$app->get_domains( session('login') )};


        # loop on domains
        #foreach( @{ $app->get_domains( session('login') )} )
        #{
        #    my @zones = ();
	#		# TODO
        #    foreach my $zone ( $app->get_domain($_)->output() )
        #    {
        #        # avoid some var
        #        # keep only hash type
        #        if( ref($zone) eq 'HASH' )
        #        {
        #            if( $zone->{'addr'} )
        #            {
        #                unless( $zone->{'addr'} eq '@' )
        #                {
        #                    # normal zone, push it
        #                    push( @zones, $zone );
        #                }
        #                else
        #                {
        #                    # domain properties
        #                    $zone_properties{$_} = $zone;
        #                }
        #            }
        #        }
        #    }
        #    $domains{$_} = [ @zones ];
        #}

        #my @keys = keys(%domains);
        #print "key : $_  value : $domains{$_}\n" foreach(@keys);
#		foreach my $k ( keys %domains) {
#			foreach my $v ( keys @{ $domains{$k} } ) {
#				#print "dump : ".dump( $v )."\n";
#				if( UNIVERSAL::isa($domains{$k}[$v], "HASH" ) )
#				{
#					print "hash...\n";
#					print "start ------\n";
#					print "$_ => $domains{$k}[$v]{$_}\n" foreach( keys $domains{$k}[$v] );
#					print "end ------\n\n";
#				}
#				print "value : " . dump( $domains{$k}[$v] ) . "\n";
#			}
#		}
        #print 'manual dump : ' . dump( $domains{'karchnu.fr'} )."\n";
        #print 'prop dump : ' . dump( %zone_properties ) . "\n";
        template 'mapage' =>
        { 'login'           => session('login'),
          'domains'         => $app->get_domains(session('login')),
          'zones_domains'   => \%domains,
          'zone_properties' => \%zone_properties,
          'admin'           => session('admin')  };
        }
};

get '/details' => sub {
	# check if user is logged & if domain parameter is set
	unless( session('login') && param('domain'))
	{
		redirect '/';
	}
	else
	{

		# my ($auth_ok, $user, $admin) =
		# $usermanagement->auth( session('login'), session('password') );
		my $app = app->new( zdir => $cfg->param('zones_path'),
							dbname => $cfg->param('dbname'),
							dbhost => $cfg->param('host'),
							dbport => $cfg->param('port'),
							dbuser => $cfg->param('user'),
							dbpass => $cfg->param('passwd'),
							sgbd => $cfg->param('sgbd'),
							dnsapp => $cfg->param('dnsapp') );
		$app->init();
		my ($auth_ok, $user, $isadmin) = $app->auth( param('login') );
		my @zones = ();
		my $zone_properties;
		#say 'dump : ' . dump $user->get_zone( param('domain') );

		for( $user->get_zone( param('domain') ) ) {

			if( ref($_) eq 'HASH' and exists $_->{addr} ) {
				push( @zones, $_ )    when $_->{addr} ne '@';
				$zone_properties = $_ when $_->{addr} eq '@';
			}

		}
		template 'details' =>
		{ 'login'           => session('login'),
		  'domain'          => param('domain'),
		  'zones'           => \@zones,
		  'zone_properties' => $zone_properties };
	}

};


any ['get', 'post'] => '/administration' => sub {
    unless( session('login') )
    {
        redirect '/';
    }
    else
    {
        template 'administration' =>
        { 'login' => session('login'),
          'admin' => session('admin')  };
    }
};

any ['post', 'get'] => '/logout' => sub {
    session->destroy;
    redirect '/';
};

get '/domainadd' => sub {
	# check if user is logged & if domain parameter is set
	unless( session('login') )
	{
		redirect '/';
	}
	else
	{

        my $app = app->new( zdir => $cfg->param('zones_path'),
                            dbname => $cfg->param('dbname'),
                            dbhost => $cfg->param('host'),
                            dbport => $cfg->param('port'),
                            dbuser => $cfg->param('user'),
                            dbpass => $cfg->param('passwd'),
                            sgbd => $cfg->param('sgbd'),
                            dnsapp => $cfg->param('dnsapp') );
        $app->init();

        if( param('domain') )
        {
            # create domain
            $app->add_domain( session('login'), param('domain') );
            # Then, redirect to mapage
            redirect '/mapage';
        }

	}

};

get qr{/domaindel/(.*)} => sub {
    my ($domainToDelete) = splat;
    my $app = app->new( zdir => $cfg->param('zones_path'),
                        dbname => $cfg->param('dbname'),
                        dbhost => $cfg->param('host'),
                        dbport => $cfg->param('port'),
                        dbuser => $cfg->param('user'),
                        dbpass => $cfg->param('passwd'),
                        sgbd => $cfg->param('sgbd'),
                        dnsapp => $cfg->param('dnsapp') );
    $app->init();
    $app->delete_domain(session('login'), $domainToDelete);
    redirect '/mapage';
}

