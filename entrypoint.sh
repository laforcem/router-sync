#!/usr/bin/env sh
set -eu

SYNC_INTERVAL_MINUTES="${SYNC_INTERVAL_MINUTES:-10}"

# Validate interval is a positive integer
case "$SYNC_INTERVAL_MINUTES" in
    ''|*[!0-9]*) echo "ERROR: SYNC_INTERVAL_MINUTES must be a positive integer" >&2; exit 1 ;;
esac

# Write crontab — redirect to container stdout/stderr so logs appear in docker logs
echo "*/${SYNC_INTERVAL_MINUTES} * * * * /usr/local/bin/sync.sh >> /proc/1/fd/1 2>&1" \
    > /etc/crontabs/root

echo "Cron schedule: every ${SYNC_INTERVAL_MINUTES} minute(s)"

# Run once immediately at container start so there is no wait on first deploy
echo "Running initial sync..."
/usr/local/bin/sync.sh || echo "Initial sync failed — will retry on next cron interval"

# Start crond in foreground as PID 1
exec crond -f -l 2
