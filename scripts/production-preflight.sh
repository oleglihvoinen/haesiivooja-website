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
const html = file => fs.readFileSync(file,'utf8');
const homeFi=html('dist/index.html'), homeEn=html('dist/en/index.html');
const play='play.google.com/store/apps/details?id=com.cleanerfinder';
for(const [label,page] of [['fi',homeFi],['en',homeEn]]){
 if(!page.includes(play))throw Error(label+': missing primary Google Play app link');
 if(!page.includes('app.haesiivooja.fi'))throw Error(label+': optional AI feature link missing');
 if(!/month|monthly|Kuukausitilaus|Kuukausittain/i.test(page)||!/year|yearly|Vuositilaus|Vuosittain/i.test(page))throw Error(label+': cleaner monthly/yearly pricing boxes missing');
 if((page.match(/<details/g)||[]).length<5)throw Error(label+': homepage FAQ too sparse');
}
for(const [label,slugs] of [['fi',['kotisiivous','muuttosiivous','perussiivous','ikkunanpesu','toimistosiivous','oppaat','tietoa-meista']],['en',['home-cleaning','move-out-cleaning','deep-cleaning','window-cleaning','office-cleaning','guides','about-us']]]){
 for(const slug of slugs){
  const p=(label==='fi'?fi:en).find(x=>x.slug===slug);
  if(!p || p.sections.length<3)throw Error(label+': thin or missing page '+slug);
  const page=html('dist/'+(label==='en'?'en/':'')+slug+'/index.html');
  if(!page.includes(play))throw Error(label+': page '+slug+' does not link to Android app');
 }
}
for(const slug of ['privacy','terms-of-service','accessibility-statement']){
 if(!html('dist/'+slug+'/index.html').includes('info@haesiivooja.fi'))throw Error('Contact details missing from policy '+slug);
}
const css=fs.readFileSync('src/styles/global.css','utf8');
if(!css.includes('.card a.button'))throw Error('Card button contrast regression');
console.log('Marketplace: Google Play CTAs, cleaner plans, substantive bilingual pages, FAQ and button contrast checks OK.');
console.log('Privacy and bilingual app information pages: OK. Verify actual data processing before release.');
JS
