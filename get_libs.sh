#!/bin/bash

sudo apt-get update
sudo apt-get install libssl1.0.0 libssl-dev cpanminus make gcc

## En attendant de faire de vrais paquets pour l'application

cpanm YAML
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

cpanm Moose
cpanm Template
cpanm Template::Toolkit
cpanm Dancer 
cpanm Dancer::Test 

cpanm ExtUtils::MakeMaker 
cpanm Storable 

cpanm Plack::Handler::FCGI 
cpanm Plack::Runner 
cpanm DNS::ZoneParse
cpanm Net::OpenSSH
