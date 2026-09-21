#!/usr/bin/env bash
set -euo pipefail
umask 077

if [[ $(id -un) != rdteam ]]; then
  echo "Run this command as rdteam." >&2
  exit 1
fi

deploy_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd -- "$deploy_dir"
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
backup_stamp=$(date -u +%Y%m%dT%H%M%SZ)
backup_dir="/home/rdteam/backups/$backup_stamp"
mkdir -p -- "$backup_dir"
exec 9>/home/rdteam/backups/backup.lock
flock -n 9 || { echo "Another backup is active." >&2; exit 1; }

cp -- /home/rdteam/.config/rd-team/relay.env "$backup_dir/relay.env"
cp -- /home/rdteam/.config/cloudflared/rd-team.token "$backup_dir/tunnel.token"
cp -- "$deploy_dir/compose.override.yml" "$backup_dir/compose.override.yml"
if [[ -f /home/rdteam/app/REVISION ]]; then
  cp -- /home/rdteam/app/REVISION "$backup_dir/REVISION"
fi
"$deploy_dir/compose.sh" exec -T postgres pg_dump -U buzz -d buzz -Fc > "$backup_dir/database.dump"

# Stop only this Compose project for a consistent volume snapshot.
trap '"$deploy_dir/compose.sh" up -d --wait --wait-timeout 180' EXIT
"$deploy_dir/compose.sh" stop --timeout 30
/home/rdteam/bin/docker run \
  --name "rd-team-backup-$backup_stamp" \
  --network none --log-driver none --memory 128m --cpus 0.5 \
  --mount type=volume,src=rd-team_buzz-postgres-data,dst=/snapshot/postgres,readonly \
  --mount type=volume,src=rd-team_buzz-redis-data,dst=/snapshot/redis,readonly \
  --mount type=volume,src=rd-team_buzz-minio-data,dst=/snapshot/minio,readonly \
  --mount type=volume,src=rd-team_buzz-git-data,dst=/snapshot/git,readonly \
  --mount "type=bind,src=$backup_dir,dst=/output" \
  --entrypoint /bin/sh \
  postgres:17-alpine@sha256:b0f9560a2de083e2cc7382e75f808c7381a32852a7ec49117deedb300e552b24 \
  -ec 'tar -czf /output/volumes.tar.gz -C /snapshot postgres redis minio git'
cd -- "$backup_dir"
sha256sum database.dump volumes.tar.gz relay.env tunnel.token compose.override.yml > SHA256SUMS
"$deploy_dir/compose.sh" up -d --wait --wait-timeout 180
trap - EXIT
printf 'Backup complete: %s\n' "$backup_dir"
