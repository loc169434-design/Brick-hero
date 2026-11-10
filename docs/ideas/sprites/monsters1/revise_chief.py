"""Assemble generated corrections into opaque key sheets; key_out alone makes alpha."""
from PIL import Image
from pathlib import Path
import numpy as np
from scipy import ndimage
import shutil,subprocess,json
b=Path(__file__).resolve().parent;r=b.parents[3];key=(255,0,255)
sources={'special':'exec-d0421e99-6f4e-47cc-8abf-fdf8a85bddd3.png','attack':'exec-e4836614-7e12-4abc-9ff0-eddee3fadd1c.png','idle':'exec-88ce4805-7eac-45c0-80b4-dbc4a7f814b9.png'}
def clean_crop(im,i,rows):
 w,h=im.size;cell=im.crop((round(i%4*w/4),round(i//4*h/rows),round((i%4+1)*w/4),round((i//4+1)*h/rows)))
 a=np.array(cell.convert('RGB'));mask=np.linalg.norm(a.astype(float)-key,axis=2)>140
 lab,n=ndimage.label(mask);sizes=np.bincount(lab.ravel());sizes[0]=0;mask=lab==sizes.argmax()
 yy,xx=np.where(mask);bbox=(max(0,xx.min()-3),max(0,yy.min()-3),min(a.shape[1],xx.max()+4),min(a.shape[0],yy.max()+4))
 near=ndimage.binary_dilation(mask,iterations=3);a[~near]=key;a[np.linalg.norm(a.astype(float)-key,axis=2)<60]=key
 return Image.fromarray(a).crop(bbox)
for c,src in sources.items():
 p=b/f'raw/orc_chief_{c}_key.png';old=Image.open(p).convert('RGB');g=Image.open('/workspace/generated_images/'+src)
 shutil.copy2('/workspace/generated_images/'+src,b/f'orc_chief/generated_revision_{c}.png')
 if c in ('attack','special'):
  i=1 if c=='attack' else 5;crop=clean_crop(g,i,3)
  # Retain the exact other eleven cells. Match revised cell proportions to adjacent ready.
  target_h=391 if c=='attack' else 407
  target_w=400 if c=='attack' else 350
  crop=crop.resize((target_w,target_h+6),Image.Resampling.LANCZOS)
  cell=Image.new('RGB',(512,512),key);cell.paste(crop,(256-target_w//2,500-target_h-2))
  old.paste(cell,(i%4*512,i//4*512))
 else:
  # Continuous 0..6px breathing registration, fixed support below y=420.
  a=np.array(old.crop((0,0,512,512)));y,x=np.mgrid[:512,:512]
  for i,d in enumerate([0,2,4,6,6,4,2,0]):
   weight=np.clip((420-y)/90,0,1)*np.clip((y-130)/100,0,1)
   out=np.stack([ndimage.map_coordinates(a[...,c],[y+d*weight,x],order=1,mode='nearest') for c in range(3)],axis=2).astype('uint8')
   old.paste(Image.fromarray(out),(i%4*512,i//4*512))
 old.save(p)
 subprocess.run(['python3','tools/sprites/key_out.py',str(p),f'assets/characters/orc_chief/anim/fresh_{c}.png','--key','ff00ff'],cwd=r,check=True)
 cmd=['python3','tools/sprites/check_sheet.py',f'assets/characters/orc_chief/anim/fresh_{c}.png','--frames',str(8 if c=='idle' else 12),'--fps',str(12 if c=='idle' else 24),'--key','ff00ff','--ref',str(b/'ref/orc_chief_idle_old.png'),'--out',str(b/'orc_chief')]
 result=subprocess.run(cmd,cwd=r,capture_output=True,text=True);(b/f'orc_chief/fresh_{c}_check.log').write_text(result.stdout+result.stderr);print(c,result.stdout);assert result.returncode==0
