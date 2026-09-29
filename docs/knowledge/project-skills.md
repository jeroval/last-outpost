# Skills locaux du projet

La [documentation officielle OpenAI](https://learn.chatgpt.com/docs/build-skills), sections « Where Codex loads local skills » et « How ChatGPT and Codex use skills », consultée le 29 septembre 2026, indique que Codex découvre les dossiers `.agents/skills` entre son répertoire de travail et la racine du dépôt. Un skill porte un `SKILL.md` avec `name` et `description` ; son corps est chargé lorsqu'il est sélectionné. La découverte automatique et l'invocation explicite sont documentées.

Ce dépôt utilise donc `.agents/skills/` avec trois procédures spécifiques : évolution jouable, régression, livraison locale. Elles réutilisent les commandes du projet et ne déclarent aucune connexion MCP, aucun service permanent ni accès payant. Elles ont été créées sous le mandat utilisateur du 29 septembre : créer et faire évoluer l'écosystème IA du jeu.

La présence des fichiers, leur validation et leur usage par lecture explicite sont vérifiables localement. **Leur apparition dans le sélecteur natif du client reste à observer.** Si le client ne les montre pas, vérifier sa découverte actuelle et redémarrer seulement si nécessaire ; ne pas copier silencieusement les skills dans un répertoire global.

Les essais et versions sont suivis dans [UPDATES](../agent/UPDATES.md). Un changement de ressources déterminantes impose de réexaminer les usages concernés. Ces skills restent propres à Last Outpost : les liens et commandes supposent sa racine et ne constituent pas un paquet portable autonome.
