# Deploy HaeSiivooja Astro and retire WordPress safely

Do NOT delete `/var/www/html` during the initial cutover. It is the source of your content and your rollback copy. This procedure assumes Nginx currently serves all three domains and **must be adapted after inspecting your Nginx setup**. Do not change the `app.haesiivooja.fi` or `cascadary.com` vhosts.

## 1. Inspect and back up WordPress (no password needed)

```bash
sudo nginx -T 2>&1 | grep -nE 'server_name|root /var/www/html|proxy_pass|fastcgi_pass' | head -100
sudo ss -ltnp | grep -E ':80|:443'
ls -lah /var/www/html/wp-config.php
sudo certbot certificates
```

Do not share `wp-config.php` or DB passwords. The database configuration lives inside that file; WP-CLI uses it directly.

```bash
BACKUP="/root/haesiivooja-wp-backup-$(date +%Y%m%d-%H%M%S)"
sudo mkdir -p "$BACKUP"
sudo chmod 700 "$BACKUP"
sudo tar -C /var/www -czf "$BACKUP/wordpress-files.tar.gz" html
# Requires WP-CLI; if missing, install WP-CLI from the official wp-cli.org site first.
sudo wp --allow-root --path=/var/www/html db export "$BACKUP/wordpress.sql"
sudo wp --allow-root --path=/var/www/html option get blog_public
sudo wp --allow-root --path=/var/www/html theme list
sudo wp --allow-root --path=/var/www/html plugin list
```

The SQL backup must remain outside `/var/www/html`, the static webroot, and GitHub. Confirm the backup files exist before touching Nginx.

## 2. Get the GitHub code and export public pages

```bash
sudo mkdir -p /opt/haesiivooja-website
sudo chown "$USER":"$USER" /opt/haesiivooja-website
git clone https://github.com/oleglihvoinen/haesiivooja-website.git /opt/haesiivooja-website
cd /opt/haesiivooja-website
node -v   # Node.js 22.12+ needed; upgrade using an official supported method if older.
```

Export original legal pages using the existing WordPress installation. No MySQL password is printed:

```bash
sudo wp --allow-root --path=/var/www/html eval-file \
  /opt/haesiivooja-website/scripts/export-wp-legacy.php \
  > /tmp/haesiivooja-legacy-pages.json
python3 -m json.tool /tmp/haesiivooja-legacy-pages.json >/dev/null
cp /tmp/haesiivooja-legacy-pages.json src/data/legacy-pages.json
npm install --no-audit --no-fund
npm run predeploy
```

If predeploy fails, **stop** and recover missing pages, or inspect their real WordPress paths. Also inspect the export for HTML shortcodes, outdated absolute links, translation language and any personal information. If you commit the exported public legal text back to GitHub, review it first. Do not copy raw SQL, `wp-config.php` or WordPress user data into the repository.

To reproduce the *existing* WordPress design, transfer the public logo/images from `wp-content/uploads`, inspect the active theme and migrate relevant assets and layouts into the Astro source. This foundation is not an exact design clone yet.

## 3. Build and prepare an isolated release

```bash
cd /opt/haesiivooja-website
npm run check
npm run predeploy
bash ops/deploy-from-vps.sh "$PWD" prepare
ls -dt /var/www/haesiivooja-astro/releases/* | head -1
```

The last command prints the release directory. Set it explicitly after reviewing:

```bash
RELEASE="$(ls -dt /var/www/haesiivooja-astro/releases/* | head -1)"
# An Nginx loopback-only test site; not publicly accessible or indexable.
printf 'server { listen 127.0.0.1:8095; server_name localhost; root %s; index index.html; add_header X-Robots-Tag "noindex, nofollow" always; location / { try_files $uri $uri/ =404; } }\n' "$RELEASE" | sudo tee /etc/nginx/conf.d/haesiivooja-loopback.conf
sudo nginx -t && sudo systemctl reload nginx
curl -sSI http://127.0.0.1:8095/
curl -sSI http://127.0.0.1:8095/en/
curl -sSI http://127.0.0.1:8095/en/home-cleaning/
curl -s http://127.0.0.1:8095/sitemap-index.xml | head
```

The loopback `X-Robots-Tag` is intentional. Do NOT enable it for public production. Check desktop/mobile screenshots, imported legal pages, all assets, links and key app CTAs against the real original before switching domains.

## 4. Cut over only the main domain

First identify **exactly which Nginx files** handle `haesiivooja.fi` and confirm the WordPress vhost does not contain unrelated domains. Do not disable `/etc/nginx/sites-enabled/default` unless it really serves only WordPress.

```bash
sudo nginx -T 2>&1 | grep -n -B 15 -A 22 'server_name.*haesiivooja.fi'
sudo grep -R -nE 'server_name.*haesiivooja.fi' /etc/nginx/sites-enabled/ /etc/nginx/conf.d/
```

Use `ops/nginx-site.example.conf` as the replacement for **only** the main domain's original vhost. Adjust certificate paths based on `sudo certbot certificates`, copy the old vhost config into `$BACKUP` and ensure there are no duplicate matching `server_name` blocks. Remove the old WordPress PHP upstream only from this domain. Do not touch app/cascadary hosts.

```bash
# activate the validated prepared release, with no rebuild:
RELEASE="$(ls -dt /var/www/haesiivooja-astro/releases/* | head -1)"
sudo ln -s "$RELEASE" /var/www/haesiivooja-astro/current.new
sudo mv -Tf /var/www/haesiivooja-astro/current.new /var/www/haesiivooja-astro/current
# Now install the reviewed Nginx site config and disable ONLY the old WordPress vhost.
sudo nginx -t && sudo systemctl reload nginx
```

Verify before retiring anything:

```bash
curl -sSI https://haesiivooja.fi/
curl -sSI https://haesiivooja.fi/en/
curl -sSI https://haesiivooja.fi/en/home-cleaning/
curl -sSI https://haesiivooja.fi/robots.txt
curl -sSI https://haesiivooja.fi/sitemap-index.xml
curl -sSI https://haesiivooja.fi/wp-login.php  # expect 404, NOT 200
curl -sSI https://app.haesiivooja.fi/
curl -sSI https://cascadary.com/
```

Check `https://haesiivooja.fi/sitemap-index.xml` in Search Console and inspect both FI/EN page examples. Configure 301 redirects for any WordPress paths that changed; do not redirect unknown paths to the homepage.

## 5. Take WordPress offline, preserve a rollback

Once Nginx is definitely serving Astro and the old PHP location no longer exists, **WordPress is offline for the domain**. There is no need to stop MariaDB/MySQL, PHP-FPM, or the Nginx service: they may serve other applications.

After confirming nothing else references `/var/www/html`, optionally move it aside instead of deleting it:

```bash
sudo grep -R -nF '/var/www/html' /etc/nginx /etc/apache2 2>/dev/null || true
# ONLY after reviewing that output:
sudo mv /var/www/html "/var/www/haesiivooja-wordpress-retired-$(date +%Y%m%d)"
```

Keep the SQL and file backups for the rollback period. Moving WordPress before the successful site switch could cause downtime. To roll back, restore the old vhost configuration and filesystem from the backup and run `nginx -t` before reloading.

## Subsequent releases

```bash
cd /opt/haesiivooja-website
git pull --ff-only
# Any verified changes to imported legacy-pages.json on VPS need to be retained across pulls.
bash ops/deploy-from-vps.sh "$PWD" activate
sudo nginx -t && sudo systemctl reload nginx
```
