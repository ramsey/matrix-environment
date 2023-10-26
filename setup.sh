#!/bin/bash -e

if [[ ! -e .env ]]; then
  echo "[ERROR] You must create a .env file."
  exit 1
fi

set -a
source .env
set +a

shell_format="$(printf '${%s} ' $(cat .env | cut -d'=' -f1))"

if [[ -z "${DATABASE_DATA_PATH}" || ! -d "${DATABASE_DATA_PATH}" ]]; then
  echo "[ERROR] You must set DATABASE_DATA_PATH, and this path must exist."
  exit 1
fi

if [[ -z "${DATABASE_PASS}" ]]; then
  echo "[ERROR] You must set DATABASE_PASS."
  exit 1
fi

if [[ ! -z "${SYNAPSE_ADMIN_CONTACT}" && $SYNAPSE_ADMIN_CONTACT != mailto* ]]; then
  echo "[ERROR] The SYNAPSE_ADMIN_CONTACT value must begin with \"mailto:\"."
  exit 1
fi

if [[ -z "${SYNAPSE_DATA_PATH}" || ! -d "${SYNAPSE_DATA_PATH}" ]]; then
  echo "[ERROR] You must set SYNAPSE_DATA_PATH, and this path must exist."
  exit 1
fi

if [[ -z "${SYNAPSE_SERVER_NAME}" ]]; then
  echo "[ERROR] You must set SYNAPSE_SERVER_NAME."
  exit 1
fi

if [[ -z "${CADDY_DATA_PATH}" || ! -d "${CADDY_DATA_PATH}" ]]; then
  echo "[ERROR] You must set CADDY_DATA_PATH, and this path must exist."
  exit 1
fi

if [[ -z "${IRC_BRIDGE_DATA_PATH}" || ! -d "${IRC_BRIDGE_DATA_PATH}" ]]; then
  echo "[ERROR] You must set IRC_BRIDGE_DATA_PATH, and this path must exist."
  exit 1
fi

mkdir -p "${SYNAPSE_DATA_PATH}/synapse/log"
mkdir -p "${SYNAPSE_DATA_PATH}/synapse/media_store"
mkdir -p "${CADDY_DATA_PATH}/caddy"
mkdir -p "${IRC_BRIDGE_DATA_PATH}/irc-bridge"

chmod a+w "${SYNAPSE_DATA_PATH}/synapse"
chmod a+w "${SYNAPSE_DATA_PATH}/synapse/log"
chmod a+w "${SYNAPSE_DATA_PATH}/synapse/media_store"
chmod a+w "${CADDY_DATA_PATH}/caddy"

if [[ ! -e "${SYNAPSE_DATA_PATH}/synapse/homeserver.yaml" ]]; then
  echo "Copying synapse/homeserver.yaml to ${SYNAPSE_DATA_PATH}/synapse/homeserver.yaml"
  envsubst "$shell_format" < "./synapse/homeserver.yaml" > "${SYNAPSE_DATA_PATH}/synapse/homeserver.yaml"
fi

if [[ ! -e "${SYNAPSE_DATA_PATH}/synapse/log.yaml" ]]; then
  echo "Copying synapse/log.yaml to ${SYNAPSE_DATA_PATH}/synapse/log.yaml"
  envsubst "$shell_format" < "./synapse/log.yaml" > "${SYNAPSE_DATA_PATH}/synapse/log.yaml"
fi

if [[ ! -e "${CADDY_DATA_PATH}/caddy/Caddyfile" ]]; then
  echo "Copying caddy/Caddyfile to ${CADDY_DATA_PATH}/caddy/Caddyfile"
  envsubst "$shell_format" < "./caddy/Caddyfile" > "${CADDY_DATA_PATH}/caddy/Caddyfile"
fi

if [[ ! -e "${IRC_BRIDGE_DATA_PATH}/irc-bridge/config.yaml" ]]; then
  echo "Copying irc-bridge/config.yaml to ${IRC_BRIDGE_DATA_PATH}/irc-bridge/config.yaml"
  envsubst "$shell_format" < "./irc-bridge/config.yaml" > "${IRC_BRIDGE_DATA_PATH}/irc-bridge/config.yaml"
fi

if [[ ! -e "${IRC_BRIDGE_DATA_PATH}/irc-bridge/passkey.pem" ]]; then
  echo "Creating ${IRC_BRIDGE_DATA_PATH}/irc-bridge/passkey.pem"
  openssl genpkey \
    -out "${IRC_BRIDGE_DATA_PATH}/irc-bridge/passkey.pem" \
    -outform PEM \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:2048 \
    &> /dev/null
fi

if [[ ! -e "${IRC_BRIDGE_DATA_PATH}/irc-bridge/appservice-registration-irc.yaml" ]]; then
  echo "Creating ${IRC_BRIDGE_DATA_PATH}/irc-bridge/appservice-registration-irc.yaml"
  docker run \
    --rm \
    -it \
    -v "${IRC_BRIDGE_DATA_PATH}/irc-bridge:/data" \
    --entrypoint=bash \
    matrixdotorg/matrix-appservice-irc:latest \
    -c "\
      node app.js \
        --generate-registration \
        --file /data/appservice-registration-irc.yaml \
        --url 'http://irc-bridge:8090' \
        --config /data/config.yaml \
        --localpart appservice-libera \
    "

  escaped_server_name="${SYNAPSE_SERVER_NAME/\./\\\\.}"
  sed -i "s/$escaped_server_name/libera\\\.chat/" "${IRC_BRIDGE_DATA_PATH}/irc-bridge/appservice-registration-irc.yaml"
fi

docker compose up -d database &> /dev/null
sleep 5s
while [[ -z "$(docker exec -it matrix-environment-database-1 psql -U synapse -XtAc 'select 1')" ]]; do true; done
if [[ -z "$(docker exec -it matrix-environment-database-1 psql -U synapse -XtAc "SELECT 1 FROM pg_database WHERE datname='ircbridge'")" ]]; then
  docker exec -it matrix-environment-database-1 createdb -U synapse ircbridge
  sleep 1s
fi
docker compose down database &> /dev/null

echo "Setup is complete!"
