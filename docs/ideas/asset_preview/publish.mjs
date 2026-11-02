// Build a GitHub Pages-ready directory. Publishing the branch is a separate step.
// node docs/ideas/asset_preview/publish.mjs
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const artifacts=process.env.ARTIFACT_DIR||path.resolve(repo,'../artifacts/brickbound-training-orc');
const output=path.join(artifacts,'site');
if(fs.existsSync(output))throw new Error('Output already exists; preserve or remove the previous generated site before rebuilding: '+output);
fs.mkdirSync(output,{recursive:true});
function copy(relative){
  const source=path.join(repo,relative),dest=path.join(output,relative);
  fs.mkdirSync(path.dirname(dest),{recursive:true});
  fs.cpSync(source,dest,{recursive:true,filter:file=>!file.endsWith('.import')});
}
for(const relative of ['assets/tiles/training','assets/tiles/orc_shield','assets/tiles/animation_pack.json','assets/fx/tile_reactions','docs/ideas/asset_preview','docs/ideas/animation_pack.md'])copy(relative);
const zip=path.join(artifacts,'brickbound_training_orc.zip');
if(!fs.existsSync(zip))throw new Error('Missing asset ZIP: '+zip);
fs.mkdirSync(path.join(output,'downloads'),{recursive:true});
fs.copyFileSync(zip,path.join(output,'downloads/brickbound_training_orc.zip'));
let html=fs.readFileSync(path.join(output,'docs/ideas/asset_preview/index.html'),'utf8');
html=html.replace('id="bundle-download" hidden','id="bundle-download"').replace('href="../../../assets/brickbound_training_orc.zip"','href="../../../downloads/brickbound_training_orc.zip"');
fs.writeFileSync(path.join(output,'docs/ideas/asset_preview/index.html'),html);
fs.writeFileSync(path.join(output,'.nojekyll'),'');
fs.writeFileSync(path.join(output,'index.html'),'<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="0;url=./docs/ideas/asset_preview/"><title>Brickbound Hero · Asset viewer</title></head><body><a href="./docs/ideas/asset_preview/">Mở Training & Orc · Sprite và animation</a></body></html>\n');
fs.writeFileSync(path.join(output,'README.md'),'# Brickbound Hero asset viewer\n\nPublished from art/tiles. GitHub Pages source: gh-pages, /(root).\n\nOpen index.html or docs/ideas/asset_preview/. The viewer loads individual PNGs and does not preload the large offline HTML or ZIP.\n');
console.log('GitHub Pages site: '+output);
