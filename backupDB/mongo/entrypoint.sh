#!/bin/bash
set -e

# Export Docker environment variables for cron jobs
env | grep -E '^(MONGO_|AWS_|S3_)' > /etc/backup.env

chmod 600 /etc/backup.env

echo "Backup environment prepared"

exec cron -f