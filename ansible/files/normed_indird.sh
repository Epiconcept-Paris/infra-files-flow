#!/bin/bash

ABS=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

IFS=$'\n'
for i in $($ABS/../indirdctl check); do 
	echo "SERVEUR;serveur;services;SERVICE_DOWN;service $i down"
done