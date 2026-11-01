import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://haesiivooja.fi',
  trailingSlash: 'always',
  output: 'static',
  integrations: [sitemap()],
});
