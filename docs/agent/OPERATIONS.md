# Faire vivre le développement de Last Outpost

Ce suivi sert pendant une session de travail autorisée. Il n'installe pas de service IA en arrière-plan. Le socle gouverné reste dans `AGENTS.md`, `AGENT_SYSTEM.md` et `reference/` ; les connaissances et procédures ci-dessous ne changent pas ses permissions.

## Entrées de travail

| Besoin | Point d'entrée | Résultat attendu |
| --- | --- | --- |
| Reprendre le projet | [PROJECT](PROJECT.md), puis [roadmap](../ROADMAP.md) | État réel, prochain jalon et limites connues |
| Développer un choix jouable | [$last-outpost-feature](../../.agents/skills/last-outpost-feature/SKILL.md) | Règle, présentation, sauvegarde et parcours cohérents |
| Corriger un défaut | [$last-outpost-regression](../../.agents/skills/last-outpost-regression/SKILL.md), [BUGS](BUGS.json) | Reproduction, correction et preuve conservées |
| Préparer un jeu facile à lancer | [$last-outpost-release](../../.agents/skills/last-outpost-release/SKILL.md) | Artefacts locaux testés, instructions et limites réelles |
| Retrouver un apprentissage | [Index de connaissances](../knowledge/INDEX.md) | Source, portée, preuve et condition de réexamen |
| Vérifier le suivi | `powershell -NoProfile -File scripts/agent-check.ps1` | Liens locaux, format des skills et cohérence des bugs |

Ces rôles sont des responsabilités, pas des agents permanents. Si une session délègue du travail, attribuer des fichiers distincts et faire intégrer les preuves par un seul responsable de `PROJECT.md` et du registre pour éviter les écrasements.

## Boucle courte

Au début d'un jalon, choisir le blocage joueur ou l'hypothèse déterminante dans le suivi existant. Définir une observation qui dira si le résultat est meilleur. Pendant le travail, conserver l'identifiant d'un bug et le test qui le reproduit. En fin de jalon, exécuter les contrôles pertinents, mettre à jour le statut avec sa preuve et inscrire le changement livré dans [le changelog produit](../CHANGELOG.md).

Conserver une nouvelle note ou adapter un skill seulement si elle évite un défaut observé ou facilite une prochaine décision. [UPDATES](UPDATES.md) suit ces évolutions de l'écosystème et leurs essais. Une règle contredite doit être corrigée ou retirée ; aucune auto-note ne valide sa qualité.

## Registre bugs

`BUGS.json` est la source unique du statut des défauts. Chaque entrée garde `id`, `title`, `severity`, `status`, `reproduction`, `expected`, `actual`, `fix`, `evidence` et `updated`.

- `open` : défaut constaté, correction absente.
- `in_progress` : travail attribué et actif.
- `fixed_pending_verification` : changement écrit, preuve encore insuffisante.
- `verified` : correction observée dans un périmètre précisé par la preuve.
- `deferred` : raison et déclencheur de reprise documentés dans `fix`.

Une preuve possède date, commande/protocole, résultat et références locales. La fermeture décrit ce que le contrôle couvre, pas une garantie générale. Pour rouvrir un défaut, conserver les anciennes preuves et ajouter le nouveau résultat. Ne pas convertir une demande fonctionnelle en bug pour promettre une réussite.

`agent-check.ps1` est en lecture seule et peut être exécuté à chaque modification de ces fichiers. Il ne lance ni Godot ni IA, n'installe rien et ne transforme pas un test raté en correction automatique. Les commandes Godot et exports restent celles du projet ; l'activation d'une CI distante est distincte de sa rédaction.
