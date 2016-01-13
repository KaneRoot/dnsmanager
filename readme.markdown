# DNSmanager (en)

This project is about managing DNS zones with a simple website, provinding a
name to anyone on the Internet. It is binded to the [netlib.re][netlibre]
project. This service let you manage your dynamic IP address with your domain so
you don't need DynDNS anymore, and it's all libre software !

The association managing the infrastructure behind this service is [Alsace
Réseau Neutre][arn] which is an ethical ISP based in Alsace, France. Don't be
shy, go ask your questions !

## Tools

  * [Dancer2](http://perldancer.org/)
  * [Net::DNS](https://metacpan.org/pod/Net::DNS)
  * [Bootstrap](http://twitter.github.io/bootstrap/)
  * [DBD::mysql](https://metacpan.org/module/DBD::mysql)
  * [Moo](https://metacpan.org/pod/Moo)
  * [Crypt::Digest::SHA256](https://metacpan.org/pod/Crypt::Digest::SHA256)

## TODO

  * zone delegation
  * REST API
  * captcha ?

# Installation (base)

I suggest using [perlbrew][perlbrew] and [cpanm][cpanm] for the installation,
to not change your current environment. So install them then :

    perlbrew install perl-5.18.0
    perlbrew switch perl-5.18.0
    perlbrew exec sh init/deploiement.sh all

# Contribution (but only to the user interface)

If you want to contribute only on the application interface, you don't need to install and configure all the applications involved in the production release of dnsmanager.
First, uncomment "isviewtest" on **conf/config.yml** then :

    perlbrew install perl-5.18.0
    perlbrew switch perl-5.18.0
    perlbrew exec sh init/deploiement.sh installdep
    perlbrew exec sh init/deploiement.sh perlmodules

Finally, to run the application with fake views :

    perlbrew exec plackup --port 3000 bin/app.psgi


# DNSmanager (fr)

Ce projet est un programme de gestion de zones DNS à partir d'un site web
simple, permettant à chacun d'avoir un nom sur **Internet**. Il est lié au
service en ligne [netlib.re][netlibre]. Ce service en ligne peut
remplacer avantageusement DynDNS puisqu'il est basé sur du code libre, et une
association s'occupe de son maintien ([Alsace Réseau
Neutre][arn], éthique++).

De manière factuelle :

- des utilisateurs peuvent s'enregistrer puis
  - ajouter, supprimer, modifier des zones DNS
  - mettre à jour un enregistrement A ou AAAA automatiquement via un script

- des administrateurs sont là pour
  - supprimer des zones, des utilisateurs
  - vous aider sur IRC (#arn sur irc.geeknode.org) ! \o/

# installation (base)

L'installation de l'application se fait de préférence via
[perlbrew][perlbrew] et [cpanm][cpanm] ce qui permet d'installer les
bibliothèques sans toucher à votre installation de Perl. Installez ces
programmes puis faites :

    perlbrew install perl-5.18.0
    perlbrew switch perl-5.18.0
    perlbrew exec sh init/deploiement.sh all

# Contribuer (uniquement à l'interface)

Si vous souhaitez contribuer à *l'interface*, il suffit de décommenter la ligne
indiquant "isviewtest" dans le fichier de configuration **conf/config.yml**.
À partir de là, vous pouvez installer l'application comme ceci :

    perlbrew install perl-5.18.0
    perlbrew switch perl-5.18.0
    perlbrew exec sh init/deploiement.sh installdep
    perlbrew exec sh init/deploiement.sh perlmodules

Puis pour faire vos tests :

    perlbrew exec plackup --port 3000 bin/app.psgi

## Ce qu'il reste à faire

  * délégation de zone
  * API REST
  * captcha ?

[netlibre]: https://netlib.re/
[arn]: https://www.arn-fai.net
[perlbrew]: http://perlbrew.pl/
[cpanm]: http://search.cpan.org/~miyagawa/App-cpanminus-1.7040/bin/cpanm
