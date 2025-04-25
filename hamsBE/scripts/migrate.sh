#!/bin/bash

# bash scripts/migrate.sh up → Chạy migration
# bash scripts/migrate.sh down → Rollback migration
# bash scripts/migrate.sh force 1 → Fix lỗi dirty database
# bash scripts/migrate.sh version → Kiểm tra version hiện tại
# bash scripts/migrate.sh drop →`` Xóa toàn bộ database

DB_URL="postgres://hamster:hamster@localhost:5432/hamster?sslmode=disable"
MIGRATION_PATH="internal/database/migrations"

case "$1" in
  up)
    migrate -path $MIGRATION_PATH -database "$DB_URL" up
    ;;
  down)
    migrate -path $MIGRATION_PATH -database "$DB_URL" down
    ;;
  force)
    migrate -path $MIGRATION_PATH -database "$DB_URL" force $2
    ;;
  version)
    migrate -path $MIGRATION_PATH -database "$DB_URL" version
    ;;
  drop)
    migrate -path $MIGRATION_PATH -database "$DB_URL" drop
    ;;
  *)
    echo "Usage: $0 {up|down|force <version>|version|drop}"
    exit 1
    ;;
esac
