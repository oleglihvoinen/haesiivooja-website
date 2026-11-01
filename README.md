# HaeSiivooja website — bilingual SEO-first Astro

> **Ubuntu production server update (2026-11-01):** The actual VPS uses **Apache2**, not Nginx. Both `haesiivooja.fi` and `haesiivooja.com` share `/var/www/html`, and duplicate HTTP vhosts exist for `.fi`. Follow [docs/DEPLOY_APACHE.md](docs/DEPLOY_APACHE.md) for this server; do **not** run the Nginx or `/var/www/html` symlink cutover scripts. Inspect the Apache vhosts before changing live routing.


**Status: staging foundation, not yet the live WordPress replacement.** Contains 17 Finnish and 17 corresponding English routes (including the two homepages), with human-readable English slugs, fully translated service and guide copy, hreflang alternate links, Finnish/English navigation, independent self-canonicals, translated SEO titles/descriptions and structured data. Sitemap lists both sets of URLs. Original WordPress media/theme not yet imported; do not describe the result as pixel-perfect.

## Requirements

- Node.js >=22.22 and npm.
- WordPress at `/var/www/html` as the migration source, accessible on Ubuntu through WP-CLI using its existing `wp-config.php` credentials. Do not share database credentials.
- Nginx hostname `haesiivooja.fi`, separate from the existing `app.haesiivooja.fi` and `cascadary.com` configurations.

## Local build and checks

```bash
npm install
npm run check:content
npm run build
npm run check:seo
npm run predeploy
```

`npm run predeploy` **deliberately fails until** legal pages have been exported from WordPress to `src/data/legacy-pages.json`. This prevents publishing a new site that removes the legal pages. `npm run check` runs content, build and technical SEO checks. Build on the VPS if dependencies cannot be downloaded in your workstation. Add the generated `package-lock.json` to Git once available.

## Language routes and SEO

| Finnish | English |
|---|---|
| `/` | `/en/` |
| `/etsi-siivooja/` | `/en/find-a-cleaner/` |
| `/siivouspalvelut/` | `/en/cleaning-services/` |
| `/kotisiivous/` | `/en/home-cleaning/` |
| `/muuttosiivous/` | `/en/move-out-cleaning/` |
| `/perussiivous/` | `/en/deep-cleaning/` |
| `/ikkunanpesu/` | `/en/window-cleaning/` |
| `/toimistosiivous/` | `/en/office-cleaning/` |
| `/siivouksen-hinta/` | `/en/cleaning-prices/` |
| `/miten-se-toimii/` | `/en/how-it-works/` |
| `/siivoojaksi/` | `/en/for-cleaners/` |
| `/tietoa-meista/` | `/en/about-us/` |
| `/yhteystiedot/` | `/en/contact/` |
| `/oppaat/` | `/en/guides/` |
| `/oppaat/muuttosiivouksen-tarkistuslista/` | `/en/guides/move-out-cleaning-checklist/` |
| `/oppaat/kotisiivouksen-hinta/` | `/en/guides/home-cleaning-prices/` |
| `/oppaat/kotitalousvahennys-siivous/` | `/en/guides/household-tax-deduction-cleaning/` |

**Hreflang alternates are written in the HTML head, not the sitemap XML.** This is a supported Google approach. Astro's sitemap integration automatically indexes both sets of routes, including translated URL slugs. Because Finnish and English slugs are different, generic sitemap-i18n prefix substitution would be incorrect. Finnish is the default and `x-default` points to Finnish; no automatic geolocation redirection.

**Legacy WordPress terms, privacy and accessibility pages** must be imported from the actual source. These are not translated into new English legal pages until reviewed English legal content is available. The footer links to these published original URLs once imported; no misleading English legal translations are generated.

## Deployment and WordPress removal

Follow **[docs/DEPLOY_UBUNTU.md](docs/DEPLOY_UBUNTU.md)**. It includes a database-and-files backup, WP-CLI content export, loopback-only staging check, Nginx vhost cutover and rollback-safe retirement of `/var/www/html`. The deployment helper only creates a release by default; activation must be explicit. Do not stop shared MySQL, PHP-FPM or Nginx services.

See [docs/SEO_PLAN.md](docs/SEO_PLAN.md) for Search Console and growth planning and [docs/URL_MIGRATION.md](docs/URL_MIGRATION.md) for redirect decisions. This code alone cannot guarantee Google indexing or rankings. Current public legal text, media assets, content accuracy, and forms still require migration and acceptance checks.
