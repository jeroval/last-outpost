# Architecture

`project.godot` démarre `scenes/station.tscn`. `game/station_game.gd` assemble les composants et traduit les touches en actions ; `game/player/third_person_controller.gd` gère le déplacement et la caméra ; `game/world/station_world.gd` construit la scène 3D et synchronise son aspect avec l'état. La logique de jeu persistante est dans `game/core/station_state.gd`. `game/core/content_catalog.gd` lit `data/content.json` (objets, recettes, lieux et tables de butin).

La séparation **contenu → règles → présentation** évite une classe par objet et permet d'ajouter des lieux ou des recettes sans modifier l'inventaire. L'export inclut explicitement `data/*.json`. Les actions actuelles passent par `station_game.gd` ; lorsqu'un second type de construction ou d'équipement demandera les mêmes opérations, extraire alors un système commun plutôt que créer des sous-systèmes vides.

`game/ui/station_hud.gd` affiche accueil, pause et panneaux accessibles au clavier ; `region_map.gd` dessine la carte interactive. Les actions émettent un signal vers le contrôleur de session. Les mouvements sont suspendus pendant les menus. Le temps de simulation avance seulement après confirmation de la nuit. `game/audio/soundscape.gd` synthétise les sons locaux.

La sauvegarde `user://last_outpost_station_v1.json` conserve son nom pour retrouver les anciennes parties. Son contenu est maintenant en **version 2**, avec migration de la version 1 : inventaires, butins, constructions, besoins, jour, position, mode, météo, commerce et défense. `game/save/save_service.gd` écrit un fichier temporaire, conserve une copie `.bak` et remplace le fichier principal. Le chargement valide les données avant mutation et essaie la copie si nécessaire. Une défaite n'écrase pas la dernière sauvegarde vivante. Les réglages sont dans `last_outpost_settings.cfg`.

Sur le Web, le petit JSON de progression est écrit de manière synchrone dans `localStorage`, avec copie de secours et vérification de lecture. Le service signale les refus ou quotas du navigateur. Il retrouve les sauvegardes des anciens exports dans `user://` quand aucune clé de progression Web n'existe ; la prochaine sauvegarde les migre. Cette distinction évite d'annoncer une écriture terminée alors que le système de fichiers Web attend encore sa synchronisation. Les réglages de confort restent dans le fichier Godot. La persistance dépend du navigateur et de son origine ; effacer les données du site efface la partie.

Les coûts et offres sont dans le catalogue ; la production, les quotas de visite et les événements déterministes selon la graine sont dans l'état. L'interface annonce la prochaine menace avant consommation des réserves. Le monde synchronise l'état visuel après chaque action significative.

`tools/launcher/Launcher.cs` est un lanceur Windows WinForms compilé avec le compilateur .NET Framework de Windows. Il lance le jeu natif ou sert les exports Web sur `127.0.0.1:18747`. Cette origine stable conserve les sauvegardes du navigateur entre lancements. Fermer le lanceur arrête son serveur ; aucun service permanent n'est installé. Les sauvegardes natives et navigateur sont distinctes.

`scenes/main.tscn` et `scripts/main.gd` sont le prototype de colonie conservé comme mode expérimental distinct. Ses règles ne sont pas mélangées à celles de la station.
