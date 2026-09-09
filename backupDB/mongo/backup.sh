#!/bin/bash
set -euo pipefail

DATE=$(date +"%Y-%m-%d_%H-%M")

echo "Starting MongoDB backup at $(date)"

# List all non-system databases
DATABASES=$(mongosh \
  --host "$MONGO_HOST" \
  --port "$MONGO_PORT" \
  --username "$MONGO_USERNAME" \
  --password "$MONGO_PASSWORD" \
  --authenticationDatabase "$MONGO_AUTH_DB" \
  --quiet \
  --eval '
    db.adminCommand("listDatabases").databases
      .map(d => d.name)
      .filter(n => !["admin","config","local"].includes(n))
      .join(" ")
  ')

echo "Databases found: $DATABASES"

for DB in $DATABASES; do

  BACKUP_DIR="/backup/$DB-$DATE"
  ARCHIVE="/backup/$DB-$DATE.tar.gz"

  echo "Backing up database: $DB"

  mkdir -p "$BACKUP_DIR"

  mongodump \
    --host="$MONGO_HOST" \
    --port="$MONGO_PORT" \
    --username="$MONGO_USERNAME" \
    --password="$MONGO_PASSWORD" \
    --authenticationDatabase="$MONGO_AUTH_DB" \
    --db="$DB" \
    --out="$BACKUP_DIR"

  tar -czf "$ARCHIVE" -C /backup "$DB-$DATE"

  aws s3 cp "$ARCHIVE" \
    "s3://$S3_BUCKET/mongodb/$DB/$DATE.tar.gz" \
    --region "$AWS_REGION"

  rm -rf "$BACKUP_DIR"
  rm -f "$ARCHIVE"

  echo "Completed backup for $DB"

done

echo "MongoDB backup finished."