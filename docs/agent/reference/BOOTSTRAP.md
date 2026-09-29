# Initialisation et intégrations

Version du socle : **0.4.0** — 29 septembre 2026.  
Module gouverné de [AGENT_SYSTEM.md](../../../AGENT_SYSTEM.md). À consulter pour initialiser, migrer ou configurer le projet, pas à chaque tâche. Les permissions et limites des maîtres restent applicables. Les liens ci-dessous sont relatifs à ce fichier ; les chemins en code sont relatifs à la racine du projet.

<a id="initialisation"></a>
## 1. Initialisation relançable

**Cinq fichiers sont fournis ensemble : deux maîtres et trois modules.** Aucun projet produit, outil, workflow, connexion ou skill actif n'est présumé installé par leur présence. Le reste est créé ou réutilisé selon le besoin réel. Une correction ponctuelle n'autorise pas un audit complet du dépôt.

1. **Observer.** Identifier la racine, les instructions applicables, les composants, les versions, OS/shell, manifestes, tests, scripts, CI, documentation et changements locaux. Inspecter les scripts avant exécution ; ne pas fouiller les répertoires personnels, secrets ou projets voisins.
2. **Cadrer.** Reprendre objectif, hors périmètre, critères, environnements prévus et délégation. Distinguer exécution locale, CI et cible produit. Dépôt vide et technologie inconnue : préparer le cadrage et les éléments neutres, sans inventer application, stack ou commandes.
3. **Établir la référence.** Exécuter les contrôles autorisés pertinents. Conserver code/commit/diff, commandes, périmètre et résultats, dont échecs préexistants. Absence de tests ou d'outils n'est pas une réussite.
4. **Cartographier.** Pour chaque capacité ci-dessous, trouver son équivalent ou identifier le manque. Réutiliser le suivi existant ; ne pas imposer une deuxième organisation.
5. **Construire.** Compléter les fichiers autorisés avec le contenu réel de la stack. Relier IDE, terminal et CI aux mêmes opérations. Suivre les contrats d'[ENGINEERING](ENGINEERING.md#validation) ; séparer les jalons sans demander de nouveau une autorisation inchangée.
6. **Vérifier la relance.** Contrôler diff, syntaxe, liens et commandes. Réexécuter les contrôles d'initialisation lorsque faisable : aucun écrasement, doublon, changement de verrou ou réinstallation sans changement pertinent. Conserver un [point de reprise](LEARNING.md#continuite) puis restituer les résultats et limites.

### Couverture attendue

Pour un développement logiciel suivi dans VS Code avec GitHub, chaque ligne reçoit un statut motivé. **Requis désigne une capacité, pas un nouveau fichier obligatoire.** Les statuts sont définis dans le maître ; un échec constaté reste explicite.

| Capacité | Attendu / niveau |
|---|---|
| Démarrage et validation | **Requis.** But, prérequis, installation, lancement, tests, commandes et limites dans README/DEVELOPMENT ou équivalent. |
| Hygiène du dépôt | **Requis.** Exclusions adaptées aux secrets et artefacts ; conventions texte, binaire et édition. Pas de renormalisation globale sans besoin ni mandat. |
| Dépendances | **Si applicables.** Manifestes et verrouillage de l'écosystème ; versions, sources et restauration reproductible, sans registre parallèle. |
| Vérification du logiciel | **Requis pour le code modifié.** Comportements testables, contrôles appropriés et preuve ; intégration/e2e selon interfaces et risque. |
| Commandes communes | **Requis.** Diagnostic, restauration et validation séparés ; réutilisation du gestionnaire natif avant des scripts. |
| VS Code | **Requis pour ce profil.** Tâches et réglages utiles ; extensions recommandées si nécessaires ; débogage seulement pour une cible réelle. |
| CI GitHub | **Requis pour le code exécutable ciblant GitHub.** Validation cohérente avec la stack ; exécution distante à vérifier séparément. Pas de workflow factice si stack inconnue. |
| Suivi des changements | **Requis comme capacité.** Git/diff, suivi de mission ; PR si utilisées, changelog pour changements livrés, décisions pour arbitrages structurants. |
| Continuité | **Requise pour initialisation/mission longue.** Point de reprise compact, plan actif unique et preuves. Pas de journal imposé à une correction isolée. |
| Connaissances | **Capacité requise, notes conditionnelles.** Documentation pertinente repérée, accès bibliothèque réel vérifié ; index uniquement si utile. |
| Skills | **Mécanisme requis, création conditionnelle.** Détecter/réutiliser les capacités accessibles. Zéro nouveau skill peut être le bon résultat. |
| Sécurité et maintenance | **Examen requis, outils conditionnels.** Contrôles et mise à jour des dépendances adaptés ; aucun scanner payant ou doublon par défaut. |
| Codex/MCP/conteneur | **Conditionnel.** Aucune obligation de créer une configuration, un connecteur ou un environnement supplémentaire. |
| Publication et licence | **Conditionnel, mandat adapté.** Pas de release, de déploiement, de licence ni de compte inventé pour remplir une arborescence. |
| Réglages externes | **À vérifier séparément.** Confiance du client, identité Git, Actions, protections, secrets, accès bibliothèque et permissions réelles. |

Le suivi reste court : `capacité | chemin/commande | statut | preuve ou blocage`. Mettre à jour les éléments affectés, pas tout le rapport à chaque tâche. Une capacité requise non vérifiée rend l'initialisation partielle. `NON_APPLICABLE` exige une raison liée au projet, pas l'absence d'accès.

<a id="arborescence"></a>
## 2. Carte des destinations

Les cinq éléments marqués « fourni » sont le paquet initial. Les autres sont des destinations possibles, non des fichiers vides à créer. Conserver la structure native, les tests colocalisés et les monorepos. Ne pas déplacer le code vers `src/` ni créer des `.gitkeep` uniquement pour matérialiser cette carte.

```text
projet/
├── AGENTS.md                         # fourni : principes
├── AGENT_SYSTEM.md                   # fourni : boucle et routage
├── README.md                         # but et démarrage réel
├── .gitignore                        # secrets, caches, environnements, rapports
├── .editorconfig                     # conventions retenues
├── .gitattributes                    # texte/binaire et fins de ligne
├── .env.example                      # si variables nécessaires, valeurs non secrètes
├── <manifestes et fichiers verrou>    # stack réelle
├── CHANGELOG.md                      # si changements livrés/versionnés
├── CONTRIBUTING.md                   # si collaboration
├── SECURITY.md                       # si diffusion, canal réel
├── LICENSE                           # décision de l'ayant droit
├── .vscode/
│   ├── tasks.json
│   ├── settings.json
│   ├── extensions.json
│   └── launch.json                   # si débogage applicable
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── security.yml              # conditionnel
│   │   ├── release.yml               # conditionnel et mandaté
│   │   ├── agent-evals.yml           # essais définis et autorisés
│   │   └── agent-maintenance.yml     # automatisation bornée explicitement demandée
│   ├── dependabot.yml                # si maintenance adoptée
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/               # si collaboration
│   └── CODEOWNERS                    # propriétaires réels
├── .codex/
│   └── config.toml                   # facultatif, approuvé, sans secrets
├── .agents/skills/<nom-unique>/
│   ├── SKILL.md                      # compétence adoptée
│   ├── scripts/                      # seulement nécessaires
│   ├── references/                   # ressources vérifiées à destination
│   ├── assets/                       # si utile
│   └── agents/openai.yaml            # facultatif, compatible avec le client
├── docs/
│   ├── DEVELOPMENT.md
│   ├── ARCHITECTURE.md               # si architecture non triviale
│   ├── TESTING.md                    # si détail utile
│   ├── decisions/                    # décisions, ADR si nécessaire
│   ├── knowledge/
│   │   ├── INDEX.md                  # index, pas copie de bibliothèque
│   │   └── <sujet>.md                # notes sourcées
│   └── agent/
│       ├── reference/
│       │   ├── BOOTSTRAP.md          # fourni : initialisation
│       │   ├── ENGINEERING.md        # fourni : réalisation et contrôle
│       │   └── LEARNING.md           # fourni : continuité et apprentissage
│       ├── PROJECT.md                # état local, non souverain
│       ├── CURRENT_PLAN.md           # facultatif sans suivi équivalent
│       ├── plans/                    # plans identifiés et archives utiles
│       ├── candidates/<nom>/         # compétences non activées
│       └── evaluations/              # uniquement si justifié
│           ├── README.md             # protocole et commandes
│           ├── scenarios/            # cas et assertions versionnés
│           └── results/              # bilans, pas journaux bruts
├── scripts/
│   ├── doctor.<ext>                  # ou commande native
│   ├── setup.<ext>                   # ou commande native
│   └── validate.<ext>                # ou commande native
├── tests/
│   ├── unit/                         # ou tests colocalisés
│   ├── integration/                  # interfaces/services
│   ├── e2e/                          # parcours de bout en bout
│   └── fixtures/                     # données synthétiques
├── src/                              # ou structure existante
├── reports/                          # temporaire, ignoré, rétention limitée
└── .devcontainer/devcontainer.json   # facultatif, environnement approuvé
```

**Référence gouvernée ≠ état du projet.** Ne pas déplacer arbitrairement `reference/`, ni y écrire les observations quotidiennes. Les modules ne deviennent pas modifiables librement parce qu'ils sont sous `docs/`. Les chemins natifs et leur découverte dépendent du produit ; nos dossiers `docs/agent/` et `docs/knowledge/` ainsi que le maître opérationnel sont des conventions explicitement reliées. [B1][B2][B3]

<a id="integrations"></a>
## 3. VS Code et Codex

### VS Code

Fusionner les fichiers existants au lieu de remplacer les préférences. Ne pas désactiver Workspace Trust ou les restrictions d'extension. L'écriture d'une recommandation n'installe rien et ne prouve pas une exécution dans l'IDE.

Pour `tasks.json`, utiliser le format documenté `version: "2.0.0"` et les commandes réelles du projet : diagnostic, préparation explicite, tests, validation. Préférer `type: "process"` et des arguments séparés quand adaptés ; définir `cwd`, groupe et diagnostics utiles. Pas d'installation à l'ouverture du dossier. Relier les tâches aux mêmes commandes que la CI, sans recopier leur logique. [B3]

`settings.json` ne contient que les réglages partagés utiles à la stack. Vérifier les identifiants des extensions recommandées ; ne pas les confondre avec un verrouillage de versions. Ne créer `launch.json` que pour un débogueur et une entrée réels ; un éventuel `preLaunchTask` doit exister. Adapter un workspace multi-racines, les chemins avec espaces et l'OS. Distinguer syntaxe JSON/JSONC valide et essai de débogage effectué.

**Copilot facultatif.** Lorsqu'il est effectivement utilisé, vérifier les formats pris en charge. Un éventuel `.github/copilot-instructions.md` ou complément ciblé ne porte que les spécificités utiles, sans dupliquer les maîtres ni créer des personnages spécialisés. Vérifier la lecture réelle : un lien n'est pas une preuve de chargement. [B4]

### Configuration et accès Codex

Identifier le client réellement utilisé : extension, CLI ou environnement cloud, avec version/capacités observables. Ne pas présumer qu'une capacité d'un autre client est disponible. `.codex/config.toml` n'est créé que si nécessaire, avec confiance du projet et accord appropriés. Ne pas modifier la configuration globale pour résoudre une seule tâche locale. Les chemins `.agents/`, `.codex/` ou `.git` peuvent être protégés malgré un workspace inscriptible : respecter la politique effective. [B2][B5]

**Configuration partageable ≠ état machine ≠ authentification.** Avant une modification autorisée de configuration, identifier qui la gère et préparer une sauvegarde ciblée dans un emplacement autorisé. Préserver les personnalisations ; ne pas synchroniser clés, profils personnels, sessions ou sauvegardes sensibles. CC Switch inspire cette séparation, mais n'est ni installé ni requis par le socle. Un gestionnaire tiers ne devient pas une deuxième source de configuration concurrente. [B6]

Codex documente un cache utilisateur `auth.json` ou un stockage dans le coffre du système. Ne jamais le copier dans le dépôt, dans les artefacts ni dans un `credentials.json` local au projet ; ne pas déplacer `CODEX_HOME` dans le dépôt pour partager l'accès. Vérifier la connexion via un statut sans afficher les jetons. MCP et plugins demandent une configuration, des permissions et un accès réellement approuvés ; aucun catalogue n'est installé par défaut. [B7]

<a id="reception"></a>
## 4. Réception et migration

La réception vérifie les capacités applicables, pas un nombre de fichiers. Contrôler au minimum : cinq fichiers cohérents et liens résolus ; travail humain préservé ; commandes existantes ; configurations syntaxiquement valides ; succès et échecs correctement remontés ; absence de placeholder dans une configuration prétendue opérationnelle ; documentation et point de reprise utiles. Les exemples `<ext>`/`<nom>` de ce manuel ne sont pas des scripts prêts à exécuter.

Faire apparaître séparément syntaxe, validation locale, essai VS Code et CI distante. Les intégrations GitHub et leurs réglages sont détaillés dans [ENGINEERING](ENGINEERING.md#github). Sans accès, livrer le résultat local et les blocages exacts, sans déclarer une réception globale. Une capacité obligatoire ne disparaît pas du bilan.

**Migration V0.3 → V0.4 :** comparer aux deux fichiers réellement présents ; conserver les adaptations ; remplacer les maîtres de façon revue et ajouter les trois modules ensemble. Vérifier toutes les références locales et mettre à jour la version du socle dans le suivi seulement après vérification des cinq fichiers. Ne pas réinitialiser les plans, tests, connaissances ou skills existants. Une référence à une ancienne section doit être corrigée vers le module correspondant. Ne pas conserver une seconde copie active de l'ancien manuel.

Pour dix dépôts, comparer séparément les adaptations ; un déploiement pilote vérifié précède une diffusion approuvée. Copier un paquet ne prouve ni son chargement ni son efficacité. La validation d'un module isolé ne vaut pas validation de l'ensemble ; les essais pertinents sont définis dans [LEARNING](LEARNING.md#evaluations).

## Sources de compatibilité et inspiration

Revue documentaire du 29 septembre 2026. Les destinations et critères ci-dessus reprennent la V0.3 et constituent nos choix de construction ; les éditeurs documentent les formats, pas la réussite de cette organisation. Les liens externes peuvent évoluer : vérifier la version du client avant génération.

[B1]: https://developers.openai.com/codex/guides/agents-md "OpenAI — découverte des instructions"
[B2]: https://developers.openai.com/codex/config-basic "OpenAI — configuration Codex"
[B3]: https://code.visualstudio.com/docs/debugtest/tasks "Microsoft — tâches VS Code"
[B4]: https://code.visualstudio.com/docs/agent-customization/custom-instructions "Microsoft — instructions personnalisées"
[B5]: https://learn.chatgpt.com/docs/agent-approvals-security "OpenAI — approbations et sécurité"
[B6]: https://github.com/farion1231/cc-switch/blob/main/docs/user-manual/en/5-faq/5.1-config-files.md "CC Switch — séparation des configurations et sauvegardes"
[B7]: https://developers.openai.com/codex/auth "OpenAI — authentification"
