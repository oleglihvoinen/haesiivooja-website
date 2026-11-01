# HaeSiivooja — Finnish Cleaning Marketplace

Bilingual product website for the **HaeSiivooja Android app**, connecting people who need cleaning services with cleaning professionals searching for customers in Finland.

## Main product and conversion

**Primary entry:** [HaeSiivooja Android app on Google Play](https://play.google.com/store/apps/details?id=com.cleanerfinder) — currently in open testing.

**Customer journey:** install the Android app, register for free, search cleaners near the cleaning location, agree on the job and book with **€0 HaeSiivooja customer booking fee**. The actual cleaning job is a paid service from the chosen professional.

**Cleaner journey:** install the Android app, create a professional profile, describe services and the work area, and find prospective customers. Professional subscription options: **monthly or yearly**; the current amounts and renewal conditions must be checked in the app before subscribing. Do not invent or copy historic pricing into marketing content.

**Optional separate feature:** AI cleaning search on the web. It must remain a secondary link, not the main app download, booking or cleaner-signup CTA.

## Content and SEO

- Distinct Finnish and English localized pages, descriptions and semantic page headings.
- Structured customer/cleaner journeys and substantial service-specific copy.
- Dedicated pricing/subscription area and transparent distinction between customer bookings and paid cleaning jobs.
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

The Google Play developer listing identifies HaeSiivooja Oy. Keep privacy disclosures consistent with the actual Android SDKs, Google Play Data safety section, location use, financial data, deletion process, storage providers and international transfers. The website privacy policy is not a substitute for a real processing inventory. Verify professional subscription prices and renewal terms inside the running app.
