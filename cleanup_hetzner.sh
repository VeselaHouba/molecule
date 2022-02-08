#!/usr/bin/env bash
# quick and dirty - drop all servers in project and all ssh keys except one defined by "PROTECTED_KEY"
if [ -z $HCLOUD_TOKEN ]; then 
  echo "Set HCLOUD_TOKEN env variable!"
  exit 1
fi
PROTECTED_KEY=3404693
function servers () {
  curl \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $HCLOUD_TOKEN" \
    'https://api.hetzner.cloud/v1/servers' \
  | jq '.servers[].id'
}

function ssh_keys () {
  curl \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $HCLOUD_TOKEN" \
    'https://api.hetzner.cloud/v1/ssh_keys' \
  | jq '.ssh_keys[].id'
}

function delete_srv () {
  dropsrv=$1
  curl -X DELETE \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $HCLOUD_TOKEN" \
    https://api.hetzner.cloud/v1/servers/$dropsrv
}

function delete_key () {
  dropkey=$1
  curl -X DELETE \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $HCLOUD_TOKEN" \
    https://api.hetzner.cloud/v1/ssh_keys/$dropkey
}

srv=$(servers)
for i in $srv; do
  echo "Dropping server $i"
  delete_srv $i
  sleep 5
done

keys=$(ssh_keys)
for i in $keys; do
  if [ $i -ne $PROTECTED_KEY ];then
    echo "Dropping key $i"
    delete_key $i
  else
    echo "protected key"
  fi
  sleep 5
done
