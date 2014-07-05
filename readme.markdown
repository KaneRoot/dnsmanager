Gérer la création de zones par des utilisateurs.
Les utilisateurs s'enregistrent, crééent des zones et les modifient comme ils le souhaitent.
Des administrateurs peuvent supprimer des utilisateurs avec leurs zones.

## Outils

  * [Dancer](http://perldancer.org/)
  * [DNS::ZoneParse](http://search.cpan.org/~mschilli/DNS-ZoneParse-1.10/lib/DNS/ZoneParse.pm)
  * [Bootstrap](http://twitter.github.io/bootstrap/)
  * [DBD::mysql](https://metacpan.org/module/DBD::mysql)
  * [Moose](https://metacpan.org/module/ETHER/Moose-2.0802/lib/Moose.pm)
  * [Crypt::Digest::SHA256](http://search.cpan.org/~mik/CryptX-0.021/lib/Crypt/Digest/SHA256.pm)

## TODO

  * captcha
  * demander confirmation avant suppression d'une zone
  * proposer la complétion de l'adresse IP du client dans les champs A, AAAA, MX…
  * rajouter les types de RR manquants dans l'interface
  * mise à jour automatique via un script côté client de l'adresse IP (façon dyndns)
  * déléguer les zones

Si on souhaite faire un client pour mettre à jour automatiquement une zone avec son IP:

  * [Net::HTTPS::Any](https://metacpan.org/module/IVAN/Net-HTTPS-Any-0.10/lib/Net/HTTPS/Any.pm) est une piste
