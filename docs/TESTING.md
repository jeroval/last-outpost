# Vérification

## Contrôles reproductibles

Sous Windows, `scripts/doctor.ps1` vérifie Godot 4.7.2, les fichiers indispensables et les modèles d'export demandés. `scripts/validate.ps1` importe puis exécute les quatre suites ci-dessous et `agent-check.ps1`. Un code de sortie nul ne suffit pas : le runner refuse également les erreurs Godot et l'absence du marqueur attendu.

| Suite | Comportement contrôlé |
| --- | --- |
| `tests/smoke.gd` | Ancienne colonie : récolte, abri, météo, pénurie, victoire |
| `tests/station_smoke.gd` | Catalogue, poids, fouille, dépôt, constructions, énergie, besoins, sauvegarde, scène |
| `tests/progression_smoke.gd` | Retraits conservatifs, objectifs tenant compte du sac, 32 graines permettant les améliorations, 24 jours synthétiques de production/troc, quotas, menaces, défense, migration et rejets atomiques |
| `tests/ux_smoke.gd` | 62 contrôles : accueil, blocage des commandes dans les menus, mouvement, pause, Tab, confort, reprise, copie de secours, échec d'écriture, limites et caméra |
| `tests/launcher.ps1` | Dossiers avec espaces, exports absents, HTTP/MIME WebAssembly, refus de traversal/méthodes/hôtes externes, arrêt du serveur |
| `scripts/agent-check-selftest.ps1` | 5 cas du contrôleur agentique : nominal, preuve absente, statut injustifié, identifiant dupliqué, JSON invalide |

Les tests de sauvegarde utilisent des fichiers isolés. Le parcours navigateur utilise un profil Chrome temporaire ; les sauvegardes personnelles sont préservées. Les simulations ne mesurent ni le plaisir ni une durée de jeu humaine.

## Exports et parcours réel

Construire Web puis Windows avec `scripts/export-web.ps1` et `scripts/export-windows.ps1`, puis seulement `scripts/build-launcher.ps1 -Package`. `python tests/web_smoke.py` lance le serveur du launcher, attend le chargement réel de Godot, recueille console/réseau et capture le menu. `--steps tests/web_journey.json` rejoue le parcours observé à 1440×900 et vérifie les valeurs persistées avant/après rechargement puis Continuer. Les captures doivent être relues pour confirmer aussi l'état réellement chargé ; le script ne comprend pas sémantiquement les écrans.

Parcours utile : accueil → Découverte → tutoriel → entrepôt → stock → étagère. Vérifier ensuite retrait/consommation, carte, préparation de nuit et compte rendu, sauvegarde, recharge du navigateur et Continuer. Au moins une action doit modifier le jeu. Extraire également l'archive complète dans un chemin avec espaces et lancer l'exécutable exporté sans le dépôt.

## Limites de validation

Les résultats datés sont dans `CHANGELOG.md` et `agent/PROJECT.md`. La revue visuelle couvre la résolution de référence et les grands textes. Accessibilité avec lecteur d'écran, petits écrans/tactile, manette, autres navigateurs, performances sur PC faible et qualité sonore subjective restent à vérifier. Aucun playtest humain prolongé n'est déclaré. Une capture automatisée interrompue immédiatement peut laisser des objets audio à la fermeture ; les tests fonctionnels attendent leur libération.
