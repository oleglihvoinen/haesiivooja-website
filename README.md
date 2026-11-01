# HaeSiivooja — Finnish Cleaning Marketplace

Bilingual product website for the **HaeSiivooja mobile app (Android and iOS)**, connecting people who need cleaning services with cleaning professionals searching for customers in Finland.

## Main product and conversion

**Primary entry:** [HaeSiivooja Android app on Google Play](https://play.google.com/store/apps/details?id=com.cleanerfinder) — currently in open testing.

**We are looking for cleaners throughout Finland** to join HaeSiivooja and reach more customers.

**Customer journey:** install the Android app, register for free, search cleaners near the cleaning location, agree on the job and register for free and pay a **€12.50 customer service fee when making a booking**. The cleaning job itself is a separate paid service from the chosen professional.

**Development:** Oleg Lihvoinen is the mobile developer (Android and iOS); Viktoriya Lihvoinen designed the UX/UI and website.

**Cleaner journey:** install the Android app, create a professional profile, describe services and the work area, and find prospective customers. Cleaner registration is free. Professional subscriptions cost **€5.50 monthly** or **€60 yearly**; the applicable billing and renewal conditions are shown in the app.

**Optional separate feature:** AI cleaning search on the web. It must remain a secondary link, not the main app download, booking or cleaner-signup CTA.

## Content and SEO

- Distinct Finnish and English localized pages, descriptions and semantic page headings.
- Structured customer/cleaner journeys and substantial service-specific copy.
- Dedicated pricing/subscription area: free registration, €12.50 customer booking service fee, €5.50/month or €60/year for cleaners, and separately priced cleaning work.
- Three linked cleaning guides, useful FAQs, and the two-founder history of Oleg Lihvoinen and Viktoriya Lihvoinen.
- Canonical URLs, reciprocal hreflang, Open Graph metadata, JSON-LD organization/website/app and FAQ markup, robots and XML sitemap.
- Privacy policy at `/privacy/` (English: `/en/privacy/`), terms, cleaner conditions, accessibility and account deletion.
- GitHub Actions validates Astro build, links, translations, privacy pages, primary Google Play CTAs, subscription cards and HTML content.

**Search engine visibility:** technical SEO and useful content support discovery but cannot guarantee Google rankings. Use Search Console to inspect coverage and queries, and keep content accurate as the app changes.

## Local development

Node.js >= 22.22.0.

```bash
npm install
npm run check
npm run predeploy
npm run dev
```

## Apache deployment

See [docs/DEPLOY.md](docs/DEPLOY.md). Build a versioned static release, verify it and atomically switch the `/var/www/haesiivooja-astro/current` symlink only after validation. This repository does not require WordPress or a production Node process.

## Legal accuracy to verify

The Google Play developer listing identifies HaeSiivooja Oy. Keep privacy disclosures consistent with the actual Android SDKs, Google Play Data safety section, location use, financial data, deletion process, storage providers and international transfers. The website privacy policy is not a substitute for a real processing inventory. Confirm that the displayed customer and cleaner fees match the current app checkout, including VAT treatment and subscription renewal terms.

## Restoring original WordPress app screenshots

The original WordPress uploads remain on the VPS unless they were removed separately. The Astro site serves a curated local copy, not WordPress itself. Run `python3 scripts/restore-wordpress-app-images.py --scan` and then `python3 scripts/restore-wordpress-app-images.py --apply` on the VPS before building. The importer copies actual WordPress screenshots into `public/app-screenshots/` and builds a local image manifest at `src/data/app-screenshots.local.json`. Both are kept out of Git so future deployments remain safe. Images appear in the homepage hero and the screenshot gallery after `npm run check` and the usual Apache static release activation. See `docs/RESTORE_APP_IMAGES.md`.
