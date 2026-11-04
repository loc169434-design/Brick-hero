"""Offline sprite baking for #24. Pillow only; never loaded by the game.

Run from any directory: python docs/ideas/build_anim_moves.py --batch 1
The existing pilot atlases and their metadata are immutable inputs.
"""
from pathlib import Path
import argparse, copy, hashlib, json, math
from PIL import Image, ImageDraw, ImageChops, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'assets/characters'
REVIEW = ROOT / 'docs/ideas/anim_moves_review'
SPECS = json.loads((ROOT/'docs/ideas/anim_moves_specs.json').read_text())
SIZE = (512,512)
BG = '#183247'
R = Image.Resampling.BICUBIC

def blank(): return Image.new('RGBA',SIZE)
def load(c,p): return Image.open(ASSETS/c/(p+'.png')).convert('RGBA')
def maskpoly(points):
    m=Image.new('L',SIZE);ImageDraw.Draw(m).polygon(points,fill=255);return m

def part(im,points):
    p=im.copy();p.putalpha(ImageChops.multiply(p.getchannel('A'),maskpoly(points)));return p

def cut(im,p):
    out=im.copy();out.putalpha(ImageChops.subtract(out.getchannel('A'),p.getchannel('A')));return out

def xf(im,angle=0,pivot=(256,385),dx=0,dy=0,sx=1,sy=1):
    # Output-to-input affine, retaining the full 512-square canvas.
    a=math.radians(angle);c=math.cos(a);s=math.sin(a);px,py=pivot
    aa=c/sx;bb=-s/sx;dd=s/sy;ee=c/sy
    return im.transform(SIZE,Image.Transform.AFFINE,(aa,bb,px-aa*(px+dx)-bb*(py+dy),dd,ee,py-dd*(px+dx)-ee*(py+dy)),R)

def pointxf(point,angle=0,pivot=(256,385),dx=0,dy=0):
    x,y=point;px,py=pivot;a=math.radians(angle);c=math.cos(a);s=math.sin(a)
    return [round(px+c*(x-px)+s*(y-py)+dx,2),round(py-s*(x-px)+c*(y-py)+dy,2)]

def comp(*layers):
    im=blank()
    for layer in layers: im.alpha_composite(layer)
    return im

def atlas_frames(c,clip,wear='fresh'):
    p=ASSETS/c/'anim'/f'{wear}_{clip}.png'
    meta=json.loads((p.parent/'anim.json').read_text())['clips'][clip]
    im=Image.open(p).convert('RGBA')
    return [im.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512)) for i in range(meta['frames'])]

class Hero:
    def __init__(self):
        self.idle=atlas_frames('hero_rookie','idle')[0]
        im=self.idle
        self.sword=part(im,[(347,389),(337,367),(364,309),(361,282),(372,258),(385,263),(430,158),(468,138),(476,177),(417,277),(437,285),(432,313),(408,310),(379,382)])
        # Keep knuckles in the arm layer, never on the sword.
        fist=maskpoly([(368,299),(387,291),(404,300),(409,313),(405,330),(390,349),(373,345),(362,333)])
        self.sword.putalpha(ImageChops.subtract(self.sword.getchannel('A'),fist))
        self.arm=part(im,[(313,283),(329,278),(346,294),(365,303),(377,293),(395,293),(410,303),(408,326),(398,346),(380,354),(343,351),(324,341),(311,319)])
        self.shield=part(im,[(70,333),(76,313),(93,299),(121,288),(156,289),(181,301),(199,323),(205,349),(200,382),(183,411),(157,429),(122,429),(93,414),(76,392),(68,364)])
        self.originallegs=part(im,[(194,384),(238,382),(268,383),(288,380),(324,392),(339,420),(357,423),(360,445),(367,460),(388,470),(397,502),(116,502),(116,477),(130,456),(144,445),(143,433),(162,423),(182,412)])
        self.head=part(im,[(166,208),(169,168),(194,142),(214,129),(229,112),(249,111),(259,100),(278,104),(301,118),(322,124),(328,144),(314,166),(306,184),(311,211),(305,227),(287,237),(259,233),(237,224),(215,217),(193,217)])
        self.scarf=part(im,[(71,304),(72,276),(88,255),(126,237),(172,220),(194,219),(229,229),(255,240),(284,239),(307,238),(310,256),(294,275),(276,286),(252,273),(228,261),(193,247),(168,248),(136,255),(102,278)])
        self.leftleg=blank();d=ImageDraw.Draw(self.leftleg)
        d.polygon([(193,386),(227,392),(234,407),(211,434),(190,454),(157,442),(165,422)],fill='#6b4433',outline='#352419',width=4)
        leftboot=part(im,[(141,432),(198,432),(211,448),(192,468),(189,500),(115,501),(117,476),(129,458)])
        self.leftleg=comp(self.leftleg,leftboot)
        self.thigh=blank();d=ImageDraw.Draw(self.thigh)
        d.polygon([(274,378),(304,376),(331,404),(335,430),(315,443),(291,423),(278,409)],fill='#6b4433',outline='#352419',width=4)
        d.polygon([(284,388),(300,385),(320,410),(320,425),(309,428),(292,408)],fill='#81543d')
        self.boot=part(im,[(289,429),(358,421),(362,446),(366,462),(387,468),(397,486),(394,501),(287,501),(286,469),(295,449)])
        self.rightleg=comp(self.thigh,self.boot)
        body=im
        for p in (self.sword,self.arm,self.shield,self.head,self.scarf,self.leftleg,self.rightleg):body=cut(body,p)
        body=part(body,[(132,254),(205,231),(265,248),(312,246),(336,278),(318,302),(318,351),(337,397),(289,404),(263,408),(227,399),(197,399),(195,374),(195,326),(146,303)])
        # Close the tiny areas hidden behind the original wrist and shoulder.
        fill=blank();d=ImageDraw.Draw(fill)
        d.polygon([(302,284),(325,284),(332,308),(323,335),(309,333)],fill='#485a78',outline='#392716',width=2)
        self.body=comp(fill,body)
        self.openhand=part(load('hero_rookie','fresh_throw'),[(327,223),(354,231),(377,229),(397,216),(410,215),(411,235),(430,235),(438,244),(433,255),(437,264),(427,275),(414,276),(408,288),(396,289),(380,276),(351,278),(328,270)])
    def frame(self,lean=0,bodydy=0,head=0,arm=0,wrist=0,shield=0,shield_dx=0,shield_dy=0,leg=0,knee=0,empty=False,expression=None,prop=None,scarf=0,hide_blade=False):
        # Whole-body travel deliberately absent; the game controls that.
        right=comp(self.thigh,xf(self.boot,knee,(320,427)))
        right=xf(right,leg,(291,387))
        if leg>70 and knee<0:
            extended=blank();d=ImageDraw.Draw(extended)
            d.polygon([(277,377),(305,369),(400,316),(426,332),(322,406),(293,408)],fill='#6b4433',outline='#352419',width=4)
            d.polygon([(298,380),(402,323),(411,335),(315,396)],fill='#81543d')
            right=comp(extended,xf(self.boot,dx=90,dy=-110))
        hd=xf(self.head,head,(257,224))
        if expression:
            hd=self.expression(hd,expression)
        blade=xf(self.sword,wrist,(388,321)) if not empty and not hide_blade else blank()
        a=self.arm
        if empty:
            # Open throwing hand uses the approved original release drawing.
            a=comp(part(self.arm,[(310,278),(354,278),(370,299),(364,347),(337,350),(311,324)]),xf(self.openhand,0,(0,0),dx=1,dy=68))
        upperarm=xf(comp(blade,a),arm,(325,298))
        sh=xf(self.shield,shield,(150,353),shield_dx,shield_dy)
        sc=xf(self.scarf,scarf,(245,250))
        # The left forearm behind a moved shield is reconstructed, not left as a hole.
        forearm=blank();d=ImageDraw.Draw(forearm)
        if shield_dx or shield_dy:
            tx,ty=150+shield_dx,353+shield_dy
            d.line([(173,285),(187,309),(tx,ty)],fill='#38251b',width=33,joint='curve')
            d.line([(173,285),(187,309),(tx,ty)],fill='#e4a66d',width=25,joint='curve')
        upper=comp(self.body,sc,hd,forearm,upperarm,sh)
        if prop: upper=comp(upper,prop)
        back=xf(self.leftleg,min(0,leg),(210,390))
        legs=self.originallegs if not leg and not knee else comp(back,right)
        return comp(legs,xf(upper,lean,(256,390),dy=bodydy))
    def expression(self,im,which):
        out=im.copy();d=ImageDraw.Draw(out)
        if which in ('dizzy','scared','hurt','smile'):
            # Eye replacement stays within original skin, so head outline/hair never change.
            d.ellipse((247,158,287,190),fill='#ffce96')
            if which=='dizzy':
                for cx,cy in [(259,174),(282,174)]:
                    pts=[]
                    for i in range(65):
                        a=i/64*math.pi*4;r=1+i/64*8
                        pts.append((cx+math.cos(a)*r,cy+math.sin(a)*r))
                    d.line(pts,fill='#402516',width=2)
                d.ellipse((278,210,296,231),fill='#8c3238',outline='#402516',width=2)
                d.ellipse((283,218,299,237),fill='#f17779',outline='#402516',width=2)
            elif which=='hurt':
                d.line([(249,171),(260,177),(250,182)],fill='#402516',width=3)
                d.line([(276,170),(285,176),(276,182)],fill='#402516',width=3)
            elif which=='scared':
                for cx in (258,282):
                    d.ellipse((cx-8,162,cx+6,185),fill='#fff4dc',outline='#402516',width=2)
                    d.ellipse((cx-1,169,cx+3,180),fill='#402516')
                d.ellipse((302,191,309,207),fill='#90d9eb',outline='#36597a',width=1)
            else:
                d.arc((249,165,266,183),180,350,fill='#402516',width=3)
                d.arc((274,163,289,181),180,350,fill='#402516',width=3)
        return out

# Pose dictionaries are actual limb/head configurations, not translated stills.
def mix(a,b,t):
    keys=set(a)|set(b);out={}
    for k in keys:
        x=a.get(k,0);y=b.get(k,0)
        if isinstance(x,(bool,str)) or isinstance(y,(bool,str)) or x is None or y is None:
            out[k]=x if t<.5 else y
        else:out[k]=x+(y-x)*t
    return out

def timeline(keys,count):
    result=[]
    for i in range(count):
        left=max(k for k in keys if k<=i);right=min(k for k in keys if k>=i)
        t=0 if right==left else (i-left)/(right-left)
        result.append(mix(keys[left],keys[right],t))
    return result

HERO_KEYS={
 'throw':{0:{'arm':30,'wrist':0,'lean':-5,'scarf':4},2:{'arm':90,'wrist':-30,'lean':-9,'head':-5},3:{'arm':95,'wrist':-30,'lean':-7},4:{'arm':-22,'empty':True,'lean':10,'scarf':-5},5:{'arm':-35,'empty':True,'lean':12},7:{'arm':-10,'empty':True,'lean':4},9:{'empty':True}},
 'leap':{0:{},2:{'bodydy':16,'lean':-3,'leg':10,'knee':-12},4:{'arm':75,'wrist':-20,'leg':-24,'knee':65,'lean':-4},6:{'arm':100,'wrist':-35,'leg':-35,'knee':75,'head':-8},9:{'arm':100,'wrist':-35,'leg':-30,'knee':65},10:{'arm':-20,'wrist':-70,'lean':12,'bodydy':10,'leg':15,'knee':-15},11:{'arm':-100,'wrist':30,'lean':14,'bodydy':15},12:{'arm':-60,'wrist':20,'lean':10,'bodydy':10},13:{'lean':5,'bodydy':8,'arm':-15},15:{}},
 'kick':{0:{},1:{'leg':48,'knee':110,'lean':-5,'arm':25},2:{'leg':65,'knee':120,'lean':-8,'arm':30},3:{'leg':83,'knee':-25,'lean':-8,'arm':20,'head':5},4:{'leg':63,'knee':90,'lean':-5,'arm':15},5:{'leg':35,'knee':55},7:{}},
 'bash':{0:{},2:{'shield_dx':58,'shield_dy':-38,'shield':-18,'lean':7,'arm':28},3:{'shield_dx':78,'shield_dy':-42,'shield':-20,'lean':11,'arm':35},4:{'shield_dx':142,'shield_dy':-42,'shield':-20,'lean':14,'arm':30,'head':10,'scarf':-8},5:{'shield_dx':124,'shield_dy':-38,'shield':-17,'lean':12,'arm':25},7:{'shield_dx':35,'shield_dy':-12,'lean':5,'arm':10},9:{}},
 'hurt':{0:{'lean':-10,'head':-14,'arm':28,'expression':'hurt'},2:{'lean':-14,'head':-20,'arm':35,'shield':12,'expression':'hurt'},3:{'lean':7,'head':5,'arm':-10,'expression':'hurt'},5:{'lean':-4,'head':-5},7:{}},
 'knocked':{0:{'lean':-16,'head':-15,'arm':35,'bodydy':5,'expression':'hurt'},2:{'lean':-30,'head':-22,'arm':55,'shield':20,'bodydy':18,'expression':'hurt'},3:{'lean':-20,'arm':35,'bodydy':10},5:{'lean':-7,'arm':15},7:{}},
 'dizzy':{0:{'lean':-4,'head':10,'arm':-10,'empty':True,'expression':'dizzy'},3:{'lean':5,'head':-12,'arm':-5,'empty':True,'expression':'dizzy'},6:{'lean':-5,'head':-8,'arm':4,'empty':True,'expression':'dizzy'},9:{'lean':3,'head':11,'arm':-5,'empty':True,'expression':'dizzy'},11:{'lean':-4,'head':10,'arm':-10,'empty':True,'expression':'dizzy'}},
 'scared':{0:{'lean':-5,'head':-5,'shield_dx':65,'shield_dy':-40,'arm':25,'expression':'scared'},2:{'lean':-7,'head':-2,'shield_dx':70,'shield_dy':-44,'arm':28,'expression':'scared'},4:{'lean':-4,'head':-7,'shield_dx':63,'shield_dy':-38,'arm':24,'expression':'scared'},6:{'lean':-6,'head':-4,'shield_dx':68,'shield_dy':-42,'arm':27,'expression':'scared'},7:{'lean':-5,'head':-5,'shield_dx':65,'shield_dy':-40,'arm':25,'expression':'scared'}},
 'cheer':{0:{},2:{'arm':95,'wrist':5,'head':-10,'scarf':-6},4:{'arm':112,'wrist':-10,'head':-14,'bodydy':-10,'leg':-18,'knee':40,'expression':'smile','scarf':6},6:{'arm':100,'head':-10,'bodydy':-6,'leg':-10,'knee':30,'expression':'smile'},8:{'arm':75,'bodydy':5},11:{}},
 'victory':{0:{'arm':100,'head':-10,'expression':'smile','scarf':-3},3:{'arm':110,'head':-12,'expression':'smile','scarf':5,'bodydy':-3},6:{'arm':100,'head':-8,'expression':'smile','scarf':-4},9:{'arm':108,'head':-10,'expression':'smile','scarf':5},11:{'arm':100,'head':-10,'expression':'smile','scarf':-3}},
}

def bottle(angle=0,dx=0,dy=0):
    im=blank();d=ImageDraw.Draw(im)
    d.rounded_rectangle((352,278,382,317),radius=9,fill='#b72436',outline='#3c251b',width=3)
    d.rectangle((359,268,375,282),fill='#f4c99a',outline='#3c251b',width=2)
    d.line((359,286,359,300),fill='#ffd3cb',width=3)
    return xf(im,angle,(367,295),dx,dy)

def hero_frames(clip,hero):
    n=SPECS['hero_rookie'][clip][0]
    if clip=='drink':
        keys={0:{},1:{'empty':True,'arm':-12},3:{'empty':True,'arm':45,'head':-5},5:{'empty':True,'arm':110,'head':-15},7:{'empty':True,'arm':110,'head':-18},8:{'empty':True,'arm':35,'head':5},9:{'empty':True,'arm':20,'expression':'smile'},11:{}}
        frames=[]
        for i,p in enumerate(timeline(keys,n)):
            prop=None
            if 1<=i<=8:
                # Bottle follows the same shoulder transform as the hand.
                t=min((i-1)/4,1) if i<=7 else .5
                prop=bottle(-85*t,dx=-69*t,dy=-85*t)
            p['prop']=prop;frames.append(hero.frame(**p))
    elif clip=='defeat':
        keys={0:{},2:{'lean':-8,'head':14,'bodydy':12,'arm':-10,'expression':'hurt'},4:{'lean':-18,'head':20,'bodydy':35,'arm':-25,'leg':30,'knee':60,'expression':'hurt'},6:{'lean':-35,'bodydy':45,'arm':-30,'leg':45,'knee':50,'expression':'dizzy'},8:{'lean':-45,'bodydy':30,'arm':-30,'leg':45,'knee':50,'expression':'dizzy'},11:{'lean':-45,'bodydy':30,'arm':-30,'leg':45,'knee':50,'expression':'dizzy'}}
        frames=[hero.frame(**p) for p in timeline(keys,n)]
        for i in range(3,n):
            t=min((i-2)/7,1)
            pose=hero.frame(head=12,arm=-15,expression='hurt',bodydy=15*(1-t))
            frames[i]=xf(pose,angle=80*t,pivot=(256,490),dx=140*t,dy=-210*t)
            bbox=frames[i].getbbox()
            frames[i]=xf(frames[i],dy=500-bbox[3])
        frames[-2]=frames[-1].copy()
    else:frames=[hero.frame(**p) for p in timeline(HERO_KEYS[clip],n)]
    if clip not in ('throw','defeat','victory','dizzy','scared'):
        frames[-1]=hero.idle.copy()
    # The leap's sword is embedded in its arc during the rapid downward swing.
    if clip=='leap':
        for i in (9,10):
            # Remove the rigid blade from this pose before adding the swept blade.
            p=timeline(HERO_KEYS[clip],n)[i]
            p['hide_blade']=True
            p['arm']=15 if i==9 else -20
            frame=hero.frame(**p)
            hand=pointxf((388,321),p['arm'],(325,298))
            hand=pointxf(hand,p.get('lean',0),(256,390),dy=p.get('bodydy',0))
            fx=blank();d=ImageDraw.Draw(fx)
            p0=hand;p1=(487,230);p2=(460,70);p3=(270,65)
            pts=[]
            for j in range(81):
                t=j/80;u=1-t
                pts.append((u*u*u*p0[0]+3*u*u*t*p1[0]+3*u*t*t*p2[0]+t*t*t*p3[0],u*u*u*p0[1]+3*u*u*t*p1[1]+3*u*t*t*p2[1]+t*t*t*p3[1]))
            d.line(pts,fill='#fff3c7',width=24,joint='curve')
            d.line(pts,fill='#754626',width=16,joint='curve')
            d.line(pts,fill='#dda04d',width=11,joint='curve')
            d.line([(x-3,y-3) for x,y in pts],fill='#ffd58a',width=3,joint='curve')
            frames[i]=comp(fx,frame)
    return frames

def write_clip(c,clip,frames,info,wear='fresh'):
    folder=ASSETS/c/'anim';folder.mkdir(exist_ok=True)
    sheet=Image.new('RGBA',(2048,math.ceil(len(frames)/4)*512))
    for i,im in enumerate(frames):sheet.alpha_composite(im,(i%4*512,i//4*512))
    path=folder/f'{wear}_{clip}.png';sheet.save(path,optimize=True)
    preview(c,clip,frames,info,wear)
    return path

def durations(n,fps,unit=100):
    return [round((i+1)*unit/fps)-round(i*unit/fps) for i in range(n)]

def preview(c,clip,frames,info,wear):
    stem=f'{c}_{wear}_{clip}';REVIEW.mkdir(exist_ok=True)
    grid=Image.new('RGB',(1024,math.ceil(len(frames)/4)*282),BG);d=ImageDraw.Draw(grid)
    for i,f in enumerate(frames):
        x=i%4*256;y=i//4*282
        grid.paste(f.resize((256,256),Image.Resampling.LANCZOS),(x,y+26),f.resize((256,256),Image.Resampling.LANCZOS))
        d.text((x+8,y+7),f'{i:02}'+(' IMPACT' if info.get('impact')==i else ''),fill='#ffe5a5')
    grid.save(REVIEW/f'{stem}_numbered.png')
    # Three cycles eliminate GIF's 10ms quantisation drift for 8-frame clips.
    cycle=frames*3
    gif=[]
    for f in cycle:
        bg=Image.new('RGBA',SIZE,BG);bg.alpha_composite(f);gif.append(bg.resize((320,320),Image.Resampling.LANCZOS).convert('RGB').quantize(colors=240))
    gif[0].save(REVIEW/f'{stem}.gif',save_all=True,append_images=gif[1:],duration=[x*10 for x in durations(len(cycle),info['fps'])],loop=0,disposal=2,optimize=False)
    frames[0].save(REVIEW/f'{stem}.webp',save_all=True,append_images=frames[1:],duration=durations(len(frames),info['fps'],1000),loop=0,lossless=True)

def pair_preview(attacker,clip,defender,reaction):
    af=atlas_frames(attacker,clip);df=atlas_frames(defender,reaction)
    ai=json.loads((ASSETS/attacker/'anim/anim.json').read_text())['clips'][clip]
    dm=json.loads((ASSETS/defender/'anim/anim.json').read_text())['clips'][reaction]
    impact=ai['impact'];total=max(len(af),impact+len(df))+12
    canvas=[]
    shield_image=load('orc_shield','shield_3')
    for tick in range(total):
        a=af[min(tick,len(af)-1)];di=max(0,min(tick-impact,len(df)-1))
        d=df[di] if tick>=impact else atlas_frames(defender,'idle')[0]
        if attacker=='orc_shield':
            sp=ai['shield'][min(tick,len(af)-1)]
            a=comp(a,xf(shield_image,dx=sp[0]-95,dy=sp[1]-319))
        if defender=='orc_shield':
            sp=dm['shield'][di] if tick>=impact else (95,319)
            d=comp(d,xf(shield_image,dx=sp[0]-95,dy=sp[1]-319))
        bg=Image.new('RGBA',(768,420),BG)
        ad=ImageDraw.Draw(bg)
        ad.line((0,400,768,400),fill='#587285',width=2)
        ad.text((18,12),f'{attacker}: {clip} / impact {impact} -> {defender}: {reaction}',fill='white')
        travel=50*max(0,1-abs(tick-impact)/max(impact,1))
        knock=20*max(0,1-abs(tick-impact-2)/6) if tick>=impact else 0
        hero=a if attacker=='hero_rookie' else d
        orc=d if attacker=='hero_rookie' else a
        hx=int(15+(travel if attacker=='hero_rookie' else -knock))
        ox=int(365+(-travel if attacker=='orc_shield' else knock))
        bg.alpha_composite(hero.resize((384,384),Image.Resampling.LANCZOS),(hx,20))
        bg.alpha_composite(orc.resize((384,384),Image.Resampling.LANCZOS),(ox,20))
        canvas.append(bg.convert('RGB').quantize(colors=240))
    stem=f'{attacker}_{clip}_vs_{defender}_{reaction}'
    canvas[0].save(REVIEW/f'{stem}.gif',save_all=True,append_images=canvas[1:],duration=[v*10 for v in durations(total,24)],loop=0,disposal=2,optimize=False)
    return {'file':stem+'.gif','fps':24,'impact':impact,'reaction_first_frame':impact,'timeline_frames':total}


def batch1():
    hero=Hero();folder=ASSETS/'hero_rookie/anim';meta=json.loads((folder/'anim.json').read_text())
    for clip,spec in SPECS['hero_rookie'].items():
        n,fps,loop,*impact=spec;info={'frames':n,'fps':fps,'loop':loop}
        if impact:info['impact']=impact[0]
        if clip in ('idle','attack'):raise RuntimeError(f'Refusing to replace pilot {clip}')
        frames=hero_frames(clip,hero);write_clip('hero_rookie',clip,frames,info);meta['clips'][clip]=info
    (folder/'anim.json').write_text(json.dumps(meta,indent=2)+'\n')
    pairs=[pair_preview('hero_rookie',c,'orc_shield','hurt') for c in ('kick','bash','leap')]
    (REVIEW/'batch1_timing.json').write_text(json.dumps(pairs,indent=2)+'\n')

class Orc:
    def __init__(self):
        self.idle=atlas_frames('orc_shield','idle')[0];im=self.idle
        self.head=part(im,[(156,195),(165,153),(189,127),(189,100),(225,100),(249,109),(284,119),(308,136),(308,163),(332,174),(326,201),(308,226),(284,240),(270,259),(236,266),(207,242),(183,225)])
        self.left=part(im,[(160,237),(190,249),(187,282),(163,308),(140,321),(121,347),(97,363),(68,361),(47,348),(43,321),(53,303),(82,297),(104,277),(127,273),(145,250)])
        self.right=part(im,[(347,216),(377,220),(403,240),(426,267),(433,292),(424,325),(397,351),(368,372),(341,361),(346,335),(357,313),(369,287),(351,273)])
        self.legs=part(im,[(166,392),(229,395),(269,397),(297,390),(353,388),(380,423),(395,465),(412,478),(415,502),(94,502),(95,478),(119,464),(141,435)])
        body=im
        for p in (self.head,self.left,self.right,self.legs):body=cut(body,p)
        self.body=part(body,[(169,220),(214,219),(247,248),(276,243),(310,214),(350,207),(367,241),(350,281),(356,324),(365,350),(353,372),(371,394),(333,409),(295,394),(268,414),(240,400),(208,413),(168,402),(165,380),(185,350),(185,319),(182,284),(168,263)])
        # Reconstruct tunic area originally hidden by bent right arm.
        fill=blank();d=ImageDraw.Draw(fill)
        d.polygon([(315,242),(351,237),(353,315),(343,335),(315,326)],fill='#7c6c47',outline='#382b1a',width=3)
        self.body=comp(fill,self.body)
        self.bald=load('orc_shield','bald')
        self.baldtop=part(self.bald,[(0,0),(512,0),(512,319),(0,319)])
        self.baldbase=cut(self.bald,self.baldtop)
    def frame(self,lean=0,bodydy=0,head=0,left=0,right=0,ldx=0,ldy=0,rdx=0,rdy=0,expression=None,stone=False,bald=False):
        if bald:
            frame=comp(self.baldbase,xf(self.baldtop,head,(251,285),dy=bodydy))
            return frame,None
        hd=xf(self.head,head,(246,235))
        if expression:hd=self.expression(hd,expression)
        la=xf(self.left,left,(170,258),ldx,ldy)
        ra=xf(self.right,right,(361,251),rdx,rdy)
        bridge=blank();d=ImageDraw.Draw(bridge)
        d.ellipse((144,236,193,281),fill='#b4c742',outline='#382b19',width=3)
        d.ellipse((340,219,383,266),fill='#b4c742',outline='#382b19',width=3)
        if ldx or ldy:
            d.line((170,258,170+ldx,258+ldy),fill='#382b19',width=43)
            d.line((170,258,170+ldx,258+ldy),fill='#b4c742',width=35)
        if rdx or rdy:
            d.line((361,251,361+rdx,251+rdy),fill='#382b19',width=43)
            d.line((361,251,361+rdx,251+rdy),fill='#b4c742',width=35)
        if right < -70 and rdx < 0:
            # Reuse the same wrapped forearm texture for a fully extended release/punch.
            t=min(1,(-right-60)/45)
            dx=160-70*t;dy=-35*t
            ra=xf(self.left,-10*t,(170,258),dx,dy)
            d.line((361,251,170+dx,258+dy),fill='#382b19',width=45)
            d.line((361,251,170+dx,258+dy),fill='#b4c742',width=37)
        if stone:
            rock=blank();d=ImageDraw.Draw(rock)
            d.polygon([(354,330),(360,312),(381,305),(401,315),(408,334),(396,352),(372,358)],fill='#92928b',outline='#34352c',width=3)
            d.line([(362,319),(380,314),(395,322)],fill='#c5c4b1',width=4)
            ra=comp(ra,xf(rock,right,(361,251),rdx,rdy))
        upper=comp(bridge,self.body,hd,ra,la)
        frame=comp(self.legs,xf(upper,lean,(256,390),dy=bodydy))
        anchor=pointxf((95,319),left,(170,258),ldx,ldy)
        anchor=pointxf(anchor,lean,(256,390),dy=bodydy)
        return frame,anchor
    def expression(self,im,which):
        out=im.copy();d=ImageDraw.Draw(out)
        if which=='red':
            d.ellipse((190,157,203,170),fill='#ef3f2d',outline='#66291c',width=2)
            d.ellipse((224,168,237,181),fill='#ef3f2d',outline='#66291c',width=2)
        elif which=='scared':
            for x,y in ((196,159),(230,174)):
                d.ellipse((x-9,y-9,x+8,y+11),fill='#fffae5',outline='#3c321b',width=2)
                d.ellipse((x-1,y-3,x+3,y+6),fill='#302518')
            d.ellipse((173,206,233,239),fill='#472b23',outline='#34271a',width=3)
            d.polygon([(179,208),(186,224),(192,207)],fill='#fff0c5',outline='#34271a')
            d.polygon([(218,210),(225,225),(231,211)],fill='#fff0c5',outline='#34271a')
            d.ellipse((289,203,297,218),fill='#8cd6e6',outline='#2f5a61',width=1)
        elif which=='laugh':
            d.ellipse((175,204,238,242),fill='#42291f',outline='#342719',width=3)
            d.ellipse((184,226,224,240),fill='#cb7058')
            d.polygon([(179,205),(186,224),(194,205)],fill='#fff0c5',outline='#34271a')
            d.polygon([(220,210),(225,225),(232,211)],fill='#fff0c5',outline='#34271a')
        return out

ORC_KEYS={
 'throw':{0:{'right':35,'stone':True,'lean':-3},2:{'right':105,'stone':True,'head':6,'lean':-6},3:{'right':130,'stone':True,'lean':-7},4:{'right':-105,'rdx':-65,'rdy':45,'lean':9},5:{'right':-110,'rdx':-50,'rdy':35,'lean':8},7:{'right':-45,'rdx':-20,'rdy':10,'lean':3},9:{}},
 'charge':{0:{},2:{'lean':-8,'head':15,'left':-8,'bodydy':10},3:{'lean':-12,'head':18,'left':-12,'bodydy':15},4:{'lean':14,'head':18,'left':14,'right':-10,'bodydy':10},5:{'lean':12,'head':12,'left':10,'bodydy':7},7:{'lean':5,'head':5},9:{}},
 'dodge':{0:{},2:{'lean':-12,'head':-8,'left':-15,'right':15},4:{'lean':-18,'head':-12,'left':-22,'right':25},6:{'lean':-10,'head':-7,'left':25,'right':-45,'expression':'laugh'},8:{'lean':-5,'head':-4,'left':15,'right':-35,'expression':'laugh'},11:{}},
 'windup':{0:{'left':80,'right':-80,'rdy':35,'head':10,'expression':'red'},2:{'left':86,'right':-86,'rdy':35,'head':12,'expression':'red'},4:{'left':78,'right':-76,'rdy':35,'head':8,'expression':'red'},6:{'left':84,'right':-84,'rdy':35,'head':11,'expression':'red'},7:{'left':80,'right':-80,'rdy':35,'head':10,'expression':'red'}},
 'scared':{0:{'lean':-5,'head':-3,'left':25,'right':-35,'expression':'scared'},2:{'lean':-7,'head':2,'left':28,'right':-40,'expression':'scared'},4:{'lean':-4,'head':-4,'left':22,'right':-32,'expression':'scared'},6:{'lean':-6,'head':1,'left':27,'right':-38,'expression':'scared'},7:{'lean':-5,'head':-3,'left':25,'right':-35,'expression':'scared'}},
 'cheer':{0:{},2:{'right':-65,'rdy':30,'left':55,'head':-10,'expression':'laugh'},4:{'right':-90,'rdy':35,'left':75,'head':-15,'expression':'laugh'},5:{'right':-70,'rdy':25,'left':55,'head':-8,'expression':'laugh'},6:{'right':-90,'rdy':35,'left':75,'head':-15,'expression':'laugh'},8:{'right':-55,'left':35,'head':-8,'expression':'laugh'},11:{}},
 'bald':{0:{'bald':True,'head':-2},2:{'bald':True,'head':4,'bodydy':2},4:{'bald':True,'head':-5},6:{'bald':True,'head':2,'bodydy':1},7:{'bald':True,'head':-2}},
 'victory':{0:{'left':-85,'right':90,'head':-8,'expression':'laugh'},3:{'left':-100,'right':105,'head':-12,'bodydy':-6,'expression':'laugh'},6:{'left':-80,'right':85,'head':-6,'expression':'laugh'},9:{'left':-100,'right':100,'head':-10,'bodydy':-5,'expression':'laugh'},11:{'left':-85,'right':90,'head':-8,'expression':'laugh'}},
 'attack':{0:{},3:{'right':100,'lean':-6,'head':8},5:{'right':110,'lean':-8,'head':10},6:{'right':-105,'rdx':-60,'rdy':30,'lean':10},7:{'right':-90,'rdx':-50,'rdy':25,'lean':8},9:{'right':-35,'rdx':-10,'lean':3},11:{}},
}

def orc_frames(clip,orc):
    n=SPECS['orc_shield'][clip][0]
    if clip=='defeat':
        frames=[]
        for i in range(n):
            t=min(i/9,1)
            pose,_=orc.frame(left=-15,right=25,expression='scared')
            f=xf(pose,angle=-80*t,pivot=(256,490),dx=-135*t,dy=-210*t)
            bbox=f.getbbox();f=xf(f,dy=500-bbox[3]);frames.append(f)
        frames[0]=orc.idle.copy();return frames,None
    poses=timeline(ORC_KEYS[clip],n);frames=[];anchors=[]
    for pose in poses:
        f,a=orc.frame(**pose);frames.append(f);anchors.append(a)
    if clip not in ('bald','windup','scared','victory'):
        frames[-1]=orc.idle.copy();anchors[-1]=[95,319]
    return frames,anchors if clip!='bald' else None

def batch2():
    orc=Orc();folder=ASSETS/'orc_shield/anim';meta=json.loads((folder/'anim.json').read_text())
    for clip,spec in SPECS['orc_shield'].items():
        n,fps,loop,*impact=spec;info={'frames':n,'fps':fps,'loop':loop}
        if impact:info['impact']=impact[0]
        if clip in ('idle','hurt'):raise RuntimeError(f'Refusing to replace pilot {clip}')
        frames,anchors=orc_frames(clip,orc)
        if anchors:info['shield']=anchors
        write_clip('orc_shield',clip,frames,info);meta['clips'][clip]=info
    (folder/'anim.json').write_text(json.dumps(meta,indent=2)+'\n')
    timing=pair_preview('orc_shield','charge','hero_rookie','knocked')
    (REVIEW/'batch2_timing.json').write_text(json.dumps(timing,indent=2)+'\n')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--batch',type=int,required=True);args=parser.parse_args()
    if args.batch==1:batch1()
    elif args.batch==2:batch2()
