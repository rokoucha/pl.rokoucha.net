#!/bin/bash
# update.sh - Automated Pleroma updater
set -ue

pushd $(cd "$(dirname $0)/../"; pwd)

# Config
PLEROMA_NAME="web"
POSTGRES_NAME="postgres"
DEPLOY_URL="https://pl-next.ggrel.net/"
COMMIT_HASH=$(git ls-remote https://git.pleroma.social/pleroma/pleroma.git HEAD | head -c 7)
RUNNING_HASH=""

notify() {
    message="$(cat -)"
    echo "$message"
    toot post "$message" > /dev/null 2>&1
}

# Get running Pleroma version
if docker-compose run --rm ${PLEROMA_NAME} echo Hey, you alive? > /dev/null 2>&1; then
    RUNNING_HASH="$(docker-compose exec ${PLEROMA_NAME} git --no-pager show -s --format=%H | head -c 7)"
fi

# Is running latest version?
if [ "${COMMIT_HASH}" = "${RUNNING_HASH}" ] ; then
    echo "Already running latest Pleroma(${RUNNING_HASH})!"
    exit 0
fi

# Let's Update!
echo "Update Pleroma ${RUNNING_HASH} to ${COMMIT_HASH} !" | notify

echo "[${COMMIT_HASH}] Pulling postgres..." | notify
docker-compose pull ${POSTGRES_NAME} 

echo "[${COMMIT_HASH}] Building Pleroma..." | notify
docker-compose build --no-cache --build-arg PLEROMA_VER="${COMMIT_HASH}" "${PLEROMA_NAME}"

echo "[${COMMIT_HASH}] Migrating..." | notify
docker-compose run --rm ${PLEROMA_NAME} mix ecto.migrate

echo "[${COMMIT_HASH}] Deploying..." | notify
docker-compose up -d --remove-orphans

for i in $(seq 1 5); do
    isAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" "${DEPLOY_URL}")
    
    if [ "$isAlive" -eq 200 ]; then
	echo "[${COMMIT_HASH}] Update is done!" | notify

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

