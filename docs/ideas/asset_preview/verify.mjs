// Integration checks for the delivered asset viewer, not application gameplay tests.
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import assert from 'node:assert/strict';
const require=createRequire(import.meta.url),{chromium}=require('playwright');
const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const siteRoot=process.env.SITE_ROOT||repo;
const artifacts=process.env.ARTIFACT_DIR||path.resolve(repo,'../artifacts/brickbound-training-orc');
const server=http.createServer((req,res)=>{
  try{
    const url=new URL(req.url,'http://localhost');
    const file=url.pathname==='/portable.html'?path.join(artifacts,'preview_training_orc.html'):path.resolve(siteRoot,'.'+decodeURIComponent(url.pathname));
    if(url.pathname!=='/portable.html'&&!file.startsWith(siteRoot+path.sep)){res.writeHead(403).end();return}
    const body=fs.readFileSync(file),mime={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.png':'image/png','.json':'application/json'}[path.extname(file)]||'text/plain';
    res.writeHead(200,{'Content-Type':mime});res.end(body);
  }catch{res.writeHead(404).end()}
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const base='http://127.0.0.1:'+server.address().port;
const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
let checks=0;
try{
  const context=await browser.newContext({viewport:{width:1280,height:1000}}),page=await context.newPage(),errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  await page.goto(base+'/docs/ideas/asset_preview/index.html');
  await page.waitForFunction(()=>window.artPreview?.ready);
  // Verify every exported atlas, per-frame content and transparent death/clear endpoints.
  const manifest=JSON.parse(fs.readFileSync(path.join(repo,'assets/tiles/animation_pack.json'),'utf8'));
  assert.equal(manifest.atlases.length,76);checks++;
  for(const atlas of manifest.atlases){
    const result=await page.evaluate(async a=>{
      const im=new Image();im.src=TileRenderer.urlFor(a.file);await im.decode();
      const cv=document.createElement('canvas');cv.width=cv.height=192;const ctx=cv.getContext('2d');
      const samples=[];const occupancy=[];
      for(const n of [0,8,16,23]){
        ctx.clearRect(0,0,192,192);ctx.drawImage(im,n%8*192,Math.floor(n/8)*192,192,192,0,0,192,192);
        const pixels=ctx.getImageData(0,0,192,192).data;let opaque=0,hash=2166136261;
        for(let i=0;i<pixels.length;i++){hash=Math.imul(hash^pixels[i],16777619);if(i%4===3&&pixels[i]>0)opaque++}
        samples.push(hash);occupancy.push(opaque);
      }
      return {w:im.naturalWidth,h:im.naturalHeight,samples,occupancy};
    },atlas);
    assert.deepEqual([result.w,result.h],[1536,576],atlas.file);
    assert.ok(result.occupancy[0]>1000,atlas.file+' missing first frame');
    assert.ok(new Set(result.samples).size>1,atlas.file+' is static');
    if(atlas.animation==='combo'||atlas.animation==='death'||atlas.family==='orc_shield'&&atlas.animation==='win')assert.equal(result.occupancy[3],0,atlas.file+' should end transparent');
    checks+=4;
  }
  for(const family of ['training','orc_shield'])for(const color of ['red','green','yellow','purple']){
    await page.evaluate(async({family,color})=>artPreview.select(family,color,'win'),{family,color});
    await page.waitForFunction(()=>[...document.images].every(im=>im.complete&&im.naturalWidth>0));
    assert.equal(await page.locator('#events button').count(),family==='training'?7:12);checks++;
  }
  await page.evaluate(async()=>{await artPreview.select('orc_shield','red','idle');artPreview.state.speed=30});
  await page.locator('[data-scene="near"]').click();
  await page.waitForFunction(()=>artPreview.state.animation==='idle'&&artPreview.state.queue.length===0);
  checks++;
  await page.locator('[data-scene="victory"]').click();
  await page.waitForFunction(()=>artPreview.state.animation==='win'&&!artPreview.state.playing);
  checks++;
  await page.locator('#restart').click();await page.locator('#play').click();
  assert.equal(await page.evaluate(()=>artPreview.state.playing),false);checks++;
  await page.locator('#timeline').fill('8');
  assert.equal(await page.evaluate(()=>Math.floor(artPreview.state.time/TILE_PACK.animations[artPreview.state.animation].seconds*24)),8);checks++;
  await page.locator('#step').click();assert.match(await page.locator('#frame-info').textContent(),/10 \/ 24/);checks++;
  await page.evaluate(async()=>artPreview.select('orc_shield','yellow','near_miss'));
  await page.screenshot({path:path.join(artifacts,'preview_desktop.png'),fullPage:true});
  await page.setViewportSize({width:390,height:844});
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'mobile horizontal overflow');checks++;
  await page.screenshot({path:path.join(artifacts,'preview_mobile.png'),fullPage:true});
  assert.deepEqual(errors,[]);checks++;
  // The portable page must work with all asset/network requests blocked.
  const portableContext=await browser.newContext({reducedMotion:'reduce'}),portable=await portableContext.newPage(),portableErrors=[],external=[];
  portable.on('pageerror',e=>portableErrors.push(e.message));
  await portableContext.route('**/*',route=>{
    if(route.request().url()===base+'/portable.html')route.continue();
    else{external.push(route.request().url());route.abort()}
  });
  await portable.goto(base+'/portable.html');await portable.waitForFunction(()=>window.artPreview?.ready);
  assert.equal(await portable.evaluate(()=>artPreview.state.playing),false);checks++;
  await portableContext.setOffline(true);
  await portable.evaluate(async()=>{await artPreview.select('training','purple','combo');await artPreview.select('orc_shield','green','near_miss')});
  await portable.waitForFunction(()=>[...document.images].every(im=>im.complete&&im.naturalWidth>0));
  assert.match(await portable.locator('#atlas-download').getAttribute('href'),/^data:image\/png;base64,/);checks++;
  assert.match(await portable.locator('#godot-download').getAttribute('href'),/^data:text\/plain;base64,/);checks++;
  assert.deepEqual(portableErrors,[]);assert.deepEqual(external,[]);checks+=2;
  console.log('PASS: '+checks+' checks; 76 moving atlases, all families/colors, terminal transparency, scenario sequencing, controls, mobile layout, reduced motion, portable page offline.');
}finally{await browser.close();await new Promise(r=>server.close(r))}
