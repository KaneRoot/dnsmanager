# DNSmanager

Ce projet est un programme de gestion de zones DNS à partir d'un site web
simple, permettant à chacun d'avoir un nom sur **Internet**. Il est lié au
service en ligne [netlib.re](https://netlib.re/). Ce service en ligne peut
remplacer avantageusement DynDNS puisqu'il est basé sur du code libre, et une
association s'occupe de son maintien ([Alsace Réseau
Neutre](https://www.arn-fai.net), éthique++).

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

  * déléguer les zones
  * captcha ?
