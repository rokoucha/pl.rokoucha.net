#!/bin/bash
# backup-mega.sh - Automated Postgres backup to MEGA
set -ue

# Get project name
PROJECT_NAME="$(basename "$(cd "$(dirname "$0")/../"; pwd)")"

# Config check
if [ -z "${MEGA_SESSION:+UNDEF}" ];then
  echo 'MEGA_SESSION is not defined.' 1>&2
  exit 1
fi
if [ -z "${NET_NAME:+UNDEF}" ];then
  echo 'NET_NAME is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_DB:+UNDEF}" ];then
  echo 'POSTGRES_DB is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_NAME:+UNDEF}" ];then
  echo 'POSTGRES_NAME is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_VER:+UNDEF}" ];then
  echo 'POSTGRES_VER is not defined.' 1>&2
  exit 1
fi

# Backup path must use absolute path because this path will use in MEGA
if [ -z "${BACKUP_PATH:+UNDEF}" ];then
  BACKUP_PATH="/Backups/$PROJECT_NAME/$POSTGRES_NAME-$POSTGRES_VER-$POSTGRES_DB-$(date "+%Y%m%d_%H%M%S").pgdump"
fi

# Parse backup path
BACKUP_FILE="$(basename "$BACKUP_PATH")"

# Make temporary workspace
TMP_PATH=$(mktemp -d)

"$(cd "$(dirname "$0")"; pwd)/backup.sh" -f "$TMP_PATH/$BACKUP_FILE"

# Put to MEGA
docker run \
  --rm \
  -v "$TMP_PATH:/backup" \
  "danielquinn/megacmd-alpine" \
    sh -c "
      mega-login $MEGA_SESSION > /dev/null &&
      mega-put -c /backup/$BACKUP_FILE $BACKUP_PATH &&
      mega-logout --keep-session > /dev/null
    "

# Clean temporary workspace
rm -rf "$TMP_PATH"

# Successful
echo "Backup completed successfully"
echo "$BACKUP_PATH"
