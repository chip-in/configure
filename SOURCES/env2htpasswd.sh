#!/bin/bash
HTPASSWD=/etc/nginx/htpasswd
echo "# generated password file" > $HTPASSWD
IFS=','
for entry in $JWT_ISSUER_HTPASSWD; do
  echo "$entry" >> $HTPASSWD
done
