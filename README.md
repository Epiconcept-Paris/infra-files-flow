# infra_files_flow
Scripts de gestion de répertoires d'arrivée

## Installation du prototype de script indird

Il faut copier les fichiers aux emplacements suivants :
````
indird			/usr/local/bin
indird.conf		/etc
indird@.service		/etc/systemd/system
indirdwake@.service	/etc/systemd/system
indirdwake@.path	/etc/systemd/system
````
Après modification du fichier indird.conf, il faut lancer :
````
# systemctl enable indird@<tag>.service
# systemctl enable indirdwake@<tag>.path

# systemctl start indird@<tag>.service
````
et pour arrêter / désinstaller :

````
# systemctl stop indird@<tag>.service
# systemctl disable indirdwake@<tag>.path
# systemctl disable indird@<tag>.service

````

## Proposed Indird config file

[indird.yml]: ./indird.yml "local file"

As decided with CGD and CTY on 2019-01-09, here is some YAML configs examples
to be used as `indird` daemon (as seen with CTY)

The [indird.yml][] file contains three example configs derived from
actual running file flow setups.

Data structure and comments in [indird.yml][] gives a effective
guideline for implementation of the daemon.

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

My interpretation of the specs resulting from meeting with CGD and CTY

```
# optionally could also wakeup from inotify
wakeup on signal or wakeup from sleep and store last touch time of spool dir on first wakeup
if dir untouched since last wakeup or if spool dir locked return
protected by lock
  while dir touched since last loop
    loop on rules of conf
      loop on files of rules
        loop on actions of rules using timeout or retry option
          loop on on_return of action choosing fronm OK or KO
        loop on log_to of rules
```
