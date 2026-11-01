import fs from 'node:fs';
import path from 'node:path';
const dist=path.resolve('dist');
if(!fs.existsSync(dist))throw new Error('Run npm run build first.');
const files=[];
function walk(folder){for(const ent of fs.readdirSync(folder,{withFileTypes:true})){const p=path.join(folder,ent.name);if(ent.isDirectory())walk(p);else if(p.endsWith('.html'))files.push(p);}}
walk(dist);
const pagesFi=JSON.parse(fs.readFileSync('src/data/pages.json'));
const pagesEn=JSON.parse(fs.readFileSync('src/data/pages.en.json'));
const guidesFi=JSON.parse(fs.readFileSync('src/data/guides.json'));
const guidesEn=JSON.parse(fs.readFileSync('src/data/guides.en.json'));
const pairs=[['/','/en/'],...pagesFi.map((p,i)=>[`/${p.slug}/`,`/en/${pagesEn[i].slug}/`]),...guidesFi.map((g,i)=>[`/oppaat/${g.slug}/`,`/en/guides/${guidesEn[i].slug}/`])];
const issues=[];const canonical=new Set();const titles=new Map();
const base='https://haesiivooja.fi';
const fileFor=(slug)=>path.join(dist,slug,'index.html');
for(const [fi,en] of pairs){
 const left=fileFor(fi),right=fileFor(en);
 for(const f of [left,right])if(!fs.existsSync(f))issues.push(`Missing translation ${f}`);
 if(!fs.existsSync(left)||!fs.existsSync(right))continue;
 for(const [f,lang] of [[left,'fi'],[right,'en']]) {
  const html=fs.readFileSync(f,'utf8');
  for(const [href,code] of [[base+fi,'fi'],[base+en,'en'],[base+fi,'x-default']]){
   const re=new RegExp(`<link\\s+rel="alternate"\\s+hreflang="${code}"\\s+href="${href.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')}"\\s*\\/?`);
   if(!re.test(html))issues.push(`${f}: missing hreflang ${code} ${href}`);
  }
  if(!new RegExp(`<html\\s+lang="${lang}"`).test(html))issues.push(`${f}: expected HTML lang=${lang}`);
 }
}
for(const file of files){
 const html=fs.readFileSync(file,'utf8');
 const title=html.match(/<title>([^<]*)<\/title>/i)?.[1];
 const can=html.match(/<link rel="canonical" href="([^"]+)"/i)?.[1];
 const desc=html.match(/<meta name="description" content="([^"]+)"/i)?.[1];
 const h1=(html.match(/<h1\b/gi)||[]).length;
 if(!title||!can||!desc||h1!==1)issues.push(`${file}: title/canonical/description missing or H1 count ${h1}`);
 if(can&&canonical.has(can))issues.push(`${file}: duplicate canonical ${can}`);
 if(can)canonical.add(can);
 if(title){if(titles.has(title))issues.push(`${file}: duplicate title, see ${titles.get(title)}`);titles.set(title,file);}
 for(const [,href] of html.matchAll(/href="(\/[^"?#]*)"/g)){
  if(href.startsWith('/_astro/')||/\.(svg|png|jpg|jpeg|webp|css|js|xml|txt|ico)$/i.test(href))continue;
  if(!fs.existsSync(fileFor(href)))issues.push(`${file}: broken internal link ${href}`);
 }
 if(/noindex/i.test(html))issues.push(`${file}: contains noindex`);
 if(/lorem ipsum|john doe/i.test(html))issues.push(`${file}: contains placeholder text`);
}
for(const r of ['robots.txt','sitemap-index.xml'])if(!fs.existsSync(path.join(dist,r)))issues.push(`Missing ${r}`);
const xmlFiles=fs.existsSync(dist)?fs.readdirSync(dist).filter(x=>/^sitemap.*\.xml$/.test(x)):[];
const xml=xmlFiles.map(x=>fs.readFileSync(path.join(dist,x),'utf8')).join(' ');
for(const [fi,en] of pairs){for(const slug of [fi,en])if(!xml.includes(base+slug))issues.push(`Sitemap missing ${slug}`);}
if(files.length<34)issues.push(`Expected at least 34 localized HTML files; got ${files.length}`);
console.log(`Checked ${files.length} generated HTML files, ${pairs.length} translation pairs, sitemaps`);
if(issues.length){issues.forEach(x=>console.error('FAIL: '+x));process.exitCode=1;}else console.log('Technical SEO and multilingual checks passed.');
