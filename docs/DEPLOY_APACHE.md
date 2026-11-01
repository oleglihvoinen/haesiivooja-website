# Apache2 migration: haesiivooja.fi (Ubuntu VPS)

**Verified server facts, 2026-11-01:** Apache2 listens on 80/443. The enabled SSL vhost `haesiivooja.fi-le-ssl.conf` and port-80 `haesiivooja.fi.conf` have `DocumentRoot /var/www/html`. The SSL and HTTP `haesiivooja.com` vhosts ALSO use `/var/www/html`. A duplicate `wordpress.conf` claims the `haesiivooja.fi` HTTP name, pointing to `/var/www/html/wordpress`. Other independent vhosts include `app.haesiivooja.fi`, `cascadary.com`, analytics and APIs. **DO NOT MOVE, DELETE, OR SYMLINK /var/www/html. DO NOT RUN ops/switch-wordpress-root.sh or any Nginx guide.**

## A. Mandatory read-only inspection — before modifying Apache

```bash
sudo apache2ctl -S
sudo sed -n '1,240p' /etc/apache2/sites-enabled/haesiivooja.fi-le-ssl.conf
sudo sed -n '1,200p' /etc/apache2/sites-enabled/haesiivooja.fi.conf
sudo sed -n '1,200p' /etc/apache2/sites-enabled/wordpress.conf
sudo sed -n '1,180p' /etc/apache2/sites-enabled/haesiivooja_com-ssl.conf
sudo sed -n '1,180p' /etc/apache2/sites-enabled/haesiivooja.com.conf
sudo test -f /var/www/html/wp-load.php && echo 'WP root: /var/www/html'
sudo test -f /var/www/html/wordpress/wp-load.php && echo 'WP also in /var/www/html/wordpress'
```

Check SSL certificate paths, rewrite rules, `Directory` blocks, `ProxyPass`, `Alias`, `Redirect` directives and `AllowOverride`. Duplicate vhosts must be resolved after reviewing the full contents; the first matching declaration may win. Do not share sensitive auth headers, cert private keys, or WordPress configuration files.

## B. Back up *before* changing anything

```bash
BACKUP="/root/haesiivooja-pre-astro-$(date +%Y%m%d-%H%M%S)"
sudo install -d -m 700 "$BACKUP"
sudo tar -C / -czf "$BACKUP/apache-config.tar.gz" etc/apache2
sudo tar -C /var/www -czf "$BACKUP/wordpress-files.tar.gz" html
sudo ls -lh "$BACKUP"
```

Determine the WordPress root first; `wp-config.php` is at `/var/www/html/wp-config.php` but there may also be a `/var/www/html/wordpress` installation. Use WP-CLI on the **actual** root only. WP-CLI obtains its DB password from the existing configuration.

```bash
if ! command -v wp >/dev/null; then
  curl -fsSLo /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  php /tmp/wp-cli.phar --info
  sudo install -m 755 /tmp/wp-cli.phar /usr/local/bin/wp
fi
WP_PATH=/var/www/html  # change to /var/www/html/wordpress ONLY if that is the actual active WordPress root
sudo wp --allow-root --path="$WP_PATH" core is-installed
sudo wp --allow-root --path="$WP_PATH" db export "$BACKUP/wordpress.sql"
sudo ls -lh "$BACKUP"
```

Do not commit the SQL file, WP secrets, or raw database dumps to GitHub.

## C. Install/build Astro *alongside WordPress*, no production changes

Install git, curl, rsync, php-cli, python3 if missing; install Node 24 via nvm for the SSH account instead of replacing system-wide Node. Then:

```bash
sudo apt-get update
sudo apt-get install -y git curl rsync python3 php-cli
if [ ! -d /opt/haesiivooja-website/.git ]; then
  sudo install -d -o "$USER" -g "$(id -gn)" /opt/haesiivooja-website
  git clone https://github.com/oleglihvoinen/haesiivooja-website.git /opt/haesiivooja-website
fi
cd /opt/haesiivooja-website
git pull --ff-only
node -v  # >=22.22.0 required; use Node 24 via nvm if needed

sudo wp --allow-root --path="$WP_PATH" eval-file "$PWD/scripts/export-wp-legacy.php" > /tmp/haesiivooja-legal.json
python3 -m json.tool /tmp/haesiivooja-legal.json >/dev/null
cp /tmp/haesiivooja-legal.json src/data/legacy-pages.json
npm install --no-audit --no-fund
npm run check
npm run predeploy
bash ops/deploy-from-vps.sh "$PWD" prepare
RELEASE="$(ls -dt /var/www/haesiivooja-astro/releases/* | head -1)"
echo "Prepared $RELEASE"
```

If `predeploy` fails, the existing published WordPress slugs may differ; inspect and map real pages. Do not fill with placeholder legal text or bypass the check. Note Astro foundation does not automatically show old WordPress photos: the photos can be copied and manually selected in the Astro source.

Preserve existing *public* WordPress media paths for old legal content, if needed:

```bash
WP_UPLOADS="$WP_PATH/wp-content/uploads"
if [ -d "$WP_UPLOADS" ]; then
  sudo install -d -m 755 "$RELEASE/wp-content/uploads"
  sudo rsync -rt --prune-empty-dirs \
    --include='*/' --include='*.jpg' --include='*.jpeg' --include='*.png' \
    --include='*.webp' --include='*.gif' --include='*.avif' --exclude='*' \
    "$WP_UPLOADS/" "$RELEASE/wp-content/uploads/"
fi
```

Preview over loopback HTTP without touching Apache:

```bash
python3 -m http.server 8095 --bind 127.0.0.1 --directory "$RELEASE" >/tmp/haesiivooja-preview.log 2>&1 &
PREVIEW_PID=$!
curl -fI http://127.0.0.1:8095/
curl -fI http://127.0.0.1:8095/en/
curl -fI http://127.0.0.1:8095/en/home-cleaning/
curl -fI http://127.0.0.1:8095/sitemap-index.xml
kill "$PREVIEW_PID"
```

## D. Cutover: use a separate Astro document root for .fi only

**Do not apply this section until the five vhost files in section A have been inspected.** Editing an existing SSL vhost without checking redirects, rewrite rules or proxy config can break the site.

The target static document root is `/var/www/haesiivooja-astro/current` (a symlink to a verified, immutable release). Use an explicit Apache directory block in the relevant **only .fi** vhosts:

```apache
DocumentRoot /var/www/haesiivooja-astro/current
DirectoryIndex index.html

<Directory /var/www/haesiivooja-astro/current>
    Options +FollowSymLinks -Indexes
    AllowOverride None
    Require all granted
</Directory>
```

Remove/replace WordPress-specific rewrites, PHP routing or old root-dependent `<Directory>` settings **only within the main .fi vhosts** as required after inspecting them. Keep existing SSL certificate directives unchanged. Resolve the duplicate *HTTP-only* `wordpress.conf` after verifying it serves no other domains (and no intended redirects). If HTTP redirects to HTTPS, preserve that behavior. Leave `haesiivooja.com` and all other vhosts untouched.

Once the prepared release has passed checks:

```bash
RELEASE="$(ls -dt /var/www/haesiivooja-astro/releases/* | head -1)"
sudo ln -s "$RELEASE" /var/www/haesiivooja-astro/current.new
sudo mv -Tf /var/www/haesiivooja-astro/current.new /var/www/haesiivooja-astro/current
sudo apache2ctl configtest
# ONLY AFTER manually reviewing and applying the targeted Apache vhost edits:
sudo systemctl reload apache2
```

The current repo intentionally does **not** provide an automatic vhost replacement because the user's Apache vhosts contain multiple aliases and duplicate HTTP names.

## E. Verify and rollback

```bash
curl -fIL https://haesiivooja.fi/
curl -fIL https://haesiivooja.fi/en/
curl -fIL https://haesiivooja.fi/en/home-cleaning/
curl -fIL https://haesiivooja.fi/robots.txt
curl -fIL https://haesiivooja.fi/sitemap-index.xml
curl -I https://haesiivooja.fi/wp-login.php  # expected 404
curl -IL https://haesiivooja.com/
curl -IL https://app.haesiivooja.fi/
curl -IL https://cascadary.com/
```

Check actual page body and page source; `curl -I` alone can return 200 from WordPress. Check no accidental `X-Robots-Tag: noindex`; inspect Search Console and submit `/sitemap-index.xml`. For rollback restore the backed-up **specific .fi Apache vhost config files** and reload after `apache2ctl configtest`. Leave WordPress files/DB intact until the new site is stable. **Never globally disable Apache, PHP, MySQL, or Docker.**
