# infra_files_flow
Script et configuration `systemd` de gestion de répertoires d'arrivée

## <a name="toc">Table des matières</a>

Dans [github](https://github.com/Epiconcept-Paris/infra-files-flow), vous pouvez naviguer aisément entre les sections de ce document en utilisant le menu dont l'icône [**☰**] se trouve à droite de la barre juste au dessus de la zone ou apparait ce texte.

* [Nouvelles fonctionnalités](#newf)
  * [Gestion d'un fichier de configuration par flux](#scfg)
  * [Gestion d'un cache du fichier de configuration](#cfgc)
  * [Gestion d'un fichier de configuration globale `/etc/indird.d/.global.json`](#gcfg)
  * [Gestion d'un système de validation de fichier reçu, en remplacement de `lsof`](#fwvs)
  * [Gestion des fichiers entrants par ordre d'arrivée](#odby)
  * [Gestion du mode debug d'un flux par simple existence d'un fichier](#sdbg)
  * [Prise en compte des nouvelles fonctionnalités dans `indirdctl`](#ictl)
  * [Vérification non-locale des fichiers de configuration](#nloc)
* [Introduction](#intro)
* [Utilitaire prérequis](#ureq)
* [Installation du script indird](#inst)
* [Algorithme de fonctionnement](#algo)
* [Variables d'environnement](#envv)
* [Fichier de configuration](#cfgf)
* [Exemples de fichiers de configuration](#cfge)
* [Utilitaires](#utils)

## <a name="newf">Nouvelles fonctionnalités en 2025-2026</a>

Ces nouvelles fonctionnalités ont été ajoutées à `indird` pour alléger la charge système dans la gestion d'un grand nombre de flux (plusieurs centaines).  
Elles se manifestent essentiellement par la prise en compte d'un répertoire `/etc/indird.d`, dans lequel chaque flux a son sous-répertoire qui va contenir des fichiers de configuration spécifiques au flux.  
L'analyse (parsing) de la configuration du flux a également été accélérée d'un facteur de 25 environ (un seul appel à `jq` au lieu d'entre 100 et 200 précédemment).  

### <a name="scfg">Gestion d'un fichier de configuration par flux

Si le fichier non-vide `/etc/indird.d/<flux>/config.json` existe, il sera prise en compte préférentiellement au membre du fichier global `/etc/indird.conf` concernant le flux.
Ce fichier `config.json` contient un objet JSON qui doit comporter un seul membre de premier niveau portant le nom du `<flux>` et qui contiendra à son tour les paramètres du flux (dont, par exemple, `path` et `sleep`).

Il est possible de générer ce fichier en utilisant la nouvelle option `split` du script `indird`.
Par exemple, pour un flux nommé `rdvradio` :

```console
indird rdvradio split
```
Si le fichier `/etc/indird.d/rdvradio/config.json` existe déjà avant le lancement de la commande `split`, trois cas peuvent se produire :
* il n'y a pas (ou plus) dans `/etc/indird.conf` de membre concernant le flux : cela est signalé et un code d'erreur spécifique 8 (`ExNoAllCfg`) est retourné
* il y a dans `/etc/indird.conf` un membre strictement identique à celui de `/etc/indird.d/rdvradio/config.json` : cela est également signalé avec un code d'erreur 9 (`ExCfgEql`)
* dans le dernier cas, la différence entre le membre dans `/etc/indird.conf` et celui dans `/etc/indird.d/rdvradio/config.json` est affichée avec un code d'erreur 10 (`ExCfgDif`)

### <a name="cfgc">Gestion d'un cache du fichier de configuration

Si le fichier non-vide `/etc/indird.d/<flux>/cache.bash` existe ET qu'il est plus récent que le fichier `/etc/indird.d/<flux>/config.json` (ou que le fichier `/etc/indird.conf` si `config.json` n'existe pas), ce fichier `cache.bash` sera chargé (très rapidement avec une commande `source`) en lieu et place du fichier `config.json`.

La génération ou la mise à jour du fichier `cache.bash` sont automatiques si le fichier est absent ou à chaque fois que le fichier JSON (par flux ou global) est vu comme plus récent que le fichier `cache.bash`.

Il est possible d'invoquer le script `indird` pour gérer le cache d'un flux avec la commande utilitaire `cache` qui dispose elle même des sous-commandes `gen`, `del`, `chk` et `prt` pour respectivement créer, supprimer, vérifier et formatter pour vérification le fichier `cache.bash`.
Par exemple, pour le flux nommé `rdvradio` :

```console
indird rdvradio cache gen	# Créer ou mettre à jour le cache
indird rdvradio cache del	# Supprimer le cache
indird rdvradio cache chk	# Vérifier le cache
indird rdvradio cache prt	# Formatter le cache pour examen et comparaisons
```

### <a name="gcfg">Gestion d'un fichier de configuration globale `/etc/indird.d/.global.json`

S'il est présent, le fichier `/etc/indird.d/.global.json` contient un objet JSON dont les membres permettent de surcharger des variables globales internes du script `indird`.  
Les membres présents sont simplement trandformés en assignations de variables `bash` et l'ensemble est évalué, sans contrôle sur les noms de membres (donc des variables locales). C'est donc une fonctinnalité puissante qui n'est pour l'instant prévue que pour modifier les variables `Use_lsof` et `wDelay` du script `indird`, et optionnellement la variable `NLocal`, comme détaillé dans le paragraphe suivant.


### <a name="fwvs">Gestion d'un système de validation de fichier reçu, en remplacement de `lsof`

Ce système s'appuie sur l'apparition, dans le répertoire `path` (voir la [Structure du fichier de configuration](#cfgs)) de chaque flux, d'un fichier témoin vide `.ok/<fichier>` pour chaque `<fichier>` reçu dans le répertoire `path` lui-même.

Ce fichier témoin doit être créé par le programme qui transfère les fichiers dans le répertoire `path` (par exemple `proftpd`).
Il est utilisé par le script `indird` pour détecter la fin de l'écriture du fichier correpondant et est alors immédiatement supprimé par `indird`.

L'activation de cette fonctionnalité dépend de la variable `Use_lsof` actuellement affectée à 'y' à la ligne 16 de `indird/indird`, ce qui veut dire que l'ancien système de détection, utilisant la commande `lsof`, est par défaut utilisé au lieu de la nouvelle fonctionnalité.  
Pour changer la valeur de la variable `Use_lsof`, il suffit de créer un membre `Use_lsof` dans le fichier de configuration globale `/etc/indird.d/.global.json`, par exemple ainsi :

```JSON
{
    "Use_lsof": "n"
}
```
Que le système de détection de fin d'écriture soit `lsof` ou les fichiers `.ok/<fichier>`, quand le script `indird` détecte que l'écriture d'un ou plusieurs fichiers n'est pas terminée, il attend avec la commande standard `sleep` un délai au 1/10e de seconde contenu dans la variable globale `wDelay` (par défaut `0.2`) avant la prochaine boucle de vérification du contenu du répertoire `path`.  
Comme cette variable est globale, il est possible de la modifier par `/etc/indird.d/.global.json`, ainsi par exemple dans le cas précédent :

```JSON
{
    "Use_lsof": "n",
    "wDelay": "0.5"
}
```
Il est à noter qu'il est également possible d'ajouter à `/etc/indird.d/.global.json` un membre `NLocal` permettant d'affecter de manière permanente les vérifications non-locales, ce qui se fait ponctuellement en affectant la variable d'environnement `INDIRD_NLOCAL` :

```JSON
{
    "Use_lsof": "n",
    "wDelay": "0.5",
    "NLocal": "y"
}
```

### <a name="odby">Gestion des fichiers entrants par ordre d'arrivée

Dans les premières versions d'`indird`, les fichiers étaient traités par ordre alphabétique.  
Mais quand il y a beaucoup de fichiers entrants, il est préférable de les traiter par ordre d'arrivée.

Un membre optionnel 'orderby' a donc été rajouté aux membres obligatoires de `filetypes.<suffix>`.
S'il est présent, il peut prendre les valeurs `mtime` ou `alpha` (par défaut).

### <a name="sdbg">Gestion du mode debug d'un flux par simple existence d'un fichier

Si un fichier `/etc/indird.d/<flux>/debug` existe, il est équivalent à la présence dans la configuration du flux de `"debug": true`.  
Cette fonctionnalité est surtout utile dans la fonction WakeupMain du script `indird`, qui peut être invoquée très fréquemment.
Cela a moins d'incidence maintenant que le cache de configuration a été implémenté.

### <a name="ictl">Prise en compte des nouvelles fonctionnalités dans `indirdctl`

Le script `ansible/files/indirdctl` a été revu et augmenté pour permettre l'appel pour tous les flux des nouvelles commandes ajoutées au script `indird/indird`. Sont ainsi apparues les commandes suivantes : 
* `split`
* `cache <sub-cmd>` ou `<sub-cmd>` peut être :
  * `gen` (generate)
  * `del` (delete)
  * `chk` (check)
  * `prt` (print)
* `chk`
* `nlchk`
* `paths`

### <a name="nloc">Vérification non-locale des fichiers de configuration</a>

La vérification non-locale du fichier de configuration (hors de la machine sur laquelle il est destiné à être utilisé) peut se faire avec la commande utilitaire `nlcheck` de `indird`, au lieu de la commande `check` pour une vérification locale (plus complète).  
Mais la commande `check` n'est pas la seule à effectuer une verification locale de la configuration, c'est également le cas des commandes `split` et `cache chk`. Si une vérification de la configuration doit être effectuée hors de la machine pour laquelle elle est destinée, il faut alors ajouter à l'environnement la variable `INDIRD_NLOCAL` avec une valeur non vide (par exemple : `INDIRD_NLOCAL=y`)


## <a name="intro">Introduction</a>

Le script `bash` "`indird`" gère un flux de fichiers entrants, déposés dans un unique répertoire d'arrivée.  
Les fichiers peuvent être de différents types et les actions effectuées sur ces fichiers peuvent varier selon le type, l'ensemble étant paramétrable dans un fichier de configuration au format JSON, sans qu'il soit nécessaire de modifier le script.
Le fichier de configuration peut être extrait d'un fichier de configuration au format YAML, éventuellement plus global (plusieurs *hosts*).  
Le script `indird` fonctionne comme un *service* `indird` de `systemd` (`man systemd.service`), donc en tant que *daemon*, en utilisant la possibilité de `systemd` de gérer plusieurs **instances** d'un même service.
Cela peut permettre dans un même système de gérer avec `indird` plusieurs répertoires d'arrivée.
La configuration de ces instances peut être regroupée dans un même fichier de configuration global au système, chaque instance étant accessible par un **tag** (étiquette).  
En l'absence d'arrivée de fichiers, le script `indird` attend par une commande `sleep` de durée paramètrable, cependant qu'une fonction spéciale de `systemd` (`man systemd.path`), paramétrée comme `indirdwake`, surveille toute modification du répertoire d'arrivée.
Lorsque celle-ci se produit, `systemd` rappelle par la commande `indird <flux> wakeup` un `indird` secondaire, qui `kill` s'il y a lieu le `sleep` en cours du `indird` principal, relançant ainsi la boucle de traitement des fichiers.

## <a name="deps">Utilitaires prérequis</a>
Le script `indird` utilise la command `jq`, qui est disponible en standard dans un paquet du même nom sous Linux Debian.
Par défaut (modifiable dans [la configuration globale](#gcfg)), `indird` utilise également l'utilitaire `lsof`, également disponible en standard dans un paquet du même nom.
Une vérification de l'accessibilité de `jq` et optionnellement de `lsof` est faite au lancement de `indird`.

## <a name="inst">Installation du script indird</a>

Il faut copier les fichiers aux emplacements suivants :
```console
indird/indird		/usr/local/bin
indird@.service		/etc/systemd/system
indirdwake@.service	/etc/systemd/system
indirdwake@.path	/etc/systemd/system
examples/indird.conf	/etc
```
et accessoirement les utilitaires fournis (voir la section **Utilitaires** dans ce document) :
```console
utils/yaml2json		/usr/local/bin
utils/mkiconf		/usr/local/bin
utils/ckiyaml		/usr/local/bin
```
Les utilitaires `mkiconf` et `ckiyaml` dépendent de l'utilitaire `yaml2json`, qui lui même nécessite les packages Debian `python-yaml` et `python-docopt`.

Après modification du fichier `/etc/indird.conf`, il faut lancer :
```console
# systemctl enable indird@<flux>.service
# systemctl enable indirdwake@<flux>.path

# systemctl start indird@<flux>.service
```
dans lequel *\<flux>* est le nom de la section du fichier de configuration à utiliser (voir ci-dessous), qui sert d'instance à `systemd`. Exemples :
```console
# systemctl start indird@sspdamoc
# systemctl start indird@sspnice
```
Les *\<flux>* `sspdamoc` et `sspnice` sont donc à la fois des instances de `indird@` pour `systemd.service` et `systemd.path` et des *\<flux>* pour `indird`, correspondant chacun à la gestion d'un répertoire.

Pour arrêter / désinstaller :

```console
# systemctl stop indird@<flux>.service

# systemctl disable indirdwake@<flux>.path
# systemctl disable indird@<flux>.service

```
Pour obtenir le status :
```console
# systemctl status indird@<flux>
# systemctl status indirdwake@<flux>.path
```
Le rechargement de la configuration `indird.conf` (après modifications) est géré :
```console
# systemctl reload indird@<flux>
```
NOTE : En cas, de modification de l'élément `path` de la configuration, le lien symbolique `/run/indird/<flux>_path` vers le chemin indiqué par `path` est automatiquement mis à jour par `indird`.

Le fichier de log interne de `indird` est pour l'instant `/var/log/indird.log` et des liens symboliques de fonctionnement son créés dans le répertoire `/run/indird` (créé par le script si nécessaire). Le scipt `indird` crée également des fichiers temporaires dans `/tmp`. Ces trois chemins sont déterminés par les variables globales `LogFile`, `RunDir` et `TmpDir` au début du script.

## <a name="algo">Algorithme de fonctionnement</a>

Il a été mis au point en 2018 après discussions entre TDE, CGD et CTY.
L'idée de base est d'exécuter pour chaque fichier entrant une ou plusieurs commandes shell (`actions`) qui peuvent réussir ou échouer, ce qui détermine à nouveau pour chacune des `actions` une ou plusieurs commandes de traitement de fin (`ends`), variables selon le succès ou l'échec de l'`action` correspondante, qui est déterminé par un jeu de conditions (`conds`). Puis le résultat de l'action est journalisé selon des modalités prédéfinies (`logs`).

Après lecture et vérification du fichier de configuration, `indird` entre dans la boucle principale suivante:
```
indéfiniment (jusqu'à un arrêt par SIGTERM)
  sortir de 'sleep' (par fin du délai ou par 'kill') et sauver le dernier 'mtime' de `path`
  tant que `path` a été modifié ('mtime') depuis le dernier tour (de cette boucle)
    pour toutes les membres de `filetypes` aussi membres de l'objet global `rules`
      pour tous les fichiers correspondant à ce membre de `filetypes` et de `rules`
	pour toutes les étapes de la règle
	  lancer l'action de l'étape
	  pour toutes les fins (`ends`) de l'étape
	    vérifier si la condition `cond` de fin s'applique
	    exécuter le `end` correspondant défini dans l'objet global `ends` des fins
	  pour tous les (`logs`) de l'étape
	    logger le résultat de l'action de l'étape
  attendre par 'sleep' la durée `sleep` spécifiée dans la configuration

l'activation par `systemd` de `indirdwake` rappelle un `indird` secondaire pour interrompre le 'sleep'
```

## <a name="envv">Variables d'environnement</a>

Le script `indird/indird` reconnait et utilise **pour certaines commandes** les variables d'environnement suivantes:

- `INDIRD_CONFIG` permet d'utiliser un fichier global de configuration(s) autre que `/etc/indird.conf`
- `INDIRD_CFGDIR` permet d'utiliser un répertoire de configuration(s) par flux autre que `/etc/indird.d/`
- `INDIRD_NLOCAL` permet d'ignorer les vérifications locales du fichier de configuration (voir [ici](#nloc))

Enfin une variable `IndPfx` est également reconnue (dérivée par défaut du `basename` du script `indird` lui-même), qui permet de modifier le préfixe `INDIRD_` dans tout le script `indird`, c'est à dire aussi bien le nom des trois variables ci-dessus que la valeur par défaut du paramètre `env_prefix`.

Il est **IMPORTANT** de noter que ces variables ne sont **PAS** prises en compte dans le fonctionnement du script `indird` comme service (`daemon`) du fait de la difficulté à modifier optionnellement l'environnement d'un service `systemd`.
Il reste toujours possible cependant de transformer le fichier `/etc/indird.conf` et/ou le répertoire `/etc/indird.d` en liens symboliques qui seront traités exactement comme si leur cibles étaient dans `/etc`.

## <a name="cfgf">Fichier de configuration</a>

### Emplacement du fichier
Il s'agit par défaut de `/etc/indird.conf`, mais il est possible de spécifier (pour des tests par exemple) un autre chemin de fichier dans la variable d'environnement `INDIRD_CONFIG`. Exemple :
```
INDIRD_CONFIG=indird.conf indird sspdamoc check
```
Si un fichier `/etc/indird.d/<flux>/config.json` est présent et non-vide, il aura priorité sur `/etc/indird.conf`. Pour rappel, il contient un object JSON avec un unique membre de 1er niveau portant le nom du flux.

Il est également possible de spécifier (pour des tests) un autre répertoire `indird.d` que dans `/etc` avec la variable d'environnement `INDIRD_CFGDIR`:
```
INDIRD_CFGDIR=indird.d indird sspdamoc split
```


### <a name="cfgs">Structure du fichier de configuration</a>
Le fichier de configuration de `indird` est au format JSON. Au niveau principal, les membres de l'objet racine (anonyme) sont les différentes instances (au moins une) spécifiés dans le fichier par leur **\<flux>**. Chaque membre **\<flux>** est à son tour un objet JSON avec un certain nombre de membres obligatoires [o] et facultatifs [f] selon la liste suivante:

* `path` [o] - Le chemin absolu du répertoire à surveiller. Son existence est vérifiée au lancement de `indird`, sinon *abort*
* `sleep` [o] - Le délai d'attente quand `path` ne reçoit pas de fichier. La valeur doit bien sur être numérique et d'au moins 5 (secondes) (variable `MinSleep` dans le script), sinon *abort*
* `host` [f] - Le nom réseau du système, qui doit correspondre au résultat de `hostname`, sinon *abort* de `indird`
* `shell` [f] - Le nom d'un shell autre que `sh` pour exécuter les commandes. La commande doit être disponible, sinon *abort* de `indird`
* `debug` [f] - Une valeur `true` ou `false` (par défaut), sinon *abort*, qui active ou non les logs de debug de `indird`

* `env_prefix` [f] - Le préfixe des variables d'environnement qui seront disponibles dans les commandes de `actions`, `ends` et `conds` (voir ci-dessous) et pour le `path` des `logs` de type `file` (voir `logs` ci dessous). Si non spécifié, il vaut `INDIRD_`
* `env` [f] - Un objet global dont chaque membre indique un suffixe de variable d'environnement et la valeur de ce suffixe. Le script `indird` ajoute automatiquement à cet objet les variables suivantes:
  - `${env_prefix}HOST` - le nom `hostname` du système
  - `${env_prefix}CONF` - le **\<flux>** spécifié
  - `${env_prefix}PATH` - la valeur de `path`
  - `${env_prefix}FILE` - le nom du fichier en cours de traitement
  - `${env_prefix}CODE` - la code de retour de l'`action` (voir ci-dessous) après son exécution)

* `filetypes` [o] - Un objet global dont chaque membre est un objet décrivant un type de fichier à gérer par `indird`, avec les (sous-)membres obligatoires suivants :
  - `desc` - un texte de description du type, pour usage dans les logs
  - `method` - la méthode, `fileglob` ou `regexp`, du filtre de nom de fichiers. La méthode `fileglob` utilise le *matching* du shell (`bash`), le méthode `regexp` (par défaut) utilise `grep`
  - `pattern` - le motif pour le filtre
  - `orderby` - l'ordre de tri, `mtime` ou `alpha` (par défaut), des fichiers sélectionnés par le filtre de nom de fichiers. L'ordre `mtime` correspond aux plus anciens fichiers en premier, l'ordre `alpha` (par défaut) à l'ordre alphabétique croissant

* `actions` [o] - Un objet global dont chaque membre est un objet décrivant une commande shell principale à exécuter (passée à `sh -c`) sur le fichier, avec les (sous-)membres suivants:
  - `desc` [f] - un texte de description
  - `cmd` [o] - la commande à exécuter, qui sera passée à sh -c
  - `chdir` [f] - un répertoire de travail optionel pour la commande
  - `env` [f] - un complément de variables d'environnement pour la commande, analogue au `env` global

* `ends` [f] - Un objet global dont chaque membre est un objet décrivant une commande shell *de nettoyage* à exécuter (passée à `sh -c`) sur le fichier, avec les (sous-)membres suivants:
  - `desc` [f] - un texte de description
  - `cmd` [o] - la commande à exécuter, qui sera passée à sh -c
  - `chdir` [f] - un répertoire de travail optionel pour la commande
  - `env` [f] - un complément de variables d'environnement pour la commande, analogue au `env` global
  - `stdin` [f] - les valeurs 'out', 'err', 'all' exclusivement, indiquant quel(s) élément(s) des stdout/stderr de l'`action` associée seront passés en stdin à la commande de ce membre de `ends`

* `logs` [f] - Un objet global dont chaque membre est un objet décrivant une méthode de journalisation à employer pour le résultat de l'action associée, avec les (sous-)membres suivants:
  - `desc` [f] - un texte de description
  - `type` [o] - le type du log, actuellement `file` ou `syslog` seulement
  - `args` [f] - les arguments du log, qui varient selon `type`. Pour `file`, on a la valeur obigatoire `path` qui indique le nom du fichier de log et pour `syslog`, deux arguments :
      + `facility` [o] - la 'facility' de syslog. Valeurs admises : `user` et `daemon`
      + `level` [o] - le niveau de log, parmi toutes les valeurs admises par logger(1), soit `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug` ainsi que `panic` pour `emerg`, `error` pour `err` et `warn` pour `warning`

* `conds` [f] - Un objet global dont chaque membre est une commande à exécuter, dont le code de retour détermine une condition pour les `rules` ci-dessous

* `rules` [o] - L'objet global principal, dont chaque membre a le nom d'un type de fichiers membre de `filetypes` et définit le jeu de règles pour gérer ce type de fichiers, sous la forme d'une liste (tableau) d'étapes (steps) ayant chacune la structure suivante :
  - `desc` [f] - un texte de description
  - `hide` [f] - une valeur `true` ou `false` (par défaut). Si true, l'étape (step) est ignorée
  - `action` [o] - le nom d'une action membre de l'objet global `actions`
  - `ends` [f] - une liste (tableau) d'objets comportant les (sous-)membres suivants:
    + `cond` [o] - le nom d'une condition dans `conds`
    + `end` [o] - le nom d'un membre de l'objet global `ends`
  - `logs` [f] - une liste (tableau) de méthodes de log du résultat de `action`, méthodes définie dans l'objet global `logs`

Dans le cas où l'exécution d'une commande `cmd` de `actions` risque d'être trop longue, il est possible de limiter sa durée en préfixant la commande avec la commande standard `timeout`. Exemple :
```
timeout 30 rsync -e "ssh -i $i_PATH/.ssh/rsync -l $i_user" "$i_FILE" $i_front:
```

Si la commande `cmd` de `actions` d'une étape (step) échoue, les étapes suivantes ne seront pas exécutées.

Pour l'instant, seul le résultat de la commande est loggé par `logs` (global et `rules`) avec le texte fixe suivant : "$Tag $act for $file returned $Ret" dans lequel les variables internes suivantes sont affectées par `indird` :
  - `$Tag` est l'instance (*\<flux>*) de `indird`, par exemple `sspdamoc`
  - `$act` est le chemin de config de l'action en cours, par exemple `actions.copy`
  - `$file` est le nom du fichier en cours
  - `$Ret` est le résultat de `$act` : `success` ou par exemple `failure (exit=3)`

Une extension facile des logs est prévue dans `indird`, les `logs` d'une étape (step) étant traités par une fonction interne StepLogs.

## <a name="cfge">Exemples de fichiers de configuration</a>

[examples/indird.yml]: examples/indird.yml "fichier local"
[examples/indird.conf]: examples/indird.conf "fichier local"

La définition du projet a donné lieu à la rédaction de l'exemple de fichier de configuration en YAML [examples/indird.yml][], pour trois hosts différents.
Les nombreux commentaires du fichier, reprenant des parties de cette documentation, permettent de situer celles-ci dans leur contexte.

Ce fichier YAML peut être transformé en JSON avec l'utilitaire `yaml2json` fourni, dérivant de celui de `https://github.com/drbild/json2yaml.git` et nécessitant comme lui les packages Debian `python-yaml` et `python-docopt`. Exemple:
```
yaml2json examples/indird.yml | jq .hosts.procom1.confs >indird.conf
```

Le fichier [examples/indird.conf][] contient un exemple de fichier de configuration généré pour le *host* `procom1` de [examples/indird.yml][]. Il est aussi possible (entre autres solutions), après l'installation de `indird`, de le générer avec l'utilitaire `mkiconf` fourni :
```
mkiconf examples/indird.yml procom1 >indird.conf
```

Est également disponible en open-source le package Javascript `yamljs` que l'on peut, sur un système ne disposant pas de `nodejs`, installer par exemple par :

```console
curl -sL https://deb.nodesource.com/setup_6.x | sudo bash -
sudo npm install -g yamljs
```

## <a name="utils">Utilitaires</a>

### Commandes utilitaires du script `indird`
`indird` dispose d'options destinées à être utilisées en ligne de commande après le **tag** (nom du flux) :
  - `config` - cette option affiche sans vérification la configuration pour un `<flux>` donné, sous une forme analogue à celle des *MIB SNMP* (par exemple : `filetypes.hl7.method="fileglob"`)
  - `check` - cette option vérifie la cohérence de la configuration entre ses différents objets, ainsi que l'existence ou la conformité des éléments *externes* à cette configuration : les chemins (`path`, `shell`) et le `host`
  - `split` - cette option génère le fichier `/etc/indird.d/<flux>/config.json` qui doit préalablement ne pas exister. Le fichier `/etc/indird.d/<flux>/cache.bash` est également généré
  - `cache` - cette option gère la génération, la suppression, la vérification et l'affichage formatté du fichier de cache `/etc/indird.d/<flux>/cache.bash`, respectivement avec les sous-commandes :
    - `gen` pour la génération
    - `del` pour la suppression
    - `chk` pour la vérification
    - `prt` pour l'affichage formatté

Exemples d'utilisation :
```console
indird sspdamoc config
indird sspnice check
INDIRD_CONFIG=procom1.conf INDIRD_NLOCAL=y indird rdvradio check
indird rdvradio cache chk
```

### Utilitaire `yaml2json`
`yaml2json` est un utilitaire Python permettant de convertir un fichier YAML en fichier JSON.

Exemples d'utilisation :
```
yaml2json examples/indird.yml indird.conf
yaml2json examples/indird.yml | jq .hosts.procom1.confs >indird.conf
```
Les fichiers peuvent être des noms ou des *pipes* (stdin ou stdou)

### Utilitaire `mkiconf`
`mkiconf` est un petit utilitaire d'extraction de configuration, qui illustre l'utilisation de `yaml2json` ci-dessus. Il facilite la génération du fichier de configuration d'un *host*.

Exemples d'utilisation :
```
mkiconf examples/indird.yml procom1 >procom1.conf
mkiconf examples/indird.yml profnt2 >profnt2.conf
```

### Utilitaire `ckiyaml`
`ckiyaml` est un petit utilitaire de vérification de fichier YAML global (multi-host), qui illustre également l'utilisation de `yaml2json`, ce dernier assurant, avec la conversion en JSON, la vérification de la syntaxe YAML. Il nécessite aussi `indird` pour la vérification de la cohérence de sa configuration. La commande génère en mémoire pour chaque *host* la configuration dont chaque *\<flux>* est ensuite vérifié par son *tag* avec la commande `jq ".$tag" | INDIRD_CONFIG=- indird <flux> nlcheck`

Exemple d'utilisation :
```
ckiyaml globalconf.yml
```
