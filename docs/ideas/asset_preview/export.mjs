// Run from the repository: node docs/ideas/asset_preview/export.mjs
// Requires Node.js, Playwright and Chromium; never changes application code.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';
import http from 'node:http';
import { execFileSync } from 'node:child_process';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../..');
const artifacts = process.env.ARTIFACT_DIR || path.resolve(repo, '../artifacts/brickbound-training-orc');
fs.mkdirSync(artifacts, {recursive:true});
const server = http.createServer((req, res) => {
  const rel = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  const target = path.resolve(repo, '.' + rel);
  if (!target.startsWith(repo + path.sep)) { res.writeHead(403).end(); return; }
  try {
    const mime = { '.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.png':'image/png','.json':'application/json' }[path.extname(target)] || 'application/octet-stream';
    const body = fs.readFileSync(target);
    res.writeHead(200, {'Content-Type': mime}); res.end(body);
  } catch { res.writeHead(404).end(); }
});
await new Promise(resolve => server.listen(0,'127.0.0.1',resolve));
const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || '/usr/bin/chromium', headless: true, args: ['--no-sandbox'] });
try {
  const page = await browser.newPage();
  await page.goto('http://127.0.0.1:'+server.address().port+'/docs/ideas/asset_preview/index.html?export=1');
  await page.evaluate(() => TileRenderer.ready);
  const config = await page.evaluate(() => TILE_PACK);
  const {cell, columns, defaultFrames: count} = config.export;
  const rows = Math.ceil(count / columns);
  const manifest = { ...config, assetRoot: 'res://', atlases: [], expressions: config.expressions.map((name,i)=>({name, x:i%3*128, y:Math.floor(i/3)*128, width:128, height:128})), origin: { x: cell/2, y:cell/2 }, fxAtlas: {file:'assets/fx/tile_reactions/effects.png',cell:128,columns:4,rows:2}, frameFormat: 'RGBA PNG; transparent; row-major; no external padding', playback: 'Non-looping clips hold their final frame. Restart at frame 0 on a new event. Terminal events override taunts. Baked FX included.' };
  for(const [family, info] of Object.entries(config.families)) {
    const folder = path.join(repo,'assets/tiles',family,'animations');fs.mkdirSync(folder,{recursive:true});
    for(const color of config.colors) {
      for(const animation of info.animations) {
        const data = await page.evaluate(({family,color,animation,count,columns,cell,rows})=>{
          const canvas=document.createElement('canvas');canvas.width=columns*cell;canvas.height=rows*cell;
          const ctx=canvas.getContext('2d');
          for(let i=0;i<count;i++){ctx.save();ctx.translate(i%columns*cell,Math.floor(i/columns)*cell);TileRenderer.draw(ctx,{family,color,animation,t:i/(count-1),size:cell});ctx.restore()}
          return canvas.toDataURL('image/png').split(',')[1];
        },{family,color,animation,count,columns,cell,rows});
        const file='assets/tiles/'+family+'/animations/'+color+'_'+animation+'.png';
        fs.writeFileSync(path.join(repo,file),Buffer.from(data,'base64'));
        // Lossless PNG recompression; no palette or pixel changes.
        execFileSync('magick', [path.join(repo,file), '-define', 'png:compression-level=9', '-define', 'png:compression-filter=5', path.join(repo,file)]);
        const spec=config.animations[animation];
        manifest.atlases.push({family,color,animation,file,width:columns*cell,height:rows*cell,cell,columns,frames:count,fps:count/spec.seconds,seconds:spec.seconds,loop:!!spec.loop});
      }
      // Native Godot resources: drag onto AnimatedSprite2D.sprite_frames.
      const names=info.animations;
      let text='[gd_resource type="SpriteFrames" load_steps='+ (1+names.length+names.length*count)+' format=3]\n\n';
      names.forEach((name,i)=>{text+='[ext_resource type="Texture2D" path="res://assets/tiles/'+family+'/animations/'+color+'_'+name+'.png" id="'+(i+1)+'"]\n'});
      text+='\n';
      names.forEach((name,i)=>{for(let n=0;n<count;n++)text+='[sub_resource type="AtlasTexture" id="Atlas_'+i+'_'+n+'"]\natlas = ExtResource("'+(i+1)+'")\nregion = Rect2('+n%columns*cell+', '+Math.floor(n/columns)*cell+', '+cell+', '+cell+')\n\n'});
      text+='[resource]\nanimations = [\n'+names.map((name,i)=>'{\n"frames": ['+Array.from({length:count},(_,n)=>'{"duration": 1.0, "texture": SubResource("Atlas_'+i+'_'+n+'")}').join(',\n')+'],\n"loop": '+!!config.animations[name].loop+',\n"name": &"'+name+'",\n"speed": '+(count/config.animations[name].seconds)+'\n}').join(',\n')+'\n]\n';
      fs.writeFileSync(path.join(repo,'assets/tiles',family,'sprite_frames_'+color+'.tres'),text);
    }
  }
  fs.writeFileSync(path.join(repo,'assets/tiles/animation_pack.json'),JSON.stringify(manifest,null,2)+'\n');
  // Portable HTML embeds every PNG and resource used by the viewer.
  const embedded={};
  const include=(rel,mime)=>embedded[rel]='data:'+mime+';base64,'+fs.readFileSync(path.join(repo,rel)).toString('base64');
  for(const [family,info] of Object.entries(config.families))for(const color of config.colors){
    include('assets/tiles/'+family+'/tile_'+color+'.png','image/png');
    include('assets/tiles/'+family+'/sprite_frames_'+color+'.tres','text/plain');
    for(const name of info.animations)include('assets/tiles/'+family+'/animations/'+color+'_'+name+'.png','image/png');
  }
  for(const color of config.colors){include('assets/tiles/orc_shield/expressions_'+color+'.png','image/png');for(const name of config.expressions)include('assets/tiles/orc_shield/expressions/'+color+'_'+name+'.png','image/png')}
  for(const name of ['effects','dust_small','dust_large','impact_small','impact_large','splinters_small','splinters_large','confetti_small','confetti_large'])include('assets/fx/tile_reactions/'+name+'.png','image/png');
  include('assets/tiles/animation_pack.json','application/json');
  include('docs/ideas/animation_pack.md','text/plain');
  let html=fs.readFileSync(path.join(here,'index.html'),'utf8');
  const scripts=['data.js','renderer.js','app.js'];
  html=html.replace('<script src="data.js"></script>','<script>window.TILE_EMBEDDED='+JSON.stringify(embedded)+';<'+ '/script><script src="data.js"></script>');
  for(const file of scripts)html=html.replace('<script src="'+file+'"></script>','<script>\n'+fs.readFileSync(path.join(here,file),'utf8').replaceAll('</script','<\\/script')+'\n<'+ '/script>');
  for(const [rel,data] of Object.entries(embedded))html=html.replaceAll('href="../../../'+rel+'"','href="'+data+'"');
  html=html.replace('href="../animation_pack.md"','href="'+embedded['docs/ideas/animation_pack.md']+'" download="animation_pack.md"');
  html=html.replace('id="bundle-download" hidden','id="bundle-download"');
  html=html.replace('href="../../../assets/brickbound_training_orc.zip"','href="brickbound_training_orc.zip"');
  fs.writeFileSync(path.join(artifacts,'preview_training_orc.html'),html);
  console.log('Portable HTML: '+path.join(artifacts,'preview_training_orc.html'));
  console.log('Exported '+manifest.atlases.length+' animation atlases, 8 SpriteFrames resources, manifest and portable HTML.');
} finally { await browser.close(); await new Promise(resolve=>server.close(resolve)); }
