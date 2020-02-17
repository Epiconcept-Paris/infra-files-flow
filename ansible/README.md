# Usage

* en attendant le changement d'inventaire
```
ansible-playbook -i ~/bin/list_new_servers.txt deploiement.yml -D
```

* pour générer les configurations dans /tmp/
```
ansible-playbook -i ~/bin/list_new_servers.txt deploiement.yml -D -t local
```

* pour juste déployer une maj de conf (retirer le -C quand c'est validé)
```
ansible-playbook -i ~/bin/list_new_servers.txt deploiement.yml -DC -t reconf
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

* utiliser l'inventaire 2019 par TDE
* paths dont dépend le logiciel (aujourd'hui, infra-data-misc), à gérer en fonction des utilisateurs
* intégrer et tester les accès ssh entre procom1 et les frontaux
* intégrer la création des accès SFTP sur procom (récup depuis https://github.com/Epiconcept-Paris/infra-mini-plays, ou à minima rationnalisation des comptes)
* commit sur /etc/ à ajouter