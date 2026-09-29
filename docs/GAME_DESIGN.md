# Last Outpost — station-service

**Direction de design, 29 septembre 2026.** La scène principale est la station en troisième personne. Le prompt `jeux.txt`, puis son complément `jeux2.txt`, orientent la progression vers un refuge productif et vivant. L'ancien concept de camp est conservé dans [COLONY_DESIGN.md](archive/COLONY_DESIGN.md).

## Promesse et boucle

Le joueur transforme une station-service abandonnée en refuge utile. Il choisit ce qu'il rapporte, consomme, investit ou échange. L'étagère donne de la place ; le récupérateur et le potager produisent des réserves ; le comptoir transforme les excédents en matériaux et carburant. Le générateur éclaire la station, consomme du carburant et attire progressivement des intrusions par son bruit.

**Boucle actuelle :** choisir un objectif → trouver ses matériaux → revenir au stock → construire ou échanger → préparer la nuit → observer production et conséquences → réorganiser les réserves. Les cinq lieux ont des butins distincts et finis ; production et commerce permettent ensuite de renouveler les ressources utiles.

Le temps avance uniquement lorsque le joueur choisit de passer la nuit au refuge. Il peut explorer et apprendre les commandes à son rythme. L'écran de préparation annonce météo, consommation du générateur, présence du marchand et éventuelle intrusion ; le bilan du matin explique les conséquences. Le monde ne simule pas encore d'évolution hors session.

Le jalon « refuge autonome » demande étagère, générateur réparé, récupérateur, potager, comptoir, au moins une barricade et un joueur en vie. Il reconnaît les infrastructures installées ; le joueur doit encore organiser ses réserves. La partie peut continuer après ce jalon. Une santé à zéro propose de reprendre une sauvegarde ou de recommencer.

## Parcours de découverte

L'accueil propose **Découverte** — besoins quotidiens réduits de moitié, sans intrusion — et **Survie**, avec consommation normale et pression du bruit. Ces modes répondent à des préférences différentes ; leur présence ne démontre pas que l'expérience convient à tous les publics.

L'accueil, l'aide, la pause, le sac, l'atelier, la carte et les réglages donnent accès aux actions par boutons et au clavier. Le guidage commence par l'entrepôt pour agrandir le stock, puis le garage pour rétablir l'électricité. Un repère et la carte indiquent la destination. Les objectifs tiennent compte des matériaux déjà dans le sac : une fois la récolte suffisante, ils ramènent au dépôt, puis à l'action de construction. Si des ingrédients manquent, ils visent un lieu qui en contient encore.

Le sac porte 18 unités de poids ; le stock passe de 24 à 48 avec l'étagère. Les ressources déposées peuvent être reprises près du stock. Cette capacité laisse préparer une sortie tout en conservant un choix de transport. Les options de texte, de son et de caméra apportent du confort ; leur accessibilité réelle reste à observer avec des joueurs.

## Systèmes qui créent les décisions

| Système réalisé | Opportunité et coût | Conséquence compréhensible |
| --- | --- | --- |
| Récupérateur | Produit 1 eau par jour clair, 3 sous la pluie, 4 sous l'orage | Garder une réserve pour les jours secs et libérer du stock |
| Potager | Consomme 1 eau du stock pour produire 2 nourritures par jour | Arbitrer entre boire, cultiver et échanger ; la production attend si le stock est plein |
| Comptoir | Marchand présent les jours pairs ; deux échanges par offre et par visite | Eau et nourriture deviennent ferraille, bois, câble ou carburant ; garder de quoi vivre |
| Générateur | Lumière contre 1 carburant par nuit et bruit croissant | L'éteindre réduit la pression ; eau et potager fonctionnent sans électricité |
| Défense | Barricades à trois points, réparation contre bois ; veille du joueur contre une nourriture par nuit | Préparer l'intrusion annoncée ou accepter une perte de réserves et éventuellement de santé |
| Graine et persistance | Butin et météo varient entre parties, restent reproductibles après chargement | Les lieux vidés le restent ; recharger ne renouvelle pas une offre épuisée |

Les intrusions sont actuellement des événements résolus au passage de nuit. Leur force est annoncée ; la garde et les barricades amortissent l'intrusion avant qu'elle affecte les réserves non protégées. Aucun ennemi ne se déplace ni ne combat dans la scène. La veille correspond à une action du joueur ; elle ne représente pas un survivant recruté. Le marchand fournit un service de troc récurrent, sans vie autonome simulée.

## Décisions inspirées de `jeux2.txt`

La transformation visible de la station, les ressources à plusieurs usages, les besoins concurrents, le bruit du générateur et le passage de collecte manuelle à production traduisent les boucles proposées. La tranche actuelle relie ces idées avec six ressources et cinq lieux. Ajouter une ressource devra introduire un usage ou un arbitrage compréhensible.

La météo et le commerce créent des occasions de planifier. La menace annoncée donne une réponse possible avant une perte. Le sac agrandi et le temps choisi par le joueur limitent les trajets imposés et la pression pendant l'apprentissage. Les prochaines améliorations doivent renforcer ces choix ou corriger un obstacle observé.

## Hypothèse décisive

Dans une séance proposée de 20 à 30 minutes sans tutoriel oral, observer si un nouveau joueur démarre depuis le lanceur, suit son premier objectif, dépose son butin, construit l'étagère et comprend comment obtenir de l'eau. Lui demander d'expliquer son prochain choix : réserve, construction, échange ou défense. Ce format est un protocole d'observation proposé, pas une durée de jeu déjà mesurée.

S'il se perd, améliorer le guidage et les actions. S'il comprend les règles mais ne voit aucun choix intéressant, revoir les coûts et conséquences avant d'ajouter des lieux. Le [protocole joueur](knowledge/player-observation.md) détaille les observations attendues.

Les tests techniques vérifient notamment un chemin de construction sur 32 graines et un cycle de 24 jours simulés avec production, consommation et commerce. Ce sont des scénarios synthétiques ; ils ne mesurent ni le plaisir, ni la rejouabilité, ni des dizaines d'heures d'intérêt. Aucun essai avec des joueurs n'a encore validé ces bénéfices.

## Principes de progression

| Palier | Capacité débloquée | Statut |
| --- | --- | --- |
| Ruine | Fouille, sac, stockage, nourriture et eau | Réalisé |
| Refuge | Étagère, barricades, guidage et accès aux réserves | Réalisé |
| Avant-poste | Générateur, lumière, carburant, bruit et défense annoncée | Réalisé ; résolution nocturne abstraite |
| Refuge autonome | Eau, potager, comptoir et troc récurrent | Réalisé ; décisions et intérêt à observer |
| Garage mobile | Réparation, véhicule pilotable et coffre utile | Différé |
| Communauté | Survivants recrutés, travail, besoins et délégation | Différé |
| Réseau régional | Expéditions, convois, automatisation et logistique entre lieux | Différé |

La progression privilégie une **nouvelle capacité** à un bonus chiffré. Les véhicules devront modifier le transport ; les survivants devront rendre une tâche délégable ; les menaces physiques devront permettre de repérer, éviter ou préparer le danger. Leurs critères sont détaillés dans la [roadmap](ROADMAP.md).

## Cadre de la première zone

Station, route, parking, boutique, garage, pompes, garage voisin, entrepôt, maison, cuve et bosquet. La géométrie est créée avec des primitives Godot pour garder un style cohérent et un chargement léger ; deux modèles d'arbres Polybuild sont réutilisés. Étagère, équipements, marchand présent et état des barricades rendent la progression visible. Des véhicules de décor ne constituent pas encore un système de conduite.

## Référence

Le framework fourni inspire les boucles, les interactions et les compromis ; il constitue une source de conception. `jeux2.txt` enrichit la direction station-service. La tranche actuelle réalise les systèmes décrits ici ; véhicules, combat, hordes et PNJ autonomes restent à concevoir et vérifier progressivement.
