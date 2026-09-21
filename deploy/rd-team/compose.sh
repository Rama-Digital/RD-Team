#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -un) != rdteam ]]; then
  echo "Run this command as rdteam." >&2
  exit 1
fi

deploy_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd -- "$deploy_dir"
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
exec /home/rdteam/bin/docker compose \
  --project-name rd-team \
  --env-file /home/rdteam/.config/rd-team/relay.env \
  --file "$deploy_dir/../compose/compose.yml" \
  --file "$deploy_dir/compose.override.yml" \
  "$@"
