Gérer la création de zones par des utilisateurs.
Les utilisateurs s'enregistrent, crééent des zones et les modifient comme ils le souhaitent.
Des administrateurs peuvent supprimer des utilisateurs avec leurs zones.
Les utilisateurs peuvent mettre leur adresse IP à jour de façon automatique grâce à un script.
Ce qui permet d'être un remplaçant de DynDNS.

## Outils

  * [Dancer2](http://perldancer.org/)
  * [DNS::ZoneParse](https://metacpan.org/pod/DNS::ZoneParse)
  * [Bootstrap](http://twitter.github.io/bootstrap/)
  * [DBD::mysql](https://metacpan.org/module/DBD::mysql)
  * [Moo](https://metacpan.org/pod/Moo)
  * [Crypt::Digest::SHA256](https://metacpan.org/pod/Crypt::Digest::SHA256)

## TODO

  * captcha
  * demander confirmation avant suppression d'une zone
  * rajouter les types de RR manquants dans l'interface (remplacement de
          DNS::ZoneParse, ou amélioration)
  * déléguer les zones
