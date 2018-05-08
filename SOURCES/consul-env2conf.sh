#!/bin/bash

BOOTSTRAP_EXPECT=1
RETRY_JOIN=
if [ -n "$PEERS" ]; then
  RETRY_JOIN="retry_join: [$PEERS],"
fi

ENCRYPT=
if [ -n "$CONSUL_SHARED_KEY" ]; then
  ENCRYPT="encrypt: [$CONSUL_SHARED_KEY],"
fi

cat > /etc/consul.conf << __EOF
{
  "data_dir" : "/var/consul",
  "log_level": "INFO",
  "bootstrap_expect": ${BOOTSTRAP_EXPECT},
  ${RETRY_JOIN}
  ${ENCRYPT}
  "client_addr": "0.0.0.0",
  "server": true
}
__EOF
