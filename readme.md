# FR
## trame du projet

> "Faire le projet en POO, pour le rendre un peu modulable (au cas où on change certaines parties en cours de route). Il y aura 2 types d'utilisateurs, l'admin + un utilisateur de base. L'admin peut créer une zone, pas l'utilisateur. L'utilisateur peut juste la modifier."

> "L'inscription : l'utilisateur va envoyer une demande pour réserver un ndd en .netlib.re et il faut que ça vérifie que le ndd n'existe pas déjà puis que ça envoie un mail aux admins. De préférence, une page web testera si le ndd est libre, indiquera une erreur à l'utilisateur s'il ne l'est pas et on rajoute un captcha pour éviter des bots." 
> "Côté admin : il faut que l'ajout d'une zone soit aussi automatique, pas qu'on ait à aller l'ajouter nous-même (mais ça c'est pour plus tard à la limite). J'ai trouvé quelques modules Perl qui font une partie du travail + je peux faire le site avec Dancer, du coup tout sera fait avec le même langage." 

## outils
* [Dancer](http://perldancer.org/)
* [Net::DNS](https://metacpan.org/module/NLNETLABS/Net-DNS-0.72/lib/Net/DNS.pm)
* [Net::DNS::ZoneParse](https://metacpan.org/module/BTIETZ/Net-DNS-ZoneParse-0.103/lib/Net/DNS/ZoneParse.pm)
* [Bootstrap](http://twitter.github.io/bootstrap/)
* [DBD::mysql](https://metacpan.org/module/DBD::mysql)

## TODO
+ "Vérifier si les modules cités dans 'outils' correspondent à ce que l'on cherche."
	+ "Aller sur #perlfr pour demander conseil."
	+ "Faire des tests d'exemple sur ces modules."
+ "Rajouter les modules qu'il nous manque (ex: pour le chiffrement du mot de passe avant l'ajout d'un utilisateur/admin)."
