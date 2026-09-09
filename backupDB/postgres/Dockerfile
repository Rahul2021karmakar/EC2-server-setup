FROM postgres:17-bookworm

RUN apt-get update && apt-get install -y \
    cron \
    gzip \
    python3 \
    python3-pip \
 && pip3 install --break-system-packages awscli \
 && rm -rf /var/lib/apt/lists/*

COPY backup.sh /usr/local/bin/backup.sh
COPY crontab /etc/cron.d/postgres-cron
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/backup.sh \
 && chmod +x /usr/local/bin/entrypoint.sh \
 && chmod 0644 /etc/cron.d/postgres-cron \
 && crontab /etc/cron.d/postgres-cron

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]