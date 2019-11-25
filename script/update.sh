#!/bin/sh
# update.sh - Pleroma updater
set -ue

pushd ../

# Config
PLEROMA_NAME="web"
POSTGRES_NAME="postgres"
DEPLOY_URL="https://pl-next.ggrel.net/"
COMMIT_HASH="$1"

echo "Update Pleroma to ${COMMIT_HASH} !"

echo "[${COMMIT_HASH}] Pulling postgres..."
docker-compose pull ${POSTGRES_NAME} 

echo "[${COMMIT_HASH}] Building Pleroma..."
docker-compose build --no-cache --build-arg PLEROMA_VER="${COMMIT_HASH}" "${PLEROMA_NAME}"

echo "[${COMMIT_HASH}] Migrating..."
docker-compose run --rm ${PLEROMA_NAME} mix ecto.migrate

echo "[${COMMIT_HASH}] Deploying..."
docker-compose up -d --remove-orphans

for i in $(seq 1 5); do
    isAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" "${DEPLOY_URL}")
    
    if [ "$isAlive" -eq 200 ]; then
	echo "[${COMMIT_HASH}] Update is done!"
	popd
	exit 0
    fi

    sleepTime=$((5\*$i))

    echo "[${COMMIT_HASH}] Return {$isAlive}, Retry in ${sleepTime}sec..." >&2

    sleep "${sleepTime}s"
done

echo "[${COMMIT_HASH}] Failed to deploy..." >&2

popd

exit 1

