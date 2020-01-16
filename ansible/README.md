# Usage

* en attendant le changement d'inventaire : ```ansible-playbook -i ~/bin/list_new_servers.txt deploiement.yml -D```

# Sources

* déploiement manuel par TDE : https://github.com/Epiconcept-Paris/infra-journals-indexed/blob/master/indexed/all/tde/journal/2019-11-25_TDE_indird.md

# Todo

* utiliser l'inventaire 2019 par TDE
* paths dont dépend le logiciel (aujourd'hui, infra-data-misc), à gérer en fonction des utilisateurs
* intégrer et tester les accès ssh entre procom1 et les frontaux
* intégrer la création des accès SFTP sur procom (récup depuis https://github.com/Epiconcept-Paris/infra-mini-plays, ou à minima rationnalisation des comptes)