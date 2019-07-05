#!/bin/bash

# Import our environment variables from systemd
tr "\000" "\n" < /proc/1/environ > /var/run/SYSTEMD_ENV

. /var/run/SYSTEMD_ENV

BOOTSTRAP_EXPECT=1
RETRY_JOIN=
if [ -n "$PEERS" ]; then
  RETRY_JOIN="\"retry_join\": [$PEERS],"
  OIFS=$IFS;IFS=","
  set -- $PEERS
  BOOTSTRAP_EXPECT=$#
  IFS=$OIFS
fi

ENCRYPT=
if [ -n "$CONSUL_SHARED_KEY" ]; then
  ENCRYPT="\"encrypt\": [$CONSUL_SHARED_KEY],"
fi

NODE_NAME=
if [ -n "$CONSUL_NODE_NAME" ]; then
  NODE_NAME="\"node_name\": \"$CONSUL_NODE_NAME\","
fi

ACL=
if [ -n "$CONSUL_ACL_ENABLED" ]; then
  ACL=',"acl" : { "enabled": true, "default_policy": "deny", "enable_token_persistence": true}'
fi
cat > /etc/consul.json << __EOF
{
  "data_dir" : "/var/consul",
  "log_level": "INFO",
  "bootstrap_expect": ${BOOTSTRAP_EXPECT},
  ${RETRY_JOIN}
  ${ENCRYPT}
  ${NODE_NAME}
  "client_addr": "0.0.0.0",
  "server": true,
  "disable_host_node_id": true
  ${ACL}
}
__EOF