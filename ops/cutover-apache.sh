#!/usr/bin/env bash
# Safe Apache2 cutover for haesiivooja.fi. NEVER moves /var/www/html.
# sudo CONFIRM_APACHE_CUTOVER=YES DISABLE_HAESIIVOOJA_COM=YES bash ops/cutover-apache.sh activate RELEASE_DIR
# sudo bash ops/cutover-apache.sh rollback BACKUP_DIR
set -Eeuo pipefail
MODE="$1"; ARG="$2"
CONF_DIR=/etc/apache2/sites-available
ENABLED=/etc/apache2/sites-enabled
BASE=/var/www/haesiivooja-astro
BACKUP=""
die(){ echo "ERROR: $*" >&2; exit 1; }
[ "$EUID" -eq 0 ] || die "Run with sudo."

restore_backup(){
 local saved="$1" name
 [ -f "$saved/haesiivooja.fi.conf" ] && [ -f "$saved/haesiivooja.fi-le-ssl.conf" ] || die "Invalid backup directory."
 for name in haesiivooja.fi.conf haesiivooja.fi-le-ssl.conf; do
   cp -a "$saved/$name" "$CONF_DIR/$name"
 done
 if [ -f "$saved/original-current" ]; then
   ln -sfn "$(cat "$saved/original-current")" "$BASE/current.restore"
   mv -Tf "$BASE/current.restore" "$BASE/current"
 elif [ -L "$BASE/current" ]; then rm -f "$BASE/current"; fi
 for name in wordpress.conf haesiivooja.com.conf haesiivooja_com-ssl.conf; do
   [ ! -f "$saved/enabled-$name" ] || a2ensite -q "$name"
 done
 apache2ctl configtest && systemctl reload apache2
 echo "Restored original Apache config. WordPress files were not moved."
}
if [ "$MODE" = rollback ]; then restore_backup "$ARG"; exit 0; fi
[ "$MODE" = activate ] || die "Usage: cutover-apache.sh activate RELEASE_DIR | rollback BACKUP_DIR"
[ "\${CONFIRM_APACHE_CUTOVER:-NO}" = YES ] || die "Set CONFIRM_APACHE_CUTOVER=YES after inspecting Apache vhosts."
case "$ARG" in "$BASE"/releases/*) ;; *) die "Release must be under $BASE/releases/" ;; esac
for path in index.html en/index.html en/home-cleaning/index.html robots.txt sitemap-index.xml; do
 [ -f "$ARG/$path" ] || die "Release missing: $path"
done
[ -f /var/www/html/wp-config.php ] || die "WordPress root has changed. Stop and inspect."
for name in haesiivooja.fi.conf haesiivooja.fi-le-ssl.conf; do
 [ -L "$ENABLED/$name" ] && [ -f "$CONF_DIR/$name" ] || die "Missing enabled .fi site $name"
done
apache2ctl configtest

BACKUP="/root/haesiivooja-apache-cutover-$(date +%Y%m%d-%H%M%S)"
install -d -m 700 "$BACKUP"
for name in haesiivooja.fi.conf haesiivooja.fi-le-ssl.conf; do cp -a "$CONF_DIR/$name" "$BACKUP/$name"; done
for name in wordpress.conf haesiivooja.com.conf haesiivooja_com-ssl.conf; do
 if [ -L "$ENABLED/$name" ]; then : > "$BACKUP/enabled-$name"; fi
done
if [ -L "$BASE/current" ]; then readlink "$BASE/current" > "$BACKUP/original-current"; fi
restore_on_error(){
 local code="$?"
 trap - ERR
 echo "Cutover failed (code $code). Attempting rollback." >&2
 restore_backup "$BACKUP" || echo "Manual rollback required from $BACKUP" >&2
 exit "$code"
}
trap restore_on_error ERR

python3 - "$CONF_DIR" "$BASE/current" <<'PY'
import pathlib, re, sys
directory=pathlib.Path(sys.argv[1]); target=sys.argv[2]
for name in ['haesiivooja.fi.conf','haesiivooja.fi-le-ssl.conf']:
    file=directory/name; source=file.read_text(encoding='utf-8')
    updated,n=re.subn(r'(?m)^[ \t]*DocumentRoot[ \t]+/var/www/html[ \t]*$', '    DocumentRoot '+target,source)
    block=('    <Directory '+target+'>\n'
           '        Options +FollowSymLinks -Indexes\n'
           '        AllowOverride None\n'
           '        Require all granted\n'
           '        DirectoryIndex index.html\n'
           '    </Directory>')
    updated,m=re.subn(r'(?ms)^[ \t]*<Directory[ \t]+/var/www/html>.*?^[ \t]*</Directory>',block,updated,count=1)
    if (n,m)!=(1,1): raise RuntimeError(f'{name}: expected one WP root & Directory, found {n}/{m}')
    updated=updated.replace('# WordPress specific configuration','# Astro static website configuration')
    file.write_text(updated,encoding='utf-8')
    print('Updated:',file)
PY

ln -s "$ARG" "$BASE/current.new"
mv -Tf "$BASE/current.new" "$BASE/current"
if [ -L "$ENABLED/wordpress.conf" ]; then a2dissite -q wordpress.conf; fi
if [ "\${DISABLE_HAESIIVOOJA_COM:-NO}" = YES ]; then
 for name in haesiivooja.com.conf haesiivooja_com-ssl.conf; do
   if [ -L "$ENABLED/$name" ]; then a2dissite -q "$name"; fi
 done
fi
apache2ctl configtest
systemctl reload apache2
for path in / /en/ /en/home-cleaning/ /robots.txt /sitemap-index.xml; do
 curl --noproxy '*' --fail --silent --show-error --max-time 15 \
   --resolve haesiivooja.fi:443:127.0.0.1 \
   "https://haesiivooja.fi$path" -o /dev/null
done
trap - ERR
echo "SUCCESS: Apache serves Astro for haesiivooja.fi"
echo "BACKUP_DIR=$BACKUP"
echo "ROLLBACK: sudo bash ops/cutover-apache.sh rollback $BACKUP"
echo "WordPress files remain at /var/www/html, which other vhosts may still reference."
