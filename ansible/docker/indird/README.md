# Conteneur de test indird

Micro-infrastructure de test pour le déploiement d'indird via le playbook `ansible/deploiement.yml`.
Ansible est joué depuis le poste de travail, ce conteneur est la cible.
Le but est d'améliorer la prise en compte de patterns de fichiers à traiter.

## Contenu

- `Dockerfile` — image Debian 12 avec systemd, SSH et les outils nécessaires
- `indird.conf` — configuration extraite d'un serveur de production (`/etc/indird.conf`)
- `hosts` — inventaire Ansible utilisant le connecteur `community.docker.docker`
- `docker-compose.yml` — lance le conteneur en mode privilégié (requis pour systemd)

## 1. Lancer le conteneur

Depuis ce dossier :

```bash
# Docker récent
docker compose up -d --build

# Ancien Docker
docker-compose up -d --build
```

## 2. Déployer indird

`indird` est ajouté aux cibles du second play de `deploiement.yml`. L'inventaire `hosts` utilise le connecteur `community.docker.docker` — pas besoin de SSH.

```bash
cedric@Mnementh6 ~/www/e/infra-files-flow/ansible (mod - master) $ ansible-playbook -i /home/cedric/www/e/infra-files-flow/ansible/docker/indird/hosts deploiement.yml -t install
```

## 3. Tester

Se connecter dans le conteneur, lancer le service
```bash
service indird@GEDLAD91_KS_L1L2_LAD start
```

et déposer des fichiers dans le répertoire surveillé :

```bash
docker exec -it indird bash
cp <fichier> /space/home/GEDLAD91/KS/L1L2/LAD/

/space/home/GEDLAD91/KS/L1L2/LAD# for i in {1..100}; do touch fichierL1L2-${i}.hl7; done
/space/home/GEDLAD91/KS/L1L2/LAD# for i in {1..100}; do touch fichierL1L2-V2-${i}.hl7; done
```

Vérifier le traitement dans les logs et les répertoires `done` / `fail` :

```bash
tail -f /var/log/indird-GEDLAD91_KS_L1L2_LAD.log
ls /space/home/GEDLAD91/done/KS/L1L2/LAD/
ls /space/home/GEDLAD91/fail/KS/L1L2/LAD/
```

Les transferts seront en erreur (pas de cible, peut être même pas rsync installé), mais cela permet de valider le bon traitement en l'état)
