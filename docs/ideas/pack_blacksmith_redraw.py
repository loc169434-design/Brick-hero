"""Only pack complete, independently drawn frames; never construct character poses.

No limb masks, face painting, rotation, warping, interpolation or cutout rigging.
A single uniform scale per clip and whole-frame registration normalize the
export canvas. Shared idle boundary cels are held for seamless transitions.
Run with a JSON mapping clip names to the generated source PNG paths.
"""
from pathlib import Path
import argparse,json,math,hashlib
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/ideas/blacksmith_review'
DEST=ROOT/'assets/characters/blacksmith/anim'
SPECS={'idle':(12,12,True,None),'talk':(8,12,True,None),'hammer':(16,24,False,9),'hammer_final':(20,24,False,12),'cheer':(16,12,False,None),'grin':(14,12,False,None)}

def cell_data(path,count,columns=4):
 im=Image.open(path).convert('RGBA');rows=math.ceil(count/columns);result=[]
 for i in range(count):
  x0=round(i%columns*im.width/columns);x1=round((i%columns+1)*im.width/columns)
  y0=round(i//columns*im.height/rows);y1=round((i//columns+1)*im.height/rows)
  # Trim the atlas gutters only; no individual body parts are cut or transformed.
  f=im.crop((x0+4,y0+4,x1-4,y1-4));arr=np.asarray(f)
  alpha=arr[:,:,3];strong=alpha>64
  yy,xx=np.where(strong);assert len(xx)>100
  bottom=int(yy.max())
  color=arr[:,:,:3].astype(float)
  boots=strong&(np.arange(f.height)[:,None]>bottom-f.height*.10)&(color[:,:,0]>color[:,:,1]*1.15)&(color[:,:,1]>color[:,:,2]*1.08)
  # Analysis only: find the two largest boot-color regions, ignoring thin wooden handles.
  from collections import deque
  visited=np.zeros(boots.shape,dtype=bool);groups=[]
  for by,bx in zip(*np.where(boots)):
   if visited[by,bx]:continue
   q=deque([(int(by),int(bx))]);visited[by,bx]=True;group=[]
   while q:
    yy0,xx0=q.popleft();group.append((yy0,xx0))
    for dy0,dx0 in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1)]:
     ny=yy0+dy0;nx=xx0+dx0
     if 0<=ny<f.height and 0<=nx<f.width and boots[ny,nx] and not visited[ny,nx]:visited[ny,nx]=True;q.append((ny,nx))
   groups.append(group)
  selected=[p for g in sorted(groups,key=len,reverse=True)[:2] for p in g]
  if selected:
   by,bx=np.array(selected).T;footx=float((bx.min()+bx.max())/2);bottom=int(by.max())
  else:footx=float((xx.min()+xx.max())/2)
  result.append((f,footx,bottom,(int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1)))
 return result

def normalize(data):
 neutral=data[0];s=400/(neutral[2]-neutral[3][1])
 # Keep every raised hammer/sweat arc within the export canvas using ONE scale per clip.
 for f,x,y,box in data:
  s=min(s,485/max(1,y-box[1]),245/max(1,x-box[0]),245/max(1,box[2]-x))
  if box[3]>y+1:s=min(s,10/(box[3]-y))
 result=[];placements=[]
 for f,x,y,box in data:
  size=(round(f.width*s),round(f.height*s));res=f.resize(size,Image.Resampling.LANCZOS)
  dx=round(256-x*s);dy=round(500-y*s)
  out=Image.new('RGBA',(512,512));out.alpha_composite(res,(dx,dy));result.append(out)
  placements.append({'scale':round(s,6),'whole_frame_offset':[dx,dy],'registered_feet':[256,500]})
 return result,placements

def preview(clip,frames,info):
 bg='#183247';rgb=[]
 for frame in frames:
  canvas=Image.new('RGBA',(512,512),bg);canvas.alpha_composite(frame)
  rgb.append(canvas.resize((224,224),Image.Resampling.LANCZOS).convert('RGB'))
 palette_canvas=Image.new('RGB',(224*len(rgb),224))
 for i,f in enumerate(rgb):palette_canvas.paste(f,(i*224,0))
 palette=palette_canvas.quantize(colors=128)
 seq=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in rgb]*3
 times=[(round((i+1)*100/info['fps'])-round(i*100/info['fps']))*10 for i in range(len(seq))]
 seq[0].save(OUT/f'{clip}.gif',save_all=True,append_images=seq[1:],duration=times,loop=0,disposal=2,optimize=False)
 grid=Image.new('RGB',(896,math.ceil(len(frames)/4)*250),bg);d=ImageDraw.Draw(grid)
 for i,(frame,small) in enumerate(zip(frames,rgb)):
  x=i%4*224;y=i//4*250;grid.paste(small,(x,y+26))
  d.text((x+8,y+7),str(i)+(' IMPACT' if info.get('impact')==i else ''),fill='#ffe3ad')
 grid.quantize(colors=160,dither=Image.Dither.NONE).save(OUT/f'{clip}_numbered.png',optimize=True)
 grid.save(f'/tmp/blacksmith_redraw_{clip}.png')

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('sources');args=p.parse_args()
 sources=json.loads(Path(args.sources).read_text());OUT.mkdir(exist_ok=True);DEST.mkdir(exist_ok=True)
 output={};provenance={};meta={'frame_size':[512,512],'columns':4,'clips':{}}
 canonical=None
 for clip,(n,fps,loop,impact) in SPECS.items():
  raw=Path(sources[clip]);frames,placements=normalize(cell_data(raw,n))
  replacements=[]
  if clip in ('hammer','hammer_final'):
   hitfile=Path(sources['impact_pair']);hit,hitpos=normalize(cell_data(hitfile,2,2));j=0 if clip=='hammer' else 1;frames[impact]=hit[j];placements[impact]=hitpos[j]
   swingfile=Path(sources['swing_pair']);swing,swingpos=normalize(cell_data(swingfile,2,2));j=0 if clip=='hammer' else 1
   frames[impact-1]=swing[j];placements[impact-1]=swingpos[j]
   replacements=[{'frame':impact,'source_file':hitfile.name,'source_sha256':hashlib.sha256(hitfile.read_bytes()).hexdigest()},{'frame':impact-1,'source_file':swingfile.name,'source_sha256':hashlib.sha256(swingfile.read_bytes()).hexdigest(),'cell':j}]

  if clip=='idle':canonical=frames[0].copy();frames[-1]=canonical.copy()
  else:frames[0]=canonical.copy();frames[-1]=canonical.copy()
  info={'frames':n,'fps':fps,'loop':loop}
  if impact is not None:info['impact']=impact
  sheet=Image.new('RGBA',(2048,math.ceil(n/4)*512))
  for i,f in enumerate(frames):sheet.alpha_composite(f,(i%4*512,i//4*512))
  sheet.save(DEST/f'fresh_{clip}.png',optimize=True);preview(clip,frames,info);output[clip]=frames;meta['clips'][clip]=info
  provenance[clip]={'source_file':raw.name,'source_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'method':'individually redrawn complete figures via image generation; whole-frame packing only','registration':placements,'shared_idle_boundary_frames':[0,n-1],'replacement_complete_cels':replacements}
 (DEST/'anim.json').write_text(json.dumps(meta,indent=2)+'\n')
 (OUT/'drawing_provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
 print('Packed 6 clips, 86 frames from complete redrawn figures.')
