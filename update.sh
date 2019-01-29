#!/bin/sh
# update.sh - Automated Pleroma updater
set -ue

DEPLOY_URL="https://pl-next.ggrel.net/"
COMMIT_HASH=$(git ls-remote https://git.pleroma.social/pleroma/pleroma.git HEAD | head -c 7)

echo "Update Pleroma to ${COMMIT_HASH} !" | toot post

echo "[${COMMIT_HASH}] Pulling postgres..." | toot post
docker-compose pull postgres

echo "[${COMMIT_HASH}] Building Pleroma..." | toot post
docker-compose build --no-cache --build-arg PLEROMA_VER=${COMMIT_HASH}

echo "[${COMMIT_HASH}] Migrating..." | toot post
docker-compose run --rm web mix ecto.migrate

echo "[${COMMIT_HASH}] Deploying..." | toot post
docker-compose up -d --remove-orphans

for i in `seq 1 5`; do
    isAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" "${DEPLOY_URL}")
    
    if [ $isAlive -eq 200 ]; then
	echo "[${COMMIT_HASH}] Update is done!" | toot post
	exit 0
    fi

    sleepTime=$(expr 5 \* $i)

    echo "[${COMMIT_HASH}] Return {$isAlive}, Retry in ${sleepTime}sec..." >&2

    sleep ${sleepTime}s
done

echo "[${COMMIT_HASH}] Failed to deploy..." >&2
exit 1

