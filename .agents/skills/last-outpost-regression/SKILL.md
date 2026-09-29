---
name: last-outpost-regression
description: "Reproduire et corriger un bug de gameplay, sauvegarde ou interface de Last Outpost, puis relier la correction à une preuve dans le registre local."
---

# Régression Last Outpost

Travaille depuis la racine contenant `project.godot`. Consulte `docs/agent/BUGS.json` pour réutiliser un identifiant existant et `docs/agent/PROJECT.md` pour les commandes et limites réelles.

Reproduis un cas minimal avec état initial, actions, attendu et résultat. Sépare le défaut du jeu, celui du script de contrôle et celui de l'environnement. Une demande de nouvelle mécanique n'est pas automatiquement un bug ; une durée de jeu souhaitée reste une hypothèse produit.

Pour un défaut de règle, utilise `tests/station_smoke.gd`, `tests/progression_smoke.gd` et les méthodes de `game/core/station_state.gd`. Pour un défaut d'entrée ou d'écriture de sauvegarde, pars de `tests/ux_smoke.gd`, puis vérifie l'écran réel : un test appelant directement une méthode ne prouve pas que le bouton ou la touche l'atteint. Pour une sauvegarde, vérifie l'aller-retour et l'absence de mutation après un chargement rejeté. Utilise des données de test séparées de la sauvegarde du joueur.

Si l'ancien état est disponible et isolable, observe l'échec du scénario avant la correction. Préserve ce résultat ; n'affaiblis pas l'attendu pour obtenir un succès. Après correction, exécute le test concerné et les contrôles rendus nécessaires par les contrats modifiés. Examine les messages `SCRIPT ERROR` et les marqueurs finaux des tests : un code de sortie Godot seul n'est pas une preuve suffisante de parcours.

Renseigne `docs/agent/BUGS.json` : identifiant stable, reproduction, impact, correction, état et preuve datée. `fixed_pending_verification` signifie code modifié sans preuve suffisante ; `verified` exige une commande ou observation, son résultat et une référence locale. Une régression rouvre le même identifiant. Exécute `scripts/agent-check.ps1` après une modification du registre.

Termine avec le résultat observable et ses limites. Pour une panne récurrente, consulte `docs/knowledge/godot-runtime.md` avant de refaire un essai déjà invalidé ; une observation locale ne devient pas une interdiction générale.
