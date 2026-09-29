---
name: last-outpost-release
description: "Préparer et vérifier une livraison locale Windows et navigateur de Last Outpost avec ses lanceurs, tests et limites documentées. Ne publie pas automatiquement."
---

# Livraison locale Last Outpost

Travaille depuis la racine contenant `project.godot`. Lis `docs/agent/PROJECT.md`, `docs/TESTING.md` et les scripts réellement utilisés avant de les exécuter. Ce skill couvre la préparation locale ; un hébergement, push ou publication exige le mandat correspondant.

Lance `scripts/doctor.ps1 -RequireWeb -RequireWindows` pour les prérequis puis `scripts/validate.ps1`. Si le lanceur change et que la validation commune ne le couvre pas déjà, exécute `tests/launcher.ps1` : il vérifie résolution des exports, serveur HTTP, confinement des chemins, arrêt du port et chemin avec espaces. Conserve les erreurs et les marqueurs des tests ; ne remplace pas un contrôle manquant par une case cochée. `scripts/agent-check.ps1` vérifie la cohérence du suivi, sans tester le jeu.

Construis les artefacts avec `scripts/export-web.ps1` et `scripts/export-windows.ps1`. Vérifie le contenu exporté : le catalogue JSON et les ressources chargées dynamiquement doivent être inclus. Une fois **les deux exports construits depuis le même état du code**, exécute `scripts/build-launcher.ps1 -Package` pour produire l'archive complète Windows/Web avec son lanceur. Ne réutilise pas silencieusement un ancien export de l'autre plateforme. Teste le lanceur et l'exécutable depuis ce dossier extrait extérieur au projet, avec un chemin comportant des espaces si le lanceur change. Utilise une sauvegarde de test et préserve celle du joueur.

Pour le Web, sers uniquement le dossier d'export sur l'interface locale. Attends le véritable chargement du moteur, inspecte erreurs console/réseau puis observe au moins une action qui change le jeu. Vérifie la sauvegarde avec un état reconnaissable différent du départ : sauvegarder, recharger, Continuer, comparer les champs modifiés (par exemple jour, besoins ou inventaire). Le seul retour du menu ou l'absence d'erreur JavaScript ne prouve pas la persistance (LO-009). Le parcours reproductible actuel est `tests/web_journey.json`, exécuté par `tests/web_smoke.py` sur le lanceur extrait ; ses assertions de stockage complètent l'inspection des captures. Une réponse HTTP 200, un canvas présent ou une capture du splash ne suffisent pas. `docs/knowledge/godot-runtime.md` précise la limite observée du temps virtuel et de la persistance navigateur.

Si le parcours d'accueil, pause, options ou reprise a changé, teste une entrée clavier et une entrée souris dans l'interface et le retour au monde. Un raccourci saisi dans un menu ne doit pas simultanément consommer une ressource ou avancer le temps.

Relie chaque artefact livré à ses vérifications réelles dans `docs/CHANGELOG.md` et `docs/agent/PROJECT.md`. N'annonce pas une CI exécutée, une publication, un support mobile, des performances minimales ou une durée de jeu sans observation correspondante. Arrête les seuls serveurs et processus de test attribuables à cette livraison.
