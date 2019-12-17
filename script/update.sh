#!/bin/bash
# update.sh - Pleroma updater
set -ue

pushd $(cd "$(dirname $0)/../"; pwd)

# Config
source ".env"
export PLEROMA_VER=${1:-develop}

if [ -z "${PLEROMA_NAME:+UNDEF}" ];then
  echo '$PLEROMA_NAME is not defined.' 1>&2
  exit 1
fi
if [ -z "${PLEROMA_URL:+UNDEF}" ];then
  echo '$PLEROMA_URL is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_NAME:+UNDEF}" ];then
  echo '$POSTGRES_NAME is not defined.' 1>&2
  exit 1
fi

echo "Update Pleroma to ${PLEROMA_VER} !"

echo "[${PLEROMA_VER}] Pulling postgres..."
docker-compose pull ${POSTGRES_NAME} 

echo "[${PLEROMA_VER}] Building Pleroma..."
docker-compose build --pull "${PLEROMA_NAME}"

echo "[${PLEROMA_VER}] Migrating..."
docker-compose run --rm ${PLEROMA_NAME} mix ecto.migrate

echo "[${PLEROMA_VER}] Deploying..."
docker-compose up -d --remove-orphans

for i in $(seq 1 5); do
    isAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" "${PLEROMA_URL}")
    
    if [ "$isAlive" -eq 200 ]; then
	echo "[${PLEROMA_VER}] Update is done!"
	popd
	exit 0
    fi

    sleepTime=$((i*5))

    echo "[${PLEROMA_VER}] Return {$isAlive}, Retry in ${sleepTime}sec..." >&2

    sleep "${sleepTime}s"
done

echo "[${PLEROMA_VER}] Failed to deploy..." >&2

popd

exit 1

