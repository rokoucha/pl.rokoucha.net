#!/bin/bash
# update.sh - Automated Pleroma updater
set -ue

pushd $(cd "$(dirname $0)/../"; pwd)

# Config
export PLEROMA_VER=$(git ls-remote https://git.pleroma.social/pleroma/pleroma.git HEAD | head -c 7)
RUNNING_HASH=""

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
if [ "${PLEROMA_VER}" = "${RUNNING_HASH}" ] ; then
    echo "Already running latest Pleroma(${RUNNING_HASH})!"
    exit 0
fi

# Let's Update!
echo "Update Pleroma ${RUNNING_HASH} to ${PLEROMA_VER} !" | notify

echo "[${PLEROMA_VER}] Pulling postgres..." | notify
docker-compose pull ${POSTGRES_NAME} 

echo "[${PLEROMA_VER}] Building Pleroma..." | notify
docker-compose build --pull ${PLEROMA_NAME}

echo "[${PLEROMA_VER}] Migrating..." | notify
docker-compose run --rm ${PLEROMA_NAME} mix ecto.migrate

echo "[${PLEROMA_VER}] Deploying..." | notify
docker-compose up -d --remove-orphans

for i in $(seq 1 5); do
    isAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" "${PLEROMA_URL}")
    
    if [ "$isAlive" -eq 200 ]; then
	echo "[${PLEROMA_VER}] Update is done!" | notify

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

