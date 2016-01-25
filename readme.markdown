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

# Un point sur le code

Le code de dnsmanager est composé de la manière suivante :

* `cli/` : regroupe les commandes à utiliser en ligne de commande, afin
  d'administrer facilement la base de donnée et les zones, et faire des tests.
  Il y a également le code du démon qui tourne sur les machines clientes pour
  gérer la mise à jour de l'adresse IP dynamique.

* `conf/` : contient la configuration du serveur, à savoir `conf.yml` pour
  indiquer où sont les serveurs de nom, comment y accéder pour mettre à
  jour les zones, quel est le répertoire à utiliser pour mettre les fichiers
  temporaires… et `reserved.zone` qui indique quelles sont les zones réservées
  par l'administrateur (ex: on ne veut pas que quelqu'un enregistre www.NDD).

* `init/` : regroupe les scripts permettant de mettre en place le serveur et la
  base de données.

* `lib/` : contient la majorité du code, qui est découpée en MVC, à savoir :

  * `lib/MyWeb/App.pm` : le contrôleur, s'occupe des routes
  * `lib/rt/App.pm` : les routes, qui font office de modèles, effectuent les
  actions à entreprendre (ajout, suppression, modification de zone et
  d'utilisateur)

Mais `lib` contient également toute la bibliothèque logicielle qui effectue les
actions, avec principalement une interface à l'authentification, la
récupération, modification et la suppression de zones et d'utilisateurs avec le
fichier `lib/app.pm`.

* `lib/configuration.pm` : gère la configuration du serveur
* `lib/copycat.pm` : copie des fichiers entre les serveurs
* `lib/db.pm` : gère les interactions avec la base de données
* `lib/encryption.pm` : chiffre les données
* `lib/fileutil.pm` : fonctions utilitaires pour gérer les fichiers
* `lib/getiface.pm` : récupère l'interface logicielle pour gérer un type de
  serveur de noms (Bind9, NSD, Knot…), les interfaces sont dans `lib/interface/`
* `lib/remotecmd.pm` : effectue une commande à distance (comme recharger un
  fichier de configuration dans Bind9)
* `lib/util.pm` : quelques fonctions utilitaires
* `lib/zone.pm` : gère les zones DNS (en général, s'occupe de recharger les
  configuration, mettre à jour les zones, etc)
* `lib/zonefile.pm` : gère les fichiers de zone

* `public/` : les fichers statics du serveur web
* `views/` : les différentes vues de l'application
 
# La délégation de zone

Le principe de délégation est de laisser une personne héberger elle-même
son serveur DNS.
Elle va gérer elle-même sa zone, on aura juste un enregistrement de sa zone
"bla.netlib.re." qui pointera vers son adresse IP via un enregistrement de
type NS et un autre de type A.
Ces enregistrements devront se faire directement dans notre zone DNS
(netlib.re. ou codelib.re.).

Pour gérer la délégation de zone, il l faut :
* mémoriser que la personne a une zone déléguée, non gérée par notre interface
  actuelle mais par une autre interface à faire, ce qui implique de toucher à la
  BDD
* qu'elle puisse ajouter son (ses) adresse(s) IP pour la délégation
* ajouter un enregistrement de type NS dans notre zone (net|code)lib.re
* mettre à jour le numéro de série de notre zone
* indiquer à notre serveur primaire de reload la zone


[netlibre]: https://netlib.re/
[arn]: https://www.arn-fai.net
[perlbrew]: http://perlbrew.pl/
[cpanm]: http://search.cpan.org/~miyagawa/App-cpanminus-1.7040/bin/cpanm
