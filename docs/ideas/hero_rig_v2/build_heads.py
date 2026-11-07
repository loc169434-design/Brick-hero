"""Complete, coherent head images. Latest user instruction: fit size, do not collage faces.
Every generated variant is a single image edit. Only transparent margin removal and
whole-image resizing/translation occur here. bare_normal stays the direct REF cut.
"""
from pathlib import Path
import json,hashlib
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from scipy import ndimage as ndi
D=Path(__file__).resolve().parent;ROOT=D.parents[2];A=ROOT/'assets/characters/hero_rig'
EXPRESSIONS=['normal','blink','angry','hurt','happy','scared']

def build(parts,ref,joints,round_number,result_dir=None):
 result_dir=D if result_dir is None else result_dir
 base=parts['head'].copy()
 reference=np.array(base);component,n=ndi.label(reference[:,:,3]>127);counts=np.bincount(component.ravel());counts[0]=0
 main=component==counts.argmax();ys,xs=np.where(main)
 # Low-alpha stray pixels outside the actual head must not determine its fitted size.
 bbox=(int(xs.min())-2,int(ys.min())-2,int(xs.max())+3,int(ys.max())+1)
 width=bbox[2]-bbox[0];height=bbox[3]-bbox[1]
 heads={};checks=[]
 Y,X=np.mgrid[:512,:512]
 for helmet in ['bare','leather_helmet','iron_helmet']:
  for expression in EXPRESSIONS:
   name=f'{helmet}_{expression}';source=None
   if name=='bare_normal':
    im=base.copy();mode='direct_ref_cut';source_box=bbox
   else:
    if helmet=='bare':source=D/'inputs'/f'head_{expression}_edit.png'
    else:
     material='leather' if helmet=='leather_helmet' else 'iron'
     source=D/'inputs'/(f'{material}_head_edit.png' if expression=='normal' else f'whole_{material}_{expression}.png')
    assert source.exists(),f'Missing complete-head image edit: {source}'
    image=Image.open(source).convert('RGBA');a=np.array(image)
    assert (a[:,:,3]==0).mean()>.05,f'Head input lacks transparency: {source}'
    labels,count=ndi.label(a[:,:,3]>127);sizes=np.bincount(labels.ravel());sizes[0]=0
    main=labels==sizes.argmax()
    # Retain antialiasing connected to the one complete head, remove isolated specks.
    keep=ndi.binary_dilation(main,iterations=2)&(a[:,:,3]>0);a[~keep]=0
    image=Image.fromarray(a);source_box=image.getbbox();image=image.crop(source_box)
    fitted_height=height if helmet=='bare' else height+4
    image=image.resize((width,fitted_height),Image.Resampling.LANCZOS)
    im=Image.new('RGBA',(512,512));im.alpha_composite(image,(bbox[0],bbox[3]-fitted_height))
    mode='single_complete_image_edit'
   path=A/'heads'/f'{name}.png';path.parent.mkdir(parents=True,exist_ok=True);im.save(path);heads[name]=im
   alpha=np.array(im)[:,:,3];box=im.getbbox()
   size_pass=(mode=='direct_ref_cut') or (im.size==(512,512) and im.mode=='RGBA' and 0<=box[0]-bbox[0]<=2 and 0<=bbox[2]-box[2]<=2 and 0<=bbox[3]-box[3]<=2 and height-3<=box[3]-box[1]<=height+4)
   checks.append({'head':name,'mode':mode,'face_collage':False,'pass_size':bool(size_pass),
     'source':str(source.relative_to(D)) if source else 'REF cut: parts/head.png',
     'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest() if source else hashlib.sha256(base.tobytes()).hexdigest(),
     'source_crop':list(source_box),'fit_reference_rectangle':list(bbox),'output_bbox':list(box),'neck_anchor':joints['neck'],
     'acceptance':'Latest user clarification: complete coherent face/head; size and placement only. Old pixel-equality constraints are not forced by patching REF.',
     'hair_review':'Visual inspection of full edited head; no separate hair/face/helmet layers exist.'})
 font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',15)
 grid=Image.new('RGB',(1500,810),'#eee7da');draw=ImageDraw.Draw(grid)
 for row,helmet in enumerate(['bare','leather_helmet','iron_helmet']):
  for col,expression in enumerate(EXPRESSIONS):
   im=heads[f'{helmet}_{expression}'].crop((155,80,345,265)).resize((230,224),Image.Resampling.LANCZOS)
   x,y=col*250,row*270;grid.paste(im,(x+10,y+35),im);draw.text((x+8,y+9),helmet+' / '+expression,font=font,fill='#392a22')
 grid.save(D/'heads_grid.png')
 (result_dir/f'head_metrics_round_{round_number:02}.json').write_text(json.dumps({'mode':'whole_head_size_only_per_latest_user_request','no_face_collage':True,'checks':checks},indent=2)+'\n')
 assert all(c['pass_size'] for c in checks)
 return heads,checks
