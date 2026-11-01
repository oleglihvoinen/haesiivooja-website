#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
node --input-type=module <<'JS'
import fs from 'node:fs';
const fi=JSON.parse(fs.readFileSync('src/data/pages.json','utf8'));
const en=JSON.parse(fs.readFileSync('src/data/pages.en.json','utf8'));
const requiredFi=['privacy','terms-of-service','accessibility-statement','app-guide','maksut','cleaner','tilin-poisto'];
const requiredEn=['privacy','terms-of-service','accessibility-statement','app-guide','payments','cleaner-terms','delete-account'];
for(const [name,items,slugs] of [['fi',fi,requiredFi],['en',en,requiredEn]]){
 for(const slug of slugs){
  const p=items.find(x=>x.slug===slug);
  if(!p || !p.title || !p.sections?.length)throw Error('Missing app information page: '+name+'/'+slug);
  const filename='dist/'+(name==='en'?'en/':'')+slug+'/index.html';
  if(!fs.existsSync(filename))throw Error('Missing built page: '+filename);
 }
}
const privacy=fs.readFileSync('dist/privacy/index.html','utf8');
if(!privacy.includes('info@haesiivooja.fi')||!privacy.includes('tietosuojakäytäntö'))throw Error('Privacy policy missing content/contact');
if(!fs.readFileSync('dist/index.html','utf8').includes('varaus'))throw Error('Customer booking message missing from homepage');
console.log('App information, privacy policy, free booking and bilingual pages: OK. Verify actual data processing before release.');
JS
