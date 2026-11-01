import fs from 'node:fs';
import path from 'node:path';

// Website-specific media restored locally from the original WordPress uploads.
// The manifest is deliberately gitignored; no original media is fabricated.
export type AppScreenshot = {src:string; altFi:string; altEn:string};
function loadScreenshots(): AppScreenshot[] {
  const file=path.resolve(process.cwd(),'src/data/app-screenshots.local.json');
  if(!fs.existsSync(file))return [];
  const items=JSON.parse(fs.readFileSync(file,'utf8')) as AppScreenshot[];
  if(!Array.isArray(items))throw new Error('Invalid local app screenshot manifest');
  return items.filter((item)=>typeof item?.src==='string'&&/^\/app-screenshots\/app-screen-\d{2}\.(png|jpg|jpeg|webp)$/i.test(item.src))
              .slice(0,8);
}
export const appScreenshots=loadScreenshots();
