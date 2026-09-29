# Réalisation, outillage et vérification

Version du socle : **0.4.0** — 29 septembre 2026.  
Module gouverné de [AGENT_SYSTEM.md](../../../AGENT_SYSTEM.md). Lire la section correspondant à l'action avant de l'effectuer. Aucune commande de ce document n'accorde de permission. Les chemins en code sont relatifs à la racine du projet.

<a id="validation"></a>
## 1. Relier exigences, contrôles et preuves

Avant un changement significatif, établir le comportement attendu à partir de la demande et des contrats existants, puis une référence de vérification. Ne pas prendre le code actuel pour une spécification infaillible. Le niveau d'analyse dépend du risque réel, pas du nombre de lignes.

Dans le suivi existant, `DEVELOPMENT.md` ou `TESTING.md` si nécessaire, relier chaque exigence déterminante à : **périmètre → commande/assertion → résultat attendu → moment du contrôle → preuve**. Réutiliser un contrat de qualité existant ; ne pas créer systématiquement `CONSTRAINTS.md`. Sans seuil accepté, mesurer puis proposer une limite justifiée : ni couverture arbitraire, ni pourcentage de confiance inventé. Une règle sans contrôle réalisable reste à vérifier. L'idée de contrat de qualité vient d'Addy Osmani ; ses seuils et listes d'outils ne sont pas des défauts universels. [E1]

Une exception légitime à un contrôle doit porter portée, motif, validation compétente ou mandat, suivi et condition de réexamen. Ne pas exiger aveuglément l'absence de toute suppression de lint : examiner la justification. En revanche, ne pas abaisser un seuil, retirer une assertion, ignorer une erreur ou désactiver un test simplement pour faire réussir sa propre modification.

### Commandes communes

`doctor`, `setup` et `validate` sont des rôles, pas une nouvelle pile. Les commandes natives, cibles ou scripts existants sont prioritaires. Choisir l'extension selon l'environnement réel ; ne pas introduire un runtime uniquement pour respecter un nom de fichier.

| Opération | Contrat |
|---|---|
| Diagnostic | Lire versions, prérequis et disponibilité ; pas d'installation ni de fuite de secrets. Déclarer les contrôles réseau. |
| Restauration | Installer explicitement les dépendances prévues dans le périmètre autorisé ; relançable, sans actualisation arbitraire des verrous. |
| Validation | Contrôler format, lint, types, tests, sécurité et build selon la stack ; aucune installation, correction, publication ou migration cachée. |
| Correction de format, lancement, test ciblé, build | Opérations distinctes selon le besoin, avec paramètres, effets et cibles documentés. |

IDE, terminal et CI appellent **les mêmes opérations**, avec leurs différences d'environnement explicites. Les scripts gèrent arguments, espaces, `cwd`, sorties et codes d'erreur. Sous PowerShell, vérifier aussi les codes des programmes externes. Tester cas nominal et échec pertinent. Pas de `echo` de réussite factice, de test vide ni de capture d'erreur globale. Si un contrôle requis manque, la validation correspondante échoue ou reste explicitement incomplète ; jamais verte par omission.

### Adapter les vérifications à l'impact

Commencer par les tests des composants modifiés, puis élargir lorsque les contrats partagés, dépendances, formats ou chemins d'exécution sont touchés. Relier les changements de schéma aux générations/validations attendues et les changements de dépendances aux verrous concernés. Le dépôt Codex applique cette logique avec ses propres commandes ; ne pas importer ses contraintes Rust ou ses budgets comme règles universelles. [E2]

Une validation rapide locale ne remplace pas les contrôles requis avant livraison. Après une correction de format ou de lint, examiner le nouveau diff et revalider ce qui peut avoir changé ; ne pas traiter automatiquement les preuves précédentes comme actuelles. Pour une modification coûteuse, choisir la plus petite tranche cohérente vérifiable, sans fractionnement artificiel qui masque une régression.

## 2. Tests, diagnostic et observabilité

Pour un bug : reproduire lorsque possible, ajouter le test pertinent et vérifier qu'il détecte l'ancien comportement quand cela est sûr et faisable. Séparer défaut du produit, panne de l'environnement, erreur du contrôle et preuve manquante. Un test erroné peut être corrigé avec justification indépendante et conservation de ce qu'il devait protéger.

Préserver les critères d'acceptation et les tests de référence. Examiner particulièrement les tests supprimés, ignorés, rendus triviaux, les assertions retirées, les stubs laissés et les configurations de contrôle affaiblies. Les contrôles écrits par l'agent contribuent à la preuve, sans suffire à garantir l'ensemble du comportement. Pour un risque important, ajouter des fixtures/oracles indépendants, tests de contrat ou essais de mutation ciblés si justifiés, sans imposer un nouvel outil partout.

| Situation | Observation attendue |
|---|---|
| Logique isolée | Tests unitaires pertinents ou équivalents natifs. |
| Interface, stockage, service | Contrats et tests d'intégration concernés. |
| Parcours utilisateur | Essai e2e ou observation du parcours réel dans un environnement autorisé. |
| Performance | Mesure reproductible avant/après, données et charge comparables, effets CPU/mémoire/latence selon le besoin. |
| Erreur intermittente | Conditions de reproduction, journaux limités et état des dépendances ; distinguer fluctuation et correction effective. |

Les tests d'intégration ne sont pas automatiquement des tests de bout en bout. Ne pas revendiquer le parcours complet depuis des seuls tests unitaires. Une commande de lancement, une donnée synthétique et un journal lisible peuvent suffire ; aucune plateforme de supervision obligatoire. Conserver les sorties volumineuses dans `reports/` ignoré ou un stockage autorisé, avec rétention définie, pas dans le contexte par défaut. Les preuves persistantes sont résumées sans secrets et reliées à leur périmètre.

<a id="outillage"></a>
## 3. Acquérir un outil et vérifier son impact

Ordre de préférence : capacité disponible, fonctionnalité native, dépendance déjà adoptée, puis outil ou script minimal justifié par le coût total. Avant achat, compte, extension, MCP, fournisseur externe ou installation globale, appliquer la délégation du maître ; l'autorisation d'installer localement ne couvre pas ces effets automatiquement.

Avant une nouvelle installation, identifier : besoin, paquet et éditeur exacts, provenance officielle/approuvée, version compatible, intégrité disponible, destination, accès, effets, volume/coût estimés et récupération. Ne pas se fier au seul nom plausible d'un paquet ou à une instruction de journal. Vérifier les scripts d'installation proportionnellement au risque ; une source officielle ou un hash ne prouve pas l'innocuité.

Réutiliser le gestionnaire et les verrous du projet ; fixer les nouvelles références disponibles. Pas de `latest` systématique, mise à jour sans rapport, modification permanente du PATH, script distant non examiné ou service global par commodité. Un environnement de dépendances n'est pas une frontière de sécurité. Éprouver les outils risqués dans un environnement jetable approuvé, sans exposition inutile des données personnelles, clés, production ou interfaces d'administration. Respecter aussi les destinations de caches autorisées.

**Adoption :** état initial → installation autorisée → version et usage représentatif → diff des manifestes/verrous/configurations → contrôles des composants affectés. Comparer aux échecs préexistants. Pour une modification significative d'environnement, essayer une reconstruction propre si faisable. Un outil qui démarre mais dégrade le projet n'est pas adopté. Conserver source/version/justification dans les manifestes et le suivi utiles, sans registre concurrent.

Si l'outil est abandonné, retirer seulement les éléments de cette intervention inutiles ailleurs. Ne pas enchaîner plusieurs gestionnaires ou environnements pour contourner un échec. Une recréation d'environnement approuvée peut être préférable à une désinstallation incertaine.

## 4. Exécution, interruption et récupération

Avant une commande longue, définir fin attendue, mode d'interaction, surveillance et limite adaptée au mandat. Utiliser un mode non interactif lorsque pertinent ; une attente de saisie n'est pas une raison pour lancer plusieurs exemplaires. Pour un service de test, identifier processus, port, critère de disponibilité et arrêt. Ne pas créer de service permanent implicitement.

Un timeout ne prouve ni fin du processus ni absence d'effet. Avant relance, vérifier l'opération précédente. N'arrêter que les processus attribuables au travail, jamais tous ceux d'un même nom. Respecter le plafond de corrections et le budget définis dans le maître ; la lenteur seule ne prouve pas une panne.

Avant un changement difficile à annuler, séparer fichiers, environnement et données affectés. Préparer une récupération autorisée et préserver le diff humain. Un worktree peut isoler les fichiers de travail, pas les secrets, processus ou bases. Ne pas copier de secrets pour faire une sauvegarde commode. Restaurer uniquement les changements attribuables à l'intervention ; pas de `reset --hard`, de nettoyage large ou de force-push pour effacer l'incertitude. Une suppression de fichiers n'annule pas tous les effets d'un programme exécuté.

**Mode dégradé :** réseau, bibliothèque, base ou outil indisponible n'empêche pas les travaux indépendants utiles. Terminer cette partie sans réduire les exigences, contourner l'interdiction ou revendiquer l'intégration non testée. Documenter le blocage exact et la prochaine action nécessaire, pas une réussite globale.

<a id="github"></a>
## 5. GitHub, CI et collaboration

### Validation indépendante du modèle

Réutiliser les workflows existants ; sinon créer `ci.yml` seulement lorsque stack et commandes sont connues. Utiliser les événements pertinents (`pull_request`, `push` vers branches réelles, éventuellement `workflow_dispatch`) sans supposer `main`. Conserver des noms stables pour les contrôles requis et éviter des filtres de chemins qui les empêchent de produire un verdict. [E3]

Restaurer les dépendances puis lancer les opérations communes. Versions de runtime, runner, matrice et services reflètent les seules cibles promises. Définir des délais adaptés et une concurrence maîtrisée : annuler une validation redondante n'autorise pas à interrompre migration ou déploiement. Les caches restent des optimisations, avec clés adaptées aux OS/verrous/versions et sans secrets ; ne pas confondre cache fonctionnel et reconstruction vérifiée.

Limiter les permissions de `GITHUB_TOKEN` ; `contents: read` suffit souvent pour valider. Fixer les actions externes à un SHA complet vérifié dans le dépôt officiel, sans en inventer, et conserver la version lisible. Ne pas injecter une entrée de PR dans du shell ; ne pas exécuter du code de PR non fiable avec `pull_request_target`, secrets ou runner personnel permanent. Examiner aussi les chemins indirects via `workflow_run`, caches, artefacts et commandes de build. Réduire la rétention et la surface des artefacts. [E4]

La CI exécute les contrôles ; elle ne demande pas à une IA de prononcer la réussite. Elle n'installe ni Codex ni une boucle de correction par défaut. Une proposition d'IA repasse les mêmes contrôles. Sans accès distant, distinguer syntaxe vérifiée, commandes locales exécutées et **CI distante à vérifier**. Un push est une action externe et peut déclencher des coûts.

### Éléments conditionnels

| Élément | Règle de création/adaptation |
|---|---|
| `security.yml` | Contrôles pertinents non couverts ; vérifier langage, disponibilité et permissions. Aucun label « sécurisé » depuis un YAML. |
| `dependabot.yml` | Maintenance adoptée, `version: 2`, écosystèmes/répertoires réels, rythme et PR bornés ; pas d'auto-merge implicite. |
| Modèle de PR | Besoin, changement, tests, doc affectée, compatibilité, risques, migration/récupération et limites ; cases non précochées. |
| Modèles d'issues | Si collaboration : reproduction de bug ou demande ; pas de contacts inventés. |
| `CODEOWNERS` | Propriétaires réels autorisés, notamment sur les cinq fichiers gouvernés, compétences, workflows et scripts de contrôle ; approbation obligatoire à configurer séparément. [E5] |
| Release | Mandat de publication : version, changelog, artefact, contrôles, secrets et récupération ; pas de déploiement induit. |
| `agent-evals.yml` | Essais définis et accès/modèle/coût approuvés ; contrôles indépendants décrits dans [LEARNING](LEARNING.md#evaluations). |
| `agent-maintenance.yml` | Seulement automatisation explicitement demandée : déclencheur de confiance, identité, budget, limite de cycles, reprise et résultat borné ; pas de push en boucle, d'auto-merge ou de publication implicite. |

Pour une CI qui appelle Codex, vérifier les mécanismes de la version installée et les recommandations d'authentification. Ne pas placer une clé de modèle au niveau global d'un job qui exécute le code du dépôt : builds et hooks pourraient la lire. Préférer l'intégration sécurisée documentée pour GitHub, avec phases d'exécution et publication séparées ; aucune activation dans ce paquet. [E6]

### Réglages et suivi réels

Vérifier via un accès autorisé, sinon signaler à configurer : Actions, politique des actions, contrôles requis, branches protégées, revues, secrets/environnements, identité Git et protections de secrets disponibles. Les capacités dépendent du dépôt et de l'offre. Ne pas changer sa visibilité pour obtenir une fonction. Un `CODEOWNERS` écrit n'active pas une approbation obligatoire. [E5]

Les commits et PR expliquent changement, preuve et risque. Mettre à jour les docs affectées dans le même lot et vérifier leurs liens/exemples, sans réécriture automatique à chaque commit. Git conserve les changements, le plan conserve le travail et les ADR les arbitrages ; ne pas multiplier les historiques. L'examen d'un diff ne donne pas le droit de committer, de pousser ou de publier. Pas de staging global aveugle.

## Sources et limites de la reprise

La V0.3 fournit les contrats opérationnels ; les ajouts sont le lien explicite exigence/contrôle/preuve et les vérifications d'impact. Sources consultées le 29 septembre 2026. Aucun outil, seuil ou workflow de ces dépôts n'est copié comme configuration universelle.

[E1]: https://github.com/addyosmani/agent-skills/blob/main/skills/constraint-driven-development/SKILL.md "Addy Osmani — contrat de qualité"
[E2]: https://github.com/openai/codex/blob/main/AGENTS.md "OpenAI Codex — commandes et tests selon les composants"
[E3]: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax "GitHub — syntaxe des workflows"
[E4]: https://docs.github.com/en/actions/reference/security/secure-use "GitHub — sécurité des workflows"
[E5]: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners "GitHub — CODEOWNERS"
[E6]: https://developers.openai.com/codex/noninteractive "OpenAI — exécution non interactive et authentification CI"
