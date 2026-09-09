docker exec cuddly_mongodb_dev mongodump --username cuddlyAdmindev --password SBg7qgcuNwnJqKIQtPutruLQm0RmzpzavJce4ReZf98 --db cuddlyduddly --out /tmp/mongo-backup --authenticationDatabase admin
docker exec cuddly_mongodb_dev mongodump --username cuddlyAdmindev --password SBg7qgcuNwnJqKIQtPutruLQm0RmzpzavJce4ReZf98 --db admin --out /tmp/mongo-backup --authenticationDatabase admin


docker cp cuddly_mongodb_dev:/tmp/mongo-backup ~/mongo-backup

cd ~

tar -czvf mongo-backup.tar.gz mongo-backup

# To copy the backup file from a remote server to local, use the following command:
scp -r -i /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/cuddly-duddly-dev.pem \
  ubuntu@13.202.109.78:~/mongo-backup.tar.gz /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/BackupDB

# To copy the backup file from local to a remote server, use the following command:
scp -r -i /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/cuddly-duddly-dev.pem \
 /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/DevOps/backupDB/ ubuntu@13.202.109.78:/home/ubuntu/DevOps/

# To copy the backup file from local to a remote server using rsync, use the following command:
rsync -avz -e "ssh -i /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/cuddly-duddly-dev.pem" \
/home/rahul/Downloads/Projects/DST/Cuddly-Duddly/DevOps/backupDB/ ubuntu@13.202.109.78:/home/ubuntu/DevOps/backupDB


scp -r -i /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/cuddly-duddly-dev.pem \
 /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/BackupDB/mongo-backup.tar.gz ubuntu@13.202.109.78:~/DevOps/

# To restore the backup on a remote server, use the following commands:
 sudo docker exec cuddly_mongodb_dev mongorestore --username cuddlyAdmindev --password 'SBg7qgcuNwnJqKIQtPutruLQm0RmzpzavJce4ReZf98' --authenticationDatabase admin --drop /tmp/mongo-backup


# To restore postgresql db backup on a remote server, use the following commands:
aws s3 cp s3://cuddlyduddly-db-backups/postgres/ /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/BackupDB/ --profile cuddlyduddly --recursive

scp -r -i /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/cuddly-duddly-dev.pem /home/rahul/Downloads/Projects/DST/Cuddly-Duddly/BackupDB ubuntu@13.202.109.78:~/postgres-backup

cat auth_db-2026-09-08.dump | docker exec -i cuddly_postgres_dev pg_restore -U dev -d auth_db -C --clean --no-owner --no-privileges



# Manually trigger the backup scripts inside the respective containers
docker exec -it postgres-backup-cron /usr/local/bin/backup.sh
docker exec -it mongodb-backup-cron /usr/local/bin/backup.sh