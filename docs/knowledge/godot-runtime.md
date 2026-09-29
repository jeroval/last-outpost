# Godot : exécution, sauvegarde et entrées

Périmètre : Godot 4.7.2 stable, Windows PowerShell et export Web Compatibility de Last Outpost. Sources consultées le 29 septembre 2026. Les URL `stable` évoluent : revalider les passages lors d'une mise à jour moteur.

## Références officielles

- [Exporter pour le Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) : WebAssembly et WebGL 2 sont nécessaires ; le renderer Compatibility convient à cette cible. Le mode mono-thread évite les exigences d'isolation propres aux threads. Les navigateurs imposent une interaction utilisateur pour certaines fonctions audio/plein écran. La persistance `user://` dépend du stockage navigateur ; navigation privée et restrictions IndexedDB peuvent l'empêcher.
- [Sauvegarder une partie](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) : sérialiser l'état requis et reconstruire les données au chargement. Le format JSON n'est pas une validation des valeurs métier. Les invariants du jeu et les migrations appartiennent au projet.
- [Propagation des InputEvent](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html) : les événements passent par plusieurs étapes ; l'interface peut les consommer avant les actions non traitées. Tester la propagation évite qu'un clic de menu déclenche aussi une action dans le monde.

## Observations du projet

| Observation | Preuve et statut | Réponse utile | Limite |
| --- | --- | --- | --- |
| Les tests impriment leur marqueur final et le runner refuse erreurs Godot, mauvais code et marqueur absent. | [Validation commune](../../scripts/validate.ps1) exécutée avec succès le 29 septembre, [preuve](../agent/PROJECT.md) | Conserver les trois observations : sortie, code et marqueur. Un import sans erreur ne démontre pas le parcours. | Les tests headless ne prouvent ni rendu ni entrées physiques. |
| Un précédent chargement de script pouvait échouer sans que le code de sortie Godot suffise à détecter la panne. | Observation de session antérieure ; journal brut non conservé. Statut : à reproduire si le runner change. | Chercher `SCRIPT ERROR`/erreurs de parsing et exiger le marqueur de fin attendu. | Ne pas affirmer que tous les échecs Godot retournent zéro. |
| Une capture Web automatisée utilisant du temps virtuel est restée au splash ; une session navigateur réelle pilotée par Playwright a chargé la station et `N` a changé le jour. | Essai antérieur décrit dans [PROJECT](../agent/PROJECT.md), journaux temporaires non archivés. | Attendre un état jouable réel puis vérifier une action observable ; distinguer chargement lent et panne. | Cela ne prouve pas un défaut général de Playwright ou du moteur. Réessayer si le protocole change. |
| Le dépôt pouvait rendre nourriture/eau inaccessibles à la consommation car elle ne lisait que le sac. | [LO-001](../agent/BUGS.json), lecture initiale de `deposit()` et `consume()` | Tester ensemble dépôt, retrait/usage et capacité. | La correction et son résultat sont suivis dans le registre, source de vérité du statut. |
| L'aller-retour JSON a révélé une différence de type entre comptes entiers en mémoire et nombres rechargés ; comparer seulement deux dictionnaires mémoire l'aurait manquée. | Échec puis correction de normalisation rapportés pendant l'implémentation ; [test `_test_save`](../../tests/progression_smoke.gd) passé avec `PROGRESSION OK` le 29 septembre | Faire réellement `stringify` → `parse` → `restore`, vérifier les quantités et l'absence de mutation en cas de refus. | Observation Godot 4.7.2 sur ce schéma ; ne pas imposer une conversion arbitraire aux champs continus. |
| Deux essais Web ont donné des reprises contradictoires : jour 2 conservé une fois, puis retour au jour 1 malgré sauvegarde et aucune erreur runtime. Après correction, trois assertions de stockage et la capture de reprise confirment jour 2 / faim 71 / soif 68. | [LO-009](../agent/BUGS.json), [parcours Web](../../tests/web_journey.json) et captures inspectées par l'agent principal | Vérifier l'état repris, pas seulement le chargement du menu. Conserver succès et contre-preuve avant de clore avec les nouveaux résultats. | Vérifié sous Chrome local à origine constante ; cause exacte initiale non démontrée. |

## Contrats à préserver

Le chargement refusé doit laisser l'état vivant intact. Une sauvegarde d'une ancienne version doit être migrée explicitement ou rejetée avec un message compréhensible. Les sauvegardes de test doivent être séparées des données du joueur. Un nouveau champ JSON exige des valeurs par défaut ou une migration justifiée ; le numéro de version seul ne règle pas la compatibilité.

Une fenêtre de menu doit bloquer les actions du monde concernées, y compris les raccourcis. La vérification pertinente inclut le retour au monde après fermeture. Pour le navigateur, distinguer une sauvegarde chargée dans la session courante d'une persistance constatée après fermeture/réouverture.

## Persistance Web : diagnostic de LO-009

Sources consultées le 29 septembre 2026 : [MDN localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage), [MDN Web Storage](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API), [OS Web de Godot 4.7.2](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/os_web.cpp) et [pont JavaScript correspondant](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/js/libs/library_godot_os.js).

**Faits de référence.** Web Storage réalise ses lectures/écritures de manière synchrone et partage les données par origine. Un stockage volumineux peut bloquer l'interface ; une politique navigateur peut refuser la persistance. Dans le code moteur consulté, la fermeture d'un fichier persistant marque une synchronisation à effectuer ; la boucle Godot déclenche ensuite une opération JavaScript reposant sur une promesse. `force_fs_sync()` marque également cette demande et ne constitue pas un accusé de fin d'écriture dans ce code.

**Observation et incertitude.** Last Outpost a montré deux reprises contradictoires après reload. L'asynchronisme documenté motive de vérifier l'état après reprise ; il ne démontre pas à lui seul la cause exacte du retour au jour 1.

**Correction vérifiée dans le périmètre testé.** Le service utilise localStorage pour son petit JSON Web, avec copie de secours et relecture immédiate. Le chemin natif conserve FileAccess et les anciennes parties Web restent récupérables via `user://` quand aucune nouvelle clé n'existe. L'essai de la dernière archive sous Chrome a comparé jour/besoins avant reload, après reload et après Continuer ; les trois assertions passent et la capture confirme la reprise. Cela ne teste pas toutes les politiques de stockage ni tous les navigateurs. Les résultats exacts sont dans [LO-009](../agent/BUGS.json).

Les tests de récupération prouvent aussi qu'un primaire corrompu ne remplace pas une copie de secours valide lors de la prochaine sauvegarde et qu'un champ de mauvais type est rejeté sans erreur moteur. Ces cas ont échoué avant correction puis passé dans les 62 contrôles UX ; ils appartiennent au service partagé, pas à une propriété générale de localStorage.
