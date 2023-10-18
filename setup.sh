#!/bin/bash -e

if [[ ! -e .env ]]; then
  echo "[ERROR] You must create a .env file."
  exit 1
fi

set -a
source .env
set +a

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

mkdir -p "${SYNAPSE_DATA_PATH}/synapse"
mkdir -p "${SYNAPSE_DATA_PATH}/synapse/log"
mkdir -p "${SYNAPSE_DATA_PATH}/synapse/media_store"

if [[ ! -e "${SYNAPSE_DATA_PATH}/synapse/homeserver.yaml" ]]; then
  echo "Copying synapse/homeserver.yaml to ${SYNAPSE_DATA_PATH}/synapse/homeserver.yaml"
  envsubst < "./synapse/homeserver.yaml" > "${SYNAPSE_DATA_PATH}/synapse/homeserver.yaml"
fi

if [[ ! -e "${SYNAPSE_DATA_PATH}/synapse/log.yaml" ]]; then
  echo "Copying synapse/log.yaml to ${SYNAPSE_DATA_PATH}/synapse/log.yaml"
  envsubst < "./synapse/log.yaml" > "${SYNAPSE_DATA_PATH}/synapse/log.yaml"
fi

echo "Setup is complete!"
