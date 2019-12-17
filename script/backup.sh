#!/bin/bash
# backup.sh - Postgres backup script
set -ue

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
        d)  PLEROMA_DB=$OPTARG
            ;;
        h)  POSTGRES_NAME=$OPTARG
            ;;
        p)  POSTGRES_PASSWORD=$OPTARG
            ;;
        u)  PLEROMA_USER=$OPTARG
            ;;
        v)  POSTGRES_VERSION=$OPTARG
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
if [ -z "${PLEROMA_DB:+UNDEF}" ];then
  echo '$PLEROMA_DB is not defined.' 1>&2
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
if [ -z "${PLEROMA_USER:+UNDEF}" ];then
  echo '$PLEROMA_USER is not defined.' 1>&2
  exit 1
fi
if [ -z "${POSTGRES_VERSION:+UNDEF}" ];then
  echo '$POSTGRES_VERSION is not defined.' 1>&2
  exit 1
fi
if [ -z "${BACKUP_PATH:+UNDEF}" ];then
  BACKUP_PATH="./$NET_NAME-$POSTGRES_NAME-$PLEROMA_DB-$(date "+%Y%m%d_%H%M%S").pgdump"
fi

# Parse backup path
BACKUP_DIR="$(cd "$(dirname "$BACKUP_PATH")"; pwd)"
BACKUP_FILE="$(basename "$BACKUP_PATH")"

# Backup
docker run \
    --rm \
    -it \
    -u "$(id -u):$(id -g)" \
    -v "$BACKUP_DIR:/backup" \
    --net="$NET_NAME" \
    --env PGPASSWORD="$POSTGRES_PASSWORD" \
    --entrypoint pg_dump \
    "postgres:$POSTGRES_VERSION" \
        -h "$POSTGRES_NAME" \
        -d "$PLEROMA_DB" \
        -U "$PLEROMA_USER" \
        --format=custom \
        -f "/backup/$BACKUP_FILE"

# Successful
echo "Backup completed successfully"
echo "$BACKUP_PATH"
