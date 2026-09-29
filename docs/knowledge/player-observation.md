# Observer l'expérience du joueur

Statut au 29 septembre 2026 : hypothèses de conception, aucun test avec un joueur observé. Le prompt `jeux2.txt` fourni par l'utilisateur demande profondeur des systèmes, conséquences compréhensibles et progression sans corvées artificielles. Ce document résume ces besoins ; il ne conserve pas le fichier privé.

L'objectif opérationnel est une entrée accessible dans un jeu de survie et de gestion. « Plaire à tout le monde » ne peut pas être vérifié par une implémentation. Observer d'abord une personne découvrant ce genre et une personne qui le connaît aidera à distinguer apprentissage et profondeur ; ces profils sont proposés, pas des participants déjà recrutés.

## Prochaine observation utile

Donner le lanceur et demander de commencer une partie sans explication orale. Observer le premier objectif, l'identification d'un lieu utile, la collecte, le retour, la réparation et la reprise d'une sauvegarde. Noter blocages, actions inattendues, recours à l'aide et ce que la personne pense avoir changé. Ne pas guider avant de noter le blocage.

Le critère prioritaire est de comprendre comment progresser et pourquoi une action échoue. La première restauration doit être possible sans commande de développeur ni ressource perdue définitivement par une simple erreur d'interface. Une hésitation, un temps ou un abandon est une observation, pas automatiquement un bug : demander ce qui était attendu.

Pour tester la profondeur, présenter un vrai choix, par exemple conserver du carburant ou alimenter une installation. Demander après l'action quelle conséquence était anticipée. Un système dont le coût demeure invisible doit recevoir du feedback avant d'être complexifié.

Consigner un retour avec build/date, profil pertinent sans identité personnelle, situation, comportement observé, citation courte autorisée, interprétation distincte et prochaine modification/test. Utiliser [BUGS](../agent/BUGS.json) pour un défaut reproductible et [ROADMAP](../ROADMAP.md) pour une hypothèse de conception. Les durées de 10 à 50 heures demandées restent des objectifs ; ne pas les annoncer avant des parties mesurées.

## Observation technique distincte d'un test joueur

LO-006 a révélé qu'un objectif correct dans sa formulation peut conduire au mauvais lieu si son calcul ignore les ressources du sac ou les réserves déjà épuisées. Le [test de guidage](../../tests/progression_smoke.gd) a échoué sur six assertions avant correction, puis passé après correction le 29 septembre. Pour ce jeu, éprouver les transitions collecte → dépôt → fabrication protège donc une partie de la compréhension du parcours. Cela ne remplace pas l'observation de sa lisibilité par un nouveau joueur.
