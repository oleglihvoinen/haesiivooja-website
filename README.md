# Hae Siivooja — Cleaning Marketplace Website

Official Finnish and English marketing website for the **Hae Siivooja** application.

**One marketplace, two audiences**
- **Customers:** find cleaning professionals near the location of the job, compare providers and book in the app. Registration and cleaner booking are **free for customers**. The cleaning service itself is paid separately, at the price agreed with the provider.
- **Cleaning professionals:** present cleaning services, define service areas and find potential customers.

Hae Siivooja is a Finnish digital marketplace, not a company providing all cleaning jobs itself. Site copy describes the app as built by Android developer **Oleg Lihvoinen** and UX/UI designer **Viktoriya Lihvoinen**, who also designed the website.

## Technology
- Astro, static pre-rendered HTML, no runtime database.
- Separate Finnish routes and English routes under `/en/`, with fully English slugs.
- Per-page SEO titles and descriptions, canonical tags, reciprocal hreflang, JSON-LD and XML sitemap.
- Responsive customer/cleaner landing pages and internal service guides.
- App information pages: `/terms-of-service/`, `/privacy/`, `/accessibility-statement/`, `/app-guide/`, `/maksut/`, `/cleaner/`, `/tilin-poisto/`, plus English equivalents.

**Google Play privacy policy:** `https://haesiivooja.fi/privacy/`. The no-slash URL `/privacy` should redirect to this page through Apache's standard DirectorySlash behavior.

## Development

Requires Node.js >= 22.22.0.

```bash
npm install
npm run check
npm run predeploy
npm run dev
```

## Deployment
See [docs/DEPLOY.md](docs/DEPLOY.md) for static Apache deployment.

## Content accuracy checklist
- Confirm the legal identity of the data controller against the actual Google Play developer listing.
- Verify processing of location, account data, app analytics/SDKs, payment data and any international transfers; update policy to match the deployed app and Play Console Data safety declaration.
- Ensure account deletion works in the app or on the web and meets Google Play requirements.
- Verify fees for professionals in the current app conditions. Never present free **customer booking** as free **cleaning work**.
- Confirm that service claims, availability and app features are accurate.
