#!/bin/sh
#
#	mkconf.sh - Output local indird.conf for tests
#	DO NOT use in production (if you could) !
#
Prg=`basename $0`
test "$1" || { echo "Usage: $Prg <host>" >&2; exit 1; }
yaml2json ../indird.yml | jq .hosts.$1.confs | sed -e "1i\\
#\\
#	indird.conf for $1\\
#" -e 's/  /    /g' | unexpand	# WARNING: will also unexpand in values !
