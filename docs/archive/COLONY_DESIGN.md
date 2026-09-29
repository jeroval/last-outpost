# Last Outpost — concept de jeu

**Statut : direction de design, 29 septembre 2026.** Le prototype Godot réalise maintenant la récolte, les abris, un foyer à deux intensités, une prévision des nuits, une météo annoncée et une conclusion après cinq nuits. Les dépôts, les trajets de retour et l'évaluation avec des joueurs restent à faire.

## Identité

**Concept en une phrase.** Sur une petite carte 3D, le joueur organise trois survivants, leurs trajets et un réseau de chaleur pour traverser cinq nuits malgré l'épuisement des ressources et une météo changeante.

**Question centrale.** Où installer le camp et à quoi consacrer les prochaines heures pour survivre cette nuit sans rendre la suivante plus difficile ?

**Promesse.** Une décision simple — allumer plus fort, rapprocher un dépôt, envoyer quelqu'un plus loin — a plusieurs conséquences lisibles. Le joueur comprend pourquoi son camp a tenu ou échoué, puis peut essayer une autre stratégie.

**Fantasme.** Devenir l'organisateur ingénieux d'un refuge fragile, et voir ses choix spatiaux et humains produire une histoire propre à chaque partie.

**Public et plateforme supposés.** Jeu solo sur navigateur d'ordinateur, à la souris, accessible sans compte. La compatibilité mobile est à étudier après la validation du cœur de jeu.

## Choix de direction

| Direction examinée | Intérêt | Limite pour la prochaine étape |
| --- | --- | --- |
| Étendre le prototype actuel avec davantage de ressources et d'événements | Rapide à produire | Les actions restent principalement séparées ; la variété dépend du contenu ajouté. |
| Simuler dès maintenant factions, commerce et monde persistant | Histoires de grande ampleur | Beaucoup de règles et d'interface avant de savoir si les décisions immédiates plaisent. |
| **Faire interagir chaleur, distance et réserves sur une petite carte** | Chaque placement et affectation change plusieurs risques visibles | Demande de rendre les causes et les trajets très lisibles. |

La troisième direction est retenue pour le prochain prototype. Elle garde l'ambition d'histoires émergentes de Last Outpost avec une simulation bornée. La persistance d'un monde pendant que l'onglet est fermé n'est pas promise : un export Godot Web cesse normalement de traiter la partie lorsque l'onglet est inactif, et une vraie simulation hors ligne demanderait une autre architecture ([limite documentée par Godot](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html#background-processing)).

## Plaisir et boucles

**Verbe principal : organiser.** Le joueur place des points de vie et de stockage, puis affecte les survivants. Récolter, observer et construire servent cet arbitrage.

- **Première minute :** envoyer un survivant chercher du bois, voir son trajet et choisir où installer un foyer avant la nuit.
- **Boucle courte :** lire une menace et une prévision → modifier une affectation, un emplacement ou l'intensité du feu → voir le trajet et les réserves évoluer → corriger.
- **Session :** traverser cinq nuits, avec un bilan des survivants, des ressources et des causes marquantes. Une session doit permettre plusieurs stratégies, même en cas d'échec.
- **Long terme envisagé :** cartes de départ et météo variées, nouvelles propriétés ou structures qui changent les combinaisons possibles. Ni progression statistique obligatoire ni collection de quêtes manuelles ne portent le cœur du jeu.

Le plaisir à vérifier est la satisfaction d'anticiper une conséquence, de voir le plan fonctionner ou échouer pour une raison compréhensible, puis d'améliorer le camp. Les récompenses et la narration viennent après cette preuve.

## Trois moyens du prochain prototype

| Moyen | Rôle | Compromis et interactions |
| --- | --- | --- |
| **Foyer** | Réchauffe une zone et éclaire les trajets. Deux intensités : braise et flamme. | La flamme protège plus loin mais consomme davantage de bois et rend le camp plus visible. Le vent déplace la zone utile. |
| **Abri** | Protège les survivants pendant la nuit. | Près du foyer, il est chaud ; loin, il libère l'espace central mais impose plus de combustible ou de froid. |
| **Dépôt** | Réduit le temps des trajets en recevant bois et nourriture. | Près des ressources, il accélère la collecte mais expose les réserves à la météo et éloigne parfois le ravitaillement du foyer. |

Les ordres de récolte existants deviennent des **affectations** : le joueur choisit qui part et vers quel lieu. Une tâche lointaine rapporte parfois plus, mais le survivant peut rentrer après la tombée du jour. Les outils ont une fonction immédiate et restent utiles ensemble ; aucun n'est une simple amélioration numérique de l'autre.

### Propriétés communes

1. **Distance et temps de trajet** : récolte, ravitaillement du feu et retour à l'abri utilisent la même mesure.
2. **Chaleur et exposition** : les survivants, les abris et les trajets réagissent à la météo et au foyer.
3. **Visibilité** : la flamme aide à surveiller le camp mais pourra plus tard attirer voyageurs ou dangers. Cette conséquence est différée tant que les rencontres ne sont pas testées.

Ces propriétés remplacent une liste de pénalités isolées. Les chiffres précis, coûts et rayons seront réglés à partir d'essais, pas présentés comme équilibrés aujourd'hui.

## Défis, échec et expression

**Objectif du prototype :** conserver au moins un survivant et un foyer opérationnel pendant cinq nuits. Les réserves, les personnes sauvées et la stabilité du camp constituent un bilan, sans imposer une solution parfaite.

**Contraintes :** bois fini, nourriture limitée, heures avant la nuit, vent ou froid annoncé, capacité de travail de trois personnes. La carte doit toujours offrir plusieurs premières décisions viables ; une graine générée ne doit pas condamner le joueur avant qu'il puisse agir.

**Stratégies possibles :** foyer central et trajets courts ; dépôt avancé pour récolter vite ; abris groupés pour économiser le bois ; feu faible et réserve de sécurité. Les conditions météo doivent pouvoir changer quelle approche est préférable.

**Échec informatif :** le bilan montre les causes proches et leur ordre : « deux retours après la nuit → trois survivants exposés → bois épuisé → foyer éteint ». Le joueur peut recommencer sur la même carte et modifier son plan rapidement. Un simple message « cohésion à zéro » ne suffit pas.

**Partage futur :** une graine de carte et un bilan court pourraient permettre de comparer des camps sans serveur social. À valider seulement si les joueurs ont envie de raconter leurs solutions.

## Prochaine tranche jouable

1. **Réalisé :** prévision de météo, bois consommé, repas manquants, rayon du feu et survivants exposés ; estimation du trajet à l'affectation.
2. **Réalisé :** foyer à deux intensités, zone de chaleur visible et consommation réelle de bois chaque nuit.
3. **Réalisé :** capacité de deux personnes par abri chauffé, exposition des survivants encore en mission et bilan chiffré des pertes nocturnes.
4. **À éprouver :** observer si les joueurs déplacent réellement leurs abris ou changent l'intensité du feu selon la météo, puis améliorer les trajets de retour si cette décision reste opaque.
5. Ajouter le dépôt uniquement si les premiers essais montrent un choix réel entre placement central et avancé.

Cette tranche permet maintenant de tester l'hypothèse fragile : **anticiper et ajuster un petit réseau de survie est-il plus intéressant que cliquer simplement sur des ressources ?** Les tests automatisés vérifient les règles ; ils ne répondent pas à cette question de plaisir. Le prototype n'ajoute ni factions, ni économie régionale, ni réseau multijoueur.

## Vérification avec joueurs

Observer des parties courtes sans guider la solution. Relever où les joueurs hésitent, ce qu'ils prévoient avant la nuit, les corrections qu'ils font après un échec et s'ils veulent relancer la même carte. Demander ensuite de raconter la cause de leur réussite ou de leur échec ; comparer leur explication au journal de simulation.

La prochaine décision dépend de ces observations : renforcer si plusieurs stratégies apparaissent et si les causes sont comprises ; corriger l'interface ou les règles si les joueurs luttent contre la sélection et les trajets ; réduire ou changer la mécanique si le meilleur choix reste toujours identique. Aucun résultat joueur n'a encore été observé.

## Source et portée

Ce concept s'inspire du document fourni **« Game design Framework GDF_260720_161428.txt »**, consulté le 29 septembre 2026 (SHA-256 `A0928968F8B996E9E200195FBF6B2A01AB43AF87B37476B06AD4A13E43263DE1`). Il en reprend l'attention aux interactions, aux boucles, aux compromis et aux échecs lisibles, sans importer ses exemples mécaniques comme exigences du projet. Les décisions du présent document restent des hypothèses de design, distinctes des consignes de `AGENTS.md`.
