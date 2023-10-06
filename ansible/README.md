# Usage déploiement indird

* en attendant le changement d'inventaire
```
ansible-playbook -i ~/bin/list_new_servers.txt deploiement.yml -D
```

* pour générer les configurations dans /tmp/
```
ansible-playbook -i ~/bin/list_new_servers.txt deploiement.yml -D -t local
```

* pour juste déployer une maj de conf (retirer le -C quand c'est validé) en ne relançant que les process contenant GEDLAD12
```
ANSIBLE_MAX_DIFF_SIZE=1000000 ansible-playbook -i ~/bin/list_new_servers.txt deploiement.yml -DC -t reconf -e filter=GEDLAD12
```

Note: l'exécution en Check va planter avec ce message, sans importance ici
```
fatal: [procom1.admin2]: FAILED! => {"msg": "'dict object' has no attribute 'stdout_lines'"}
fatal: [profntd1.admin2]: FAILED! => {"msg": "'dict object' has no attribute 'stdout_lines'"}
```

# Docker de test

* lancement des containers
```
docker-compose --file=docker/compose/docker-compose.yml --project-name=lsyncd up
```

* tester le fonctionnement
```
ansible all -i docker/hosts -m ping
```

* déploiement 
```
ansible-playbook -i docker/hosts lsyncd.yml
```

* test conf lsyncd manuelle
```
lsyncd -nodaemon /etc/lsyncd.lad_test.conf
```

# Sources

* déploiement manuel par TDE : https://github.com/Epiconcept-Paris/infra-journals-indexed/blob/master/indexed/all/tde/journal/2019-11-25_TDE_indird.md

# Todo

* intégrer la gestion des liens
```
(preprod front 2)cedric@prefnt2:/space/applisdata/esisdoccu/LAD_RP$ ls -lha
total 8.0K
drwxr-xr-x 2 www-data www-data 4.0K Jul  7 15:44 .
drwxr-xr-x 6 www-data www-data 4.0K Jul  7 15:42 ..
lrwxrwxrwx 1 www-data www-data   39 Jul  7 15:44 lad_test -> /space/home/lad_lsyncd_preprod/lad_test
lrwxrwxrwx 1 www-data www-data   44 Jul  7 15:44 lad_test_mhu -> /space/home/lad_lsyncd_preprod/lad_test_mhu/

cedric@profntd1:/space/applisdata/esisdoccu$ sudo -u www-data mkdir /space/applisdata/esisdoccu/LAD_RP
cedric@profntd1:/space/applisdata/esisdoccu$ sudo -u www-data ln -s /space/home/lad_lsyncd_prod/LADDOCCU38/ /space/applisdata/esisdoccu/LAD_RP/

cedric@profntd1:/space/applisdata/esisdoccu/LAD_RP$ ls -lh
total 0
lrwxrwxrwx 1 www-data www-data 39 Sep  4 16:45 LADDOCCU38 -> /space/home/lad_lsyncd_prod/LADDOCCU38/
cedric@profntd1:/space/applisdata/esisdoccu/LAD_RP$ ls LADDOCCU38/KU/RP/
cedric
```

* utiliser l'inventaire 2019 par TDE
* paths dont dépend le logiciel (aujourd'hui, infra-data-misc), à gérer en fonction des utilisateurs
* intégrer et tester les accès ssh entre procom1 et les frontaux
* intégrer la création des accès SFTP sur procom (récup depuis https://github.com/Epiconcept-Paris/infra-mini-plays, ou à minima rationnalisation des comptes)
* commit sur /etc/ à ajouter

# Lsyncd

## TODO

* ré-intégrer procom1:/etc/lsyncd/conf.d/* à la conf au lieu de générer selon le template
  * infra-files-flow/ansible/templates/ged_lsyncd_preprod.conf.j2
  * infra-files-flow/ansible/templates/lad_lsyncd_preprod.conf.j2

## Déploiement

* ansible-playbook lsyncd_users.yml -D
* **attention, procom1:/etc/lsyncd/conf.d/* gérer à la main, à ré-intégrer** ansible-playbook lsyncd.yml -D

## Test

* ansible-playbook lsyncd_tests_KU.yml 
* ansible-playbook lsyncd_tests_GED.yml 

## Flux

### Légende

* => flux rsync over SSH
* -> symlink au sein d'un serveur

### GED

* procom1:/space/home/lad_test_mhu/GED/ => prefnt2:/space/home/lad_lsyncd_preprod/GED/ -> /space/applisdata/esisdoccu/GED/geddoccu_test

### KU/RP

* procom1:/space/home/lad_test/KU 		=> prefnt2:/space/home/lad_lsyncd_preprod/lad_test/KU 		-> /space/applisdata/esisdoccu/LAD_RP/lad_test/KU
* procom1:/space/home/lad_test_mhu/KU 	=> prefnt2:/space/home/lad_lsyncd_preprod/lad_test_mhu/KU 	-> /space/applisdata/esisdoccu/LAD_RP/lad_test_mhu/KU
* procom1:/space/home/LADDOCCU38 		=> profntd1:/space/home/lad_lsyncd_prod 					-> /space/applisdata/esisdoccu-alpes/LAD_RP/LADDOCCU38
