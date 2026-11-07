"""Pack the drawn atlas into aligned rig layers; assemble and rotate for inspection.
Run from the repository root. No game files or original hero art are changed.
"""
from pathlib import Path
import json, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import label
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'assets/characters/hero_rig'
REVIEW=Path(__file__).resolve().parent
S=Image.open(REVIEW/'source_atlas.png').convert('RGBA')
J={'hip':[262,372],'waist':[262,335],'neck':[262,236],'cape':[236,246],
'shoulder_shield':[196,274],'elbow_shield':[196,313],'wrist_shield':[206,348],'shield':[166,352],
'shoulder_sword':[308,268],'elbow_sword':[327,305],'wrist_sword':[351,322],'grip':[354,320],
'hip_back':[236,384],'knee_back':[212,432],'ankle_back':[192,474],
'hip_front':[290,384],'knee_front':[300,432],'ankle_front':[316,474]}
# name: atlas cell, destination alpha bounding rectangle, joint, parent
P={
'cape':(3,(80,224,292,288),'cape','torso'),
'back_leg_upper':(11,(183,366,253,448),'hip_back','pelvis'),
'back_leg_lower':(12,(161,413,232,483),'knee_back','back_leg_upper'),
'back_foot':(13,(138,456,214,500),'ankle_back','back_leg_lower'),
'sword_arm_upper':(4,(288,250,338,320),'shoulder_sword','torso'),
'pelvis':(0,(198,327,313,407),'hip',None),
'front_leg_upper':(14,(267,366,329,449),'hip_front','pelvis'),
'front_leg_lower':(15,(276,412,338,484),'knee_front','front_leg_upper'),
'front_foot':(16,(279,458,373,500),'ankle_front','front_leg_lower'),
 'torso':(1,(200,237,319,378),'waist','pelvis'),
'head':(2,(174,105,329,255),'neck','torso'),
'sword_arm_lower':(5,(308,287,358,344),'elbow_sword','sword_arm_upper'),
'sword_hand':(6,(334,296,377,343),'wrist_sword','sword_arm_lower'),
'shield_arm_upper':(7,(164,252,221,327),'shoulder_shield','torso'),
'shield_arm_lower':(8,(174,290,222,359),'elbow_shield','shield_arm_upper'),
'shield_hand':(9,(185,330,224,368),'wrist_shield','shield_arm_lower'),
'shield':(10,(104,287,227,415),'shield','shield_arm_lower')}
ORDER=list(P);ORDER.insert(11,'sword')
G={
'leather_armor':{'torso':(17,(195,237,323,365)), 'shield_arm_upper':(18,(160,251,224,296)),
'sword_arm_upper':(19,(284,249,340,293)), 'pelvis':(20,(193,324,320,402))},
'leather_helmet':{'head':(21,(173,105,330,205))},
'reinforced_boots':{'back_leg_lower':(22,(158,421,231,484)), 'front_leg_lower':(23,(273,421,340,484)),
'back_foot':(24,(134,456,217,500)), 'front_foot':(24,(276,456,376,500))},
'iron_armor':{'torso':(100,(195,237,323,378)),
'shield_arm_upper':(101,(160,251,224,308)), 'sword_arm_upper':(102,(284,249,340,305)),
'pelvis':(103,(193,324,320,402))},
'iron_helmet':{'head':(104,(171,101,333,210))},
'climbing_boots':{'back_leg_lower':(105,(158,421,231,484)),
'front_leg_lower':(106,(273,421,340,484)),
'back_foot':(107,(134,454,217,500)), 'front_foot':(108,(276,454,376,500))}}

OUTFITS={
 'leather':('leather_armor','leather_helmet','reinforced_boots'),
 'iron':('iron_armor','iron_helmet','climbing_boots'),
}
def selected_items(equipped):
 return OUTFITS['leather' if equipped is True else equipped] if equipped else ()


def component(cell,sub=None):
 x,y=(cell%5)*256,(cell//5)*256
 im=S.crop((x,y,x+256,y+256))
 if cell>=100:
  atlas=Image.open(REVIEW/'iron_equipment_atlas.png').convert('RGBA')
  w,h=atlas.size; col,row=(cell-100)%3,(cell-100)//3
  im=atlas.crop((round(col*w/3),round(row*h/3),round((col+1)*w/3),round((row+1)*h/3)))
 if cell in (21,24):
  fix=Image.open(REVIEW/'equipment_atlas.png').convert('RGBA')
  if cell==21: im=fix.crop((0,0,640,640))
  elif sub[0]==0: im=fix.crop((0,920,640,1280))
  else: im=fix.crop((640,300,1280,640))
  sub=None
 if sub:im=im.crop(sub)
 # Ignore isolated generator specks; retain all pixels of the actual drawing.
 a=np.array(im); labs,n=label(a[:,:,3]>12)
 if n:
  counts=np.bincount(labs.ravel());counts[0]=0
  a[:,:,3][labs!=counts.argmax()]=0
 im=Image.fromarray(a);return im.crop(im.getbbox())

def layer(cell,box,sub=None):
 im=component(cell,sub).resize((box[2]-box[0],box[3]-box[1]),Image.Resampling.LANCZOS)
 canvas=Image.new('RGBA',(512,512));canvas.alpha_composite(im,box[:2]);return canvas

ART={};GEAR={}
for name,(cell,box,*_) in P.items():
 im=layer(cell,box);ART[name]=im
 path=OUT/'parts'/f'{name}.png';path.parent.mkdir(parents=True,exist_ok=True);im.save(path)
for item,parts in G.items():
 GEAR[item]={}
 for name,(cell,box) in parts.items():
  sub=None
  if cell==17:sub=(0,0,256,172) # cuirass only, hip tassets are a separate layer
  if cell==24:sub=(0,128,128,256) if name=='back_foot' else (128,128,256,256)
  im=layer(cell,box,sub);GEAR[item][name]=im
  path=OUT/'gear'/item/f'{name}.png';path.parent.mkdir(parents=True,exist_ok=True);im.save(path)
(OUT/'joints.json').write_text(json.dumps({'joints':J,'order':ORDER},indent=2)+'\n')

def render(equipped=False,turn=None,angle=0, margin=0):
 matrices={}
 def matrix(name):
  if name in matrices:return matrices[name]
  joint,parent=P[name][2:];m=matrix(parent) if parent else np.eye(3)
  if joint==turn:
   x,y=J[joint];a=math.radians(angle);c,s=math.cos(a),math.sin(a)
   r=np.array([[c,-s,x-c*x+s*y],[s,c,y-s*x-c*y],[0,0,1.]])
   m=m@r
  matrices[name]=m;return m
 result=Image.new('RGBA',(512+margin*2,512+margin*2))
 for name in ORDER:
  if name=='sword':continue
  im=ART[name].copy()
  if equipped:
   for item in selected_items(equipped):
    if name in GEAR[item]:im.alpha_composite(GEAR[item][name])
  m=matrix(name).copy();m[0,2]+=margin;m[1,2]+=margin
  inv=np.linalg.inv(m)
  result.alpha_composite(im.transform(result.size,Image.Transform.AFFINE,tuple(inv[:2].ravel()),Image.Resampling.BICUBIC))
 return result
bare=render();bare.save(REVIEW/'assembled_bare.png')
render(True).save(REVIEW/'assembled_leather.png')
render('iron').save(REVIEW/'assembled_iron.png')
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',13)
small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',11)
over=Image.new('RGBA',(900,630),(245,239,221,255));over.alpha_composite(bare,(194,45));d=ImageDraw.Draw(over)
left=['cape','shoulder_shield','neck','elbow_shield','shield','wrist_shield','hip_back','knee_back','ankle_back']
right=[k for k in J if k not in left]
for group,x in [(left,12),(right,714)]:
 for i,k in enumerate(group):
  px,py=J[k];px+=194;py+=45;y=38+i*61
  d.line((px,py,x+(170 if x==12 else 0),y+9),fill='#b52e30',width=1)
  d.ellipse((px-3,py-3,px+3,py+3),fill='#ef2424')
  d.text((x,y),k,fill='#802525',font=font)
  d.text((x,y+16),str(J[k]),fill='#534039',font=small)
over.convert('RGB').save(REVIEW/'joints_overlay.png')
turns=['neck','shoulder_sword','elbow_sword','wrist_sword','shoulder_shield','elbow_shield','wrist_shield','hip_back','knee_back','ankle_back','hip_front','knee_front','ankle_front']
for equipped, filename in [(False, "rotation_test_bare.png"), (True, "rotation_test_leather.png"), ("iron", "rotation_test_iron.png")]:
 contact=Image.new('RGB',(1536,5*300),'#eee8d8');d=ImageDraw.Draw(contact)
 for i,(joint,angle) in enumerate((j,a) for j in turns for a in [-35,35]):
  x=(i%6)*256;y=(i//6)*300
  panel=render(equipped,joint,angle,64).resize((256,256),Image.Resampling.LANCZOS)
  contact.paste(panel,(x,y+28),panel)
  d.text((x+8,y+8),f'{joint} {angle:+} deg',font=font,fill='#382b22')
 contact.save(REVIEW/filename)
 if equipped=='iron':contact.save(REVIEW/'rotation_test.png')
report=[]
for p in sorted(OUT.rglob('*.png')):
 im=Image.open(p);box=im.getbbox()
 assert im.mode=='RGBA' and im.size==(512,512) and box and min(box[:2])>0 and max(box[2:])<512,p
 report.append({'path':str(p.relative_to(ROOT)),'mode':im.mode,'size':list(im.size),'alpha_bbox':list(box)})
assert len(report)==35
assert all(render(outfit).getbbox()[3]==500 for outfit in (False,True,'iron'))
(REVIEW/'validation.json').write_text(json.dumps({'png_count':len(report),'canvas':[512,512],'ground_anchor':[256,500], 'rotation_degrees':[-35,35],'rotation_joints':turns,'files':report},indent=2)+'\n')
print('35 RGBA layers verified; all inside canvas. Ground y=500. Review images rebuilt.')
# Inspect contact at every limb/neck pivot in bare and equipped poses.
# This local test is deliberately narrower than the visual silhouette review.
checks=[]
for equipped in (False,True,"iron"):
 for joint in turns:
  jx,jy=J[joint]
  points=np.array([[jx+dx,jy+dy,1.] for dx in range(-4,5) for dy in range(-4,5) if dx*dx+dy*dy<=16]).T
  for angle in (-35,0,35):
   mats={}
   def mat(name):
    if name in mats:return mats[name]
    key,parent=P[name][2:];v=mat(parent).copy() if parent else np.eye(3)
    if key==joint:
     px,py=J[key];a=math.radians(angle);c,s=math.cos(a),math.sin(a)
     v=v@np.array([[c,-s,px-c*px+s*py],[s,c,py-s*px-c*py],[0,0,1.]])
    mats[name]=v;return v
   cover=np.zeros(points.shape[1])
   for name in P:
    q=np.rint(np.linalg.inv(mat(name))@points).astype(int)
    im=ART[name].copy()
    if equipped:
     for item in selected_items(equipped):
      if name in GEAR[item]:im.alpha_composite(GEAR[item][name])
    a=np.array(im)[:,:,3];valid=(q[0]>=0)&(q[0]<512)&(q[1]>=0)&(q[1]<512)
    cover[valid]=np.maximum(cover[valid],a[q[1,valid],q[0,valid]])
   checks.append({'outfit':('leather' if equipped is True else equipped or 'bare'),'joint':joint,'angle':angle,'transparent_pixels_in_radius_4':int((cover<200).sum())})
(REVIEW/'joint_contact_checks.json').write_text(json.dumps({'method':'49 nearest-pixel alpha samples in a radius-4 disk at each pivot; alpha <200 flags a local gap. Does not validate the entire silhouette.','checks':checks},indent=2)+'\n')
assert not any(c['transparent_pixels_in_radius_4'] for c in checks)
print('117 local joint-contact checks passed (bare/leather/iron; -35, 0, +35 degrees).')
