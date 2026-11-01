# Deployment commands for the verified Apache2 HaeSiivooja VPS

On 2026-11-01, the actual server was verified to use Apache2. SSL vhost `haesiivooja.fi-le-ssl.conf` and HTTP vhost `haesiivooja.fi.conf` serve `/var/www/html`. The duplicate HTTP `wordpress.conf` claims the .fi domain. Both .com vhosts also use `/var/www/html`, and one provides a Roundcube alias. Other sites (app.haesiivooja.fi, cascadary.com, APIs and analytics) have separate Apache vhosts. **Never follow the Nginx guide or move /var/www/html on this VPS.**

This procedure installs a static Astro site on a new path, then uses `ops/cutover-apache.sh` to modify only the .fi vhosts, disable the duplicate WordPress HTTP vhost, and optionally disable .com web vhosts. The script preserves SSL certificates and existing logging/other SSL directives, and attempts an automatic rollback if Apache validation or HTTPS checks fail.

## A. Backup

```bash
BACKUP="/root/haesiivooja-pre-astro-$(date +%Y%m%d-%H%M%S)"
sudo install -d -m 700 "$BACKUP"
sudo tar -C /etc -czf "$BACKUP/apache-config.tar.gz" apache2
sudo tar -C /var/www -czf "$BACKUP/wordpress-files.tar.gz" html
sudo ls -lh "$BACKUP"
```

Check the WordPress core directory (the root `wp-config.php` is at `/var/www/html`):

```bash
for dir in /var/www/html /var/www/html/wordpress; do
  if sudo test -f "$dir/wp-load.php"; then echo "WordPress core: $dir"; fi
done
```

If WP-CLI is missing:

```bash
if ! command -v wp >/dev/null; then
 curl -fsSLo /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
 php /tmp/wp-cli.phar --info
 sudo install -m 755 /tmp/wp-cli.phar /usr/local/bin/wp
fi
```

Choose the active WordPress core directory from the previous command. The usual location is /var/www/html:

```bash
WP_PATH=/var/www/html
sudo wp --allow-root --path="$WP_PATH" core is-installed
sudo wp --allow-root --path="$WP_PATH" db export "$BACKUP/wordpress.sql"
sudo ls -lh "$BACKUP"
```

WP-CLI uses the database credentials in the existing WP configuration; no password needs to be printed or reset.

## B. Install/build

Use Node.js 24 LTS for your SSH account (`nvm`), not a system-wide replacement:

```bash
sudo apt-get update
sudo apt-get install -y git curl rsync python3 php-cli
curl -fsSLo /tmp/nvm-install.sh https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh
bash /tmp/nvm-install.sh
export NVM_DIR="$HOME/.nvm"
[ ! -s "$NVM_DIR/nvm.sh" ] || . "$NVM_DIR/nvm.sh"
nvm install 24
nvm use 24
node -v
```

Get code:

```bash
sudo install -d -o "$USER" -g "$(id -gn)" /opt/haesiivooja-website
if [ ! -d /opt/haesiivooja-website/.git ]; then
 git clone https://github.com/oleglihvoinen/haesiivooja-website.git /opt/haesiivooja-website
fi
cd /opt/haesiivooja-website
git pull --ff-only
bash -n ops/cutover-apache.sh
```

Export legally required WordPress content (Finnish original pages are okay; English legal translations have not been supplied):

```bash
sudo wp --allow-root --path="$WP_PATH" post list --post_type=page --post_status=publish --fields=ID,post_name,post_title
sudo wp --allow-root --path="$WP_PATH" eval-file "$PWD/scripts/export-wp-legacy.php" > /tmp/haesiivooja-legal.json
python3 -m json.tool /tmp/haesiivooja-legal.json >/dev/null
cp /tmp/haesiivooja-legal.json src/data/legacy-pages.json
npm install --no-audit --no-fund
npm run check
npm run predeploy
```

If `npm run predeploy` fails, inspect actual WordPress legal page slugs (do not invent legal text or bypass the check). If the old legal pages refer to WordPress-specific functionality, review/update them before publishing Astro.

Prepare:

```bash
bash ops/deploy-from-vps.sh "$PWD" prepare
RELEASE="$(ls -dt /var/www/haesiivooja-astro/releases/* | head -1)"
echo "$RELEASE"
```

Optional: retain publicly accessible WP photographs; it only copies them, the Astro design will not display them until page components point to specific filenames.

```bash
if [ -d "$WP_PATH/wp-content/uploads" ]; then
 sudo install -d -m 755 "$RELEASE/wp-content/uploads"
 sudo rsync -rt --prune-empty-dirs \
   --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' \
   --include='*.webp' --include='*.avif' --include='*.gif' --exclude='*' \
   "$WP_PATH/wp-content/uploads/" "$RELEASE/wp-content/uploads/"
fi
```

## C. Cutover and verify

The script expects the existing .fi vhosts to have exactly one WordPress `DocumentRoot /var/www/html` and `<Directory /var/www/html>` block each (verified by provided output). The script does *not* move/delete WordPress. Use a separate new directory for Astro. Do **not** invoke the old `ops/switch-wordpress-root.sh` script.

First validate the prepared directory and script:

```bash
cd /opt/haesiivooja-website
bash -n ops/cutover-apache.sh
sudo apache2ctl configtest
test -f "$RELEASE/en/home-cleaning/index.html"
test -f "$RELEASE/sitemap-index.xml"
```

When ready:

```bash
sudo CONFIRM_APACHE_CUTOVER=YES \
  bash ops/cutover-apache.sh activate "$RELEASE"
```

This leaves .com enabled temporarily, so you can test before removing it. For the optional .com site shutdown, run `sudo a2dissite haesiivooja.com.conf haesiivooja_com-ssl.conf` **only if you no longer need those hostnames or their `/mail` and `/roundcube` webmail aliases**, then `sudo apache2ctl configtest && sudo systemctl reload apache2`. This does not delete SMTP/IMAP/mail accounts, DNS or certificate files.

Alternatively, to turn off the .com vhosts in the same cutover and include them in its automatic rollback:

```bash
sudo CONFIRM_APACHE_CUTOVER=YES DISABLE_HAESIIVOOJA_COM=YES \
  bash ops/cutover-apache.sh activate "$RELEASE"
```

Check:

```bash
curl -fIL https://haesiivooja.fi/
curl -fIL https://haesiivooja.fi/en/
curl -fIL https://haesiivooja.fi/en/home-cleaning/
curl -fIL https://haesiivooja.fi/sitemap-index.xml
curl -I https://haesiivooja.fi/wp-login.php
curl -IL https://app.haesiivooja.fi/
curl -IL https://cascadary.com/
sudo apache2ctl -S
```

After a successful cutover, save the displayed `BACKUP_DIR` value; rollback is:

```bash
cd /opt/haesiivooja-website
sudo bash ops/cutover-apache.sh rollback /root/haesiivooja-apache-cutover-YYYYMMDD-HHMMSS
```

WordPress files remain in `/var/www/html` because Apache's other default vhost still references that directory, even after disabling the .com vhosts. Do not delete it without an audit of all remaining vhosts. The main .fi domain should use Astro after cutover.
