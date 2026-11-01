import fs from 'node:fs';
import path from 'node:path';

// Astro creates sitemap-index.xml -> sitemap-0.xml.
// Also publish /sitemap.xml with the page URLs directly.
const dist=path.resolve('dist');
const children=fs.readdirSync(dist).filter(n=>n.startsWith('sitemap-') && n.endsWith('.xml') && n!=='sitemap-index.xml').sort();
if(!children.length)throw new Error('Astro did not generate sitemap URL files');
const entries=[],locations=new Set();
for(const filename of children){
 const data=fs.readFileSync(path.join(dist,filename),'utf8');
 const nodes=data.split('<url>').slice(1).map(chunk=>chunk.split('</url>')[0]);
 if(!nodes.length)throw new Error(filename+' has no <url> entries');
 for(const body of nodes){
  const loc=body.split('<loc>')[1]?.split('</loc>')[0];
  if(!loc||!loc.startsWith('https://haesiivooja.fi/'))throw new Error('Invalid URL in '+filename);
  if(locations.has(loc))throw new Error('Duplicate sitemap URL '+loc);
  locations.add(loc);
  entries.push('<url>'+body+'</url>');
 }
}
if(!locations.has('https://haesiivooja.fi/')||!locations.has('https://haesiivooja.fi/en/'))
 throw new Error('Sitemap missing locale homepages');
const xml='<?xml version="1.0" encoding="UTF-8"?>\n'
 +'<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
 +entries.join('\n')+'\n</urlset>\n';
fs.writeFileSync(path.join(dist,'sitemap.xml'),xml);
console.log('Published sitemap.xml with '+entries.length+' direct page URLs.');
