# Exemples de fichiers générés

## sur le serveur de fichiers

* cedric@procom1:~$ cat /etc/incron.d/sspnice                                                                                                           
```
/space/home/sspnice/hl7 IN_CLOSE_WRITE,IN_MOVED_TO /usr/local/bin/sspnice $@/$#
```
* cedric@procom1:~$ cat /usr/local/bin/sspnice
```
#!/bin/bash

rsync -e "ssh -i /space/home/sspnice/.ssh/rsync -l sspnice" "$1" \
      --whole-file --partial-dir ../tmp profnt2.front2:hl7
```

## sur le serveur frontal

* cedric@profnt2:~$ cat /etc/incron.d/sspnice 
```
/space/applistmp/sspnice/hl7 IN_MOVED_TO sudo -u www-data /usr/bin/php /space/www/apps/ssp/ressources/hl7/import.php $@/$#
```
