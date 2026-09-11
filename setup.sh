#!/usr/bin/env bash

# Stop any running process
miner stop 2>/dev/null
killall -9 miner-run screen quanpool-miner 2>/dev/null

mkdir -p /hive/miners/custom/quanpool
cd /hive/miners/custom/quanpool

# Download miner binary if not present
if [[ ! -f "quanpool-miner" ]]; then
  echo "Downloading package..."
  curl -sL "https://github.com/totosugito/dummy-data/raw/main/quanpool-1.0.0.tar.gz" | tar -xz -C /hive/miners/custom/
fi

# 1. Manifest
printf '%s\n' \
'CUSTOM_NAME=quanpool' \
'CUSTOM_VERSION=1.0.0' \
'CUSTOM_BUILD=0' \
'CUSTOM_CONFIG_FILENAME=/hive/miners/custom/quanpool/quanpool.conf' \
'CUSTOM_LOG_BASENAME=/var/log/miner/custom/quanpool' \
'MINER_NAME=quanpool' \
'MINER_VERSION=1.0.0' \
'MINER_CONFIG_FILENAME=/hive/miners/custom/quanpool/quanpool.conf' \
'MINER_API_PORT=9900' \
'MINER_LOG_BASENAME=/var/log/miner/custom/quanpool' \
'' \
'function miner_ver() {' \
'  echo "$MINER_VERSION"' \
'}' \
> /hive/miners/custom/quanpool/h-manifest.conf

# 2. Config generator
printf '%s\n' \
'#!/usr/bin/env bash' \
'' \
'function miner_config_gen() {' \
'  [[ -z "$CUSTOM_CONFIG_FILENAME" ]] && CUSTOM_CONFIG_FILENAME="/hive/miners/custom/quanpool/quanpool.conf"' \
'  local auth_arg=""' \
'  if [[ -n "$CUSTOM_TEMPLATE" ]]; then' \
'    if [[ -n "$CUSTOM_WORKER" ]]; then' \
'      auth_arg="--auth-token ${CUSTOM_TEMPLATE}.${CUSTOM_WORKER}"' \
'    else' \
'      auth_arg="--auth-token ${CUSTOM_TEMPLATE}"' \
'    fi' \
'  fi' \
'  local node_arg=""' \
'  if [[ -n "$CUSTOM_URL" ]]; then' \
'    node_arg="--node-addr ${CUSTOM_URL}"' \
'  fi' \
'  echo "serve ${auth_arg} ${node_arg} ${CUSTOM_USER_CONFIG}" > "$CUSTOM_CONFIG_FILENAME"' \
'}' \
'' \
'miner_config_gen' \
> /hive/miners/custom/quanpool/h-config.sh
chmod +x /hive/miners/custom/quanpool/h-config.sh

# 3. Runner
printf '%s\n' \
'#!/usr/bin/env bash' \
'cd /hive/miners/custom/quanpool' \
'. ./h-manifest.conf' \
'mkdir -p /var/log/miner/custom' \
'conf=""' \
'[[ -f "$CUSTOM_CONFIG_FILENAME" ]] && conf=$(cat "$CUSTOM_CONFIG_FILENAME")' \
'[[ -z "$conf" ]] && conf="serve --auth-token qzkgtUmBgMyAWfpTirp59HhitDR572uapdvWGqLhBTSRNgdA9.rig1 --node-addr 15.235.146.115:9834"' \
'eval "./quanpool-miner $conf 2>&1 | tee ${CUSTOM_LOG_BASENAME}.log"' \
> /hive/miners/custom/quanpool/h-run.sh
chmod +x /hive/miners/custom/quanpool/h-run.sh

# 4. Clean root custom dir and symlink
rm -f /hive/miners/custom/h-*
ln -sf /hive/miners/custom/quanpool/h-* /hive/miners/custom/

# 5. Config fallback
echo "serve --auth-token qzkgtUmBgMyAWfpTirp59HhitDR572uapdvWGqLhBTSRNgdA9.rig1 --node-addr 15.235.146.115:9834" > /hive/miners/custom/quanpool/quanpool.conf

echo "Starting miner..."
miner start
echo "Done! Type 'miner' to view screen."
