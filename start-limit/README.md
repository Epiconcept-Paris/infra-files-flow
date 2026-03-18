# Erreurs de StartLimit avec indirdwake

## Découverte

Début 2023, grace au déploiement de `grafana`, des messages répétés du type  
`<date> <system>systemd[1]: indirdwake@<stream>.service: Failed with result 'start-limit-hit'.`  
ont été remarqués dans `/var/log/daemon.log` sur un système Debian 9 avec beaucoup d'instances `indird`.

## Développement d'un correctif

Il a été rapidement déterminé que les messages montraient la nécessité d'un paramètre `StartLimitInterval*` de `systemd`.  
Tout d'abord, un paramètre `StartLimitIntervalSec=0` a été ajouté à `indirdwake@.path`. Il était reconnu (pas d'erreur) mais n'avait aucun effet notable.  
Ensuite, ce paramètre a été déplacé dans `indirdwake@.service` où `systemd-analyze verify indirdwake@.service` l'a immédiatement détecté comme invalide.  
Enfin, la poursuite des recherches a conduit à la découverte d'un paramètre `SmartLimitInterval=` sur les différentes releases de `systemd` des versions Debian 9,10,11,12,13.
Des tests sur la version 232 de `systemd` sur Debian 9 ont montré que ce paramètre était non seulement reconnu dans `indirdwake@.service`, mais aussi **fonctionnait** comme attendu.

## Vérification de `SmartLimitInterval` dans le code source de systemd

La dernière version de `systemd` pour les différentes versions de Debian Linux (`[+~]deb[0-9]+`), avec la dernière mise à jour pour Debian (`u[0-9]+`) se trouve dans le fichier `systemd-release`.  
Le processus de fetch, untar et grep a été consigné dans le script `check-systemd-sources`, produisant le fichier `StartLimitInter` des occurences dans les sources de la chaîne `StartLimitInter`.  
Comme le montre ce fichier `StartLimitInter`, un commentaire mentionnant le paramètre `SmartLimitInterval=` a été ajouté à la version **229** dans tous les fichiers `work/systemd-*/NEWS` **après la version 232** de `systemd` (la version pour Debian 9, pour laquelle la prise en compte du paramètre a été vérifiée), ce qui semble annoncer que le paramètre `StartLimitInterval` fonctionnera dans les versions Debian 9,10,11,12 et 13.

Voici le commentaire:
```
        * The settings StartLimitBurst=, StartLimitInterval=, StartLimitAction=
          and RebootArgument= have been moved from the [Service] section of
          unit files to [Unit], and they are now supported on all unit types,
          not just service units. Of course, systemd will continue to
          understand these settings also at the old location, in order to
          maintain compatibility.
```

# StartLimit errors with indirdwake

## Discovery

Early 2023, thanks to the deployment of `grafana`, repeated messages like  
`<date> <system>systemd[1]: indirdwake@<stream>.service: Failed with result 'start-limit-hit'.`  
were noticed in `/var/log/daemon.log` on a Debian 9 system running many instances of `indird`.

## Fix

It was quickly determined that the messages were showing the need for a `SmartLimitInterval*` systemd setting.  
At first, a `StartLimitIntervalSec=0` setting was put in `indirdwake@.path`. It was recognized (no error) but it had no noticeable effect.  
Then this setting was moved to `indirdwake@.service` where `systemd-analyze verify indirdwake@.service` immediately detected it as invalid.  
Finally, further research led to the discovery of a `SmartLimitInterval=` setting on the different `systemd` releases of Debian versions 9,10,11,12,13.
Tests on version 232 of systemd on Debian 9 showed that this setting was not only recognized in `indirdwake@.service`, but also **worked** as expected.

## Check for `SmartLimitInterval` in systemd's source code

The last version of `systemd` for the different versions of Debian Linux (`[+~]deb[0-9]+`) together with the corresponding last update for Debian (`u[0-9]+`) can be found in the `systemd-releases` file.  
The fetch, untar and grep process was consigned in the `check-systemd-sources` script, producing the `StartLimitInter` file of occurences in the sources of the `StartLimitInter` string.  
As this `StartLimitInter` file points out to, a comment mentionning the `StartLimitInterval=` parameter has been added to version **229** in all the `work/systemd-*/NEWS` files **after version 232** of `systemd` (the version for Debian 9, for which the handling of the parameter has been checked) that seems to announce that the `SmartLimitInterval` setting will work on Debian 9,10,11,12 and 13 versions.

Here is the comment:
```
        * The settings StartLimitBurst=, StartLimitInterval=, StartLimitAction=
          and RebootArgument= have been moved from the [Service] section of
          unit files to [Unit], and they are now supported on all unit types,
          not just service units. Of course, systemd will continue to
          understand these settings also at the old location, in order to
          maintain compatibility.
```

2026-03-18
