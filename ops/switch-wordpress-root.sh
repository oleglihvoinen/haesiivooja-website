#!/usr/bin/env bash
# Replace the /var/www/html webroot without modifying Nginx virtual hosts.
# USE ONLY AFTER confirming that /var/www/html is dedicated to haesiivooja.fi.
# Usage:
#   sudo CONFIRM_HAESIIVOOJA_ONLY=YES bash ops/switch-wordpress-root.sh cutover /var/www/haesiivooja-astro/releases/RELEASE
#   sudo CONFIRM_HAESIIVOOJA_ONLY=YES bash ops/switch-wordpress-root.sh rollback /var/www/haesiivooja-wordpress-RETIRED
set -Eeuo pipefail
ACTION="${1:-}"
TARGET="${2:-}"
ROOT=/var/www/html
if [[ "$EUID" != 0 ]]; then echo 'Run via sudo; this changes /var/www/html' >&2; exit 2; fi
if [[ "$CONFIRM_HAESIIVOOJA_ONLY" != YES ]]; then
  echo 'STOP: first inspect nginx -T and confirm /var/www/html serves only the main haesiivooja.fi website.' >&2
  echo 'Set CONFIRM_HAESIIVOOJA_ONLY=YES only after this check.' >&2
  exit 2
fi
if ! command -v nginx >/dev/null; then echo 'Nginx is not installed: do not use this script.' >&2; exit 2; fi
if ! nginx -t; then echo 'Nginx config invalid before cutover.' >&2; exit 2; fi
NGINX_DUMP="$(nginx -T 2>&1)"
if ! grep -Eq 'root[[:space:]]+/var/www/html[[:space:]]*;' <<<"$NGINX_DUMP"; then
  echo 'No active Nginx root /var/www/html found. Follow the dedicated-vhost migration guide instead.' >&2; exit 2
fi
probe() {
  curl --silent --show-error --fail --max-time 12 --resolve 'haesiivooja.fi:443:127.0.0.1' "https://haesiivooja.fi${1}" -o /dev/null
}
if [[ "$ACTION" == cutover ]]; then
  [[ "$TARGET" == /var/www/haesiivooja-astro/releases/* ]] || { echo 'Release must be inside /var/www/haesiivooja-astro/releases/' >&2; exit 2; }
  [[ -d "$TARGET" && -f "$TARGET/index.html" && -f "$TARGET/en/index.html" && -f "$TARGET/sitemap-index.xml" && -f "$TARGET/robots.txt" ]] || {
    echo 'Release missing its homepages or SEO files; refusing to take WordPress offline.' >&2; exit 2;
  }
  [[ -d "$ROOT" && ! -L "$ROOT" && -f "$ROOT/wp-config.php" ]] || {
    echo '/var/www/html is not an existing WordPress directory; refusing cutover.' >&2; exit 2;
  }
  RETIRED="/var/www/haesiivooja-wordpress-$(date +%Y%m%d-%H%M%S)"
  echo "Moving original WordPress into $RETIRED"
  mv -- "$ROOT" "$RETIRED"
  if ! ln -s -- "$TARGET" "$ROOT"; then
    mv -- "$RETIRED" "$ROOT"
    echo 'Could not activate release. Restored original WordPress.' >&2; exit 1
  fi
  if ! (nginx -t && systemctl reload nginx && probe / && probe /en/ && probe /robots.txt && probe /sitemap-index.xml); then
    echo 'New site failed checks. Restoring the original WordPress root.' >&2
    rm -- "$ROOT"
    mv -- "$RETIRED" "$ROOT"
    nginx -t && systemctl reload nginx || true
    exit 1
  fi
  echo 'SUCCESS: Astro serves /var/www/html. WordPress PHP files are no longer in the webroot.'
  echo "ROLLBACK_DIRECTORY=$RETIRED"
  echo 'Keep WordPress files and database backups. Do NOT uninstall shared services.'
elif [[ "$ACTION" == rollback ]]; then
  [[ -L "$ROOT" && -d "$TARGET" && -f "$TARGET/wp-config.php" ]] || {
    echo 'Expected Astro symlink and a valid retired WordPress directory. Refusing rollback.' >&2; exit 2;
  }
  rm -- "$ROOT"
  mv -- "$TARGET" "$ROOT"
  nginx -t && systemctl reload nginx
  echo 'WordPress root restored. Re-check the site and any relevant services.'
else
  echo 'Usage: switch-wordpress-root.sh cutover RELEASE_DIR | rollback RETIRED_WORDPRESS_DIR' >&2
  exit 2
fi
