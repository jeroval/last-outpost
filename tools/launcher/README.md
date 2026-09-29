# Lanceur Windows

`Jouer.cmd` à la racine ouvre `build/LastOutpostLauncher.exe`. Depuis une archive
complète extraite, ouvrir directement `LastOutpostLauncher.exe`.

Le lanceur utilise WinForms et le .NET Framework fourni avec Windows 10/11.
La compilation utilise le `csc.exe` local ; elle n'installe aucun outil.

```powershell
./scripts/build-launcher.ps1
./tests/launcher.ps1
# Après les exports Windows ET Web à jour :
./scripts/build-launcher.ps1 -Package
```

L'archive produite est `build/LastOutpost-Complet-Windows-Web.zip`. Elle contient
le lanceur, son fichier de configuration, un guide de démarrage et les dossiers
`windows/` et `web/`. Le lanceur résout ces deux dossiers relativement à son
propre exécutable, indépendamment du répertoire courant.

Le bouton navigateur sert uniquement le dossier `web/` sur
`http://127.0.0.1:18747/`. Le port reste identique entre les lancements afin de
conserver l'origine des sauvegardes du navigateur. Si ce port est occupé, le
lanceur affiche une explication ; il ne change pas silencieusement d'origine.
Fermer le lanceur ferme le serveur et ses connexions. Les sauvegardes du navigateur
et de Windows sont séparées.

Le serveur accepte GET et HEAD, borne les chemins au dossier Web, refuse les
traversées et liens symboliques, vérifie l'en-tête Host et émet les types MIME
WebAssembly ainsi que les en-têtes d'isolation du navigateur. Il n'écoute ni sur
le réseau local ni sur Internet.

Commandes de diagnostic, sans lancement du navigateur :

```powershell
Start-Process ./build/LastOutpostLauncher.exe -ArgumentList '--diagnose', 'diagnostic.txt' -Wait
Start-Process ./build/LastOutpostLauncher.exe -ArgumentList '--self-test', 'rapport.txt' -Wait
Start-Process ./build/LastOutpostLauncher.exe -ArgumentList '--preview', 'apercu.png' -Wait
# Serveur de contrôle limité à 60 secondes, URL écrite dans le fichier :
Start-Process ./build/LastOutpostLauncher.exe -ArgumentList '--serve-test', 'url.txt', '60'
```

Les chemins contenant des espaces doivent être entourés de guillemets dans les
arguments transmis par `Start-Process`, comme le fait `tests/launcher.ps1`.
Le diagnostic retourne 0 si au moins un export existe, 2 si aucun n'est disponible.
Le test retourne 0 uniquement si tous ses contrôles passent. `--serve-test` accepte
une durée de 1 à 300 secondes et reste une aide de vérification bornée.
