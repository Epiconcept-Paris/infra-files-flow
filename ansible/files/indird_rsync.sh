#!/bin/bash

# Usage: indird_transfert.sh <ssh_key> <user> <file> <srvdest> <remotedir>
# Example: indird_transfert.sh /home/me/.ssh/key me /tmp/a.txt server /data/

LOGFILE="/var/log/indird_transfert.log"
MAX_RETRY=5
TIMEOUT=20   # secondes pour tuer rsync si bloqué

ssh_key="$1"
user="$2"
file="$3"
srvdest="$4"
remotedir="$5"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') user=$user srvdest=$srvdest file=$file : $1" >> "$LOGFILE"
}

if [[ $# -ne 5 ]]; then
    echo "Usage: $0 <ssh_key> <user> <file> <srvdest> <remotedir>"
    exit 1
fi

if [[ ! -f "$file" ]]; then
    echo "Fichier introuvable : $file"
    exit 2
fi

chmod 0664 "$file"

attempt=1
while (( attempt <= MAX_RETRY )); do
    log "Tentative $attempt/5 : début transfert"

    timeout "$TIMEOUT" rsync -a \
        -e "ssh -i $ssh_key -l $user" \
        "$file" \
        --no-group --whole-file --partial-dir ../tmp \
        "$srvdest:$remotedir"

    rc=$?

    if [[ $rc -eq 0 ]]; then
        log "Succès"
        exit 0
    else
        log "Échec tentative $attempt rc=$rc"
    fi

    ((attempt++))
    sleep 2
done

log "ÉCHEC FINAL après $MAX_RETRY tentatives"
exit 3
