"""Extra armor items requested after the v2 revision. No game catalog/code edits.
Rig art comes from edited worn figures; separately generated inventory icons are
catalog presentation only and NEVER a source for rig textures.
"""
from pathlib import Path
import json,re,math
import numpy as np
from scipy import ndimage as ndi
from scipy.optimize import minimize
from PIL import Image,ImageDraw,ImageFont
D=Path(__file__).resolve().parent;ROOT=D.parents[2];A=ROOT/'assets/characters/hero_rig'
STYLES=[('royal_armor','Giáp Hoàng Gia','#d5aa45'),('obsidian_armor','Giáp Hắc Thép','#b84945'),('frost_armor','Giáp Băng','#4baecb')]
j=json.loads((A/'joints.json').read_text());J=j['joints'];ORDER=j['order']
source=(ROOT/'scripts/battle/hero_rig.gd').read_text();block=source.split('const PARTS := {',1)[1].split('\n}',1)[0]
P={n:(joint,parent or None) for n,joint,parent in re.findall(r'"([^"]+)": \{"joint": "([^"]+)", "parent": "([^"]*)"\}',block) if n!='sword'}
assert set(P)=={p.stem for p in (A/'parts').glob('*.png')}
parts={n:Image.open(A/'parts'/f'{n}.png').convert('RGBA') for n in P}
parts['head']=Image.open(A/'heads/iron_helmet_normal.png').convert('RGBA')
ref=np.array(Image.open(D/'ref.png').convert('RGBA'));protect=np.array(Image.open(D/'protected_pixels.png'))>127
vis=np.array(Image.open(D/'cut_regions.png'));palette=np.random.default_rng(11).integers(40,240,(len(ORDER)+1,3),dtype=np.uint8)
labels=np.zeros((512,512),int)
for index in range(1,len(ORDER)+1):labels[np.all(vis[:,:,:3]==palette[index],axis=2)&(vis[:,:,3]>0)]=index
Y,X=np.mgrid[:512,:512]
def poly(points):
 im=Image.new('1',(512,512));ImageDraw.Draw(im).polygon(points,fill=1);return np.array(im,dtype=bool)
ROI={
 'torso':poly([(215,275),(293,280),(307,267),(330,288),(324,319),(308,337),(326,379),(219,380),(210,351),(211,317)]),
 'pelvis':poly([(198,317),(311,317),(329,395),(310,421),(266,408),(224,421),(188,400)]),
 'sword_arm_upper':poly([(287,246),(317,248),(342,277),(344,308),(313,319),(295,296)]),
 'shield_arm_upper':poly([(155,244),(211,245),(234,280),(232,315),(204,323),(154,300)])}
names=list(ROI);owner=np.full((512,512),-1,int)
for i,n in enumerate(names):owner[ROI[n]]=i
for i,n in enumerate(names):owner[labels==ORDER.index(n)+1]=i
# Use the edited iron-wearing figure as the registration reference for these item edits.
base=Image.open(D/'wear_iron_body_registered.png').convert('RGBA');base128=base.resize((128,128),Image.Resampling.LANCZOS)
mask128=np.array(Image.fromarray(np.uint8(protect)*255).resize((128,128),Image.Resampling.NEAREST))>127
baseline128=np.array(base128).astype(float)

def matrices(turn=None,angle=0):
 cache={}
 def mat(n):
  if n in cache:return cache[n]
  key,parent=P[n];m=mat(parent).copy() if parent else np.eye(3)
  if key==turn:
   x,y=J[key];r=math.radians(angle);c,s=math.cos(r),math.sin(r)
   m=m@np.array([[c,-s,x-c*x+s*y],[s,c,y-s*x-c*y],[0,0,1.]])
  cache[n]=m;return m
 for n in P:mat(n)
 return cache

def render(gear,turn=None,angle=0,fixture=False,margin=0):
 ms=matrices(turn,angle);out=Image.new('RGBA',(512+2*margin,512+2*margin))
 for n in ORDER:
  if n=='sword':
   if not fixture:continue
   im=Image.open(D/'fixtures/ref_sword.png').convert('RGBA');m=ms['sword_hand'].copy()
  else:
   im=parts[n].copy()
   if n in gear:im.alpha_composite(gear[n])
   if n in ('back_leg_lower','back_foot','front_leg_lower','front_foot'):
    im.alpha_composite(Image.open(A/'gear/climbing_boots'/f'{n}.png').convert('RGBA'))
   m=ms[n].copy()
  m[0,2]+=margin;m[1,2]+=margin;iv=np.linalg.inv(m)
  out.alpha_composite(im.transform(out.size,Image.Transform.AFFINE,tuple(iv[:2].ravel()),Image.Resampling.BICUBIC))
 return out

icons=Image.open(D/'inputs/new_item_icons_sheet.png').convert('RGBA');iw,ih=icons.size
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',17)
big=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',27)
card=Image.new('RGB',(1536,1050),'#ede5d7');draw=ImageDraw.Draw(card)
rotations=Image.new('RGB',(1536,13*280),'#ede5d7');rd=ImageDraw.Draw(rotations)
turns=['neck','shoulder_sword','elbow_sword','wrist_sword','shoulder_shield','elbow_shield','wrist_shield','hip_back','knee_back','ankle_back','hip_front','knee_front','ankle_front']
records=[]
for si,(item,title,color) in enumerate(STYLES):
 raw=Image.open(D/'inputs'/f'wear_{item}.png').convert('RGBA').resize((512,512),Image.Resampling.LANCZOS)
 small=raw.resize((128,128),Image.Resampling.LANCZOS)
 def loss(p):
  tx,ty,sx,sy=p
  im=small.transform((128,128),Image.Transform.AFFINE,(1/sx,0,-tx/(4*sx),0,1/sy,-ty/(4*sy)),Image.Resampling.BICUBIC)
  return float(np.abs(np.array(im).astype(float)-baseline128)[mask128].mean())
 opt=minimize(loss,[0,0,1,1],method='Powell',bounds=[(-16,16),(-16,16),(.9,1.1),(.9,1.1)],options={'maxiter':12,'xtol':.01})
 tx,ty,sx,sy=opt.x;wear=raw.transform((512,512),Image.Transform.AFFINE,(1/sx,0,-tx/sx,0,1/sy,-ty/sy),Image.Resampling.BICUBIC)
 wear.save(D/f'wear_{item}.png');wa=np.array(wear)
 changed=(np.max(np.abs(wa.astype(int)-ref.astype(int)),axis=2)>12)&(wa[:,:,3]>0)&~protect
 gear={};layers=[]
 for index,n in enumerate(names):
  allowed=ndi.distance_transform_edt(~(np.array(parts[n])[:,:,3]>0))<=24
  mask=changed&(owner==index)&allowed
  array=np.zeros_like(wa);array[mask]=wa[mask];im=Image.fromarray(array)
  dest=A/'gear'/item/f'{n}.png';dest.parent.mkdir(parents=True,exist_ok=True);im.save(dest);gear[n]=im
  layers.append({'part':n,'path':str(dest.relative_to(ROOT)),'pixels':int(mask.sum()),'outside_owner_plus24':int((mask&~allowed).sum())})
 # Inventory icons are generated AFTER the worn designs and never read above.
 cell=icons.crop((round(si*iw/3),0,round((si+1)*iw/3),ih));ca=np.array(cell)
 labs,count=ndi.label(ca[:,:,3]>127);sizes=np.bincount(labs.ravel());keep=np.isin(labs,np.where(sizes>=50)[0])&(labs!=0)
 keep=ndi.binary_dilation(keep,iterations=2)&(ca[:,:,3]>0);ca[~keep]=0;cell=Image.fromarray(ca);cell=cell.crop(cell.getbbox())
 scale=min(460/cell.width,460/cell.height);cell=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.LANCZOS)
 icon=Image.new('RGBA',(512,512));icon.alpha_composite(cell,((512-cell.width)//2,(512-cell.height)//2))
 iconpath=A/'item_icons'/f'{item}.png';iconpath.parent.mkdir(parents=True,exist_ok=True);icon.save(iconpath)
 assembled=render(gear,fixture=True);assembled.save(D/f'assembled_{item}.png')
 x=si*512;draw.rounded_rectangle((x+12,12,x+500,1038),radius=22,fill='#faf5e9',outline=color,width=4)
 draw.text((x+32,40),title,font=big,fill='#332822')
 thumb=icon.resize((300,300),Image.Resampling.LANCZOS);card.paste(thumb,(x+106,95),thumb)
 card.paste(assembled,(x,440),assembled);draw.text((x+32,995),item,font=font,fill='#55483d')
 joint_checks=[]
 for row,joint in enumerate(turns):
  for ai,angle in enumerate((-35,35)):
   col=si*2+ai;xx,yy=col*256,row*280
   im=render(gear,joint,angle,margin=64);thumb=im.resize((256,256),Image.Resampling.LANCZOS)
   rotations.paste(thumb,(xx,yy+24),thumb);rd.text((xx+4,yy+3),f'{item} {joint} {angle:+}',font=font,fill='#332822')
   alpha=np.array(im)[64:576,64:576,3]>127;jx,jy=J[joint];region=(X-jx)**2+(Y-jy)**2<=400
   holes=int((ndi.binary_fill_holes(alpha)&~alpha&region).sum())
   joint_checks.append({'joint':joint,'angle':angle,'gap_pixels_radius20':holes,'pass':holes==0})
 records.append({'id':item,'name':title,'slot':'armor','icon':str(iconpath.relative_to(ROOT)),
   'layers':layers,'alignment_tx_ty_sx_sy':list(map(float,opt.x)),'rotation_checks':joint_checks,
   'status':'visual_assets_only_not_registered_in_game_catalog','price':None,'unlock':None,
   'head_used_in_preview':'iron_helmet_normal','boots_used_in_preview':'climbing_boots'})
card.save(D/'new_items_grid.png');rotations.save(D/'new_items_rotation_grid.png')
(D/'new_items.json').write_text(json.dumps({'items':records,'integration':'Register these IDs in game data/code and map icons; source files remain inside the authorized art directory. No balance values invented.'},ensure_ascii=False,indent=2)+'\n')
print('3 new armor items; 12 rig layers; 3 inventory icons. Rotation gap counts:',{r['id']:sum(not c['pass'] for c in r['rotation_checks']) for r in records})
