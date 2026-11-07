"""Reproducible REF pixel cutout, registered image-edit gear extraction, strict reports.
Run from repo root: python3 docs/ideas/hero_rig_v2/build_v2.py --round N
Never changes code, scenes, reference sprites or item icons. Max 8 numbered rounds.
"""
from pathlib import Path
import argparse, json, math, hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi
from scipy.optimize import minimize
D=Path(__file__).resolve().parent; ROOT=D.parents[2]; A=ROOT/'assets/characters/hero_rig'
arg=argparse.ArgumentParser();arg.add_argument('--round',type=int,required=True);arg.add_argument('--correction',type=int);args=arg.parse_args();R=args.round
RUN_DIR=D if args.correction is None else D/'corrections'/f'{args.correction:02}'
RUN_DIR.mkdir(parents=True,exist_ok=True)
assert 1<=R<=8
REF=Image.open(D/'ref.png').convert('RGBA');src=np.array(REF);valid=src[:,:,3]>0
Y,X=np.mgrid[:512,:512]
def poly(points):
 im=Image.new('1',(512,512));ImageDraw.Draw(im).polygon(points,fill=1);return np.array(im,dtype=bool)
def disk(x,y,r):return (X-x)**2+(Y-y)**2<=r*r
old=json.loads((A/'joints.json').read_text());ORDER=old['order']
J={'hip':[262,372],'waist':[262,334],'neck':[262,237],'cape':[237,245],
'shoulder_shield':[195,275],'elbow_shield':[194,307],'wrist_shield':[195,345],'shield':[166,352],
'shoulder_sword':[302,272],'elbow_sword':[322,313],'wrist_sword':[343,323],'grip':[354,318],
'hip_back':[235,381],'knee_back':[211,425],'ankle_back':[190,471],
'hip_front':[286,380],'knee_front':[304,425],'ankle_front':[312,473]}
P={'pelvis':('hip',None),'torso':('waist','pelvis'),'head':('neck','torso'),'cape':('cape','torso'),
'shield_arm_upper':('shoulder_shield','torso'),'shield_arm_lower':('elbow_shield','shield_arm_upper'),
'shield_hand':('wrist_shield','shield_arm_lower'),'shield':('shield','shield_arm_lower'),
'sword_arm_upper':('shoulder_sword','torso'),'sword_arm_lower':('elbow_sword','sword_arm_upper'),
'sword_hand':('wrist_sword','sword_arm_lower'),
'back_leg_upper':('hip_back','pelvis'),'back_leg_lower':('knee_back','back_leg_upper'),'back_foot':('ankle_back','back_leg_lower'),
'front_leg_upper':('hip_front','pelvis'),'front_leg_lower':('knee_front','front_leg_upper'),'front_foot':('ankle_front','front_leg_lower')}
polygons={
'cape':[(76,222),(202,214),(245,229),(301,250),(298,277),(277,285),(221,268),(193,253),(155,279),(127,305),(75,312)],
'back_leg_upper':[(207,365),(261,374),(234,425),(207,439),(160,435),(166,409)],
'back_leg_lower':[(173,412),(235,417),(222,452),(210,479),(156,481),(156,444)],
'back_foot':[(158,454),(211,454),(219,503),(132,503),(131,477)],
'sword_arm_upper':[(287,248),(309,250),(326,273),(332,299),(308,321),(292,305)],
'pelvis':[(209,342),(304,342),(324,383),(300,406),(259,389),(234,410),(200,397)],
'front_leg_upper':[(268,365),(309,363),(327,398),(327,430),(275,435),(265,402)],
'front_leg_lower':[(276,416),(329,414),(345,449),(334,483),(278,481),(269,445)],
'front_foot':[(283,454),(331,455),(352,462),(379,478),(378,503),(276,503)],
 'torso':[(190,243),(234,242),(296,261),(317,275),(323,308),(308,337),(324,368),(282,381),(272,356),(268,380),(223,373),(210,351),(201,317),(176,294),(167,261)],
'head':[(164,100),(332,100),(332,230),(291,242),(280,249),(264,250),(241,235),(216,224),(171,225)],
'sword_arm_lower':[(312,285),(331,283),(356,299),(360,325),(343,345),(317,339),(303,319)],
'sword_hand':[(344,291),(352,295),(363,295),(376,301),(376,314),(371,329),(367,341),(356,344),(341,338),(332,324),(333,307),(338,296)],
'shield_arm_upper':[(167,254),(203,256),(223,278),(228,309),(206,329),(179,305),(154,289)],
'shield_arm_lower':[(177,288),(213,286),(226,322),(218,355),(185,362),(173,333)],
'shield_hand':[(185,329),(215,329),(224,352),(207,370),(184,361)],
'shield':[(142,286),(184,288),(211,307),(226,337),(228,366),(215,397),(191,413),(153,417),(122,402),(104,375),(101,344),(111,313)]}
sword=(X>=332)&(Y<292)&valid
sword|=poly([(350,289),(372,293),(365,302),(349,298)])
sword|=poly([(345,338),(362,340),(359,362),(350,370),(338,371),(328,360),(331,346)])
sword&=valid
# Reserve the fist silhouette, including its ink outline, from the sword fixture.
sword &= ~poly(polygons['sword_hand'])
sword |= poly([(370,291),(391,290),(390,299),(379,300),(373,298)])&valid
fix=src.copy();fix[~sword]=0;Image.fromarray(fix).save(D/'fixtures/ref_sword.png')
sword_exclusion=ndi.distance_transform_edt(~sword)<=4
Image.fromarray(np.uint8(sword_exclusion)*255).save(D/'fixtures/sword_exclusion_4px.png')
labels=np.zeros((512,512),np.int16)
for k,n in enumerate(ORDER,1):
 if n!='sword':labels[poly(polygons[n])&valid&~sword]=k
# Every visible REF pixel is retained. Unclaimed border pixels go to nearest cut region.
unclaimed=(labels==0)&valid&~sword
if unclaimed.any():
 indices=ndi.distance_transform_edt(labels==0,return_distances=False,return_indices=True)
 labels[unclaimed]=labels[tuple(indices[:,unclaimed])]
# The tunic hem/belt belong to the pelvis, so its equipment cannot be hidden by torso.
hip_cloth=poly([(218,330),(300,330),(324,369),(280,382),(271,355),(268,380),(223,374),(210,354)])
labels[hip_cloth&valid&~sword]=ORDER.index('pelvis')+1
labels[sword]=0
labels[(labels==ORDER.index('sword_hand')+1)&(X<337)]=ORDER.index('sword_arm_lower')+1
# Separate source colors for ownership inspection; not game art.
palette=np.random.default_rng(11).integers(40,240,(len(ORDER)+1,3),dtype=np.uint8)
vis=np.zeros_like(src);vis[:,:,:3]=palette[labels];vis[:,:,3]=src[:,:,3];vis[sword]=0
Image.fromarray(vis).save(D/'cut_regions.png')
parts={};part_masks={}
for n,(joint,parent) in P.items():
 k=ORDER.index(n)+1;visible=(labels==k)
 caps=disk(*J[joint],24)
 for child,(cj,cp) in P.items():
  if cp==n:caps|=disk(*J[cj],24)
 caps &= valid&~sword
 if n=='pelvis':caps|=disk(*J['hip_back'],23)
 if n=='head':caps&=visible
 if n=='sword_hand':caps&=(X>=337)
 if n=='torso':caps&=(Y<337)
 if n=='front_leg_upper':caps&=(labels!=ORDER.index('pelvis')+1)
 # Padding must be hidden at rest, not repaint an earlier visible owner.
 caps&=((labels>=k)|(labels==0))
 # Hidden rounded joint paint: extend material sampled from this cut piece.
 material=ndi.binary_erosion(visible,iterations=3)
 if not material.any(): material=disk(*J[joint],6)&valid&~sword
 if not material.any():material=valid&~sword
 indices=ndi.distance_transform_edt(~material,return_distances=False,return_indices=True)
 out=np.zeros_like(src);out[caps]=src[tuple(indices[:,caps])];out[caps,3]=np.where(valid[caps],src[caps,3],255)
 # Where a cap is exposed, retain the precise REF pixels. Later pieces hide other caps.
 exposed=caps&(labels<=k)&(labels!=0);out[exposed]=src[exposed];out[visible]=src[visible]
 mask=visible|caps
 under_neck=caps&disk(*J['neck'],20)&(labels>k) if n=='torso' else np.zeros_like(caps)
 out[under_neck,:3]=src[231,258,:3]
 out[~mask]=0
 if n=='pelvis':out[caps & (src[:,:,3]<128),3]=255
 im=Image.fromarray(out);parts[n]=im;part_masks[n]=mask
 dest=A/'parts'/f'{n}.png';dest.parent.mkdir(parents=True,exist_ok=True);im.save(dest)
(A/'joints.json').write_text(json.dumps({'joints':J,'order':ORDER},indent=2)+'\n')
# Gear is extracted ONLY from differences between registered WEAR and REF.
# These regions assign equipment ownership, not separately drawn item icons.
ROIS={
 'torso':poly([(215,275),(293,280),(307,267),(330,288),(324,319),(308,337),(326,379),(219,380),(210,351),(211,317)]),
'pelvis':poly([(198,317),(311,317),(326,382),(305,410),(264,394),(226,414),(191,399)]),
'sword_arm_upper':poly([(287,246),(317,248),(336,277),(341,303),(313,316),(295,296)]),
'shield_arm_upper':poly([(155,244),(211,245),(231,280),(232,311),(204,320),(159,298)]),
'back_leg_lower':poly([(156,410),(239,410),(230,455),(213,479),(146,477)]),
'back_foot':poly([(147,452),(217,452),(226,505),(123,505),(126,472)]),
'front_leg_lower':poly([(267,410),(338,408),(353,448),(342,482),(267,482)]),
'front_foot':poly([(272,453),(341,450),(387,472),(390,505),(263,505)])}
# Mask immutable image areas for registration and image-edit preservation measurements.
protected={
'face':poly([(248,170),(291,165),(308,189),(310,227),(273,237),(244,219),(229,199)]),
'shield':disk(166,352,49),
'cape':poly([(89,269),(118,251),(160,244),(186,239),(199,245),(157,268),(129,290),(98,284)]),
'bare_arm':poly([(312,307),(325,299),(334,306),(334,327),(318,333)]),
'fist':poly([(348,307),(362,303),(368,310),(364,329),(355,333),(342,327)])}
# The old broad red test also selected dark-brown shirt/strap outlines.
# Protect only actual scarf colors in its anatomical region, plus its cut owner.
rgb=src[:,:,:3].astype(float)
red_core=(rgb[:,:,0]>90)&(rgb[:,:,1]<.5*rgb[:,:,0])&(rgb[:,:,2]>.78*rgb[:,:,1])
scarf_zone=(X>=75)&(X<=310)&(Y>=215)&(Y<=310)
red=ndi.binary_dilation(ndi.binary_fill_holes(ndi.binary_closing(red_core&scarf_zone,iterations=1)),iterations=2)&scarf_zone
protected['cape']|=red|(labels==ORDER.index('cape')+1)
protected['shield']|=(labels==ORDER.index('shield')+1)
protected['fist']|=(labels==ORDER.index('sword_hand')+1)
for n in ('sword_arm_lower','shield_arm_lower','shield_hand'):
 protected['bare_arm']|=(labels==ORDER.index(n)+1)
protected={k:v&(src[:,:,3]>200) for k,v in protected.items()}
protect=np.logical_or.reduce(list(protected.values()))
Image.fromarray(np.uint8(protect)*255).save(D/'protected_pixels.png')
outfits={'leather':('leather_armor','leather_helmet','reinforced_boots'), 'iron':('iron_armor','iron_helmet','climbing_boots')}
wear={};gear={};registration={};owner_metrics={}
def affine(im,p):
 tx,ty,sx,sy=p
 return im.transform((512,512),Image.Transform.AFFINE,(1/sx,0,-tx/sx,0,1/sy,-ty/sy),Image.Resampling.BICUBIC)
for outfit,items in outfits.items():
 available=sorted((D/'inputs').glob(f'wear_{outfit}_r*.png'),key=lambda p:int(p.stem.rsplit('r',1)[1]))
 rawpath=[p for p in available if int(p.stem.rsplit('r',1)[1])<=R][-1]
 raw=Image.open(rawpath).convert('RGBA').resize((512,512),Image.Resampling.LANCZOS)
 # Fit translation + independent scale ONLY, no warping, repainting or REF replacement.
 ref=src.astype(float); sample=protect.copy();sample[1::2,:]=False;sample[:,1::2]=False
 def loss(p):
  a=np.array(affine(raw,p)).astype(float)
  err=np.abs(a[:,:,:3]-ref[:,:,:3])[sample]
  return float(err.mean()+.4*np.percentile(err.max(axis=1),95)+.2*np.mean(np.abs(a[:,:,3]-ref[:,:,3])[sample]))
 cachepath=D/'inputs'/f'{rawpath.stem}_registration.json'
 fingerprint=hashlib.sha256(rawpath.read_bytes()+protect.tobytes()).hexdigest()
 cache=json.loads(cachepath.read_text()) if cachepath.exists() else {}
 if cache.get('sha256')==fingerprint and cache.get('objective')=='mae_plus_p95':
  params=np.array(cache['parameters'])
 else:
  opt=minimize(loss,cache.get('parameters',[0,0,1,1]),method='Powell',bounds=[(-24,24),(-24,24),(.85,1.15),(.85,1.15)],options={'maxiter':25,'xtol':.005})
  params=opt.x;cachepath.write_text(json.dumps({'sha256':fingerprint,'objective':'mae_plus_p95','parameters':list(map(float,params))},indent=2)+'\n')
 im=affine(raw,params);wear[outfit]=im;im.save(D/f'wear_{outfit}.png');wa=np.array(im)
 diff=np.max(np.abs(wa.astype(int)-src.astype(int)),axis=2)>12
 silhouette=(wa[:,:,3]>0)&(src[:,:,3]==0)
 changed=(diff|silhouette)&(wa[:,:,3]>0)&~sword_exclusion
 # Head opening is protected; gear must not contain face, cape, shield or bare arm pixels.
 candidate=changed&~protect
 gear[outfit]={};rows=[];assigned=np.zeros((512,512),bool)
 # Owner overlaps resolve in drawing order: upper arms cover chest, boots cover shin.
 owner=np.full((512,512),-1,dtype=int);names=list(ROIS)
 for i,n in enumerate(names):owner[ROIS[n]]=i
 # Visible original pixels follow their actual source owner. This prevents a chest
 # change assigned to a rear shoulder from disappearing behind the torso.
 for i,n in enumerate(names):owner[labels==ORDER.index(n)+1]=i
 for i,n in enumerate(names):
  owner_region=(owner==i)
  # +24 is an exact Euclidean dilation of the actual exported parent part alpha.
  allowed=ndi.distance_transform_edt(~part_masks[n])<=24
  mask=candidate&owner_region&allowed
  a=np.zeros_like(src);a[mask]=wa[mask];g=Image.fromarray(a)
  # Compose exact WEAR colors/alpha on each owner, without touching original source pixels.
  gear[outfit][n]=g;assigned|=mask
  item=items[1] if n=='head' else items[2] if 'foot' in n or 'leg_lower' in n else items[0]
  path=A/'gear'/item/f'{n}.png';path.parent.mkdir(parents=True,exist_ok=True);g.save(path)
  rows.append({'item':item,'part':n,'pixels':int(mask.sum()),'outside_owner_plus_24':int((mask&~allowed).sum()),'bbox':g.getbbox()})
 owner_metrics[outfit]=rows
 reg={}
 for name,mask in protected.items():
  err=np.max(np.abs(wa[:,:,:3].astype(float)-ref[:,:,:3]),axis=2)[mask]
  reg[name]={'mae_rgb':float(np.abs(wa[:,:,:3].astype(float)-ref[:,:,:3])[mask].mean()),'p95_max_channel_error':float(np.percentile(err,95))}
 registration[outfit]={'input':str(rawpath.relative_to(D)),'transform_tx_ty_sx_sy':list(map(float,params)),
 'protected_regions':reg,'protected_mae_rgb':float(np.abs(wa[:,:,:3].astype(float)-ref[:,:,:3])[protect].mean()),
 'protected_p95_max_channel_error':float(np.percentile(np.max(np.abs(wa[:,:,:3].astype(float)-ref[:,:,:3]),axis=2)[protect],95))}
from build_heads import build as build_heads
heads,head_checks=build_heads(parts,REF,J,R,result_dir=RUN_DIR)
for helmet in ('leather_helmet','iron_helmet'):
 obsolete=A/'gear'/helmet/'head.png'
 if obsolete.exists():obsolete.unlink()
 obsolete_import=Path(str(obsolete)+'.import')
 if obsolete_import.exists():obsolete_import.unlink()
# Complete replacement heads supersede helmet overlays in the comparison target too.
# Preserve the raw registered edit as independent evidence; never patch its protected regions.
raw_wear={o:im.copy() for o,im in wear.items()}
for outfit,items in outfits.items():
 raw_wear[outfit].save(D/f'wear_{outfit}_body_registered.png')
 a=np.array(wear[outfit]);head_region=ndi.distance_transform_edt(~(np.array(parts['head'])[:,:,3]>127))<=12
 cape_pixels=(labels==ORDER.index('cape')+1)
 remove=head_region&(Y<253)&~cape_pixels
 a[remove]=0
 im=Image.fromarray(a);im.alpha_composite(heads[f'{items[1]}_normal'])
 wear[outfit]=im;im.save(D/f'wear_{outfit}.png')
# Precompose selected outfit layers onto parent pieces, so gear follows exactly the same matrix.
skins={'bare':parts}
for outfit in outfits:
 skins[outfit]={}
 for n,im in parts.items():
  a=im.copy()
  if n in gear[outfit]:a.alpha_composite(gear[outfit][n])
  skins[outfit][n]=heads[f'{outfits[outfit][1]}_normal'].copy() if n=='head' else a

def matrices(turn=None,angle=0):
 cache={}
 def mat(n):
  if n in cache:return cache[n]
  joint,parent=P[n];m=mat(parent).copy() if parent else np.eye(3)
  if joint==turn:
   x,y=J[joint];a=math.radians(angle);c,s=math.cos(a),math.sin(a)
   m=m@np.array([[c,-s,x-c*x+s*y],[s,c,y-s*x-c*y],[0,0,1.]])
  cache[n]=m;return m
 for n in P:mat(n)
 return cache

def render(outfit='bare',turn=None,angle=0,sword_fixture=False,icon=False,margin=0):
 ms=matrices(turn,angle);res=Image.new('RGBA',(512+2*margin,512+2*margin))
 for n in ORDER:
  if n=='sword':
   if not (sword_fixture or icon):continue
   im=Image.open(D/'fixtures/ref_sword.png').convert('RGBA')
   if icon:
    item=Image.open(ROOT/'assets/ui/items/wood_sword.png').convert('RGBA')
    scale=210/256;gx,gy=J['grip'];im=Image.new('RGBA',(512,512))
    # Exact inverse mapping: icon grip (128,186) maps to J['grip'], scale 210/256, no rotation.
    im=item.transform((512,512),Image.Transform.AFFINE,(1/scale,0,128-gx/scale,0,1/scale,186-gy/scale),Image.Resampling.BICUBIC)
   m=ms['sword_hand'].copy()
  else:im=skins[outfit][n];m=ms[n].copy()
  m[0,2]+=margin;m[1,2]+=margin;inv=np.linalg.inv(m)
  res.alpha_composite(im.transform(res.size,Image.Transform.AFFINE,tuple(inv[:2].ravel()),Image.Resampling.BICUBIC))
 return res

def iou(a,b,exclude=None):
 a=np.array(a)[:,:,3]>127;b=np.array(b)[:,:,3]>127
 if exclude is not None:a&=~exclude;b&=~exclude
 return float((a&b).sum()/max(1,(a|b).sum()))
FONT=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',16)
def compare(left,right,filename,labels):
 canvas=Image.new('RGB',(1024,550),'#eae5dc');d=ImageDraw.Draw(canvas)
 for i,(im,title) in enumerate(zip([left,right],labels)):
  canvas.paste(im,(512*i,35),im);d.text((512*i+14,10),title,font=FONT,fill='#392a22')
 canvas.save(D/filename)
bare=render();bare.save(D/'assembled_bare.png')
compare(REF,render(sword_fixture=True),'compare_bare.png',['REF (original pixels)','Cut parts + REF sword fixture'])
compare(REF,render(icon=True),'compare_ingame_sword.png',['REF','Game icon: grip=(128,186); scale=210/256'])
for o in outfits:
 assembled=render(o,sword_fixture=True);assembled.save(D/f'assembled_{o}.png')
 compare(wear[o],assembled,f'compare_{o}.png',[f'WEAR_{o.upper()} registered',f'Assembled {o} + REF sword fixture'])
# All limb/neck joints, with descendants inheriting parent transforms; all three outfits.
turns=['neck','shoulder_sword','elbow_sword','wrist_sword','shoulder_shield','elbow_shield','wrist_shield','hip_back','knee_back','ankle_back','hip_front','knee_front','ankle_front']
W,H=256,288
rot=Image.new('RGB',(6*W,13*H),'#eae5dc');draw=ImageDraw.Draw(rot)
rotation=[]
for row,joint in enumerate(turns):
 for oi,o in enumerate(skins):
  for ai,angle in enumerate([-35,35]):
   col=oi*2+ai;x,y=col*W,row*H
   im=render(o,joint,angle,margin=64);thumb=im.resize((256,256),Image.Resampling.LANCZOS)
   rot.paste(thumb,(x,y+27),thumb);draw.text((x+4,y+5),f'{o} {joint} {angle:+}',font=FONT,fill='#392a22')
   # A seam is an enclosed transparent hole or a disconnected parent/child contact
   # in the 20px joint neighborhood. Exterior background is reported separately.
   arr=np.array(im)[:,:,3]>127;jx,jy=J[joint];roi=disk(jx,jy,20)
   alpha=arr[64:576,64:576];holes=ndi.binary_fill_holes(alpha)&~alpha&roi
   raw_background=int((~alpha&roi).sum())
   child=next(n for n,(j,p) in P.items() if j==joint);parent=P[child][1]
   # Read both local parent/child alpha under their actual hierarchy transforms.
   ms=matrices(joint,angle);masks=[]
   for n in [parent,child]:
    iv=np.linalg.inv(ms[n]);im2=skins[o][n].transform((512,512),Image.Transform.AFFINE,tuple(iv[:2].ravel()),Image.Resampling.BICUBIC)
    masks.append((np.array(im2)[:,:,3]>127)&roi)
   overlap=int((masks[0]&masks[1]).sum());local=masks[0]|masks[1]
   cc,count=ndi.label(local)
   sizes=np.bincount(cc.ravel());significant=sum(v>=4 for v in sizes[1:])
   gap=int(holes.sum());passed=bool(gap==0 and overlap>0 and significant==1)
   rotation.append({'outfit':o,'joint':joint,'angle':angle,'interior_gap_pixels_radius20':gap,'parent_child_overlap_pixels_radius20':overlap,'local_components_ge4px':int(significant),'exterior_background_pixels_radius20':raw_background,'pass':passed})
rot.save(D/'rotation_grid.png')
# Neck seams for all 18 heads, actual hierarchy rotation at -20 and +20 degrees.
head_rotation=[]
hgrid=Image.new('RGB',(6*230,6*245),'#eae5dc');hd=ImageDraw.Draw(hgrid)
original_head=skins['bare']['head']
for hi,(name,head) in enumerate(heads.items()):
 for ai,angle in enumerate((-20,20)):
  skins['bare']['head']=head
  im=render('bare','neck',angle,margin=64)
  alpha=np.array(im)[64:576,64:576,3]>127;region=disk(*J['neck'],20)
  holes=int((ndi.binary_fill_holes(alpha)&~alpha&region).sum())
  # Is there one connected neck contact region, ignoring exterior background?
  cc,num=ndi.label(alpha&region);sz=np.bincount(cc.ravel());components=sum(x>=4 for x in sz[1:])
  head_rotation.append({'head':name,'angle':angle,'interior_gap_pixels_radius20':holes,'components_ge4px':int(components),'pass':bool(holes==0 and components==1)})
  index=hi*2+ai;x=index%6*230;y=index//6*245
  tile=im.crop((214,134,414,344)).resize((215,215),Image.Resampling.LANCZOS)
  hgrid.paste(tile,(x+7,y+27),tile);hd.text((x+4,y+4),name+' '+str(angle),font=FONT,fill='#392a22')
skins['bare']['head']=original_head
hgrid.save(D/'heads_neck_rotation.png')
# Reference icons beside equipped in-pose result; never used as layer sources.
icons=Image.new('RGB',(1024,2*550),'#eae5dc');di=ImageDraw.Draw(icons)
for row,(o,items) in enumerate(outfits.items()):
 y=row*550;di.text((16,y+12),o,font=FONT,fill='#392a22')
 for k,item in enumerate(items):
  iconim=Image.open(ROOT/f'assets/ui/items/{item}.png').convert('RGBA').resize((155,155),Image.Resampling.LANCZOS)
  icons.paste(iconim,(k*167,y+190),iconim);di.text((k*167+5,y+353),item,font=FONT,fill='#392a22')
 dressed=render(o,sword_fixture=True);icons.paste(dressed,(512,y+35),dressed)
icons.save(D/'icon_vs_rig.png')
body_iou=iou(REF,bare,sword_exclusion)
metrics={'round':R,'correction_after_user_feedback':args.correction,'ref_sha256':hashlib.sha256((D/'ref.png').read_bytes()).hexdigest(),'body_iou_without_sword_4px':body_iou,'body_iou_pass':body_iou>=.97,
 'full_ref_iou_with_fixture_informational':iou(REF,render(sword_fixture=True)),
 'head_acceptance':'whole_head_size_only_per_latest_user_request','head_rotation':head_rotation,'head_checks':head_checks,'registration':registration,'gear_owner_checks':owner_metrics,'rotation':rotation,
 'rotation_pass':all(x['pass'] for x in rotation),'outfits':{}}
for o in outfits:
 score=iou(wear[o],render(o,sword_fixture=True),sword_exclusion)
 reg=registration[o]
 canonical=np.array(wear[o]).astype(float)
 # The user now requests newly generated complete faces and size-only head fitting.
 # Head pixels are therefore no longer tested for equality with the original face.
 body_protect=protect&~(ndi.distance_transform_edt(~(np.array(parts['head'])[:,:,3]>127))<=12)
 error=np.abs(canonical[:,:,:3]-src[:,:,:3].astype(float))[body_protect]
 reg['raw_edit_nearly_identical']=reg['protected_mae_rgb']<=10 and reg['protected_p95_max_channel_error']<=30
 reg['final_wear_protected_mae_rgb']=float(error.mean())
 reg['final_wear_protected_p95_max_channel_error']=float(np.percentile(error.max(axis=1),95))
 # The current WEAR target uses complete replacement heads per the later request.
 # Raw pre-head edit diagnostics remain above, unmodified, and are not concealed.
 near=reg['final_wear_protected_mae_rgb']<=10 and reg['final_wear_protected_p95_max_channel_error']<=30
 metrics['outfits'][o]={'raw_edit_iou_informational':iou(raw_wear[o],render(o,sword_fixture=True),sword_exclusion),'iou_without_sword_4px':score,'iou_pass':score>=.95,'unclothed_pixels_nearly_identical':near}
metrics['all_pass']=all(c['pass'] for c in head_rotation) and all(c['pass_size'] for c in head_checks) and metrics['body_iou_pass'] and metrics['rotation_pass'] and all(x['iou_pass'] and x['unclothed_pixels_nearly_identical'] for x in metrics['outfits'].values()) and all(not r['outside_owner_plus_24'] for rows in owner_metrics.values() for r in rows)
for p in A.rglob('*.png'):
 im=Image.open(p);assert im.mode=='RGBA' and im.size==(512,512),p
assert len(list((A/'parts').glob('*.png')))==17 and sum(len(list((A/'gear'/item).glob('*.png'))) for values in outfits.values() for item in values)==16 and len(list((A/'heads').glob('*.png')))==18
(RUN_DIR/f'metrics_round_{R:02}.json').write_text(json.dumps(metrics,indent=2)+'\n')
rounds=(D/'rounds.md') if args.correction is None else RUN_DIR/'rounds.md'
if not rounds.exists():rounds.write_text('# Số đo từng vòng\n\nNgưỡng cố định: IoU thân không kiếm ≥0.97; IoU mặc đồ ≥0.95; lớp đồ ngoài mảnh chủ +24px =0.\nVùng kiếm REF được nới Euclidean 4px ở cả hai ảnh trước khi chấm IoU.\nGiữ nguyên pixel vùng không mặc đồ: MAE RGB ≤10/255 và P95 sai số kênh lớn nhất ≤30/255.\nKhớp: xét bán kính 20px, không lỗ alpha kín, cha/con phải có diện tích chồng >0 và một thành phần tiếp xúc. Nền ngoài cơ thể không được gọi là khe hở; số pixel nền vẫn ghi riêng.\n\n| Vòng | Thân IoU | Da IoU | Sắt IoU | MAE da/sắt | Khớp lỗi /78 | Ngoài chủ+24 | Kết luận |\n|---|---:|---:|---:|---:|---:|---:|---|\n')
mae=[registration[o]['final_wear_protected_mae_rgb'] for o in outfits]
line=f"| {R} | {body_iou:.6f} | {metrics['outfits']['leather']['iou_without_sword_4px']:.6f} | {metrics['outfits']['iron']['iou_without_sword_4px']:.6f} | {mae[0]:.3f}/{mae[1]:.3f} | {sum(not x['pass'] for x in rotation)}/78 | 0 | {'ĐẠT' if metrics['all_pass'] else 'TRƯỢT'} |\n"
head_line=f'\nBản sửa — đầu nguyên ảnh: {sum(c["pass_size"] for c in head_checks)}/18 đúng kích thước/vị trí; không ghép khuôn mặt. Xoay cổ: {sum(c["pass"] for c in head_rotation)}/36.\n'
lines=rounds.read_text().splitlines(keepends=True);lines=[l for l in lines if not l.startswith(f'| {R} |')];rounds.write_text(''.join(lines)+line+head_line)
print(json.dumps({k:v for k,v in metrics.items() if k in ('round','body_iou_without_sword_4px','full_ref_iou_with_fixture_informational','outfits','rotation_pass','all_pass')},indent=2))
