Vocabulaire
===========

* serveur d'entrée des fichiers, ou serveur de fichiers : serveur où les fichiers sont déposés par un intervenant externe à Epiconcept (sftp, transfert node, etc...)
* serveur apache, frontal, serveur de traitement : frontal Apache/PHP qui sert l'application web et assure le traitement des fichiers (via un script PHP fournit par l'application)
* flux de fichiers : un ensemble de fichiers de nature identique, déposés dans un dossier précis sur un serveur de fichiers, et traités sur un serveur apache (donc transférés entre les deux). En résumé, pour le définir, nous avons donc

  * un serveur de fichiers, sur lequel nous avons un chemin de dépot
  * un serveur apache, sur lequel nous avons un chemin de stockage et un script PHP de traitement à exécuter

Workflow
========

* des fichiers sont déposés sur un serveur d'entrée dans un dossier propre au flux

  * via SFTP
  * protocole spécifique 

* ils doivent être copiés sur un serveur de traitement, un frontal Apache/PHP, dans un dossier propre au flux

  * un log doit permettre de suivre chaque fichier transféré
  * les fichiers correctement transférés doivent être archivés dans un dossier spécifique (dans une autre partie de l'arborescence par rapport au dossier d'entrée)

* sur ce frontal, un script sera appelé pour traiter le fichier

  * un log doit tracer chaque traitement, avec son résultat et d'éventuelles traces sur les sorties error/std
  * les fichiers sont archivés si un drapeau spécifique est activé (sinon c'est le script de traitement qui s'en occupe)

* optionnellement (ce n'est pas le cas de tous les flux), le script peut fournir un fichier d'acquitement qui doit être renvoyé en retour

  * il le dépose dans un dossier 'out', ou le fournit à un script pour traitement immédiat
  * ce fichier doit in fine être déposé dans un dossier 'out' sur le serveur de fichiers

Contraintes
===========

* traitement en temps réel à l'échelle de quelques secondes
* tous les chemins peuvent être configurés indépendamment (via Ansible et remplacement dans un template de script ou de fichier de conf au besoin)

  * typiquement, le dépot se fait dans /space/home/$user/inbox, mais sur un flux c'est totalement différent
  * le dossier sur le frontal est généralement dans /space/applistmp/$application/hl7
  * le script est variable
  * les logs seront généralement dans /var/log/epiconcept/flux/$nomflux.log (et mis en rotation via nos scripts existants)

* liberté sur la technologie utilisée, avec juste une discussion sur la facilité de déploiement, la non multiplication des services/daemons
* journaux pour tous les traitements réalisés, avec l'idée de sortir (travail epiconcept) un CR à donner aux chefs de projets sur l'activité du flux
* archivage des fichiers une fois traités
* possibilité de relancer le traitement sur des fichiers qui n'auraient pas été traités dans le flux (genre serveur éteint ou injoignable), via cron ou manuellement (pour inotify, un touch sur les fichiers non traités suffirait)
* possibilité de lister les fichiers en attente de traitement, sur le serveur de fichiers ou sur le serveur de traitement (s'ils ne sont plus des fichiers sur disque, auquel cas ls suffit)

Livrable
========

* ensemble de script et configuration, avec procédure manuelle de déploiement (la partie Ansible sera faite par Epiconcept)
* documentation sur l'usage normal et la récupération de fonctionnement en manuel
* documentation technique (choix, logiciels, etc...) 
