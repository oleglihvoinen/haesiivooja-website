#!/usr/bin/env bash
# Build and publish an immutable static Astro release for Apache.
# Usage: bash ops/deploy-from-vps.sh /opt/haesiivooja-website prepare|activate
set -euo pipefail
SOURCE_DIR="${1:?Provide absolute path to website repository}"
MODE="${2:-prepare}"
[[ "$MODE" == prepare || "$MODE" == activate ]] || { echo 'Use prepare or activate' >&2; exit 2; }
cd "$SOURCE_DIR"
if [[ -f package-lock.json ]]; then npm ci --no-audit --no-fund; else npm install --no-audit --no-fund; fi
npm run check
npm run predeploy
TS="$(date +%Y%m%d-%H%M%S)"
DEST=/var/www/haesiivooja-astro
RELEASE="$DEST/releases/$TS"
sudo install -d -m 755 "$RELEASE"
sudo rsync -a --delete dist/ "$RELEASE/"
if [[ "$MODE" == activate ]]; then
 sudo ln -s "$RELEASE" "$DEST/current.new"
 sudo mv -Tf "$DEST/current.new" "$DEST/current"
 echo "Activated static release $RELEASE. Apache must already use $DEST/current as its DocumentRoot."
else
 echo "PREPARED_RELEASE=$RELEASE"
 echo "Review and test release, then activate only after validation."
fi
