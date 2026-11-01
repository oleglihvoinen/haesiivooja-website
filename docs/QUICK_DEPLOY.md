# HaeSiivooja: WordPress to Astro, quick VPS deployment

Use this only if the active Nginx configuration for **haesiivooja.fi** has `root /var/www/html;` and **no other application/domain** uses that directory. Do not run the cutover until you have examined the Nginx output; a shared directory or Apache/other proxy setup needs a different cutover. The other apps and their vhosts must remain unchanged.

## 1. Diagnose and back up

```bash
sudo nginx -t
sudo nginx -T 2>&1 | grep -nE 'server_name|root[[:space:]]+/var/www/html|disable_symlinks|X-Robots-Tag|noindex' | head -120
test -f /var/www/html/wp-config.php && echo "WordPress found"
sudo apt-get update
sudo apt-get install -y git curl rsync php-cli mariadb-client
BACKUP="/root/haesiivooja-backup-$(date +%Y%m%d-%H%M%S)"
sudo mkdir -p "$BACKUP"
sudo chmod 700 "$BACKUP"
sudo tar -C /var/www -czf "$BACKUP/wordpress-files.tar.gz" html
```

If WP-CLI is not installed, install the official PHAR:

```bash
if ! command -v wp >/dev/null; then
  curl -fsSLo /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  php /tmp/wp-cli.phar --info
  sudo install -m 755 /tmp/wp-cli.phar /usr/local/bin/wp
fi
sudo wp --allow-root --path=/var/www/html db export "$BACKUP/wordpress.sql"
sudo ls -lh "$BACKUP"
```

WP-CLI uses the credentials already in `wp-config.php`. NEVER print or commit them; keep the SQL export outside the webroot.

## 2. Clone and import

```bash
sudo install -d -o "$USER" -g "$(id -gn)" /opt/haesiivooja-website
git clone https://github.com/oleglihvoinen/haesiivooja-website.git /opt/haesiivooja-website
cd /opt/haesiivooja-website
node -v
```

Requires Node 22.12+; if not present, use a shell-user-local Node install such as nvm, not a forced global Node replacement that could affect other apps.

```bash
sudo wp --allow-root --path=/var/www/html post list --post_type=page --post_status=publish --fields=ID,post_name,post_title
sudo wp --allow-root --path=/var/www/html eval-file "$PWD/scripts/export-wp-legacy.php" > /tmp/haesiivooja-legacy.json
python3 -m json.tool /tmp/haesiivooja-legacy.json >/dev/null
cp /tmp/haesiivooja-legacy.json src/data/legacy-pages.json
npm install --no-audit --no-fund
npm run check
npm run predeploy
```

**STOP** if the predeploy script reports missing legal pages: verify the actual published WordPress page slugs and edit the export mapping before proceeding. The new site does not require the WordPress database after migration.

## 3. Build versioned static release and preserve public WordPress images

```bash
bash ops/deploy-from-vps.sh "$PWD" prepare
RELEASE="$(ls -dt /var/www/haesiivooja-astro/releases/* | head -1)"
echo "$RELEASE"
sudo install -d -m 755 "$RELEASE/wp-content/uploads"
sudo rsync -rt --prune-empty-dirs \
  --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' \
  --include='*.webp' --include='*.avif' --include='*.gif' --exclude='*' \
  /var/www/html/wp-content/uploads/ "$RELEASE/wp-content/uploads/"
```

Imported pages can now reference existing photos at the old `/wp-content/uploads/...` paths. The new Astro homepage currently uses a graphic illustration rather than a newly imported WordPress photo. Photos must be curated and linked in the source to display on new service pages.

## 4. Switch just the main domain (Nginx document root path only)

Do this **only** if `/var/www/html` is exclusive to `haesiivooja.fi`, and the main site is served through Nginx's `root` directive (not Apache or `proxy_pass`). No change to the app/cascadary configurations is needed.

```bash
cd /opt/haesiivooja-website
RELEASE="$(ls -dt /var/www/haesiivooja-astro/releases/* | head -1)"
sudo CONFIRM_HAESIIVOOJA_ONLY=YES bash ops/switch-wordpress-root.sh cutover "$RELEASE"
```

The script renames WordPress to a timestamped backup directory, creates `/var/www/html` as a symlink to the Astro release, reloads Nginx and probes Finnish/English home, English service page, robots and sitemap through the local HTTPS endpoint. If any probe fails, the script attempts to restore WordPress. Save the printed `ROLLBACK_DIRECTORY` path.

## 5. Verify SEO and the other apps

```bash
curl -IL https://haesiivooja.fi/
curl -IL https://haesiivooja.fi/en/
curl -IL https://haesiivooja.fi/en/home-cleaning/
curl -IL https://haesiivooja.fi/robots.txt
curl -IL https://haesiivooja.fi/sitemap-index.xml
curl -IL https://app.haesiivooja.fi/
curl -IL https://cascadary.com/
curl -I https://haesiivooja.fi/wp-login.php
```

Expect 200 for the main pages, sitemap and robots, and typically 404 for WordPress's login. Inspect page source and response headers for unintended noindex directives. Submit `https://haesiivooja.fi/sitemap-index.xml` in Google Search Console after launch. Use actual Search Console data to evaluate indexing and ranking.

## Rollback

Use the exact timestamped retired directory printed at cutover:

```bash
cd /opt/haesiivooja-website
sudo CONFIRM_HAESIIVOOJA_ONLY=YES bash ops/switch-wordpress-root.sh rollback /var/www/haesiivooja-wordpress-YYYYMMDD-HHMMSS
```

Keep the original WordPress directory and SQL archive until the replacement is stable. Do not uninstall Nginx, MySQL/MariaDB, PHP-FPM, or Docker globally: other apps may use them.

For websites that use a dedicated Nginx vhost path rather than `root /var/www/html;`, follow `docs/DEPLOY_UBUNTU.md` instead of the guarded webroot switch.
