# Point de reprise — Last Outpost

**29 septembre 2026 — livraison locale vérifiée.** Le socle de projet 0.4.0 est conservé ; les dernières instructions Software Engineering fournies par l'utilisateur s'appliquent également. Aucun fichier du socle gouverné n'a été modifié par cette intervention.

## Direction et état réel

Le mandat poursuit `jeux2.txt` : jeu de survie, reconstruction et gestion post-apocalyptiques, parcours accessible, launcher simple et écosystème IA. `scenes/station.tscn` est la scène principale ; `scenes/main.tscn` conserve l'ancien prototype de colonie.

La version livrée ajoute accueil, guide, pause, carte, sac, atelier, grands textes, volume et modes Découverte/Survie. Les objectifs guident la collecte et le retour au stock. Eau, potager, commerce, météo, bruit, menace annoncée et défense forment la boucle du refuge productif. Le temps avance après confirmation de la nuit. Les voitures restent des décors ; conduite, combat physique, hordes et survivants autonomes restent différés. Aucun essai humain prolongé ne valide encore la durée de vie ou le plaisir.

Sauvegarde v2 avec migration v1, copies de secours, validation et préservation de la dernière partie vivante. Windows utilise le fichier Godot ; Web utilise un petit JSON synchrone dans localStorage, avec reprise des anciens fichiers Web quand aucune clé n'existe. Les deux plateformes conservent leurs parties séparément.

## Livrables et preuves finales

- `Jouer.cmd` ouvre `build/LastOutpostLauncher.exe`. L'archive `build/LastOutpost-Complet-Windows-Web.zip` contient launcher, Windows, Web et notices. Extraire tout puis ouvrir le launcher ; le garder ouvert pour jouer dans le navigateur. Aucun hébergement public.
- Les deux exports ont été reconstruits après les derniers correctifs. Archive finale : 48859232 octets ; SHA-256 `20FDD2DE5805DEF5872FBB349E8DB8B0D1C0984A8A32A58915E46754B26AACF1`.
- `scripts/validate.ps1` : code 0, PLAYTEST/STATION/PROGRESSION/UX/AGENT CHECK OK. La progression couvre 32 graines et 24 jours synthétiques. **62 contrôles UX/sauvegardes** couvrent entrées, pause, reprise, boutons de retrait/consommation, guidage, erreurs, backup, caméra et limites. Trace `build/validation-final.log`.
- `tests/launcher.ps1` : code 0 ; exports, chemins avec espaces, HTTP/WASM, confinement et arrêt du serveur. Launcher inspecté visuellement depuis archive extraite. Origine Web stable : `127.0.0.1:18747`.
- Natif final extrait hors dépôt : démarrage headless code 0, stderr vide, empreinte identique au build. Rendu du menu natif et du launcher inspecté ; traces `build/qa-verified/` et `build/qa-release-final/`. Notice ASCII et licences vérifiées.
- Chrome réel depuis l'archive extraite : `tests/web_smoke.py --steps tests/web_journey.json --output build/web-release-save-final`, code 0. Accueil, démarrage, marche, carte, nuit, sac, sauvegarde, reload et Continuer exercés. Trois assertions conservent jour 2/faim 71/soif 68 ; la capture après reprise confirme ces valeurs et la position. Aucune erreur console/réseau, serveur arrêté.
- Le contrôle structurel vérifie trois skills et neuf bugs. Son auto-test a accepté le cas nominal et refusé preuve absente, clôture injustifiée, doublon et JSON invalide.

Le détail des défauts et des essais contradictoires reste dans [BUGS](BUGS.json). LO-009 avait repris J2 puis J1 lors d'essais successifs malgré runtime PASS ; cette observation a déclenché correction et vérification de l'état effectivement repris. Les cas de health mal typé et de backup corrompu ont échoué avant correction et passent maintenant. Ne pas effacer ces contre-preuves ni attribuer sans preuve la cause exacte à l'asynchronisme moteur.

## Écosystème et limites

| Capacité | Statut actuel |
| --- | --- |
| Règles, UX et sauvegardes | Vérifiées techniquement dans les scénarios décrits |
| Launcher et exports locaux | Vérifiés sur Windows et Chrome local |
| Trois skills de projet | Adoptés et utilisés par lecture explicite ; découverte native non observée |
| Connaissances, bugs et journal | En place et contrôlés par `scripts/agent-check.ps1` |
| CI et tâches VS Code | Préparées ; exécution distante/dans l'éditeur non observée |
| Mobile, manette, autres navigateurs, PC faible | Non validés |
| Service IA permanent | Aucun installé ; procédures actives pendant les sessions autorisées |
| Publication | Aucun push ni hébergement effectué |

## Reprise utile

La branche initiale est `main` à `1cce5fe`. Beaucoup de fichiers restent non suivis et README modifié ; aucun commit n'a été créé. Relire `git status --short` avant les prochaines écritures. Les données personnelles et textes fournis restent hors dépôt ; les tests utilisent des sauvegardes isolées. Les exports et traces sont ignorés par Git et doivent être reconstruits ailleurs. Godot 4.7.2 portable et ses modèles correspondants sont disponibles sur cette machine.

Le jalon courant est livré. La prochaine observation utile est un nouveau joueur suivant son premier trajet, construisant l'étagère et reprenant sa partie sans aide orale. Le [protocole proposé](../knowledge/player-observation.md) distingue cet essai des simulations. Corriger les blocages observés avant d'étendre les systèmes. Aucun budget chiffré ni ordonnanceur permanent n'a été fourni.

Entrées : [conception](../GAME_DESIGN.md), [roadmap](../ROADMAP.md), [tests](../TESTING.md), [changements](../CHANGELOG.md), [opérations](OPERATIONS.md), [évolutions](UPDATES.md), [connaissances](../knowledge/INDEX.md).

## Ajout du ciel — 29 septembre 2026

Sky procédural et couche de nuages volumétriques animés, shader Compatibility et bruit original. Couverture/teinte liées à la météo. Trois météos inspectées sur le rendu natif. Validation commune PASS62 ; exports reconstruits, natif rendu depuis archive extraite code0, Chrome avec nuit et reprise PASS (build/web-sky/report.json et capture10 relue). Aucun changement de sauvegarde ou de règles. Performances sur PC faible non mesurées, pas d'ombres nuageuses au sol. Voir ASSETS et CHANGELOG.
