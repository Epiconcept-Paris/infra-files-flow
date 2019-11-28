# infra_files_flow
Configuration systemd et script de gestion de répertoires d'arrivée

## Introduction
Le script `bash` "`indird`" gère un flux de fichiers entrant (déposés) dans un unique répertoire d'arrivée.  
Les fichiers peuvent être de différents types et les actions effectuées sur ces fichiers peuvent varier selon le type, l'ensemble étant paramétrable dans un fichier de configuration en JSON, qui peut être extrait d'un fichier de configuration en YAML (éventuellement plus global), sans qu'il soit nécessaire de modifier le script.  
Le script `indird` fonctionne comme un service de `systemd`, donc en tant que *daemon*, en utilisant la possibilité de `systemd` de gérer plusieurs instances d'un même service, ce qui peut permettre dans un même système de gérer plusieurs répertoires d'arrivée.

## Utilitaire prérequis
Le script `indird` utilise l'utilitaire `jq` qui est disponible dans les paquets Linux Debian standards.
Une vérification de l'accessibilité de `jq` est faite au lancement de `indird`.

## Installation du script indird

Il faut copier les fichiers aux emplacements suivants :
```
indird			/usr/local/bin
indird.conf		/etc
indird@.service		/etc/systemd/system
indirdwake@.service	/etc/systemd/system
indirdwake@.path	/etc/systemd/system
```
Après modification du fichier indird.conf, il faut lancer :
```
# systemctl enable indird@<tag>.service
# systemctl enable indirdwake@<tag>.path

# systemctl start indird@<tag>.service
```
dans lequel *\<tag>* est le nom de la section du fichier de configuration à utiliser (voir ci-dessous). Exemple :
```
# systemctl start indird@sspdamoc
```
C'est ainsi qu'il est ainsi possible d'utiliser plusieurs instances de `indird` sur le même système, avec un *\<tag>* différent pour chaque instance.

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
Le rechargement de configuration est géré :
```
# systemctl reload indird@<tag>
```
NOTE : En cas, de modification de l'élément `path` de la configuration, le lien symbolique `/run/indird/<tag>_path` vers le chemin indiqué par `path` est automatiquement mis à jour par `indird`.

Le fichier de log interne de `indird` est pour l'instant `/var/log/indird.log` et des liens symboliques de fonctionnement son créés dans le répertoire `/run/indird` (créé par le script si nécessaire). Le scipt `indird` crée également des fichiers temporaires dans /tmp. C'est trois chemins sont déterminés par les variables shell `LogFile`, `RunDir` et `TmpDir` au début du script.

## Fichier de configuration

Le fichier de configuration constitue le socle de l'algorithme de fonctionnement d'`indird`, permettant de spécifier des jeux de commandes à appliquer à des types de fichiers sans modifier le script `indird` lui-même.

### Emplacement du fichier
Il s'agit par défaut de `/etc/indird.conf`, mais il est possible de spécifier (pour des tests par exemple) un autre chemin de fichier dans la variable d'environnement `INDIRD_CONFIG`. Exemple :
```
$ INDIRD_CONFIG=indird.conf indird sspdamoc check
```

### Structure du fichier de configuration
Le fichier de configuration de `indird` est au format JSON. Au niveau principal, les membres de l'objet global sont les différentes instances *\<tag>* spécifiés dans le fichier. Chaque membre *\<tag>* est à son tour un objet JSON avec un certain nombre de membres obligatoires [o] et facultatifs [f] selon la liste suivante:

* `path` [o] - le chemin absolu du répertoire à surveiller. Son existence est vérifiée au lancement de `indird`, sinon *abort*
* `sleep` {o] - le délai d'attente quand `path` ne reçoit pas de fichier. La valeur doit bien sur être numérique et d'au moins 5 (secondes) (variable `MinSleep` dans le script), sinon *abort*
* `host` [f] - le nom réseau du système, qui doit correspondre au résultat de `hostname`, sinon *abort* de `indird`
* `shell` [f] - le nom d'un shell autre que `sh` pour exécuter les commandes. La commande doit être disponible, sinon *abort* de `indird`
* `debug` [f] - une valeur `true` ou `false` (par défaut), sinon *abort*, qui active ou non les logs de debug de `indird`

* `env_prefix` [f] - le préfixe des variables d'environnement qui seront disponibles dans les commandes de `actions`, `ends` et `conds` (voir ci-dessous) et pour le `path` des `logs` de type `file` (voir `logs`ci dessous). Si non spécifié, il vaut `INDIRD_`
* `env` [f] - un objet dont chaque membre indique un suffixe de variable d'environnement et la valeur de ce suffixe. Le script `indird` ajoute automatiquement à cet objet les variables suivantes:
  - `${env_prefix}HOST` - le nom `hostname` du système
  - `${env_prefix}CONF` - le *\<tag>* spécifié
  - `${env_prefix}PATH` - la valeur de `path`
  - `${env_prefix}FILE` - le nom du fichier en cours de traitement
  - `${env_prefix}CODE` - la code de retour de l'`action` (voir ci-dessous) après son exécution)

* `filetypes` [o] - Un objet dont chaque membre est un objet décrivant un type de fichier à gérer par `indird`, avec les (sous-)membres obligatoires suivants :
  - `desc` - un texte de description du type, pour usage dans les logs
  - `method` - la méthode, `fileglob` ou `regexp`, du filtre de nom de fichiers. La méthode `fileglob` utilise le *matching* du shell (`bash`), le méthode `regexp` utilise `grep`
  - `pattern` - le motif pour le filtre

* `actions` [o] - Un objet dont chaque membre est un objet décrivant une commande shell à exécuter (passée à `sh -c`), avec les (sous-)membres suivants:
  - `desc` [f] - un texte de description
  - `cmd` [o] - la commande à exécuter, qui sera passée à sh -c
  - `chdir` [f] - un répertoire de travail optionel pour la commande
  - `env` [f] - un complément de variables d'environnement pour la commande, analogue au `env` global

* `ends` [f] - Un objet dont chaque membre est un objet décrivant une commande shell à exécuter (passée à `sh -c`), avec les (sous-)membres suivants:
  - `desc` [f] - un texte de description
  - `cmd` [o] - la commande à exécuter, qui sera passée à sh -c
  - `chdir` [f] - un répertoire de travail optionel pour la commande
  - `env` [f] - un complément de variables d'environnement pour la commande, analogue au `env` global
  - `stdin` [f] - les valeurs 'out', 'err', 'all' exclusivement, indiquant quel(s) élément(s) des stdout/stderr de l'`action` associée seront passés en stdin à la commande de ce membre de `ends`

* `logs` [f] - Un objet dont chaque membre est un objet décrivant une méthode de journalisation à employer pour le résultat de l'action associée, avec les (sous-)membres suivants:
  - `desc` [f] - un texte de description
  - `type` [o] - le type du log, actuellement `file` ou `syslog` seulement
  - `args` [f] - les arguments du log, qui varient selon `type`. Pour `file`, on a la valeur obigatoire `path` qui indique le nom du fichier de log et pour `syslog`, deux arguments :
      + `facility` [o] - la 'facility' de syslog. Valeurs admises : `user` et `daemon`
      + `level` [o] - le niveau de log, parmi toutes les valeurs admises par logger(1), soit `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug` ainsi que `panic` pour `emerg`, `error` pour `err` et `warn` pour `warning`

* `conds` [f] - Un objet dont chaque membre est une commande à exécuter, dont le code de retour détermine une condition pour les `rules` ci-dessous

* `rules` [o] - l'objet principal, dont chaque membre est un jeu de règles pour gérer le type de fichiers défini par le membre de `filetypes` du même nom. Chaque objet se compose d'un tableau d'étapes (steps) ayant chacune la structure suivante :
  - `desc` [f] - un texte de description
  - `hide` [f] - une valeur `true` ou `false` (par défaut). Si true, l'étape (step) est ignorée
  - `action` [f] - le nom d'une action A TERMINER
  - `ends` [f] - le
  - `logs` [f] - le
  - `x` [f] - le
* `x` [o] - le
  - `x` [f] - le

## Exemples de fichiers de configuration

[indird.yml]: indird.yml "fichier local"
[indird/indird.conf]: indird/indird.conf "fichier local"

La définition du projet a donné lieu à la rédaction d'un exemple de fichier de configuration en YAML : [indird.yml][]
Les nombreux commentaires du fichier, reprenant des parties de cette documentation, permet de situer celles-ci dans leur contexte.
Ce fichier YAML peut être transformé en JSON avec différents outils open-source, par exemple :

    A TERMINER

Le fichier [indird/indird.conf][] contient un exemple de fichier de configuration généré pour un des hosts de [indird.yml][]

## Algorithme de fonctionnement

Il a été mis au point après discussions entre TDE, CGD et CTY.
Après lecture et vérification du fichier de configuration, `indird` entre dans la boucle principale suivante:
```
indéfiniment (jusqu'à un arrêt par SIGTERM)
  sortir de 'sleep' (par fin du délai ou par 'kill') et sauver le dernier 'mtime' de `path`
  tant que `path` a été modifié ('mtime') depuis le dernier tour (de cette boucle)
    pour toutes les règles membres de l'objet global `rules`
      pour tous les fichiers correspondant au membre de l'objet global `filetypes` de la règle
	pour toutes les étapes de la règle
	  lancer l'action de la règle
	  pour toutes les fins (`ends`) de la règle
	    vérifier si la condition `cond` de fin s'applique
	    exécuter le `end` correspondant défini dans l'objet global `ends` des fins
	  pour tous les (`logs`) de la règle
	    logger le résultat de l'action de la règle
le notify envoyé par le service indirdwake fait sortir du 'sleep'
```

## Proposed Indird config file (by TDE)

    A TERMINER

As decided with CGD and CTY on 2019-01-09, here are some YAML config examples
to be used by an `indird` daemon (as seen with CTY)

The [indird.yml][] file contains three example configs derived from
actual running file-flow setups.

Data structures and comments in [indird.yml][] give an effective
guideline for the implementation of the daemon.

You can extract these configs (and check the file correctness) by running

```
yaml2json indird.yml | jq .hosts.procom1.confs.sspdamoc
yaml2json indird.yml | jq .hosts.procom1.confs.sspnice
# optionally use json2yaml
yaml2json indird.yml | jq .hosts.profnt2.confs.sspnice	| json2yaml -
```

To install yaml2json and json2yaml

```
curl -sL https://deb.nodesource.com/setup_6.x | sudo bash -
sudo npm install -g yamljs
```
