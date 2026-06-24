#!/usr/bin/env bash
# Run once on the GCP VM to set up the repo and switch compose to build from source.
# Usage: sudo bash vm-setup.sh <github-repo-url>
# Example: sudo bash vm-setup.sh https://github.com/daki/redash.git

set -euo pipefail

GITHUB_URL="${1:?Usage: $0 <github-repo-url>}"
REPO_DIR="/opt/redash-src"
COMPOSE_FILE="/opt/redash/compose.yaml"

echo "==> Cloning repo into $REPO_DIR..."
git clone "$GITHUB_URL" "$REPO_DIR"

echo "==> Replacing compose.yaml with production build config..."
cp "$COMPOSE_FILE" "${COMPOSE_FILE}.bak"
cp "$REPO_DIR/compose.prod.yaml" "$COMPOSE_FILE"

echo "==> Copying deploy script to /usr/local/bin/redash-deploy..."
cp "$REPO_DIR/deploy.sh" /usr/local/bin/redash-deploy
chmod +x /usr/local/bin/redash-deploy

echo ""
echo "==> Setup complete!"
echo "    Source code: $REPO_DIR"
echo "    Compose file: $COMPOSE_FILE (backup: ${COMPOSE_FILE}.bak)"
echo ""
echo "    Next steps:"
echo "    1. Review /opt/redash/compose.yaml"
echo "    2. Run: COMPOSE_FILE=$COMPOSE_FILE docker compose build"
echo "    3. Run: COMPOSE_FILE=$COMPOSE_FILE docker compose up -d"
echo "    4. To deploy future changes: sudo redash-deploy"
