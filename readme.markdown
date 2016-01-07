# DNSmanager (en)

This project is about managing DNS zones with a simple website, provinding a
name to anyone on the Internet. It is binded to the [netlib.re][netlibre]
project. This service let you manage your dynamic IP address with your domain so
you don't need DynDNS anymore, and it's all libre software !

The association managing the infrastructure behind this service is [Alsace
Réseau Neutre][arn] which is an ethical ISP based in Alsace, France. Don't be
shy, go ask your questions !

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

## Outils

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

[netlibre]: https://netlib.re/
[arn]: https://www.arn-fai.net
