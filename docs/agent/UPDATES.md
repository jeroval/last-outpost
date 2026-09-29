# Évolutions de l'écosystème

Les changements du jeu sont dans [le changelog produit](../CHANGELOG.md). Ce journal suit uniquement les procédures, connaissances et contrôles de développement.

## 2026-09-29 — version locale 0.1

Mandat : l'utilisateur demande explicitement des skills, une base de connaissances, un suivi des corrections et une amélioration continue autour de Last Outpost. Le socle gouverné 0.4.0 est conservé.

Ajouts : trois skills de projet ciblant mécanique jouable, régression et livraison locale ; [registre des bugs](BUGS.json) ; [mode de fonctionnement](OPERATIONS.md) ; [base de connaissances](../knowledge/INDEX.md) distinguant sources, observations et hypothèses ; contrôle `scripts/agent-check.ps1`.

État initial : skills candidats en cours de validation ; découverte native du client non observée. Aucun ordonnanceur, service IA permanent, modèle externe, configuration globale ou publication n'est installé.

Contrôles exécutés le 29 septembre sous Windows/PowerShell :

| Contrôle | Résultat observé | Portée |
| --- | --- | --- |
| `python .../skill-creator/scripts/quick_validate.py` | Échec initial : module `yaml` absent dans le Python système | Dépendance du validateur, pas défaut des skills ; aucune installation globale effectuée |
| `uv run --no-project --cache-dir .godot/skill-validation-cache --with PyYAML==6.0.3 python .../quick_validate.py <skill>` pour chacun des trois candidats | `Skill is valid!`, code 0 trois fois | Frontmatter, noms et absence de scaffold ; [PyYAML 6.0.3](https://pypi.org/project/PyYAML/6.0.3/) isolé dans le cache local ignoré |
| `powershell -NoProfile -File scripts/agent-check.ps1 -SkillsPath docs/agent/candidates` | `AGENT CHECK OK`, code 0 | Trois skills, trois bugs, existence des destinations des liens locaux |
| `powershell -NoProfile -File scripts/agent-check-selftest.ps1` | `AGENT CHECK SELFTEST OK`, code 0 | Fixture valide acceptée ; preuve absente, clôture sans preuve pass, doublon et JSON invalide refusés avec code 1 ; fixture retirée |

Les essais d'usage métier sont distincts des contrôles de structure ci-dessus. Les candidats régression et livraison sont appliqués à LO-001 et à la livraison locale en cours ; résultats à consigner après observation. Le cas exclu de découverte est une correction typographique isolée : elle ne justifie aucun de ces trois workflows, ni lancement Godot, ni export.

Usage explicite du candidat livraison, précontrôle borné pendant le développement : `doctor.ps1 -RequireWeb -RequireWindows` a confirmé Godot `4.7.2.stable.official.ed1daf0bf` et ses deux modèles d'export. Le contrôle du suivi exécuté immédiatement après a refusé un lien vers `game/core/station_state.gd`, temporairement absent pendant l'édition concurrente. Résultat conservé comme échec de disponibilité à cet instant ; nouvelle validation attendue après stabilisation du fichier. Aucun export ni réussite globale n'a été revendiqué depuis ces précontrôles.

Retour d'usage du développeur principal après lecture des candidats feature/release : le contrôle des touches de jeu dans les menus est utilisé pour les essais d'accueil et de pause. Un manque concret du skill release a été corrigé : générer `scripts/build-launcher.ps1 -Package` seulement après les deux exports du même état du code, puis tester cette archive extraite. Cette évolution vient du parcours de livraison réel ; les résultats de son exécution restent à inscrire.

Contre-lecture par le développement du lanceur : ajout de `tests/launcher.ps1` au skill release lorsque le lanceur change et que la validation commune ne l'inclut pas. Ce contrôle vérifie des contrats HTTP et de chemins que les tests Godot ne couvrent pas. Le candidat régression est appliqué à LO-001 avec dépôt → retrait → consommation, conservation des objets et capacité ; l'ancien défaut est établi par lecture, sans prétendre à une exécution de l'ancienne version.

Essai métier du skill régression exécuté : `tests/progression_smoke.gd` a produit `PROGRESSION OK`, code 0 sans `SCRIPT ERROR`. Le cas LO-001 vérifie les réserves consommables après retrait et les limites de transport. La preuve et sa limite UI sont conservées dans [BUGS](BUGS.json). L'agent chargé de la correction a suivi le skill par lecture explicite et distingué reproduction par lecture, contrôle technique et parcours utilisateur encore à vérifier.

Adoption locale des trois procédures dans `.agents/skills/` après validation de structure et ces usages ciblés, sous le mandat explicite utilisateur. L'essai feature/release se poursuit dans la livraison en cours ; la découverte par le sélecteur natif reste à observer. La mise en place ne démontre pas un gain durable de fiabilité : il faudra observer les régressions et les interventions évitées au fil des prochaines tâches.

Vérification à destination : le validateur officiel a de nouveau rendu `Skill is valid!` pour chacun des trois dossiers `.agents/skills/`, puis `agent-check.ps1` a rendu `AGENT CHECK OK : 3 skills, 5 bugs`. Les liens de [OPERATIONS](OPERATIONS.md) pointent vers ces emplacements. L'observation sur les nombres rechargés via JSON a été ajoutée à la base de connaissances avec son test, sans changer le socle ni créer une règle générale hors contexte.

Premier cycle supplémentaire observé, LO-006 : le guidage pouvait ignorer le sac et conduire à un lieu vidé. Le test `_test_guidance` a été ajouté avant correction ; six assertions ont échoué (code 1). Après correction des destinations et du calcul des matériaux manquants, la même commande a produit `PROGRESSION OK` (code 0). Les deux résultats sont conservés dans le registre, avec la limite du rendu UI. Cet essai montre le fonctionnement du suivi sur un défaut réel ; il ne mesure pas encore un gain global de l'organisation.

Intégration à la validation commune : `scripts/validate.ps1` appelle désormais `agent-check.ps1` après quatre suites Godot et contrôle les messages d'erreur et marqueurs finaux. L'agent principal l'a exécuté avec code 0 et tous les marqueurs (`PLAYTEST`, `STATION`, `PROGRESSION`, `UX`, `AGENT CHECK`). Le skill feature a été appliqué aux entrées du menu : les contrôles vérifient explicitement que N/1/2 n'agissent pas derrière l'accueil et que le mouvement est bloqué au guide puis réactivé. Cela constitue un usage observé, distinct d'une découverte native du skill.

Usage release sur archive extraite : le test Web a passé sans erreur, puis l'inspection des captures a trouvé LO-007, un compte rendu nocturne sans conséquences lisibles. Le défaut est enregistré malgré le succès du script et entraîne correction/reconstruction. Cette observation confirme l'utilité de distinguer réussite technique et inspection du résultat ; la découverte native des skills et le bénéfice chez des joueurs restent non observés.

Complément d'intégration LO-001/LO-006 : `tests/ux_smoke.gd` passe désormais 56 contrôles, dont les signaux des boutons de retrait/consommation et le guidage après fouille. La première assertion du HUD attendait seulement une frame et précédait son rafraîchissement ; le test attend maintenant deux frames, sans changer le jeu ni affaiblir l'attendu. Les défauts sont vérifiés dans cette portée ; les clics physiques et la livraison finale restent des observations distinctes.

Contre-preuve de livraison, LO-009 : un essai Web a repris le jour 2 ; un suivant est revenu au jour 1, tous deux sans erreur runtime. Le registre conserve le succès et l'échec, et la livraison reste ouverte. Le skill release demande désormais de comparer explicitement jour/besoins/inventaire après sauvegarde, reload et Continuer ; un menu réapparu et un rapport sans erreur ne suffisent pas. LO-007 est corrigé visuellement et LO-008 conserve la correction d'encodage de la notice Windows. La cause de LO-009 est encore en diagnostic.

Recherche ciblée pour LO-009 : les sources MDN et le code Godot 4.7.2 ont été lus, puis synthétisés dans [la note d'exécution](../knowledge/godot-runtime.md). L'asynchronisme du filesystem Web est un fait de référence, sans être présenté comme la cause démontrée de l'incident. La correction adopte un petit JSON Web synchrone avec secours/relecture. Les nouveaux cas de récupération ont d'abord échoué sur deux défauts du service partagé ; ils restent dans LO-009 et la preuve finale est encore attendue.

Réexamen : modifier une procédure après un défaut réel qu'elle n'évite pas, un changement Godot/client qui invalide ses commandes ou une simplification démontrée. Pas d'évolution automatique du socle ni d'ajout de règles pour remplir le journal.

## Clôture de la livraison locale

La correction finale de LO-009 passe la validation commune (62 contrôles UX, quatre suites Godot) et le parcours Web avec trois assertions explicites de persistance. La capture du jeu repris confirme J2/faim71/soif68 ; l'archive reconstruite est testée hors dépôt. Les essais contradictoires restent dans BUGS.json. Le registre compte neuf défauts vérifiés dans leur portée, sans promesse de validation exhaustive. PROJECT et CHANGELOG portent l'état livré. Le prochain apprentissage attendu vient d'un essai humain du parcours, sans ajout de procédure par anticipation.
