#!/bin/bash
set -e

# Make Docker Compose environment variables available to cron
env | grep -E '^(POSTGRES_|AWS_|S3_)' > /etc/backup.env

chmod 600 /etc/backup.env

echo "PostgreSQL backup environment prepared"

exec cron -f