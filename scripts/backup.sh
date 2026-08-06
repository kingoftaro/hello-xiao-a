#!/usr/bin/env sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BACKUP_DIR=${BACKUP_DIR:-"$PROJECT_DIR/backups"}
RETAIN_DAYS=${RETAIN_DAYS:-7}
STAMP=$(date +%Y%m%d_%H%M%S)

compose() {
  docker compose \
    --env-file "$PROJECT_DIR/.env.prod" \
    -f "$PROJECT_DIR/docker-compose.prod.yml" \
    "$@"
}

if [ ! -f "$PROJECT_DIR/.env.prod" ]; then
  echo "Missing $PROJECT_DIR/.env.prod" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"

compose exec -T postgres pg_dump -U "${POSTGRES_USER:-agent}" "${POSTGRES_DB:-enterprise_agent}" \
  | gzip > "$BACKUP_DIR/postgres_$STAMP.sql.gz"

compose exec -T etcd sh -c \
  "ETCDCTL_API=3 etcdctl --endpoints=http://127.0.0.1:2379 snapshot save /backups/etcd_$STAMP.db"

find "$BACKUP_DIR" -type f -mtime "+$RETAIN_DAYS" -delete
echo "Backup completed: $BACKUP_DIR"
