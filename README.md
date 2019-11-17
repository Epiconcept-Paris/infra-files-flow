# infra_files_flow
Configuration systemd et script de gestion de répertoires d'arrivée

## TODO

* shell limité (cf select login, shell, server from usersunix where login in ('esis-data-pre', 'esis-data-pro', 'sspnice', 'sspdamoc'); sur Work)

## Installation du prototype de script indird

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
et pour arrêter / désinstaller :

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
NOTE : En cas, de modification de l'élément `path` de la configuration, le lien symbolique `/run/indird/<tag>_path` vers le chemin indiqué par `path` est automatiquement mis à jour par `indird`

Le fichier de log est pour l'instant `/var/log/indird.log` et les fichiers de fonctionnement vont dans `/run/indird` (créé si nécessaire).

## Proposed Indird config file (by TDE)

[indird.yml]: ./indird.yml "local file"

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
yaml2json indird.yml | jq .hosts.profnt2.confs.sspnice  | json2yaml -
```

To install yaml2json and json2yaml

```
curl -sL https://deb.nodesource.com/setup_6.x | sudo bash -
sudo npm install -g yamljs
```

## Proposed Indird pseudo code

Interpretation of the specs, resulting from meetings between TDE, CGD and CTY:

```
# wakeup from sleep (end or kill) and save last mtime of spool dir
# while dir touched since last loop
#   loop on filetypes (rules members)
#	  loop on matching files
#	    loop on rule's steps
#	      run action of step
#	      loop on ends of step (using cond)
#	      loop on logs of step
# optionally could also wakeup from inotify
```
