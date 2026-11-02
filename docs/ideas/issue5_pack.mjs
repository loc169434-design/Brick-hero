// Raster packaging only: crops, alpha isolation, uniform scale, registration and lossless PNG.
// Source artwork was generated/edited with image_gen. Original source PNGs are left in place.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const spec=JSON.parse(fs.readFileSync(path.join(repo,'docs/ideas/issue5_sources.json')));
const sourceRoot=process.env.IMAGE_SOURCE_DIR||'/workspace/generated_images';
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'brick-character-'));
const run=args=>execFileSync('magick',args,{maxBuffer:128*1024*1024});
const info=file=>run(['identify','-format','%w %h',file]).toString().trim().split(' ').map(Number);
const flags=['-strip','-define','png:exclude-chunk=date,time','-define','png:compression-level=9','-define','png:compression-filter=5'];
const records=[],rigs={hero_rookie:{id:'hero_rookie',canvas:[512,512],feet:[256,500],anchors:{}},orc_shield:{id:'orc_shield',canvas:[512,512],feet:[256,500],anchors:{}},scarecrow:{id:'scarecrow',canvas:[512,512],feet:[256,500],anchors:{}}};
function parts(file){const text=run([file,'-alpha','extract','-threshold','6%','-define','connected-components:verbose=true','-connected-components','8','null:']).toString();return [...text.matchAll(/^\s*(\d+): (\d+)x(\d+)\+(\d+)\+(\d+) ([\d.]+),([\d.]+) ([\de+.]+) srgb\(255,255,255\)/gm)].map(m=>({id:+m[1],w:+m[2],h:+m[3],x:+m[4],y:+m[5],cx:+m[6],cy:+m[7],area:+m[8]}));}
function bounds(ps){const x=Math.min(...ps.map(p=>p.x)),y=Math.min(...ps.map(p=>p.y));return{x,y,w:Math.max(...ps.map(p=>p.x+p.w))-x,h:Math.max(...ps.map(p=>p.y+p.h))-y};}
function rgba(file){const [w,h]=info(file);return{w,h,p:run([file,'-depth','8','rgba:-'])};}
function scan(p,w,h,condition){let x0=w,y0=h,x1=-1,y1=-1,n=0,sx=0,sy=0;for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=(y*w+x)*4;if(p[i+3]>0&&condition(p[i],p[i+1],p[i+2],x,y)){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);n++;sx+=x;sy+=y;}}return n?{x:x0,y:y0,w:x1-x0+1,h:y1-y0+1,n,cx:sx/n,cy:sy/n}:null;}
function largestColorRegion(p,w,h,test){
 const seen=new Uint8Array(w*h),queue=new Int32Array(w*h);let best=null;
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){const k=y*w+x,i=k*4;if(seen[k]||p[i+3]<=32||!test(p[i],p[i+1],p[i+2],x,y))continue;
  let a=0,b=1,x0=x,x1=x,y0=y,y1=y,n=0,sx=0,sy=0;queue[0]=k;seen[k]=1;
  while(a<b){const at=queue[a++],xx=at%w,yy=Math.floor(at/w);n++;sx+=xx;sy+=yy;x0=Math.min(x0,xx);x1=Math.max(x1,xx);y0=Math.min(y0,yy);y1=Math.max(y1,yy);
   for(const [nx,ny]of [[xx-1,yy],[xx+1,yy],[xx,yy-1],[xx,yy+1]])if(nx>=0&&nx<w&&ny>=0&&ny<h){const q=ny*w+nx,j=q*4;if(!seen[q]&&p[j+3]>32&&test(p[j],p[j+1],p[j+2],nx,ny)){seen[q]=1;queue[b++]=q;}}
  }
  if(!best||n>best.n)best={x:x0,y:y0,w:x1-x0+1,h:y1-y0+1,n,cx:sx/n,cy:sy/n};
 }
 return best;
}
function deriveAnchors(file,id,pose,visible,bodyOffset=0){
 const {w,h,p}=rgba(file);const endLow=pose==='defeat';
 const bodyTop=visible.y+visible.h*bodyOffset;
 let y0=endLow?Math.max(100,visible.y):bodyTop,y1=endLow?Math.min(420,visible.y+visible.h*.48):Math.min(285,bodyTop+visible.h*.32);
 let face;
 if(id==='orc_shield')face=largestColorRegion(p,w,h,(r,g,b,x,y)=>y>=y0&&y<=y1&&x>140&&x<400&&g>100&&g>r*.94&&g>b*1.25&&r>70);
 else face=largestColorRegion(p,w,h,(r,g,b,x,y)=>y>=y0&&y<=y1&&x>120&&x<400&&r>185&&g>105&&b>45&&r>g*1.12&&g>b*1.15&&b<220);
 let head=face?[Math.round(face.cx),Math.round((bodyTop+face.y+face.h)/2)]:[256,endLow?350:170];
 // Color masks provide a starting point; final anchors are visually reviewed in the gallery.
 let mouth=[head[0]+(id==='hero_rookie'?16:-12),head[1]+30];
 if(face){
  const teeth=largestColorRegion(p,w,h,(r,g,b,x,y)=>x>=face.x&&x<=face.x+face.w&&y>face.y+face.h*.52&&y<face.y+face.h&&r>222&&g>215&&b>185);
  mouth=[Math.round(face.cx+(id==='hero_rookie'?12:-12)),Math.round(face.y+face.h*.8)];
  if(teeth&&teeth.n>8&&teeth.w/teeth.h>1.25)mouth=[Math.round(teeth.cx),Math.round(teeth.cy)];
 }
 if(id==='scarecrow'){
  if(pose==='defeat'){head=[Math.round(visible.x+visible.w*.25),Math.round(visible.y+visible.h*.55)];mouth=[head[0]-8,head[1]+20];}
  else{head=[Math.round(visible.x+visible.w*.52),Math.round(visible.y+visible.h*.19)];mouth=[head[0]-(pose.endsWith('hurt')?24:14),Math.round(visible.y+visible.h*.26)];}
 }
 return{head,mouth};
}
try{
 for(const sheet of spec.sheets){
  const source=path.join(sourceRoot,sheet.file),[w,h]=info(source),all=parts(source),raw=run([source,'-depth','8','rgba:-']);
  const grouped=new Map();
  for(const p of all){const col=Math.min(sheet.cols-1,Math.floor(p.cx/(w/sheet.cols))),row=Math.min(sheet.rows-1,Math.floor(p.cy/(h/sheet.rows))),slot=row*sheet.cols+col;if(!grouped.has(slot))grouped.set(slot,[]);grouped.get(slot).push(p);}
  let shared;
  for(let slot=0;slot<sheet.poses.length;slot++){
   const pose=sheet.poses[slot];if(!pose)continue;
   const ps=(grouped.get(slot)||[]).filter(p=>p.area>=60).sort((a,b)=>b.area-a.area);if(!ps.length)throw Error('Missing '+sheet.id+'/'+pose);
   const main=ps[0],selected=ps.filter(p=>p===main||p.area>=100),bb=bounds(selected);
   const ids=selected.map(p=>p.id).join(',');
   const mask=run([source,'-alpha','extract','-threshold','6%','-define','connected-components:keep='+ids,'-define','connected-components:mean-color=true','-connected-components','8','-morphology','Dilate','Disk:1','-depth','8','gray:-']);
   const pixels=Buffer.from(raw);for(let i=0;i<w*h;i++)if(!mask[i]||!pixels[i*4+3])pixels.fill(0,i*4,i*4+4);
   const rawPath=path.join(tmp,'masked.rgba');fs.writeFileSync(rawPath,pixels);
   // Midpoint of the boot/pole span, not bbox center (sword and scarf are asymmetric).
   let left=w,right=-1;const band=Math.max(4,Math.round(main.h*.065));
   for(let yy=main.y+main.h-band;yy<main.y+main.h;yy++)for(let xx=main.x;xx<main.x+main.w;xx++)if(mask[yy*w+xx]&&pixels[(yy*w+xx)*4+3]>32){left=Math.min(left,xx);right=Math.max(right,xx);}
   const footX=(left+right)/2,footY=main.y+main.h-1;
   let bodyOffset=sheet.id==='hero_rookie'&&pose==='bruised_attack'?.11:sheet.id==='hero_rookie'&&pose==='victory'?.12:0;
   const target=sheet.id==='scarecrow'?440:400;
   let scale=(target-1)/(main.h*(1-bodyOffset)-1);
   if(sheet.shared_scale||sheet.shared_end_scale){if(shared===undefined)shared=scale;else scale=shared;}
   const crop={x:Math.max(0,bb.x-1),y:Math.max(0,bb.y-1),w:Math.min(w-bb.x+1,bb.w+2),h:Math.min(h-bb.y+1,bb.h+2)};
   scale=Math.min(scale,244/Math.max(1,footX-crop.x),244/Math.max(1,crop.x+crop.w-footX),488/Math.max(1,footY-crop.y));
   const cut=path.join(tmp,'cut.png');run(['-size',w+'x'+h,'-depth','8','rgba:'+rawPath,'-crop',`${crop.w}x${crop.h}+${crop.x}+${crop.y}`,'+repage','-resize',(scale*100).toFixed(6)+'%',...flags,'PNG32:'+cut]);
   const [cw,ch]=info(cut),sx=cw/crop.w,sy=ch/crop.h;
   const dx=256-Math.round((footX-crop.x)*sx),dy=500-Math.round((footY-crop.y)*sy);
   const dir=path.join(repo,'assets/characters',sheet.id);fs.mkdirSync(dir,{recursive:true});const destination=path.join(dir,pose+'.png');
   run(['-size','512x512','xc:none',cut,'-geometry',`${dx>=0?'+':''}${dx}${dy>=0?'+':''}${dy}`,'-compose','Over','-composite',...flags,'PNG32:'+destination]);
   let out=rgba(destination),vis=scan(out.p,out.w,out.h,()=>true);
   const groundShift=500-(vis.y+vis.h-1);
   if(groundShift){run([destination,'-roll','+0'+(groundShift>=0?'+':'')+groundShift,...flags,'PNG32:'+destination]);out=rgba(destination);vis=scan(out.p,out.w,out.h,()=>true);}
   const anchor=deriveAnchors(destination,sheet.id,pose,vis,bodyOffset);rigs[sheet.id].anchors[pose]=anchor;
   let hand=null;
   if(sheet.id==='orc_shield'&&pose!=='defeat'){
    hand=scan(out.p,512,512,(r,g,b,x,y)=>x<165&&y>270&&y<390&&g>100&&g>r*.94&&g>b*1.3);
    if(hand)hand=[Math.round(hand.cx),Math.round(hand.cy)];
   }
   records.push({id:sheet.id,pose,file:path.relative(repo,destination),source:sheet.file,sourceSHA256:crypto.createHash('sha256').update(raw).digest('hex'),sourceBounds:bb,mainBounds:main,scale,footProjection:[256,500],visibleBounds:vis,hand,...anchor});
  }
 }
 const orcHands=records.filter(x=>x.id==='orc_shield'&&x.hand).map(x=>x.hand);const median=xs=>[...xs].sort((a,b)=>a-b)[Math.floor(xs.length/2)];
 const shield=[median(orcHands.map(x=>x[0])),median(orcHands.map(x=>x[1]))];rigs.orc_shield.shield=shield;
 // Shield layers share the intact shield's crop and scale, including the missing area.
 const shields=path.join(sourceRoot,spec.shields),[sw,sh]=info(shields),sp=parts(shields).filter(x=>x.area>1000).sort((a,b)=>a.cx-b.cx),first=sp[0];
 const shieldHeight=196,shieldWidth=Math.min(154,2*(shield[0]-8)),fullCrop={x:first.x-1,y:first.y-1,w:first.w+2,h:first.h+2};
 for(let layer=3;layer>=0;layer--){const out=path.join(repo,'assets/characters/orc_shield','shield_'+layer+'.png');if(!layer){run(['-size','512x512','xc:none',...flags,'PNG32:'+out]);continue;}
  const i=3-layer,part=sp[i];if(!part)throw Error('Missing shield layer '+layer);
  const x=Math.round(fullCrop.x+i*sw/4),cut=path.join(tmp,'shield.png');
  run([shields,'-crop',`${fullCrop.w}x${fullCrop.h}+${x}+${fullCrop.y}`,'+repage','-resize',`${shieldWidth}x${shieldHeight}!`,...flags,'PNG32:'+cut]);
  run(['-size','512x512','xc:none',cut,'-geometry',`+${shield[0]-Math.round(shieldWidth/2)}+${shield[1]-Math.round(shieldHeight/2)}`,'-compose','Over','-composite',...flags,'PNG32:'+out]);
 }
 for(const [id,rig]of Object.entries(rigs))fs.writeFileSync(path.join(repo,'assets/characters',id,'rig.json'),JSON.stringify(rig,null,2)+'\n');
 fs.mkdirSync(path.join(repo,'assets/bg'),{recursive:true});
 for(const bg of spec.backgrounds){const src=path.join(sourceRoot,bg.file),[bw,bh]=info(src),top=path.join(tmp,'bg_top.png'),floor=path.join(tmp,'bg_floor.png');
  run([src,'-crop',`${bw}x${bg.source_ground_y}+0+0`,'+repage','-resize','1080x470!',top]);run([src,'-crop',`${bw}x${bh-bg.source_ground_y}+0+${bg.source_ground_y}`,'+repage','-resize','1080x190!',floor]);run([top,floor,'-append',...flags,path.join(repo,'assets/bg',bg.name+'.png')]);
 }
 fs.mkdirSync(path.join(repo,'assets/fx/battle'),{recursive:true});
 const fx=path.join(sourceRoot,spec.fx),[fw,fh]=info(fx);const effects=[['sweat',128,128],['stars',192,96],['sparkle',128,128],['splinters',256,256],['straw',256,256]];
 for(const[i,[name,ew,eh]]of effects.entries()){const cut=path.join(tmp,'fx.png');const x=Math.round(i%3*fw/3),y=Math.round(Math.floor(i/3)*fh/2);run([fx,'-crop',`${Math.floor(fw/3)}x${Math.floor(fh/2)}+${x}+${y}`,'+repage','-trim','+repage','-resize',`${ew-12}x${eh-12}`,'-gravity','center','-background','none','-extent',`${ew}x${eh}`,...flags,'PNG32:'+path.join(repo,'assets/fx/battle',name+'.png')]);}
 fs.writeFileSync(path.join(repo,'docs/ideas/issue5_registration.json'),JSON.stringify({base:spec.base_commit,style:spec.style,records,shield,shieldSize:[shieldWidth,shieldHeight]},null,2)+'\n');
 console.log('Packed '+records.length+' poses, 4 shields, 2 backgrounds, 5 FX and 3 rigs.');console.log('Shield anchor '+JSON.stringify(shield));
}finally{fs.rmSync(tmp,{recursive:true,force:true})}
