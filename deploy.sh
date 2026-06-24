#!/usr/bin/env bash
# Deploy script: run on the GCP VM to pull latest code and restart app containers.
# PostgreSQL container is never touched — data in /opt/redash/postgres-data persists.

set -euo pipefail

REPO_DIR="/opt/redash-src"
COMPOSE_FILE="/opt/redash/compose.yaml"
APP_SERVICES="server adhoc_worker scheduled_worker scheduler worker nginx"

echo "==> Pulling latest code..."
cd "$REPO_DIR"
git pull origin main

echo "==> Building app image..."
COMPOSE_FILE="$COMPOSE_FILE" docker compose build $APP_SERVICES

echo "==> Restarting app containers (postgres and redis untouched)..."
COMPOSE_FILE="$COMPOSE_FILE" docker compose up -d --no-deps $APP_SERVICES

echo "==> Done. Running containers:"
COMPOSE_FILE="$COMPOSE_FILE" docker compose ps
