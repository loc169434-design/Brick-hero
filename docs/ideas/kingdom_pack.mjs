// Raster packaging only: crops, alpha isolation, uniform scale, registration and lossless PNG.
// Source artwork was generated/edited with image_gen. Original source PNGs are left in place.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const repo=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const spec=JSON.parse(fs.readFileSync(path.join(repo,'docs/ideas/kingdom_sources.json')));
const sourceRoot=process.env.IMAGE_SOURCE_DIR||'/workspace/generated_images';
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'brick-character-'));
const run=args=>execFileSync('magick',args,{maxBuffer:128*1024*1024});
const info=file=>run(['identify','-format','%w %h',file]).toString().trim().split(' ').map(Number);
const flags=['-strip','-define','png:exclude-chunk=date,time','-define','png:compression-level=9','-define','png:compression-filter=5'];
const records=[],rigs=Object.fromEntries(['hero_iron','king','princess','blacksmith'].map(id=>[id,{id,canvas:[512,512],feet:[256,500],anchors:{}}]));
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
 let mouth=[head[0]+(id==='hero_iron'?16:-12),head[1]+30];
 if(face){
  const teeth=largestColorRegion(p,w,h,(r,g,b,x,y)=>x>=face.x&&x<=face.x+face.w&&y>face.y+face.h*.52&&y<face.y+face.h&&r>222&&g>215&&b>185);
  mouth=[Math.round(face.cx+(id==='hero_iron'?12:-12)),Math.round(face.y+face.h*.8)];
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
   let bodyOffset=sheet.id==='hero_iron'&&pose.endsWith('_cheer')?.08:sheet.id==='hero_iron'&&pose==='victory'?.12:0;
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

 for(const[id,rig]of Object.entries(rigs)){if(id==='hero_iron'){const order=['fresh','bruised','battered'].flatMap(t=>['idle','attack','hurt','scared','cheer'].map(p=>t+'_'+p)).concat(['victory','defeat']);rig.anchors=Object.fromEntries(order.map(p=>[p,rig.anchors[p]]));}}
 for(const[id,rig]of Object.entries(rigs))fs.writeFileSync(path.join(repo,'assets/characters',id,'rig.json'),JSON.stringify(rig,null,2)+'\n');
 for(const bg of spec.backgrounds){const src=path.join(sourceRoot,bg.file),[bw,bh]=info(src),out=path.join(repo,'assets/bg',bg.name+'.png');
  if(bg.dark_y){const a=path.join(tmp,'a.png'),b=path.join(tmp,'b.png');run([src,'-crop',`${bw}x${bg.dark_y}+0+0`,'+repage','-resize','1080x1350!',a]);run([src,'-crop',`${bw}x${bh-bg.dark_y}+0+${bg.dark_y}`,'+repage','-resize','1080x570!',b]);run([a,b,'-append','-alpha','off',...flags,'PNG24:'+out]);}
  else run([src,'-resize','1080x1920!','-alpha','off',...flags,'PNG24:'+out]);
 }
 const icons=path.join(sourceRoot,spec.icons),[iw,ih]=info(icons),ip=parts(icons).filter(p=>p.area>1500),iraw=run([icons,'-depth','8','rgba:-']);
 const names=['map_node_locked','map_node_open','map_node_done','wood_sword','iron_sword','tempered_sword','leather_armor','iron_armor','reinforced_boots'];
 for(let slot=0;slot<names.length;slot++){
  const ps=ip.filter(p=>Math.min(2,Math.floor(p.cx/(iw/3)))+3*Math.min(2,Math.floor(p.cy/(ih/3)))===slot);if(!ps.length)throw Error('Missing icon '+names[slot]);const bb=bounds(ps),ids=ps.map(x=>x.id).join(',');
  const mask=run([icons,'-alpha','extract','-threshold','6%','-define','connected-components:keep='+ids,'-define','connected-components:mean-color=true','-connected-components','8','-morphology','Dilate','Disk:1','-depth','8','gray:-']);
  const px=Buffer.from(iraw);for(let j=0;j<iw*ih;j++)if(!mask[j]||!px[j*4+3])px.fill(0,j*4,j*4+4);const rawfile=path.join(tmp,'icon.rgba');fs.writeFileSync(rawfile,px);
  const size=slot<3?128:256,name=names[slot],dir=path.join(repo,'assets/ui',slot<3?'':'items');fs.mkdirSync(dir,{recursive:true});
  run(['-size',iw+'x'+ih,'-depth','8','rgba:'+rawfile,'-crop',`${Math.min(iw-bb.x+1,bb.w+2)}x${Math.min(ih-bb.y+1,bb.h+2)}+${Math.max(0,bb.x-1)}+${Math.max(0,bb.y-1)}`,'+repage','-resize',`${size-16}x${size-16}`,'-gravity','center','-background','none','-extent',`${size}x${size}`,...flags,'PNG32:'+path.join(dir,name+'.png')]);
 }
 const nodes=[['scarecrow',463,1373],['orc_shield',284,1191],['frost_slime',653,1000],['goblin_thief',280,800],['stone_golem',640,670],['rune_witch',319,524],['royal_dragon',551,270]].map(([id,x,y])=>({id,x:Math.round(x*1080/941),y:Math.round(y*1920/1672)}));
 fs.writeFileSync(path.join(repo,'assets/bg/world_map.json'),JSON.stringify(nodes,null,2)+'\n');
 fs.writeFileSync(path.join(repo,'docs/ideas/kingdom_registration.json'),JSON.stringify({base:spec.base_commit,style:spec.style,records},null,2)+'\n');
 console.log('Packed '+records.length+' poses, 4 rigs, 3 backgrounds, 9 icons, 7 map points.');
}finally{fs.rmSync(tmp,{recursive:true,force:true})}
