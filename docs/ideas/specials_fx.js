/* Deterministic raster animation export; no gameplay code. */
window.SPECIAL_FX_SPEC={
 'lightning_beam.png':{frame_width:256,frame_height:96,frames:8,fps:24,loop:false},
 'lightning_hub.png':{frame_width:256,frame_height:256,frames:8,fps:24,loop:false},
 'bomb_blast.png':{frame_width:512,frame_height:512,frames:12,fps:24,loop:false},
 'star_burst.png':{frame_width:512,frame_height:512,frames:12,fps:24,loop:false},
 'star_spark.png':{frame_width:192,frame_height:192,frames:8,fps:24,loop:false},
 'fusion_flash.png':{frame_width:512,frame_height:512,frames:8,fps:24,loop:false}
};
(()=>{const root=new URL('../../',document.currentScript.src),images={};const load=(name,path)=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>{images[name]=im;resolve()};im.onerror=()=>reject(new Error(path));im.src=new URL(path,root).href});
const ready=Promise.all([...Object.keys(SPECIAL_FX_SPEC).map(file=>load(file,'docs/ideas/specials_fx_sources/'+file)),...['red','green','yellow','purple'].map(c=>load(c,'assets/tiles/orc_shield/tile_'+c+'.png'))]);
const clamp=x=>Math.max(0,Math.min(1,x));
function draw(ctx,file,frame){const s=SPECIAL_FX_SPEC[file],w=s.frame_width,h=s.frame_height,t=frame/(s.frames-1);if(frame>=s.frames-1)return;const im=images[file];ctx.save();ctx.translate(w/2,h/2);
 const pop=Math.sin(Math.min(1,t*1.5)*Math.PI*.65),fade=1-clamp((t-.36)/.64);ctx.globalAlpha=.35+.65*pop;
 if(file==='lightning_beam.png'){
  ctx.globalAlpha=(.94+.06*Math.cos(frame*Math.PI))*Math.min(1,fade*2.5);const stretch=.74+.25*Math.sin((frame+1)*2);ctx.scale(1,stretch);ctx.drawImage(im,-128,-36,256,72);ctx.restore();
  const alpha=(.94+.06*Math.cos(frame*Math.PI))*Math.min(1,fade*2.5);ctx.save();ctx.globalAlpha=alpha;ctx.lineCap='butt';for(const[a,b]of [[0,13],[243,256]]){ctx.strokeStyle='#252525';ctx.lineWidth=10;ctx.beginPath();ctx.moveTo(a,48);ctx.lineTo(b,48);ctx.stroke();ctx.strokeStyle='#fff';ctx.lineWidth=4;ctx.stroke()}ctx.restore();
  const data=ctx.getImageData(0,0,w,h);for(let y=0;y<h;y++)for(let c=0;c<4;c++)data.data[(y*w+w-1)*4+c]=data.data[y*w*4+c];ctx.putImageData(data,0,0);return;
 }
 let size,rotation=0;
 if(file==='lightning_hub.png'){size=76+172*Math.sin(Math.min(1,t*1.4)*Math.PI*.6);ctx.globalAlpha=fade;rotation=Math.sin(frame*2.2)*.055;}
 else if(file==='bomb_blast.png'){size=48+448*Math.sin(Math.min(1,t*1.5)*Math.PI*.5);ctx.globalAlpha=Math.min(1,fade*1.7);rotation=Math.sin(frame)*.02;}
 else if(file==='star_burst.png'){size=60+430*Math.sin(Math.min(1,t*1.5)*Math.PI*.5);ctx.globalAlpha=Math.min(1,fade*1.6);rotation=t*.32;}
 else if(file==='star_spark.png'){size=28+148*Math.sin(Math.min(1,t*1.4)*Math.PI*.5);ctx.globalAlpha=fade;rotation=t*.45;}
 else{size=100+390*Math.sin(Math.min(1,t*1.55)*Math.PI*.5);ctx.globalAlpha=Math.min(1,fade*1.7);rotation=Math.sin(frame)*.035;}
 ctx.rotate(rotation);ctx.drawImage(im,-size/2,-size/2,size,size);ctx.restore();
}
window.SpecialFxArt={ready,images,root,draw};})();
