#!/bin/bash

CONF_FILE="/etc/indird.conf"

# Vérifie que jq est installé
command -v jq >/dev/null 2>&1 || { echo "jq requis pour parser $CONF_FILE"; exit 1; }

# Parcours chaque path du JSON
jq -r '.[].path' "$CONF_FILE" | while read -r path; do

    if [ ! -e "$path" ]; then
        echo "dossier inexistant : $path"
    elif [ ! -d "$path" ] && [ ! -L "$path" ]; then
        echo "dossier/lien invalide : $path"
    fi

done
