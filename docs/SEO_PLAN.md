# HaeSiivooja.fi — SEO audit and launch plan (1 November 2026)

## Verified observations

- Public homepage contains demo copy ("Lorem ipsum"), a generic "John Doe / Sony CEO" testimonial, and unrelated conferencing-app sections. These should not be migrated.
- Homepage mixes Finnish content with English headings and contains repeated blocks. Hero does not lead with a clear high-intent Finnish service query.
- The marketing site links to an independent AI search subdomain at `app.haesiivooja.fi`; do not accidentally reverse-proxy or overwrite that app.
- Google Play lists HaeSiivooja as a cleaning-services discovery/booking app published by HaeSiivooja Oy.
- `site:haesiivooja.fi` searches did not surface the site's pages in the checked search results. This is **not proof** of zero Google indexing; Google Search Console is the authority.
- Direct automated fetches for `robots.txt`, WordPress REST API and XML sitemap could not be independently verified; **do not** assert their absence or that the site has a particular noindex directive.

## Immediate diagnosis on existing WordPress

1. In Google Search Console -> Page indexing, inspect `https://haesiivooja.fi/`; check exact status and "Indexing allowed?".
2. From a machine that can access the site: `curl -sSI https://haesiivooja.fi/` for HTTP status, redirects and `X-Robots-Tag`; `curl -sL https://haesiivooja.fi/ | grep -Ei 'robots|canonical'` for HTML; `curl -sL https://haesiivooja.fi/robots.txt` and `.../wp-sitemap.xml`.
3. On WordPress host: `wp option get blog_public`. `0` commonly indicates "Discourage search engines from indexing this site". If `0`, review site policy and switch appropriately only after identifying any intentional private pages.
4. Check DNS, https hostname canonical, Cloudflare/WAF/bot blocking, actual Googlebot 403/5xx in logs, sitemap status, plugin redirects and duplicate homepages.
5. Fix a confirmed blocking directive immediately on WordPress if you don't want to wait for the migration. Request indexing of the homepage and 2–3 important URLs after the fix.

## Keyword and page plan

These are **search-intent hypotheses**, not verified volume/ranking statistics.

| User intent | Target page | Primary language terms |
|---|---|---|
| Find a cleaner | `/etsi-siivooja/` | etsi siivooja, siivooja lähellä, varaa siivooja |
| Explore offerings | `/siivouspalvelut/` | siivouspalvelut, siivouspalvelu |
| Routine home cleaning | `/kotisiivous/` | kotisiivous, kotisiivouspalvelu |
| Moving | `/muuttosiivous/` | muuttosiivous, muuttosiivouspalvelu |
| Deep cleaning | `/perussiivous/` | perussiivous |
| Window work | `/ikkunanpesu/` | ikkunanpesu |
| Office cleaning | `/toimistosiivous/` | toimistosiivous |
| Compare cost | `/siivouksen-hinta/` | siivouksen hinta, kotisiivous hinta |
| Join as provider | `/siivoojaksi/` | siivoojaksi, siivoustöitä, siivousalan ammattilainen |
| How to use marketplace | `/miten-se-toimii/` | miten varaan siivoojan |
| Help choosing | `/oppaat/` | siivousopas, muuttosiivouksen tarkistuslista |

Do NOT auto-generate 100 near-identical city pages. Add an indexable location page only once real coverage, matching provider listings, original area-specific details, and meaningful availability are established. If the marketplace can expose a publicly crawlable provider directory without private user information, it could create defensible long-tail content later; do not fake listings or reviews.

## Technical requirements

- One canonical host: `https://haesiivooja.fi` with 301 from `www` and HTTP.
- Never leave `noindex` on **production**. Keep it on *staging only* (password-protect staging).
- 200 response for indexable page, 404 for missing resources, 301 only for valid old-to-new mapping.
- SSR is not needed: every marketing page HTML is generated at build time and is crawlable without JS.
- Unique titles, descriptions, one clear H1, descriptive anchor text, internally linked relevant service guides.
- Website/Organization/Breadcrumb JSON-LD without fabricated ratings, prices, offers, or LocalBusiness claims. HaeSiivooja is a marketplace, not necessarily a company providing local cleaning work directly.
- Accurate alternative text on real informative images. Optimize visual size and Core Web Vitals after assets are imported.
- Canonical, `robots.txt`, `sitemap-index.xml`, schema validation, mobile usability, accessible links, fast image delivery.
- Preserve original important WordPress URLs where appropriate; 301 redirects for moved equivalents. Avoid 301'ing unrelated pages to homepage.
- Never publish fake testimonials, fake service results, or outdated pricing.

## Off-site and continued SEO

- Verify the domain property in Google Search Console via DNS TXT, submit sitemap and request inspection of key pages (manual account step).
- Verify matching company identity in Google Play, Finnish business registry (PRH/YTJ), and real company social profiles. Maintain consistent name/website contact details.
- Earn legitimate relevant links: app publisher page, company profiles and local business ecosystem publications, partnerships with real participating cleaners, helpful original reports on cleaning search behavior. No link buying or mass directory spam.
- After Search Console collects data, prioritize pages with impressions but low CTR and create content to address actual queries rather than guessing search volume.
- Track weekly: count of indexed high-value URLs, Search Console impressions/clicks/CTR, branded vs nonbranded queries, signups/clickouts to `app.haesiivooja.fi`, technical errors and Core Web Vitals. Baseline should be captured before changes.
- Organic search results often take weeks/months; guaranteed #1 claims would be unfounded.

## Google sources

- Google Search Console Page indexing: https://support.google.com/webmasters/answer/7440203?hl=en
- URL Inspection: https://support.google.com/webmasters/answer/12482179?hl=en
- Google SEO Starter Guide: https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- Asking for recrawl: https://developers.google.com/search/docs/crawling-indexing/ask-google-to-recrawl
