#!/bin/sh

Prg=`basename $0`
test "$1" || { echo "Usage: $Prg <host>" >&2; exit 1; }
yaml2json ../indird.yml | jq .hosts.$1.confs | sed -e '1i\
#\
#	indird.conf\
#' \
-e 's/^ \{16\}/\t\t\t\t/' \
-e 's/^ \{14\}/\t\t\t    /' \
-e 's/^ \{12\}/\t\t\t/' \
-e 's/^ \{10\}/\t\t    /' \
-e 's/^ \{8\}/\t\t/' \
-e 's/^ \{6\}/\t    /' \
-e 's/^ \{4\}/\t/' \
-e 's/^ \{2\}/    /'
