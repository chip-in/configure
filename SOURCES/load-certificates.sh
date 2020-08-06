#!/bin/bash

LOGGER=$(basename -s .sh $0)
. /usr/lib/chip-in/functions.sh

function check_cert() {
  if [ -r /etc/nginx/conf.d/cert.conf.server ]; then
    certfile=$(sed -n -e '/^ *ssl_certificate/s/^ *ssl_certificate *\([^ ]*\);$/\1/p' < /etc/nginx/conf.d/cert.conf.server)
    if [ -n "$certfile" -a -r "$certfile" ]; then
      return 0
    fi
  fi
  return 1
}
function setup_cert() {
  message "put nginx ssl setting"
  cat > /etc/nginx/conf.d/cert.conf.server << '__EOF'
listen 443 ssl;
# Redirect setting for SSL jwtIssuer
set $do_redirect 0;
if ($scheme = http) {
    set $do_redirect 1;
}
# for certbot
if ($request_uri ~* /.well-known/) {
    set $do_redirect 0;
}
if ($do_redirect = 1) {
    return 301 https://$host:443$request_uri;
}
ssl_prefer_server_ciphers  on;
ssl_protocols TLSv1.2;
__EOF
  cat >> /etc/nginx/conf.d/cert.conf.server << __EOF
ssl_certificate $1;
ssl_certificate_key $2;
__EOF

  reloadNginx
}

function letsEncrypt () {
  if [ -z "$CORE_FQDN" ]; then
    error "CORE_FQDN must be specified"
  fi
  if [ -z "$LETS_ENCRYPT_EMAIL" ]; then
    error "LETS_ENCRYPT_EMAIL must be specified"
  fi
  JWT_ISSUER_OPT=
  if [ -n "$JWT_ISSUER_FQDN" ]; then
    JWT_ISSUER_OPT="-d $JWT_ISSUER_FQDN"
  fi
  message "call certbot"
  sleep 1
  if certbot certificates -d $CORE_FQDN 2>&1 | grep -q 'Certificate Name:'; then
    message "the ceritficate for $CORE_FQDN is already issued."
  else
    local count=${GIP_CHECK_RETRY:-40}
    local interval=${GIP_CHECK_INTERVAL:-15}
    while ! (host_result=$(host -4 $CORE_FQDN) && my_gip=$(curl -s https://api.ipify.org) && [ "${host_result##* }" == "$my_gip" ])
    do
      count=$(( $count - 1 ))
      if [ $count -eq 0 ]; then
              break
      fi
      sleep $interval
      message "check global ip: retry check $CORE_FQDN interval=$interval rest=$count"
    done
    if [ $count -eq 0 ]; then
      error "check global ip: exceed max retry count ${GIP_CHECK_RETRY:-10}"
    elif ! certbot certonly --webroot -w /usr/share/nginx/html -d $CORE_FQDN $JWT_ISSUER_OPT \
      --email "$LETS_ENCRYPT_EMAIL" --no-eff-email --agree-tos; then
      error "fail to get certificate from lets encrypt"
    fi
  fi
  setup_cert "/etc/letsencrypt/live/$CORE_FQDN/fullchain.pem" "/etc/letsencrypt/live/$CORE_FQDN/privkey.pem"
}

if check_cert; then
  message "certificate is already set up"
  exit 0
fi

if [ -n "$CERTIFICATE_MODE" ]; then
  case "$CERTIFICATE_MODE" in
    "selfsigned")
      setup_cert /etc/pki/tls/certs/localhost.crt /etc/pki/tls/private/localhost.key
      ;;
    "certbot")
      letsEncrypt
      ;;
    *)
      error "unknown CERTIFICATE_MODE: $CERTIFICATE_MODE"
      ;;
  esac
fi
