// Issue #3 visual QA: run after export.mjs. No gameplay files are changed.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import http from 'node:http';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
const require=createRequire(import.meta.url),{chromium}=require('playwright');
const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const output=path.join(repo,'docs/ideas/issue3_review');fs.mkdirSync(output,{recursive:true});
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'brick-issue3-'));
const pack=JSON.parse(fs.readFileSync(path.join(repo,'assets/tiles/animation_pack.json'),'utf8'));
const prior=JSON.parse(execFileSync('git',['show','3e8821d:assets/tiles/animation_pack.json'],{cwd:repo,encoding:'utf8'}));
assert.deepEqual(pack.atlases,prior.atlases,'Atlas fields/values, filenames, fps, loop and layout must stay compatible');
assert.deepEqual(pack.families,prior.families);assert.deepEqual(pack.eventMap,prior.eventMap);
const server=http.createServer((req,res)=>{
  try{const file=path.resolve(repo,'.'+new URL(req.url,'http://localhost').pathname);if(!file.startsWith(repo+path.sep)){res.writeHead(403).end();return}const body=fs.readFileSync(file);const mime={'.html':'text/html','.js':'text/javascript','.png':'image/png'}[path.extname(file)]||'text/plain';res.writeHead(200,{'Content-Type':mime});res.end(body)}catch{res.writeHead(404).end()}
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
let checks=3;
try{
 const page=await browser.newPage();
 await page.goto('http://127.0.0.1:'+server.address().port+'/docs/ideas/asset_preview/index.html?export=1');
 await page.evaluate(()=>TileRenderer.ready);
 const metrics=await page.evaluate(async({colors})=>{
  const load=async file=>{const im=new Image();im.src=TileRenderer.urlFor(file);await im.decode();return im};
  const canvas=(w=128,h=128)=>{const c=document.createElement('canvas');c.width=w;c.height=h;return c};
  const bounds=data=>{let x0=999,y0=999,x1=-1,y1=-1;for(let y=0;y<data.height;y++)for(let x=0;x<data.width;x++)if(data.data[(y*data.width+x)*4+3]){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y)}return{x:x0,y:y0,width:x1-x0+1,height:y1-y0+1}};
  function isColor(r,g,b,color){r/=255;g/=255;b/=255;const max=Math.max(r,g,b),min=Math.min(r,g,b),d=max-min,s=max?d/max:0;let h=0;if(d){if(max===r)h=60*((g-b)/d%6);else if(max===g)h=60*((b-r)/d+2);else h=60*((r-g)/d+4);if(h<0)h+=360}if(s<.4||max<.22)return false;return color==='red'?(h<22||h>=340):color==='green'?(h>=85&&h<=165):color==='yellow'?(h>=32&&h<=65):(h>=260&&h<=320)}
  const result={staticTiles:[],orcCoverage:[],firstFrames:[],specials:[]};
  for(const family of ['training','orc_shield'])for(const color of colors){
   const im=await load('assets/tiles/'+family+'/tile_'+color+'.png'),cv=canvas(),ctx=cv.getContext('2d');ctx.drawImage(im,0,0);const staticData=ctx.getImageData(0,0,128,128);
   result.staticTiles.push({family,color,canvas:[im.naturalWidth,im.naturalHeight],bounds:bounds(staticData)});
   if(family==='orc_shield')for(const size of [46,100,128]){
    const c=canvas(size,size),cx=c.getContext('2d');cx.drawImage(im,0,0,size,size);const p=cx.getImageData(0,0,size,size).data;let area=0,ring=0;
    for(let y=0;y<size;y++)for(let x=0;x<size;x++){const i=(y*size+x)*4;if(isColor(p[i],p[i+1],p[i+2],color)){const weight=p[i+3]/255;area+=weight;if(x<size*.24||x>=size*.76||y<size*.24||y>=size*.76)ring+=weight}}
    result.orcCoverage.push({color,size,coloredFraction:area/(size*size),outerBandColoredFraction:ring/(size*size)});
   }
   for(const animation of ['idle','land']){
    const atlas=await load('assets/tiles/'+family+'/animations/'+color+'_'+animation+'.png');const c=canvas(192,192),cx=c.getContext('2d');cx.drawImage(atlas,0,0,192,192,0,0,192,192);const inside=cx.getImageData(32,32,128,128);let differing=0,maxDelta=0;for(let i=0;i<inside.data.length;i++){const delta=Math.abs(inside.data[i]-staticData.data[i]);if(delta)differing++;maxDelta=Math.max(maxDelta,delta)}result.firstFrames.push({family,color,animation,bounds:bounds(cx.getImageData(0,0,192,192)),differingChannels:differing,maxChannelDelta:maxDelta});
   }
  }
  for(const name of ['lightning','bomb','rainbow']){const im=await load('assets/tiles/special_'+name+'.png'),c=canvas(),ctx=c.getContext('2d');ctx.drawImage(im,0,0);const data=ctx.getImageData(0,0,128,128);let empty=0;for(let i=3;i<data.data.length;i+=4)if(!data.data[i])empty++;result.specials.push({name,canvas:[im.width,im.height],bounds:bounds(data),transparentFraction:empty/16384,centerAlpha:data.data[(64*128+64)*4+3]})}
  return result;
 },{colors:pack.colors});
 for(const tile of metrics.staticTiles){assert.deepEqual(tile.canvas,[128,128]);assert.deepEqual(tile.bounds,{x:4,y:4,width:120,height:120},tile.family+'/'+tile.color);checks+=2}
 for(const c of metrics.orcCoverage){assert.ok(c.coloredFraction>=.4,c.color+' '+c.size+'px has only '+(c.coloredFraction*100).toFixed(1)+'% gameplay color');assert.ok(c.outerBandColoredFraction>=.20,'Gameplay color must remain on perimeter');checks+=2}
 for(const f of metrics.firstFrames){assert.deepEqual(f.bounds,{x:36,y:36,width:120,height:120},f.family+'/'+f.color+'/'+f.animation);assert.ok(f.maxChannelDelta<=1,'Static/first frame differ: '+JSON.stringify(f));checks+=2}
 for(const s of metrics.specials){assert.deepEqual(s.canvas,[128,128]);assert.ok(s.transparentFraction>.1);if(s.name!=='rainbow')assert.ok(s.transparentFraction>.25,'Overlays must leave the tile visible');assert.ok(s.bounds.width<=120&&s.bounds.height<=120);checks+=4}
 // Generate review images at their actual pixel size, not scaled-up mockups.
 const magick=args=>execFileSync('magick',args);
 for(const family of ['training','orc_shield'])for(const size of [46,100])for(const gray of [false,true]){
  const files=[];for(const color of pack.colors){const file=path.join(tmp,family+'_'+color+'_'+size+'_'+gray+'.png');const args=[path.join(repo,'assets/tiles',family,'tile_'+color+'.png'),'-resize',size+'x'+size];if(gray)args.push('-colorspace','Gray');args.push('-strip',file);magick(args);files.push(file)}
  magick(['montage',...files,'-tile','4x1','-geometry',size+'x'+size+'+6+6','-background','#ddd8ce','-strip',path.join(output,family+'_'+size+'_'+(gray?'gray':'color')+'.png')]);
 }
 for(const gray of [false,true]){
  const files=[];for(const special of ['lightning','bomb'])for(const family of ['training','orc_shield'])for(const color of pack.colors){
   const file=path.join(tmp,special+'_'+family+'_'+color+'_'+gray+'.png');const args=[path.join(repo,'assets/tiles',family,'tile_'+color+'.png'),path.join(repo,'assets/tiles','special_'+special+'.png'),'-compose','Over','-composite','-resize','100x100'];if(gray)args.push('-colorspace','Gray');args.push('-strip',file);magick(args);files.push(file);
  }
  magick(['montage',...files,'-tile','4x4','-geometry','100x100+6+6','-background','#ddd8ce','-strip',path.join(output,'specials_100_'+(gray?'gray':'color')+'.png')]);
 }
 for(const size of [46,100])for(const gray of [false,true]){
  const files=[];for(const special of ['lightning','bomb','rainbow']){const file=path.join(tmp,'standalone_'+special+'_'+size+'_'+gray+'.png');const args=[path.join(repo,'assets/tiles','special_'+special+'.png'),'-resize',size+'x'+size];if(gray)args.push('-colorspace','Gray');args.push('-strip',file);magick(args);files.push(file)}
  magick(['montage',...files,'-tile','3x1','-geometry',size+'x'+size+'+6+6','-background','#ddd8ce','-strip',path.join(output,'specials_standalone_'+size+'_'+(gray?'gray':'color')+'.png')]);
 }
 const result={issue:3,checks,manifestCompatibility:'All 76 atlas records unchanged, including required fields and values; same families and event map.',normalization:'All eight family tiles visible bounds exactly 120×120 at (4,4); first idle/land bounds exactly match static placement.',colorMetric:'HSV hue-range mask, saturation >= 0.4 and value >= 0.22; alpha-weighted area / full canvas area. This measures color coverage, not human recognition speed.',visualReview:'Contact sheets are provided for human inspection at 46px, 100px and grayscale; no claim of a user study.',...metrics};
 fs.writeFileSync(path.join(output,'metrics.json'),JSON.stringify(result,null,2)+'\n');
 const sections=[['Orc · 46 px','orc_shield_46_color.png','orc_shield_46_gray.png'],['Orc · 100 px','orc_shield_100_color.png','orc_shield_100_gray.png'],['Training · 46 px','training_46_color.png','training_46_gray.png'],['Training · 100 px','training_100_color.png','training_100_gray.png'],['Sét, bom, cầu vồng · 46 px','specials_standalone_46_color.png','specials_standalone_46_gray.png'],['Sét, bom, cầu vồng · 100 px','specials_standalone_100_color.png','specials_standalone_100_gray.png'],['Overlay · 100 px: sét Training, sét Orc, bom Training, bom Orc','specials_100_color.png','specials_100_gray.png']];
 fs.writeFileSync(path.join(output,'index.html'),'<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Issue 3 · Kiểm tra ảnh</title><style>body{font:16px/1.6 system-ui;background:#f4f0e8;color:#302519;margin:24px}section{margin:30px 0;overflow:auto}img{display:block;max-width:none;margin:10px 0}h1{font-size:26px}small{color:#655}</style><h1>Issue #3 · Ảnh ở kích thước thật</h1><p>Thứ tự màu: đỏ, xanh lá, vàng, tím. Mỗi cặp: ảnh màu trên, ảnh xám dưới. Hình không được phóng to bằng CSS.</p>'+sections.map(([title,a,b])=>'<section><h2>'+title+'</h2><img src="'+a+'" alt="'+title+' màu"><img src="'+b+'" alt="'+title+' xám"></section>').join('')+'<p><a href="metrics.json">Số đo tự kiểm tra</a> · Đây là bằng chứng hình ảnh và phép đo kỹ thuật, không phải thử nghiệm tốc độ nhận diện với người chơi.</p></html>');
 console.log('PASS issue #3: '+checks+' checks; 8 normalized tiles; >=40% color at 46/100/128px; 16 matching idle/land first frames; unchanged atlas contract; 3 transparent specials.');
 console.log(metrics.orcCoverage.filter(x=>x.size===46).map(x=>x.color+': '+(x.coloredFraction*100).toFixed(1)+'% color').join(', '));
}finally{await browser.close();await new Promise(r=>server.close(r));fs.rmSync(tmp,{recursive:true,force:true})}
