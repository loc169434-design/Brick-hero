"""Bake #30 NPC animation from original parts using the #24 Pillow tools.
Run: python docs/ideas/build_blacksmith_anim.py
Only writes blacksmith/anim and docs/ideas/gear_review. No game code.
"""
from pathlib import Path
import math,json,runpy,hashlib
from PIL import Image,ImageDraw,ImageChops
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
TOOLS=runpy.run_path(str(ROOT/'docs/ideas/build_anim_moves.py'))
blank,part,cut,xf,comp,pointxf=[TOOLS[n] for n in ['blank','part','cut','xf','comp','pointxf']]
OUT=ROOT/'docs/ideas/gear_review';OUT.mkdir(exist_ok=True)
DEST=ROOT/'assets/characters/blacksmith/anim';DEST.mkdir(exist_ok=True)
BG='#183247'
source=Image.open(ROOT/'assets/characters/blacksmith/idle.png').convert('RGBA')
active=part(source,[(175,261),(191,253),(211,261),(216,283),(210,301),(204,317),(193,339),(195,354),(190,375),(174,383),(171,400),(164,425),(153,440),(128,440),(111,427),(101,404),(110,388),(130,373),(146,377),(156,365),(149,351),(155,331),(158,307),(160,290),(165,275)])
free=part(source,[(321,250),(345,239),(365,247),(384,266),(391,286),(380,310),(367,329),(349,346),(339,357),(321,356),(305,345),(302,331),(313,315),(324,304),(336,292),(321,277)])
head_part=part(source,[(201,181),(210,156),(211,126),(230,112),(232,103),(265,99),(290,106),(311,121),(335,151),(339,172),(327,192),(316,210),(298,222),(280,237),(252,243),(229,226),(203,220),(200,203)])
legs=part(source,[(188,405),(232,408),(266,408),(307,411),(335,407),(345,428),(339,448),(354,464),(367,480),(370,502),(144,502),(144,482),(157,460),(171,447),(171,431)])
body=source
for p in [active,free,head_part,legs]:body=cut(body,p)
body=part(body,[(195,230),(218,225),(245,238),(268,232),(285,220),(313,217),(335,229),(352,245),(349,267),(331,291),(319,316),(321,349),(339,384),(335,408),(306,418),(264,415),(225,414),(191,408),(182,386),(187,359),(202,330),(208,305),(198,291),(184,276),(180,254)])
# Patch only the shirt area originally hidden by the hammer arm.
patch=blank();pd=ImageDraw.Draw(patch)
pd.polygon([(183,251),(209,243),(219,260),(209,290),(189,293)],fill='#46566c',outline='#35271e',width=3)
body=comp(patch,body)

def largest_component(im):
 from collections import deque
 alpha=np.array(im.getchannel('A'));todo=alpha>0;seen=np.zeros(todo.shape,dtype=bool);groups=[]
 for y,x in zip(*np.where(todo)):
  if seen[y,x]:continue
  q=deque([(int(y),int(x))]);seen[y,x]=True;group=[]
  while q:
   yy,xx=q.popleft();group.append((yy,xx))
   for dy,dx in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1)]:
    ny=yy+dy;nx=xx+dx
    if 0<=ny<512 and 0<=nx<512 and todo[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((ny,nx))
  groups.append(group)
 largest=max(groups,key=len);keep=np.zeros_like(alpha)
 for y,x in largest:keep[y,x]=alpha[y,x]
 out=im.copy();out.putalpha(Image.fromarray(keep));return out
body=largest_component(body)


SPECS={'idle':{'frames':8,'fps':12,'loop':True},'talk':{'frames':8,'fps':12,'loop':True},'hammer':{'frames':6,'fps':24,'loop':False,'impact':3},'cheer':{'frames':12,'fps':12,'loop':False}}
POSES={
'idle':[{},{'arm':-4,'lean':-.5},{'arm':-95,'head':-2},{'arm':-145,'dx':60,'dy':-55,'head':-3},{'arm':-142,'dx':57,'dy':-52,'head':-2},{'arm':-85,'dx':22,'dy':-15},{'arm':-8,'lean':.5},{}],
 'talk':[{}, {'arm':-25,'mouth':.7,'head':-1},{'arm':-55,'mouth':1,'head':-2,'lean':1},{'arm':-65,'mouth':.3,'head':-1},{'arm':-40,'mouth':1,'head':1},{'arm':-20,'mouth':.2,'head':2},{'arm':-8,'mouth':.65,'head':1},{}],
 'hammer':[{}, {'arm':-145,'head':3,'lean':-2}, {'arm':-80,'head':-3,'smear':True}, {'arm':-30,'head':-4,'lean':3,'bodydy':2}, {'arm':-65,'head':-2,'lean':1},{}],
 'cheer':[{}, {'arm':-65,'mouth':.4,'head':-2},{'arm':-120,'dx':15,'dy':-25,'mouth':.8,'head':-3},{'arm':-145,'dx':28,'dy':-50,'mouth':1,'head':-4},{'arm':-150,'dx':32,'dy':-55,'mouth':1,'head':-5},{'arm':-148,'dx':32,'dy':-53,'mouth':.7,'head':-4},{'arm':-150,'dx':32,'dy':-55,'mouth':1,'head':-5},{'arm':-140,'dx':25,'dy':-40,'mouth':.8,'head':-3},{'arm':-110,'dx':15,'dy':-20,'mouth':.7,'head':-2},{'arm':-65,'mouth':.4},{'arm':-20,'mouth':.2},{}]
}

def frame(arm=0,head=0,dx=0,dy=0,lean=0,bodydy=0,mouth=0,smear=False,laugh=False):
 h=head_part.copy()
 if mouth:
  d=ImageDraw.Draw(h)
  # Mouth stays inside the existing moustache/beard; all hair and outline unchanged.
  height=5+round(16*mouth)
  d.ellipse((229,193,261,193+height),fill='#59271e',outline='#38251c',width=2)
  d.arc((230,193,260,205),0,180,fill='#fff1cc',width=3)
  if mouth>.6:d.ellipse((237,202,254,211),fill='#db7965')
 if laugh:
  d=ImageDraw.Draw(h)
  d.ellipse((213,151,256,177),fill='#f2b78a')
  d.arc((215,153,235,169),185,350,fill='#3a261e',width=3)
  d.arc((237,150,255,166),185,350,fill='#3a261e',width=3)
 h=xf(h,head,(269,220))
 a=xf(active,arm,(196,282),dx,dy)
 bridge=blank();d=ImageDraw.Draw(bridge)
 if dx or dy:
  d.line([(196,282),(196+dx,282+dy)],fill='#37261d',width=44)
  d.line([(196,282),(196+dx,282+dy)],fill='#edb085',width=35)
 # Keep the actual current hammer head inside its swept metal trail.
 if smear:
  trail=blank();td=ImageDraw.Draw(trail)
  for j in range(18):
   angle=-140+j/17*60;center=pointxf((135,410),angle,(196,282))
   radius=19+j/17*7
   td.ellipse((center[0]-radius,center[1]-radius,center[0]+radius,center[1]+radius),fill=(187,181,184,round(20+j/17*85)))
  a=comp(trail,a)
 upper=comp(bridge,body,h,free,a)
 return comp(legs,xf(upper,lean,(256,410),dy=bodydy))

def times(n,fps,unit=100):return [round((i+1)*unit/fps)-round(i*unit/fps) for i in range(n)]

def export(clip,frames,info):
 atlas=Image.new('RGBA',(2048,math.ceil(len(frames)/4)*512))
 for i,f in enumerate(frames):atlas.alpha_composite(f,(i%4*512,i//4*512))
 atlas.save(DEST/f'fresh_{clip}.png',optimize=True)
 rgb=[]
 for f in frames:
  bg=Image.new('RGBA',(512,512),BG);bg.alpha_composite(f);rgb.append(bg.resize((320,320),Image.Resampling.LANCZOS).convert('RGB'))
 palette_source=Image.new('RGB',(320*len(rgb),320))
 for i,f in enumerate(rgb):palette_source.paste(f,(i*320,0))
 pal=palette_source.quantize(colors=192)
 gif=[f.quantize(palette=pal,dither=Image.Dither.NONE) for f in rgb]*3
 gif[0].save(OUT/f'blacksmith_{clip}.gif',save_all=True,append_images=gif[1:],duration=[v*10 for v in times(len(gif),info['fps'])],loop=0,disposal=2,optimize=False)
 grid=Image.new('RGB',(1024,math.ceil(len(frames)/4)*282),BG);gd=ImageDraw.Draw(grid)
 for i,f in enumerate(frames):
  x=i%4*256;y=i//4*282;small=f.resize((256,256),Image.Resampling.LANCZOS);grid.paste(small,(x,y+26),small);gd.text((x+8,y+7),str(i)+(' IMPACT' if info.get('impact')==i else ''),fill='#ffe2a8')
 grid.save(OUT/f'blacksmith_{clip}_numbered.gif')
 grid.save(f'/tmp/brick-blacksmith-{clip}-grid.png')

def export_contact_review():
 atlas=Image.open(DEST/'fresh_hammer.png').convert('RGBA');frames=[]
 for i in range(6):
  f=atlas.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512))
  bg=Image.new('RGBA',(512,512),BG);d=ImageDraw.Draw(bg)
  d.polygon([(3,397),(94,397),(86,412),(70,418),(70,444),(90,452),(90,470),(15,470),(15,454),(35,444),(35,420),(16,413)],fill='#847f82',outline='#35271d',width=3)
  d.polygon([(7,399),(91,399),(82,406),(18,406)],fill='#c8c2c2')
  bg.alpha_composite(f);d=ImageDraw.Draw(bg)
  d.text((12,14),f'FRAME {i}'+(' / IMPACT' if i==3 else ''),fill='#ffe2a8')
  if i==3:
   for points in [[(53,391),(41,378)],[(69,391),(78,376)],[(47,399),(30,396)]]:d.line(points,fill='#ffd460',width=3)
  frames.append(bg.resize((320,320),Image.Resampling.LANCZOS).convert('RGB'))
 seq=frames*3
 seq[0].save(OUT/'blacksmith_hammer_contact.gif',save_all=True,append_images=seq[1:],duration=[v*10 for v in times(len(seq),24)],loop=0,disposal=2)

if __name__=='__main__':
 for clip,info in SPECS.items():
  frames=[frame(**dict(pose,laugh=True)) if clip=='cheer' and 2<=i<=8 else frame(**pose) if pose else source.copy() for i,pose in enumerate(POSES[clip])]
  frames[-1]=source.copy()
  export(clip,frames,info)
 (DEST/'anim.json').write_text(json.dumps({'frame_size':[512,512],'columns':4,'clips':SPECS},indent=2)+'\n')
 contact=pointxf((132,438),-30,(196,282));contact=pointxf(contact,3,(256,410),dy=2)
 (OUT/'blacksmith_contact.json').write_text(json.dumps({'clip':'hammer','impact_frame':3,'impact_seconds':.125,'contact_on_canvas':contact,'note':'Approximate lower hammer-head contact; anvil is provided by the forge scene, not baked into character atlas.'},indent=2)+'\n')
 export_contact_review()
 print('Baked idle/talk/hammer/cheer; hammer impact=3; contact',contact)
