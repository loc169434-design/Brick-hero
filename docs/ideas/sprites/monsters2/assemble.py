"""Lay out generated RGB poses; only key_out.py creates final alpha."""
import argparse, json, subprocess
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

p=argparse.ArgumentParser()
p.add_argument('monster'); p.add_argument('clip'); p.add_argument('source')
p.add_argument('--frames',type=int,required=True); p.add_argument('--fps',type=int,required=True)
p.add_argument('--source-rows',type=int,default=3); p.add_argument('--offset',type=int,default=0)
a=p.parse_args()
root=Path('docs/ideas/sprites/monsters2'); out=root/a.monster; out.mkdir(exist_ok=True)
ref=root/'ref'/f'{a.monster}_idle_old.png'
im=Image.open(a.source).convert('RGB'); ar=np.array(im)
def mask(rgb):
    d=rgb.astype(int)
    return ~((d[:,:,0]>180)&(d[:,:,2]>180)&(d[:,:,1]<100))
poses=[]; boxes=[]
for i in range(a.offset,a.offset+a.frames):
    x=i%4; y=i//4
    f=im.crop((round(x*im.width/4),round(y*im.height/a.source_rows),round((x+1)*im.width/4),round((y+1)*im.height/a.source_rows)))
    m=mask(np.array(f)); lab,n=ndimage.label(m)
    sizes=np.bincount(lab.ravel()); valid=np.flatnonzero(sizes>=max(20, sizes[1:].max()*.015)); valid=valid[valid!=0]
    m=np.isin(lab,valid); yy,xx=np.where(m)
    box=(int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)); boxes.append(box); poses.append(f.crop(box))
rr=np.array(Image.open(ref).convert('RGBA'))[:512,:512,3]>=128
yy=np.where(rr)[0]; height=int(yy.max()-yy.min()+1)
scale=height/poses[0].height
# Uniform scale within a clip: preserve actual crouches, stretches and falls.
sheet=Image.new('RGB',(2048,512*((a.frames+3)//4)),(255,0,255))
for i,f in enumerate(poses):
    w,h=round(f.width*scale),round(f.height*scale)
    if w>500 or h>494: raise RuntimeError(f'pose {i} needs room: {w}x{h}; regenerate')
    f=f.resize((w,h),Image.Resampling.LANCZOS)
    # Normalize only flat background, leaving drawn pixels intact.
    rgb=np.array(f); bg=~mask(rgb); rgb[bg]=(255,0,255); f=Image.fromarray(rgb)
    sheet.paste(f,((i%4)*512+256-w//2,(i//4)*512+501-h))
raw=root/'raw'/f'{a.monster}_{a.clip}_key.png'; sheet.save(raw)
target=Path('assets/characters')/a.monster/'anim'/f'fresh_{a.clip}.png'
subprocess.run(['python3','tools/sprites/key_out.py',str(raw),str(target),'--key','ff00ff'],check=True)
cmd=['python3','tools/sprites/check_sheet.py',str(target),'--frames',str(a.frames),'--fps',str(a.fps),'--key','ff00ff','--ref',str(ref),'--out',str(out)]
if a.clip=='defeat': cmd+=['--airborne']
r=subprocess.run(cmd,capture_output=True,text=True); print(r.stdout)
(out/f'{a.clip}_check.log').write_text(r.stdout+r.stderr)
(out/f'{a.clip}_layout.json').write_text(json.dumps({'source':a.source,'boxes':boxes,'scale':scale,'reference_height':height},indent=2))
raise SystemExit(r.returncode)
