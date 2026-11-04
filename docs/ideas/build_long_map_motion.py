"""Offline ambient-motion preview using existing artwork, no game-code changes."""
from pathlib import Path
import json, math
import numpy as np
from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/ideas/long_map_review'
FX=ROOT/'assets/bg/world_map_fx'
FX.mkdir(exist_ok=True)
SOURCES={'smoke':'assets/bg/orc_camp/smoke.png','sparkle':'assets/fx/battle/sparkle.png','glow':'assets/fx/particles/glow.png'}
for name,source in SOURCES.items():Image.open(ROOT/source).convert('RGBA').save(FX/(name+'.png'))
base=Image.open(ROOT/'assets/bg/world_map.png').convert('RGBA')
smoke=Image.open(FX/'smoke.png').convert('RGBA')
star=Image.open(FX/'sparkle.png').convert('RGBA')
glow=Image.open(FX/'glow.png').convert('RGBA')

# Select glints only on existing blue river pixels, away from the dirt nodes.
a=np.array(base)
blue=(a[:,:,2]>a[:,:,0].astype(float)*1.12)&(a[:,:,1]>a[:,:,0].astype(float)*1.15)&(a[:,:,1]>95)
water=[]
for region in [(80,900,260,1150),(500,2050,700,2480)]:
 x0,y0,x1,y1=region;ys,xs=np.where(blue[y0:y1,x0:x1])
 if len(xs):
  order=np.argsort(ys)
  for q in [.15,.38,.65,.85]:
   k=order[int(q*(len(order)-1))];water.append([int(xs[k]+x0),int(ys[k]+y0)])
meta={'version':1,'map_size':[1080,3840],'loop_seconds':4,'preview_fps':12,'textures':{'smoke':{'file':'smoke.png','frame_size':[192,192],'columns':4,'frames':4},'sparkle':{'file':'sparkle.png','frame_size':[128,128],'columns':1,'frames':1},'glow':{'file':'glow.png','frame_size':[128,128],'columns':1,'frames':1}},'smoke':[{'position':[200,1156],'phase':0.0},{'position':[261,1123],'phase':0.33},{'position':[319,1153],'phase':0.66}],'water_glints':water,'gold_glints':[[578,286],[626,304],[675,275],[729,302],[770,279]],'smoke_motion':{'size_px':96,'rise_px':65,'drift_px':12,'opacity':0.8,'tint':[216,160,245]},'water_motion':{'size_px':[8,18],'travel_y_px':12,'period_seconds':2,'opacity':0.45,'tint':[190,239,255]},'gold_motion':{'size_px':[20,34],'opacity':0.8,'period_seconds':4},'integration':'Additive asset specification only. No existing game code automatically loads this file. Keep the map texture and its 15 node coordinates fixed; position FX in map-local coordinates so they scroll with the map.','sources':SOURCES}
(FX/'anim.json').write_text(json.dumps(meta,indent=2)+'\n')

scale=.5
background=base.resize((540,1920),Image.Resampling.LANCZOS)

def paint(frame,texture,x,y,size,opacity,tint=None,bottom=False):
 sprite=texture.copy()
 if tint is not None:
  alpha=sprite.getchannel('A');sprite=Image.new('RGBA',sprite.size,tuple(tint)+(0,));sprite.putalpha(alpha)
 size=max(1,round(size*scale));sprite=sprite.resize((size,size),Image.Resampling.LANCZOS)
 sprite.putalpha(sprite.getchannel('A').point(lambda v:round(v*opacity)))
 px=round(x*scale-size/2);py=round(y*scale-(size if bottom else size/2))
 frame.alpha_composite(sprite,(px,py))

def render(t):
 frame=background.copy()
 for emitter in meta['smoke']:
  p=(t/4+emitter['phase'])%1;index=min(3,int(p*4))
  tex=smoke.crop((index*192,0,(index+1)*192,192));x,y=emitter['position']
  paint(frame,tex,x+12*p+3*math.sin(p*math.tau),y-65*p,96,.8*math.sin(math.pi*p)**1.5,[216,160,245],True)
 for i,(x,y) in enumerate(water):
  p=(t/2+i/len(water))%1;w=math.sin(math.pi*p)**2
  paint(frame,glow,x,y+12*p,8+10*w,.45*w,[190,239,255])
 for i,(x,y) in enumerate(meta['gold_glints']):
  w=max(0,math.sin(math.tau*t/4+i*1.23))**4
  paint(frame,star,x,y,20+14*w,.8*w)
 return frame

count=48
frames=[render(i/12) for i in range(count)]
durations=[round((i+1)*1000/12)-round(i*1000/12) for i in range(count)]
webp=OUT/'world_map_motion.webp'
for width in [540,432,360]:
 seq=[f.resize((width,round(3840*width/1080)),Image.Resampling.LANCZOS) for f in frames]
 seq[0].save(webp,save_all=True,append_images=seq[1:],duration=durations,loop=0,quality=72,method=4,minimize_size=True)
 if webp.stat().st_size<2_000_000:break
assert webp.stat().st_size<2_000_000

# Explicit transparent deltas retain a fixed palette and a sharp static map.
small=[f.resize((270,960),Image.Resampling.LANCZOS).convert('RGB') for f in frames]
palette_source=Image.new('RGB',(1080,960))
for i,k in enumerate([0,12,24,36]):palette_source.paste(small[k],(i*270,0))
pal=palette_source.quantize(colors=127,method=Image.Quantize.MEDIANCUT)
palette=[0,0,0]+pal.getpalette()[:127*3];palette+= [0]*(768-len(palette))
sequence=[];previous=None
for f in small:
 q=np.asarray(f.quantize(palette=pal,dither=Image.Dither.NONE),dtype=np.uint8).copy()+1
 if previous is None:delta=q.copy()
 else:delta=np.where(q!=previous,q,0).astype(np.uint8)
 p=Image.fromarray(delta,'P');p.putpalette(palette);p.info['transparency']=0;sequence.append(p);previous=q
sequence[0].save(OUT/'world_map_motion.gif',save_all=True,append_images=sequence[1:],duration=[(round((i+1)*100/12)-round(i*100/12))*10 for i in range(count)],loop=0,transparency=0,disposal=1,optimize=False)
assert (OUT/'world_map_motion.gif').stat().st_size<2_000_000
report={'loop_seconds':4,'fps':12,'source_frames':48,'production_map_unchanged':True,'coordinates_unchanged':True,'effects':['three gentle chimney smoke plumes','blue-river glints','gold-hoard glints'],'webp':{'bytes':webp.stat().st_size,'size':[width,round(3840*width/1080)]},'gif':{'bytes':(OUT/'world_map_motion.gif').stat().st_size,'size':[270,960]},'integration_required':True}
(OUT/'motion_validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
