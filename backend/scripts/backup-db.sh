#!/usr/bin/env sh
# Sao lưu CSDL KarVocab từ container Postgres (docker compose) ra file .sql.gz.
# Giữ lại KEEP bản mới nhất (mặc định 7). Chạy trong thư mục backend/:
#   sh scripts/backup-db.sh
set -eu

KEEP="${KEEP:-7}"
DB_NAME="${DB_NAME:-karvocab}"
DB_USER="${DB_USER:-karvocab}"
BACKUP_DIR="${BACKUP_DIR:-backups}"

mkdir -p "$BACKUP_DIR"
FILE="$BACKUP_DIR/karvocab-$(date +%Y%m%d-%H%M%S).sql.gz"

docker compose exec -T postgres pg_dump -U "$DB_USER" -d "$DB_NAME" --no-owner \
  | gzip > "$FILE"

if [ ! -s "$FILE" ]; then
  echo "Sao lưu thất bại: $FILE rỗng" >&2
  rm -f "$FILE"
  exit 1
fi
echo "Đã sao lưu: $FILE"

# Xoá các bản cũ, chỉ giữ KEEP bản mới nhất
ls -1t "$BACKUP_DIR"/karvocab-*.sql.gz 2>/dev/null | tail -n +"$((KEEP + 1))" | while read -r old; do
  rm -f "$old"
  echo "Đã xoá bản cũ: $old"
done
