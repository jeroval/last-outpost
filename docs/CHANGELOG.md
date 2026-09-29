# Journal des changements

## 29 septembre 2026 — ciel et nuages volumétriques

- Ciel procédural : horizon, dégradé et soleil aligné avec la lumière du monde.
- Nuages en volume par shader Sky, animés par le vent, éclairage approché et couverture variant avec Clair/Pluie/Orage. Bruit original généré localement, sans asset externe.
- Compatibility conservé pour WebGL 2. Marching borné à 20 pas, arrêt anticipé et cubemap simplifiée ; mipmaps et décalage spatial des échantillons réduisent les bandes lointaines observées au premier rendu.
- Validation commune passée (62 contrôles UX), trois météos inspectées en rendu natif. Exports Windows/Web et archive reconstruits, démarrage natif rendu code 0 depuis archive extraite. Chrome : parcours avec nuit et reprise, trois assertions de persistance, aucune erreur console/réseau ; capture finale inspectée. Traces `build/validation-sky.log`, `build/web-sky/`, `build/sky-native-*.log`.
- Limites : pas d'ombres nuageuses au sol, pas de FogVolumes Forward+, performances sur PC faible non mesurées.

Archive : SHA-256 `20FDD2DE5805DEF5872FBB349E8DB8B0D1C0984A8A32A58915E46754B26AACF1`. [Aperçu et fonctionnement](ASSETS.md).

## 29 septembre 2026 — refuge productif et lancement simplifié

### Jeu et parcours

- Accueil, choix Découverte/Survie, tutoriel, pause, aide, carte avec destination, sac et atelier. Volume et grands textes configurables ; clavier et boutons visibles.
- Objectifs tenant compte du sac et du stock, repères 3D et distance. Premier trajet vers l'entrepôt puis dépôt et étagère.
- Récupérateur d'eau, potager, comptoir, marchand récurrent et troc limité par visite. Préparation de nuit avec météo et menace annoncées, garde, usure et réparation des barricades.
- Sac de 18 unités, stock de 24 puis 48, retrait des consommables déposés. Journaux de nuit explicitant besoins, production et événements.
- Décor harmonisé, bâtiments accessibles, équipements visibles, personnage animé, pluie et sons procéduraux. Caméra protégée des obstacles et joueur borné au terrain.
- Sauvegarde v2 avec migration v1, validation avant chargement, copie de secours et préservation de la dernière partie vivante. Après reprise d'une copie de secours, le primaire corrompu ne l'écrase pas.
- Persistance Web du petit JSON par stockage navigateur synchrone, avec relecture, copie et erreur visible en cas de refus. Les anciens fichiers Web restent chargeables pour migration. Une reprise intermittente de J1 après sauvegarde de J2 a motivé cette correction ; la cause exacte dans l'ancienne synchronisation n'est pas établie.

### Livraison locale

`Jouer.cmd` ouvre le launcher ; l'archive `build/LastOutpost-Complet-Windows-Web.zip` contient le même launcher, Windows, Web et les notices. Extraire tout puis ouvrir `LastOutpostLauncher.exe`. Le serveur navigateur reste local, sur une origine stable, et s'arrête avec le launcher. Aucun hébergement public effectué.

SHA-256 de l'archive livrée : `7EEDA2FCC31D2FC4F343894488CB72C26A38768749B132FD479C2A030C123566`.

### Vérifications exécutées

- `scripts/validate.ps1` : code 0, quatre suites Godot passées, dont 32 graines et 24 jours synthétiques de progression, **62 contrôles UX/sauvegardes**, puis contrôle du suivi agentique.
- `tests/launcher.ps1` : code 0 ; chemins avec espaces, détection des exports, HTTP/WebAssembly, refus des accès hors dossier et arrêt du serveur. Launcher et menu natif inspectés visuellement hors dépôt.
- Deux exports reconstruits après les corrections ; archive finale extraite hors dépôt. Exécutable natif final démarré en headless, code 0 et stderr vide ; empreinte identique à celle du build.
- Chrome réel via `tests/web_smoke.py --steps tests/web_journey.json` depuis le launcher extrait : accueil, démarrage, déplacement, carte, nuit, inventaire, sauvegarde, reload et Continuer. Trois assertions vérifient J2/faim71/soif68 avant et après reload puis après reprise ; la capture du jeu chargé confirme ces valeurs. Aucune erreur console/réseau ; serveur de test arrêté.
- Rendu atelier et carte relu à 1440×900, dont grands textes. Les essais antérieurs ayant révélé des défauts restent dans le registre ; un rapport runtime réussi n'a pas suffi à clôturer la persistance.

Traces locales ignorées par Git : `build/validation-final.log`, `build/web-release-save-final/`, `build/qa-verified/`, `build/qa-release-final/`. Le protocole reproductible est conservé dans `tests/` et [TESTING.md](TESTING.md).

### Écosystème

Trois skills locaux, une base de connaissances sourcée, un registre de bugs avec preuves, un journal d'évolution et un contrôle de cohérence exécutable. Le validateur des skills, le contrôle du suivi et ses cinq scénarios de non-régression ont été exécutés. Les procédures fonctionnent durant les sessions autorisées ; aucun agent permanent n'a été installé. Détails dans [agent/UPDATES.md](agent/UPDATES.md).

### Limites

Version jouable enrichie, sans validation de dizaines d'heures de plaisir ni playtest humain prolongé. Véhicules pilotables, combat physique, hordes et survivants autonomes restent différés. Mobile, manette, autres navigateurs et performance sur machines faibles ne sont pas validés. La CI est préparée, sans exécution distante revendiquée.

## 29 septembre 2026 — première station

- Scène principale de station-service en troisième personne ; ancien mode colonie conservé dans `scenes/main.tscn`.
- Catalogue JSON, fouille limitée, inventaire, dépôt, étagère, barricade, générateur, besoins, objectif de restauration et sauvegarde versionnée.
- Première boucle testée et premiers exports Web/Windows produits ; repris et enrichis par la livraison ci-dessus.
