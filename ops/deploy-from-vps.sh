#!/usr/bin/env bash
# Build a versioned release without changing the live site by default.
# Usage: bash ops/deploy-from-vps.sh /opt/haesiivooja-website prepare
# Or:   bash ops/deploy-from-vps.sh /opt/haesiivooja-website activate
set -euo pipefail
SOURCE_DIR="${1:?Usage: deploy-from-vps.sh /path/to/repo [prepare|activate]}"
MODE="${2:-prepare}"
[[ "$MODE" == prepare || "$MODE" == activate ]] || { echo 'Mode must be prepare or activate' >&2; exit 2; }
cd "$SOURCE_DIR"
if [[ -f package-lock.json ]]; then npm ci --no-audit --no-fund; else npm install --no-audit --no-fund; fi
npm run check
npm run predeploy
TS="$(date +%Y%m%d-%H%M%S)"
DEST=/var/www/haesiivooja-astro
RELEASE="$DEST/releases/$TS"
sudo install -d -m 755 "$RELEASE"
sudo rsync -a --delete dist/ "$RELEASE/"
# Preserve previous releases as rollback points; never touch WordPress here.
if [[ "$MODE" == activate ]]; then
  sudo ln -s "$RELEASE" "$DEST/current.new"
  sudo mv -Tf "$DEST/current.new" "$DEST/current"
  echo "Activated static release $RELEASE (Nginx must already be configured and reviewed)."
else
  echo "PREPARED_RELEASE=$RELEASE"
  echo 'Not activated. Validate on staging, then activate explicitly.'
fi
