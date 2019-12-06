# infra_files_flow
Configuration `systemd` et script de gestion de répertoires d'arrivée

## Introduction
Le script `bash` "`indird`" gère un flux de fichiers entrants, déposés dans un unique répertoire d'arrivée.  
Les fichiers peuvent être de différents types et les actions effectuées sur ces fichiers peuvent varier selon le type, l'ensemble étant paramétrable dans un fichier de configuration au format JSON, sans qu'il soit nécessaire de modifier le script. Le fichier de configuration peut être extrait d'un fichier de configuration au format YAML, éventuellement plus global (plusieurs *hosts*).  
Le script `indird` fonctionne comme un *service* `indird` de `systemd` (`man systemd.service`), donc en tant que *daemon*, en utilisant la possibilité de `systemd` de gérer plusieurs **instances** d'un même service, ce qui peut permettre dans un même système de gérer avec `indird` plusieurs répertoires d'arrivée. La configuration de ces instances peut être regroupée dans un même fichier de configuration global au système, chaque instance étant accessible par un **tag** (étiquette).  
En l'absence d'arrivée de fichiers, le script `indird` attend par une commande `sleep` de durée paramètrable, cependant qu'une fonction spéciale de `systemd` (`man systemd.path`), paramétrée comme `indirdwake`, surveille toute modification du répertoire d'arrivée. Lorsque celle-ci se produit, `systemd` rappelle par la commande `indird <tag> wakeup` un `indird` secondaire qui `kill` s'il y a lieu le `sleep` en cours du `indird` principal, relançant ainsi la boucle de traitement des fichiers.

## Utilitaire prérequis
Le script `indird` utilise l'utilitaire `jq`, qui est disponible dans les paquets Linux Debian standards.
Une vérification de l'accessibilité de `jq` est faite au lancement de `indird`.

## Installation du script indird

Il faut copier les fichiers aux emplacements suivants :
```
indird/indird		/usr/local/bin
indird@.service		/etc/systemd/system
indirdwake@.service	/etc/systemd/system
indirdwake@.path	/etc/systemd/system
examples/indird.conf	/etc
```
et accessoirement les utilitaires fournis (voir la section **Utilitaires** dans ce document) :
```
utils/yaml2json		/usr/local/bin
utils/mkiconf		/usr/local/bin
utils/ckiyaml		/usr/local/bin
```
Les utilitaires `mkiconf` et `ckiyaml` dépendent de l'utilitaire `yaml2json`, qui lui même nécessite les packages Debian `python-yaml` et `python-docopt`.

Après modification du fichier `/etc/indird.conf`, il faut lancer :
```
# systemctl enable indird@<tag>.service
# systemctl enable indirdwake@<tag>.path

# systemctl start indird@<tag>.service
```
dans lequel *\<tag>* est le nom de la section du fichier de configuration à utiliser (voir ci-dessous), qui sert d'instance à `systemd`. Exemples :
```
# systemctl start indird@sspdamoc
# systemctl start indird@sspnice
```
Les *\<tag>* `sspdamoc` et `sspnice` sont donc à la fois des instances de `indird@` pour `systemd.service` et `systemd.path` et des *\<tag>* pour `indird`, correspondant chacun à la gestion d'un répertoire.

Pour arrêter / désinstaller :

```
# systemctl stop indird@<tag>.service

# systemctl disable indirdwake@<tag>.path
# systemctl disable indird@<tag>.service

```
Pour obtenir le status :
```
# systemctl status indird@<tag>
# systemctl status indirdwake@<tag>.path
```
Le rechargement de la configuration `indird.conf` (après modifications) est géré :
```
# systemctl reload indird@<tag>
```
NOTE : En cas, de modification de l'élément `path` de la configuration, le lien symbolique `/run/indird/<tag>_path` vers le chemin indiqué par `path` est automatiquement mis à jour par `indird`.

Le fichier de log interne de `indird` est pour l'instant `/var/log/indird.log` et des liens symboliques de fonctionnement son créés dans le répertoire `/run/indird` (créé par le script si nécessaire). Le scipt `indird` crée également des fichiers temporaires dans `/tmp`. C'est trois chemins sont déterminés par les variables shell `LogFile`, `RunDir` et `TmpDir` au début du script.

## Algorithme de fonctionnement

Il a été mis au point après discussions entre TDE, CGD et CTY.
L'idée de base est d'exécuter pour chaque fichier entrant une ou plusieurs commandes shell (`actions`) qui peuvent réussir ou échouer, ce qui détermine à nouveau pour chacune des `actions` une ou plusieurs commandes de traitement de fin (`ends`), variables selon le succès ou l'échec de l'`action` correspondante, qui est déterminé par un jeu de conditions (`conds`). Puis le résultat de l'action est journalisé selon des modalités prédéfinies (`logs`).

Après lecture et vérification du fichier de configuration, `indird` entre dans la boucle principale suivante:
```
indéfiniment (jusqu'à un arrêt par SIGTERM)
  sortir de 'sleep' (par fin du délai ou par 'kill') et sauver le dernier 'mtime' de `path`
  tant que `path` a été modifié ('mtime') depuis le dernier tour (de cette boucle)
    pour toutes les `filetypes` membres de l'objet global `rules`
      pour tous les fichiers correspondant à ce membre de `filetypes`
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

## Fichier de configuration

### Emplacement du fichier
Il s'agit par défaut de `/etc/indird.conf`, mais il est possible de spécifier (pour des tests par exemple) un autre chemin de fichier dans la variable d'environnement `INDIRD_CONFIG`. Exemple :
```
INDIRD_CONFIG=indird.conf indird sspdamoc check
```

### Structure du fichier de configuration
Le fichier de configuration de `indird` est au format JSON. Au niveau principal, les membres de l'objet racine (anonyme) sont les différentes instances (au moins une) spécifiés dans le fichier par leur **\<tag>**. Chaque membre **\<tag>** est à son tour un objet JSON avec un certain nombre de membres obligatoires [o] et facultatifs [f] selon la liste suivante:

* `path` [o] - Le chemin absolu du répertoire à surveiller. Son existence est vérifiée au lancement de `indird`, sinon *abort*
* `sleep` {o] - Le délai d'attente quand `path` ne reçoit pas de fichier. La valeur doit bien sur être numérique et d'au moins 5 (secondes) (variable `MinSleep` dans le script), sinon *abort*
* `host` [f] - Le nom réseau du système, qui doit correspondre au résultat de `hostname`, sinon *abort* de `indird`
* `shell` [f] - Le nom d'un shell autre que `sh` pour exécuter les commandes. La commande doit être disponible, sinon *abort* de `indird`
* `debug` [f] - Une valeur `true` ou `false` (par défaut), sinon *abort*, qui active ou non les logs de debug de `indird`

* `env_prefix` [f] - Le préfixe des variables d'environnement qui seront disponibles dans les commandes de `actions`, `ends` et `conds` (voir ci-dessous) et pour le `path` des `logs` de type `file` (voir `logs`ci dessous). Si non spécifié, il vaut `INDIRD_`
* `env` [f] - Un objet global dont chaque membre indique un suffixe de variable d'environnement et la valeur de ce suffixe. Le script `indird` ajoute automatiquement à cet objet les variables suivantes:
  - `${env_prefix}HOST` - le nom `hostname` du système
  - `${env_prefix}CONF` - le **\<tag>** spécifié
  - `${env_prefix}PATH` - la valeur de `path`
  - `${env_prefix}FILE` - le nom du fichier en cours de traitement
  - `${env_prefix}CODE` - la code de retour de l'`action` (voir ci-dessous) après son exécution)

* `filetypes` [o] - Un objet global dont chaque membre est un objet décrivant un type de fichier à gérer par `indird`, avec les (sous-)membres obligatoires suivants :
  - `desc` - un texte de description du type, pour usage dans les logs
  - `method` - la méthode, `fileglob` ou `regexp`, du filtre de nom de fichiers. La méthode `fileglob` utilise le *matching* du shell (`bash`), le méthode `regexp` utilise `grep`
  - `pattern` - le motif pour le filtre

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

## Exemples de fichiers de configuration

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

```
curl -sL https://deb.nodesource.com/setup_6.x | sudo bash -
sudo npm install -g yamljs
```
## Utilitaires

### `indird`
`indird` dispose d'options destinées à être utilisées en ligne de commande :
  - `config` - cette option affiche sans vérification la configuration pour un *\<tag> donné, sous une forme analogue à celle des *MIB SNMP* (par exemple : `filetypes.hl7.method="fileglob"`)
  - `check` - cette option vérifie la cohérence de la configuration entre ses différents objets, ainsi que l'existence ou la conformité des éléments *externes* à cette configuration : les chemins (`path`, `shell`) et le `host`
  - `nlcheck` - cette option (non-local check) vérifie uniquement la cohérence de la configuration entre ses objets, pas les chemins effectifs et le `host`. Elle est utilisée par `ckiyaml`, décrit ci-dessous, pour vérifier la configuration d'un *host* non-local (sur un autre *host*)

Exemples d'utilisation :
```
indird sspdamoc config
indird sspnice check
INDIRD_CONFIG=procom1.conf indird rdvradio nlcheck
```

### `yaml2json`
`yaml2json` est un utilitaire Python permettant de convertir un fichier YAML en fichier JSON.

Exemples d'utilisation :
```
yaml2json examples/indird.yml indird.conf
yaml2json examples/indird.yml | jq .hosts.procom1.confs >indird.conf
```
Les fichiers peuvent être des noms ou des *pipes* (stdin ou stdou)

### `mkiconf`
`mkiconf` est un petit utilitaire d'extraction de configuration, qui illustre l'utilisation de `yaml2json` ci-dessus. Il facilite la génération du fichier de configuration d'un *host*.

Exemples d'utilisation :
```
mkiconf examples/indird.yml procom1 >procom1.conf
mkiconf examples/indird.yml profnt2 >profnt2.conf
```

### `ckiyaml`
`ckiyaml` est un petit utilitaire de vérification de fichier YAML global (multi-host), qui illustre également l'utilisation de `yaml2json`, ce dernier assurant, avec la conversion en JSON, la vérification de la syntaxe YAML. Il nécessite aussi `indird` pour la vérification de la cohérence de sa configuration. La commande génère pour chaque *host* un fichier de configuration temporaire dont chaque *\<tag>* est ensuite vérifié avec la commande `INDIRD_CONFIG=<config_temporaire> indird <tag> nlcheck`

Exemple d'utilisation :
```
ckiyaml globalconf.yml
```
