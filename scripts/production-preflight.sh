#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
node --input-type=module <<'JS'
import fs from 'node:fs';
const pages=JSON.parse(fs.readFileSync('src/data/legacy-pages.json','utf-8'));
const required=['terms-of-service','privacy-policy','accessibility-statement'];
const missing=required.filter(slug=>!pages.some(page=>page.slug===slug&&typeof page.content==='string'&&page.content.replace(/<[^>]+>/g,'').trim().length>=80));
if(missing.length) {console.error('BLOCKED: WordPress legal page imports missing: '+missing.join(', '));process.exitCode=1;}
else console.log('Legal content check OK; manually review all imported pages, styles, links and any old URLs before production.');
JS
