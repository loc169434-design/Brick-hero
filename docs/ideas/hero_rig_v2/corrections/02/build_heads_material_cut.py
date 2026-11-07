"""Register edited heads; retain REF silhouette/neck and localize feature edits.
Only image-edit results are used for new art. No item icon is pasted into a head.
Called by build_v2.py; writes complete replacement heads, not helmet overlays.
"""
from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageFilter
from scipy import ndimage as ndi
from scipy.optimize import minimize
D=Path(__file__).resolve().parent;ROOT=D.parents[2];A=ROOT/'assets/characters/hero_rig'
def build(parts,ref,joints,round_number,result_dir=None):
 result_dir=D if result_dir is None else result_dir
 base=parts['head'].copy(); b=np.array(base);rr=np.array(ref);Y,X=np.mgrid[:512,:512]
 def poly(points):
  m=Image.new('1',(512,512));ImageDraw.Draw(m).polygon(points,fill=1);return np.array(m,dtype=bool)
 # Only facial interiors change; silhouette, ear, nose, jaw and neck remain original.
 eye=poly([(259,160),(286,161),(300,173),(305,194),(261,196),(255,184)])
 mouth=((X-279)/27)**2+((Y-209)/14)**2<=1
 editable=(eye|mouth)&(b[:,:,3]>0)
 # Protect nose even where it intersects the expression region.
 nose=poly([(295,182),(311,183),(313,203),(295,203)])
 editable &= ~nose
 neckx,necky=joints['neck']; alpha=b[:,:,3]>127
 contour=(alpha&~ndi.binary_erosion(alpha,iterations=3))&(Y>=necky-40)&(X>=242)
 throat=poly([(239,225),(263,237),(278,239),(281,250),(264,251),(239,236)])&alpha
 seam=contour|throat
 editable &= ~seam
 Image.fromarray(np.uint8(seam)*255).save(D/'fixtures/neck_chin_mask.png')
 Image.fromarray(np.uint8(editable)*255).save(D/'fixtures/expression_feature_mask.png')
 sheet=Image.open(D/'inputs/expression_edits.png').convert('RGBA');sw,sh=sheet.size
 expressions=['normal','blink','angry','hurt','happy','scared'];bare={}
 normal_cell=sheet.crop((0,0,round(sw/3),round(sh/2)))
 anchor=poly([(246,176),(292,174),(307,192),(310,225),(285,236),(252,220)])&alpha
 def transform(cell,p):
  tx,ty,sx,sy=p
  return cell.transform((512,512),Image.Transform.AFFINE,(1/sx,0,-tx/sx,0,1/sy,-ty/sy),Image.Resampling.BICUBIC)
 def error(p):
  a=np.array(transform(normal_cell,p)).astype(float)
  return float(np.abs(a[:,:,:3]-b[:,:,:3])[anchor].mean())
 # The sheet face edit is registered using its normal expression, then that one
 # transform is shared by all expression cells. No expression-specific warping.
 fit=None
 if not all((D/'inputs'/f'head_{e}_edit.png').exists() for e in expressions if e!='normal'):
  fit=minimize(error,[145,80,.4,.4],method='Powell',bounds=[(120,175),(55,115),(.30,.52),(.30,.52)],options={'maxiter':15})

 for i,e in enumerate(expressions):
  im=base.copy()
  if e!='normal':
   individual=D/'inputs'/f'head_{e}_edit.png'
   if individual.exists():
    edit=Image.open(individual).convert('RGBA');ea=np.array(edit)
    labs,count=ndi.label(ea[:,:,3]>127);counts=np.bincount(labs.ravel());counts[0]=0
    keep=labs==counts.argmax();ea[~keep]=0
    edit=Image.fromarray(ea);box=edit.getbbox()
    crop=edit.crop(box).resize((155,145),Image.Resampling.LANCZOS)
    aligned=Image.new('RGBA',(512,512));aligned.alpha_composite(crop,(174,105))
    # Register with immutable nose/ear/nape pixels, NOT changing eye/mouth pixels.
    fixed=poly([(216,184),(244,184),(246,217),(227,221)])|nose|throat
    fixed &= alpha
    def local_transform(p):return transform(aligned,p)
    def local_cost(p):
     a=np.array(local_transform(p)).astype(float)
     return float(np.abs(a[:,:,:3]-b[:,:,:3])[fixed].mean())
    adjustment=minimize(local_cost,[0,0,1,1],method='Powell',bounds=[(-8,8),(-8,8),(.94,1.06),(.94,1.06)],options={'maxiter':10,'xtol':.01})
    aligned=local_transform(adjustment.x);aa=np.array(aligned);out=np.array(im)
    transfer=editable&(aa[:,:,3]>200)
    out[transfer,:3]=aa[transfer,:3]
   else:
    cw,ch=sw/3,sh/2;col,row=i%3,i//3
    cell=sheet.crop((round(col*cw),round(row*ch),round((col+1)*cw),round((row+1)*ch)))
    aligned=transform(cell,fit.x)
    # Reject matte/background connected to the cell border before transferring edits.
    ca=np.array(cell);dark=ca[:,:,:3].astype(int).sum(axis=2)<240
    labs,count=ndi.label(dark);border=np.unique(np.concatenate([labs[0],labs[-1],labs[:,0],labs[:,-1]]));border=border[border!=0]
    background=np.isin(labs,border)
    bg=Image.fromarray(np.uint8(background)*255)
    bg=bg.transform((512,512),Image.Transform.AFFINE,(1/fit.x[2],0,-fit.x[0]/fit.x[2],0,1/fit.x[3],-fit.x[1]/fit.x[3]),Image.Resampling.NEAREST)
    transfer=editable&~(np.array(bg)>127)
    aa=np.array(aligned);out=np.array(im);out[transfer,:3]=aa[transfer,:3]
   im=Image.fromarray(out)
  bare[e]=im
 hats={};cap_masks={}
 for key,file in [('leather_helmet','leather_head_edit.png'),('iron_helmet','iron_head_edit.png')]:
  source=Image.open(D/'inputs'/file).convert('RGBA')
  pixels=np.array(source);components,n=ndi.label(pixels[:,:,3]>127)
  counts=np.bincount(components.ravel());counts[0]=0
  keep=components==counts.argmax();pixels[~keep]=0
  source=Image.fromarray(pixels);box=source.getbbox()
  crop=source.crop(box).resize((155,150),Image.Resampling.LANCZOS)
  im=Image.new('RGBA',(512,512));im.alpha_composite(crop,(174,100));a=np.array(im)
  # Keep ONLY the painted helmet material from the edited complete head.
  # No generated face/ear/jaw can survive beneath the original REF face.
  # The two material outlines were traced on the coherent edit, not on an item icon.
  if key=='iron_helmet':
   upper=poly([(165,90),(340,90),(340,185),(325,181),(313,176),(304,171),(298,176),(289,173),(282,160),(269,159),(252,163),(232,170),(215,178),(211,185),(199,190),(184,192),(175,188),(165,181)])
   rear=poly([(176,181),(214,176),(212,185),(210,193),(211,205),(219,224),(207,227),(188,217),(175,208)])
   rgb=a[:,:,:3].astype(int)
   steel=(rgb.max(axis=2)-rgb.min(axis=2)<45)&(rgb.mean(axis=2)>60)&(a[:,:,3]>127)
   ink=(rgb[:,:,0]<95)&(rgb[:,:,1]<80)&(rgb[:,:,2]<70)
   material=(upper|rear)&(steel|(ink&ndi.binary_dilation(steel,iterations=3)))
  else:
   material=poly([(165,90),(340,90),(340,182),(322,179),(313,172),(306,168),(294,163),(279,161),(260,162),(241,170),(223,180),(211,190),(206,202),(206,212),(194,217),(183,209),(179,200),(175,188),(165,186)])
  # REF face, ear and neck are one continuous region. Only a small fringe and
  # nape survive beneath the helmet; all crown/back tufts are removed first.
  face_keep=poly([(253,157),(282,157),(301,172),(319,192),(321,237),(291,250),(263,253),(238,239),(216,216),(215,188),(236,180),(246,179)])
  small_hair=(Y>=170)&(X>=205)&(X<=327)&(Y<=231)
  kept=(face_keep|small_hair|seam)&alpha
  base_pixels=b.copy();base_pixels[~kept]=0
  helmet_pixels=a.copy();helmet_pixels[~material]=0
  complete=Image.fromarray(base_pixels)
  complete.alpha_composite(Image.fromarray(helmet_pixels))
  # Preserve the seam exactly; it does not intersect cap material.
  a=np.array(complete);a[seam]=b[seam]
  a[Y>250]=0
  restore=kept&~material
  hats[key]=Image.fromarray(a)
  cap_masks[key]=material
  Image.fromarray(np.uint8(material)*255).save(result_dir/f'{key}_material_mask.png')
 hair_review=json.loads((D/'fixtures/hair_visual_review.json').read_text())
 heads={};checks=[]
 for helmet in ['bare','leather_helmet','iron_helmet']:
  for expression in expressions:
   if helmet=='bare':im=bare[expression].copy()
   else:
    out=np.array(hats[helmet]);expression_pixels=np.array(bare[expression])
    feature_region=editable&~cap_masks[helmet]
    out[feature_region]=expression_pixels[feature_region]
    # Also lock nose and common facial registration for every expression.
    out[nose&alpha]=b[nose&alpha]
    im=Image.fromarray(out)
   name=f'{helmet}_{expression}';heads[name]=im
   dest=A/'heads'/f'{name}.png';dest.parent.mkdir(parents=True,exist_ok=True);im.save(dest)
   a=np.array(im);delta=int(np.abs(a.astype(int)-b.astype(int))[seam].max())
   # Feature displacement is measured by exhaustive exact template comparison.
   f=np.array(bare[expression]);best=None
   for dy in range(-3,4):
    for dx in range(-3,4):
     shifted=np.roll(a,(dy,dx),(0,1));cost=float(np.abs(shifted[:,:,:3].astype(float)-f[:,:,:3])[editable|(nose&alpha)].mean())
     candidate=(cost,abs(dx)+abs(dy),dx,dy)
     if best is None or candidate<best:best=candidate
   # A provenance check: no REF crown-hair pixels are composited above forehead.
   # Raw edited cap is visually inspected as well; leather and hair share brown colors.
   forehead=160
   ref_hair_copied_above_forehead=int((restore&(Y<forehead)).sum()) if helmet!='bare' else 0
   invariant=0 if helmet=='bare' else int(np.any(a!=np.array(hats[helmet]),axis=2)[Y<160].sum())
   file='leather_head_edit.png' if helmet=='leather_helmet' else 'iron_head_edit.png'
   reviewed=hair_review['reviewed_inputs'].get(helmet,{})
   hair_pass=helmet=='bare' or (reviewed.get('no_hair_above_brim',False) and reviewed.get('sha256')==hashlib.sha256((D/'inputs'/file).read_bytes()).hexdigest() and invariant==0 and ref_hair_copied_above_forehead==0)
   cap_changed=0 if helmet=='bare' else int(np.any(a!=np.array(hats[helmet]),axis=2)[cap_masks[helmet]].sum())
   checks.append({'head':name,'cap_material_pixels_changed_across_expression':cap_changed,'hair_pass':bool(hair_pass),'upper_cap_pixels_changed':invariant,'neck_chin_max_rgba_error':delta,'feature_template_offset_px':[best[2],best[3]],'feature_template_mae':best[0],
      'ref_crown_hair_copied_above_forehead':ref_hair_copied_above_forehead,
      'pass_cap_unchanged':cap_changed==0,'pass_neck':delta<=6,'pass_features':abs(best[2])<=2 and abs(best[3])<=2})
 font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',15)
 grid=Image.new('RGB',(6*250,3*270),'#eee7da');draw=ImageDraw.Draw(grid)
 for row,h in enumerate(['bare','leather_helmet','iron_helmet']):
  for col,e in enumerate(expressions):
   im=heads[f'{h}_{e}'].crop((155,80,345,265)).resize((230,224),Image.Resampling.LANCZOS)
   x,y=col*250,row*270;grid.paste(im,(x+10,y+35),im);draw.text((x+8,y+9),h+' / '+e,font=font,fill='#392a22')
 grid.save(D/'heads_grid.png')
 (result_dir/f'head_metrics_round_{round_number:02}.json').write_text(json.dumps({'seam_region':'3px inner jaw contour in the 40px above neck, plus throat polygon; mask saved in fixtures. Mouth interior is excluded.',
 'feature_method':'Cross-correlate the same eye/mouth/nose template for each expression across cap variants; search +-3 pixels.',
 'hair_method':'Track REF crown-hair provenance above forehead y160; additionally inspect actual edited cap silhouette. This is not a semantic hair classifier.',
 'checks':checks},indent=2)+'\n')
 return heads,checks
