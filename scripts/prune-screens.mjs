import fs from 'node:fs';
import path from 'node:path';
const directory=path.resolve('dist/app-screenshots');
if(fs.existsSync(directory)){
 for(const name of fs.readdirSync(directory)){
  if(name.startsWith('app-screen-04.')||name.startsWith('app-screen-05.')){
    fs.rmSync(path.join(directory,name),{force:true});
    console.log('Omitted unwanted screenshot:',name);
  }
 }
}
