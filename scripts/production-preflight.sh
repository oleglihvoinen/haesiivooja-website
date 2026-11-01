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
// Guard against reverting to the old, incorrect free-booking business model.
const checkPrices = [
 ['Finnish homepage',homeFi,['12,50','5,50','60','maksutonta']],
 ['English homepage',homeEn,['€12.50','€5.50','€60','free']],
 ['Finnish pricing',html('dist/siivouksen-hinta/index.html'),['12,50','5,50','60']],
 ['English pricing',html('dist/en/cleaning-prices/index.html'),['€12.50','€5.50','€60']],
 ['Finnish cleaners',html('dist/siivoojaksi/index.html'),['5,50','60','maksutonta']],
 ['English cleaners',html('dist/en/for-cleaners/index.html'),['€5.50','€60','free']],
 ['Finnish app payments',html('dist/maksut/index.html'),['12,50','5,50','60']],
 ['English app payments',html('dist/en/payments/index.html'),['€12.50','€5.50','€60']],
 ['Finnish terms',html('dist/terms-of-service/index.html'),['12,50','5,50','60']],
 ['English terms',html('dist/en/terms-of-service/index.html'),['€12.50','€5.50','€60']],
];
for(const [label,content,phrases] of checkPrices){
 for(const value of phrases)if(!content.includes(value))throw Error(label+': missing confirmed price/registration term '+value);
}
const bad=[
 /booking is free for registered customers/i,
 /free customer booking/i,
 /book(?:ing)? without (?:a )?(?:platform )?booking fee/i,
 /asiakkaan varaus on maksuton/i,
 /rekisteröityneen asiakkaan varaus on maksuton/i,
 /varaa maksutta/i,
 /asiakkaan varausmaksu(?::|\s)\s*0\s*€/i
];
const copySources=[
 ['Home.astro',fs.readFileSync('src/components/Home.astro','utf8')],
 ['DetailPage.astro',fs.readFileSync('src/components/DetailPage.astro','utf8')],
 ['GuidePage.astro',fs.readFileSync('src/components/GuidePage.astro','utf8')],
 ['pages.fi',JSON.stringify(fi)],
 ['pages.en',JSON.stringify(en)],
 ['marketing.ts',fs.readFileSync('src/data/marketing.ts','utf8')]
];
for(const [label,content] of copySources){
 for(const pattern of bad)if(pattern.test(content))throw Error(label+': stale free-booking claim: '+pattern);
}
for(const path of ['dist/robots.txt','dist/sitemap-index.xml','dist/sitemap.xml','dist/favicon.ico','dist/brand/mascot.png']){
 if(!fs.existsSync(path))throw Error('Missing search engine discovery file: '+path);
}
if(!html('dist/robots.txt').includes('https://haesiivooja.fi/sitemap.xml'))throw Error('robots.txt has no direct URL sitemap reference');
if(!html('dist/sitemap.xml').includes('<urlset'))throw Error('Direct sitemap has no page loc entries');
if(!homeFi.includes('Etsimme siivoojia')||!homeEn.includes('cleaners'))throw Error('Cleaner recruitment messaging missing from homepage');
console.log('Confirmed pricing, free signup, cleaner recruiting and SEO sitemap regression checks passed.');

console.log('Marketplace: Google Play CTAs, cleaner plans, substantive bilingual pages, FAQ and button contrast checks OK.');
// If the local WordPress image import has run, require genuine image assets and gallery output.
const localGallery='src/data/app-screenshots.local.json';
if(fs.existsSync(localGallery)){
 const shots=JSON.parse(fs.readFileSync(localGallery,'utf8'));
 if(!Array.isArray(shots)||shots.length<1)throw Error('WordPress screenshot manifest is empty');
 for(const s of shots){
   if(!s.src?.startsWith('/app-screenshots/')||!fs.existsSync('dist'+s.src))
     throw Error('Original app screenshot missing from dist: '+s.src);
 }
 if(!homeFi.includes('screenshot-showcase')||!homeEn.includes('screenshot-showcase'))
   throw Error('Original app screenshot gallery missing from Finnish or English homepage');
 console.log('Original WordPress app screenshots included in both homepages: '+shots.length);
}
console.log('Privacy and bilingual app information pages: OK. Verify actual data processing before release.');
JS
