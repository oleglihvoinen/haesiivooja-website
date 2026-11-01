import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const dir=path.dirname(fileURLToPath(import.meta.url));
const read=(name)=>JSON.parse(fs.readFileSync(path.join(dir,'../src/data',name),'utf8'));
const [fi,en,fiGuides,enGuides]=['pages.json','pages.en.json','guides.json','guides.en.json'].map(read);
const errors=[];
if(fi.length!==en.length)errors.push(`Page counts differ: fi=${fi.length} en=${en.length}`);
if(fiGuides.length!==enGuides.length)errors.push(`Guide counts differ: fi=${fiGuides.length} en=${enGuides.length}`);
const both=[...fi.map(x=>'/'+x.slug+'/'),...en.map(x=>'/en/'+x.slug+'/'),...fiGuides.map(x=>'/oppaat/'+x.slug+'/'),...enGuides.map(x=>'/en/guides/'+x.slug+'/')];
if(new Set(both).size!==both.length)errors.push('Duplicate content routes');
for(const [label,pages] of [['fi pages',fi],['en pages',en],['fi guides',fiGuides],['en guides',enGuides]]) {
 for(const [i,p] of pages.entries()) {
  if(!p.slug||!p.title||!p.description||!(p.h1))errors.push(`${label}[${i}]: missing slug/title/description/H1`);
  if(label.includes('pages')&&(!p.sections?.length||!p.intro))errors.push(`${label}[${i}]: missing translated page body`);
  if(label.includes('guides')&&(!p.sections?.length||!p.lead))errors.push(`${label}[${i}]: missing translated guide body`);
  if(!/^[a-z0-9-]+$/.test(p.slug||''))errors.push(`${label}[${i}]: invalid slug ${p.slug}`);
 }
}
if(errors.length){errors.forEach(x=>console.error('FAIL: '+x));process.exitCode=1;}
else console.log(`Validated ${fi.length+fiGuides.length} Finnish + ${en.length+enGuides.length} English pages (plus homepages), all localized URLs unique.`);
