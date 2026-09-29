# Roadmap — Last Outpost

Mise à jour du 29 septembre 2026. Le complément `jeux2.txt` fournit une direction large ; cette roadmap distingue les capacités réalisées de leur bénéfice encore à observer. Aucun nombre d'heures de plaisir ou de rejouabilité n'est établi.

| Jalon | Critère de passage | État |
| --- | --- | --- |
| Station jouable | Déplacement, fouille, transport, dépôt/retrait, réparation, construction, jour et sauvegarde | Réalisé et vérifié techniquement |
| Démarrage et confort | Accueil, reprise, aide, pause, carte, commandes visibles, réglages et modes Découverte/Survie | Réalisé ; validation de livraison du lanceur et des exports suivie séparément |
| Navigation guidée | Orienter vers le lieu utile, le dépôt une fois le sac prêt, puis l'action de construction | Réalisé ; régression LO-006 corrigée et testée |
| Production et commerce | Eau selon météo, potager consommant l'eau, troc des excédents contre matériaux et carburant, offres limitées | Réalisé ; règles vérifiées, intérêt à observer |
| Bruit et défense | Intrusion annoncée, coût du générateur, garde du joueur, usure et réparation des barricades | Réalisé comme événement nocturne ; combat physique différé |
| Première session compréhensible | Un nouveau joueur démarre, suit un objectif, utilise ses réserves et explique un choix sans tutoriel oral | À observer avec des joueurs |
| Garage et véhicule | Réparer et conduire un véhicule ; coffre et trajet donnent une raison de le choisir malgré le carburant | Différé |
| Survivants et délégation | Recruter une personne, comprendre son besoin et lui confier une tâche utile avec résultat visible | Différé |
| Menaces physiques | Repérer une menace, comprendre bruit/vision, éviter ou défendre ; navigation et performances compatibles navigateur | Différé |
| Région et logistique | Plusieurs destinations reliées par transport ou expéditions, persistance et arbitrage entre routes | Différé |

## Prochaine observation utile

Faire découvrir le jeu depuis le lanceur, sans expliquer les commandes oralement. Observer le premier trajet vers l'entrepôt, le retour au stock, la construction, la préparation de nuit et la reprise d'une sauvegarde. Relever les hésitations, les pertes incomprises et les décisions formulées par le joueur. Le [protocole proposé](knowledge/player-observation.md) permet de conserver les observations sans les confondre avec un test automatisé.

Corriger d'abord les blocages observés. Si le parcours est compris mais que les choix ne présentent aucun intérêt, revoir coûts, ressources et conséquences. Si le joueur comprend les arbitrages et demande à agrandir son rayon de collecte, le véhicule devient un candidat pour le prochain jalon.

## Limites des preuves actuelles

`tests/progression_smoke.gd` vérifie notamment l'accès à tous les équipements et à une barricade sur 32 graines, ainsi qu'un scénario de 24 jours avec production, consommation et troc. Il vérifie aussi quotas persistants, prévision de menace, défense, sauvegarde et migration. Ces scénarios synthétiques montrent que certains parcours fonctionnent ; ils ne démontrent pas la qualité d'une session humaine, l'équilibre de toutes les stratégies ou une durée de jeu de 10 à 50 heures.

Le [point de reprise](agent/PROJECT.md) conserve les preuves de livraison et leurs limites. Les défauts observés restent dans le [registre de bugs](agent/BUGS.json). Les skills et connaissances locales servent les prochaines sessions de travail ; ils ne constituent pas un service autonome permanent.

## Ambitions encore différées

Le commerce actuel est un troc récurrent à la station. Voyageurs avec besoins propres, survivants autonomes, recrutement, métiers, factions, négociation et missions émergentes restent à développer. Les voitures visibles sont des décors ; conduite, coffre mobile, réparation détaillée, remorque et convoi restent différés.

Les intrusions actuelles n'impliquent aucun zombie ni pillard naviguant dans la scène. Combat, perception, hordes migrantes et défense spatiale réelle demandent un jalon distinct. Monde régional, événements en chaîne plus variés et automatisation par des travailleurs pourront suivre lorsque leur rôle dans les décisions du joueur sera établi.
