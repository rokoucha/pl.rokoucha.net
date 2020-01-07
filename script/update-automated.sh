#!/bin/bash
# update-automated.sh - Automated Pleroma updater
set -uex

pushd "$(cd "$(dirname "$0")/../"; pwd)"

# Config
UPSTREAM_VER=$(git ls-remote https://git.pleroma.social/pleroma/pleroma.git HEAD | head -c 7)
RUNNING_HASH=""

if [ -z "${PLEROMA_NAME:+UNDEF}" ]; then
  echo 'PLEROMA_NAME is not defined.' 1>&2
  exit 1
fi
if [ -z "${PLEROMA_URL:+UNDEF}" ]; then
  echo 'PLEROMA_URL is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_NAME:+UNDEF}" ]; then
  echo 'POSTGRES_NAME is not defined.' 1>&2
  exit 1
fi

notify() {
  message="$(cat -)"
  echo "$message"
  [ -z "${PLEROMA_QUIET:+UNDEF}" ] &&
    toot post "$message" > /dev/null 2>&1 &
}

# Get running Pleroma version
docker-compose exec -T "${PLEROMA_NAME}" echo "Hey, you alive?" &&
  if [ -z "${PLEROMA_OTP:+UNDEF}" ]; then
    RUNNING_HASH="$(docker-compose exec -T "${PLEROMA_NAME}" git --no-pager show -s --format=%H | head -c 7)";
  else
    RUNNING_HASH="$(docker-compose exec -T "${PLEROMA_NAME}" cat /pleroma.ver)"
  fi &&
    echo "Already running Pleroma ${RUNNING_HASH}"

# Is running latest version?
if [ "${UPSTREAM_VER}" = "${RUNNING_HASH}" ] ; then
  echo "Already running latest Pleroma(${RUNNING_HASH})!"
  exit 0
fi

# Let's Update!
echo "Update Pleroma ${RUNNING_HASH} to ${UPSTREAM_VER} !" | notify

echo "[${UPSTREAM_VER}] Pulling postgres..." | notify
docker-compose pull "${POSTGRES_NAME}"

echo "[${UPSTREAM_VER}] Building Pleroma..." | notify
docker-compose build --pull "${PLEROMA_NAME}"

echo "[${UPSTREAM_VER}] Migrating..." | notify
if [ -z "${PLEROMA_OTP:+UNDEF}" ]; then
  docker-compose run --rm "${PLEROMA_NAME}" mix ecto.migrate
else
  docker-compose run --rm "${PLEROMA_NAME}" /opt/pleroma/bin/pleroma_ctl migrate
fi

echo "[${UPSTREAM_VER}] Deploying..." | notify
docker-compose up -d --remove-orphans

for i in $(seq 1 5); do
  isAlive=$(curl -s -o /dev/null -I -w "%{http_code}\n" "${PLEROMA_URL}")
  
  if [ "$isAlive" -eq 200 ]; then
    echo "[${UPSTREAM_VER}] Update is done!" | notify

    popd
    exit 0
  fi

  sleepTime=$((i*5))

  echo "[${UPSTREAM_VER}] Return {$isAlive}, Retry in ${sleepTime}sec..." >&2

  sleep "${sleepTime}s"
done

echo "[${UPSTREAM_VER}] Failed to deploy..." >&2

popd
exit 1

