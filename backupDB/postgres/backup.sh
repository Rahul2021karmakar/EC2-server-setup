#!/bin/bash
set -euo pipefail

DATE=$(date +"%Y-%m-%d_%H-%M")

export PGPASSWORD="$POSTGRES_PASSWORD"

echo "Starting PostgreSQL backup at $(date)"

DATABASES=$(psql \
  -h "$POSTGRES_HOST" \
  -p "$POSTGRES_PORT" \
  -U "$POSTGRES_USER" \
  -d postgres \
  -At \
  -c "SELECT datname
      FROM pg_database
      WHERE datistemplate = false
      AND datallowconn = true
      AND datname NOT IN ('postgres');")

echo "Databases found:"
echo "$DATABASES"

for DB in $DATABASES; do

  FILE="/backup/${DB}-${DATE}.sql.gz"

  echo "Backing up database: $DB"

  pg_dump \
    -h "$POSTGRES_HOST" \
    -p "$POSTGRES_PORT" \
    -U "$POSTGRES_USER" \
    -d "$DB" \
    --no-owner \
    --no-privileges \
    | gzip > "$FILE"

  aws s3 cp "$FILE" \
    "s3://$S3_BUCKET/postgres/$DB/$DATE.sql.gz" \
    --region "$AWS_REGION"

  rm -f "$FILE"

  echo "Completed backup for $DB"

done

echo "PostgreSQL backup finished."