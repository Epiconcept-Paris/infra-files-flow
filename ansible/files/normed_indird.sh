#!/bin/bash

ABS=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

IFS=$'\n'
for i in $($ABS/../indirdctl check); do 
	echo "SERVEUR;serveur;services;SERVICE_DOWN;service $i down"
done

IFS=$'\n'
for i in $(grep cmd /etc/indird.conf |grep -oe '/space/applisdata.*[$]' |sort |uniq -c | awk '$1 != 1'); do 
	echo "SERVEUR;serveur;services;INDIRD_CONFLIT;multiples occurences d'un chemin de traitement: $i "
done	