---
name: last-outpost-feature
description: "Développer une mécanique ou un parcours jouable de Last Outpost sous Godot, avec contenu, sauvegarde et interface cohérents. Pour une régression identifiée, utiliser le skill de régression."
---

# Une évolution jouable de Last Outpost

Travaille depuis la racine contenant `project.godot`. Ce skill est propre à ce dépôt ; il ne fournit pas de framework Godot général.

Lis `docs/agent/PROJECT.md`, puis les sections pertinentes de `docs/GAME_DESIGN.md` et `docs/ARCHITECTURE.md`. Reprends la demande et l'état actuel avant de choisir une nouvelle mécanique.

Décris le choix créé pour le joueur : opportunité, coût compréhensible, risque, conséquence observable et réponse possible. Une contrainte qui ajoute seulement des allers-retours doit être revue. Lie la mécanique à un objectif visible et à une action disponible au joueur ; ne livre pas seulement une donnée ou un bouton inactif.

Le catalogue est dans `data/content.json`, les règles persistantes dans `game/core/station_state.gd`, l'orchestration dans `game/station_game.gd`, l'interface dans `game/ui/station_hud.gd`, la représentation 3D dans `game/world/station_world.gd` et les écritures de sauvegarde dans `game/save/save_service.gd`. Lis les consommateurs affectés avant de modifier un contrat. Préserve le mode colonie distinct et utilise le renderer Compatibility prévu pour le navigateur.

Si l'état sauvegardé change, prends une sauvegarde de test antérieure et vérifie sa migration ou son rejet explicite sans écraser les données. Les menus doivent consommer leurs entrées avant que les actions du monde les reçoivent. Les particularités Web et les observations locales sont dans `docs/knowledge/godot-runtime.md`.

Valide la règle affectée avec un scénario concret, puis le parcours visible : découvrir l'objectif, agir, comprendre le résultat, sauvegarder et reprendre. `scripts/validate.ps1` couvre les tests existants ; il ne démontre pas le rendu ni le plaisir. Les contrôles d'export sont distincts et utiles si packaging, fichiers inclus ou cible Web changent.

Actualise le suivi existant : `docs/CHANGELOG.md` pour le changement livré, `docs/agent/BUGS.json` pour un défaut précis, `docs/agent/PROJECT.md` au jalon. Ajoute une connaissance ou modifie ce skill seulement si une observation nouvelle change utilement la prochaine action. Rapporte ce qui est jouable, testé et encore hypothétique ; n'estime pas des heures de plaisir depuis le nombre de systèmes.
