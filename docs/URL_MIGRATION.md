# URL migration decisions — to finalize against WordPress pages

Preserve existing pages where legal / user trust relevance matters and import exact publicly published content from WordPress. Suggested mappings must be manually checked:

| WordPress URL | Planned destination | Action |
|---|---|---|
| `/` | `/` | Keep |
| `/terms-of-service/` | `/terms-of-service/` | Keep exact slug and migrate full legal content |
| `/privacy-policy/` | `/privacy-policy/` | Keep exact slug and migrate full legal content |
| `/accessibility-statement/` | `/accessibility-statement/` | Keep exact slug and migrate full legal content |
| `/app-guide/` | `/app-guide/` or `/miten-se-toimii/` | Keep if relevant; otherwise 301 to equivalent |
| `/our-story/` | `/our-story/` or `/tietoa-meista/` | Keep or 301 to equivalent after checking content |
| `/cleaner/` | `/cleaner/` or `/siivoojaksi/` | Keep or 301 to equivalent after checking content |
| `/support/` | `/yhteystiedot/` | Current page may be broken; 301 only if old URL has a meaningful corresponding page |

For Nginx, add tested rules to the **haesiivooja.fi** vhost only, e.g. `location = /cleaner/ { return 301 /siivoojaksi/; }` after deciding not to import `/cleaner/`. Do not create both a live 200 page and a redirect for the same URL.

Audit the exported original URL list and the sitemap before finalizing. Export media URLs too and review whether any are receiving Google traffic.
