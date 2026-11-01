# Deploy Hae Siivooja Astro site on Apache2

This repository builds a static website. The Apache VirtualHost for `haesiivooja.fi` should use `/var/www/haesiivooja-astro/current` as its DocumentRoot. Back up the site configuration before editing it.

```bash
cd /opt/haesiivooja-website
git pull --ff-only
npm install --no-audit --no-fund
npm run check
npm run predeploy
bash ops/deploy-from-vps.sh "$PWD" prepare
```

Preview the generated release and test the policies and English pages before activation:

```bash
RELEASE="$(ls -dt /var/www/haesiivooja-astro/releases/* | head -1)"
test -f "$RELEASE/index.html"
test -f "$RELEASE/en/index.html"
test -f "$RELEASE/privacy/index.html"
test -f "$RELEASE/en/privacy/index.html"
test -f "$RELEASE/sitemap.xml"
```

If Apache is already configured to point at `/var/www/haesiivooja-astro/current`, activate the tested release:

```bash
sudo ln -s "$RELEASE" /var/www/haesiivooja-astro/current.new
sudo mv -Tf /var/www/haesiivooja-astro/current.new /var/www/haesiivooja-astro/current
sudo apache2ctl configtest
sudo systemctl reload apache2
```

If Apache is not yet configured for the static directory, configure the main website's HTTP and HTTPS virtual hosts with the following directives, **preserving their existing certificate, logging and redirect configuration**:

```apache
DocumentRoot /var/www/haesiivooja-astro/current
<Directory /var/www/haesiivooja-astro>
    Options +FollowSymLinks -Indexes
    AllowOverride None
    Require all granted
    DirectoryIndex index.html
</Directory>
```

Use `sudo apache2ctl configtest` before reloading.

Verify the live privacy URL and its redirect:

```bash
curl -IL https://haesiivooja.fi/privacy
curl -fIL https://haesiivooja.fi/privacy/
curl -fIL https://haesiivooja.fi/en/privacy/
curl -fIL https://haesiivooja.fi/
curl -fIL https://haesiivooja.fi/en/
curl -fIL https://haesiivooja.fi/sitemap.xml
```

In Google Play Console set the Privacy Policy URL to **https://haesiivooja.fi/privacy/** after it is live, and ensure the app contains the same privacy link. Google Play also requires accurate Data safety disclosures and account deletion support.

Use a previous timestamped release for rollback by repointing `current` and reloading Apache.

The main page URL sitemap is at `https://haesiivooja.fi/sitemap.xml`. The `sitemap-index.xml` is an index file which normally lists child sitemap files rather than page URLs. The build now generates both. The site uses the restored mascot `brand/mascot.png` and a multi-resolution `favicon.ico`. Screens 4 and 5 are excluded from the output.
