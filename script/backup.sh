#!/bin/bash
# backup.sh - Postgres backup script
set -ue

# Get project name
PROJECT_NAME="$(basename "$(cd "$(dirname $0)/../"; pwd)")"

# Parse args
usage_help() {
  echo "Usage: $0 [-d database] [-h hostname] [-p password] [-u username] [-v version] [-f path]" 1>&2
  exit 1
}

while getopts n:d:h:p:u:v:f: OPT
do
  case $OPT in
    n)  NET_NAME=$OPTARG
      ;;
    d)  POSTGRES_DB=$OPTARG
      ;;
    h)  POSTGRES_NAME=$OPTARG
      ;;
    p)  POSTGRES_PASSWORD=$OPTARG
      ;;
    u)  POSTGRES_USER=$OPTARG
      ;;
    v)  POSTGRES_VER=$OPTARG
      ;;
    f)  BACKUP_PATH=$OPTARG
      ;;
    \?) usage_help
      ;;
  esac
done

shift $((OPTIND - 1))

# Config check
if [ -z "${NET_NAME:+UNDEF}" ];then
  echo '$NET_NAME is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_DB:+UNDEF}" ];then
  echo '$POSTGRES_DB is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_NAME:+UNDEF}" ];then
  echo '$POSTGRES_NAME is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_PASSWORD:+UNDEF}" ];then
  echo '$POSTGRES_PASSWORD is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_USER:+UNDEF}" ];then
  echo '$POSTGRES_USER is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_VER:+UNDEF}" ];then
  echo '$POSTGRES_VER is not defined.' 1>&2
  exit 1
fi

if [ -z "${BACKUP_PATH:+UNDEF}" ];then
  BACKUP_PATH="./$PROJECT_NAME-$POSTGRES_NAME-$POSTGRES_VER-$POSTGRES_DB-$(date "+%Y%m%d_%H%M%S").pgdump"
fi

# Parse backup path
BACKUP_DIR="$(cd "$(dirname "$BACKUP_PATH")"; pwd)"
BACKUP_FILE="$(basename "$BACKUP_PATH")"

# Backup
docker run \
  --rm \
  -u "$(id -u):$(id -g)" \
  -v "$BACKUP_DIR:/backup" \
  --net="$NET_NAME" \
  --env PGPASSWORD="$POSTGRES_PASSWORD" \
  --entrypoint pg_dump \
  "postgres:$POSTGRES_VER" \
    -h "$POSTGRES_NAME" \
    -d "$POSTGRES_DB" \
    -U "$POSTGRES_USER" \
    --format=custom \
    -f "/backup/$BACKUP_FILE"

# Successful
echo "Backup completed successfully"
echo "$BACKUP_PATH"
