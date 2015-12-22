#!/bin/bash

## En attendant de faire de vrais paquets pour l'application

sudo apt-get update

sudo apt-get install libssl1.0.0 libssl-dev cpanminus make gcc \
    libdbi-perl libdbd-mysql-perl

# sudo apt-get install bind9

cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

cpanm Dancer2
cpanm Dancer2::Plugin::Deferred
cpanm YAML::XS
cpanm Data::Dump 
cpanm File::Basename 
cpanm Find::Lib 
cpanm Test::More 
cpanm String::ShellQuote
cpanm Data::Structure::Util 
cpanm Modern::Perl
cpanm Config::Simple
cpanm Crypt::Digest::SHA256
cpanm Dancer::Session::Storable
cpanm ExtUtils::MakeMaker 
cpanm Storable 
cpanm Plack::Handler::FCGI 
cpanm Plack::Runner 
cpanm DNS::ZoneParse
cpanm Net::OpenSSH
cpanm Template
cpanm Net::SSH
cpanm Date::Calc
cpanm Data::Validate::IP

# cpanm Template::Toolkit non trouvé
