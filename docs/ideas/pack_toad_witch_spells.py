"""Pack hand-drawn #42 cels; whole-image crops/scales/registration only.

Large image-tool originals stay outside the checkout. Never construct a pose,
paint a body part, remove alpha components, or interpolate transformation cels.
"""
from pathlib import Path
import argparse,hashlib,json,math
import numpy as np
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[2];DOC=ROOT/'docs/ideas'
OUT=DOC/'toad_witch_spells_review';MANIFEST=DOC/'toad_witch_spells_sources.json'

WITCH={
 'cast_toads':(12,14,False,7),'cast_broom':(12,14,False,6),
 'throw_potion':(12,14,False,6),'cackle':(8,10,True,None),
 'stomp_angry':(8,12,False,4),'drink_transform':(16,12,False,15)}
GIANT={'burp_toads':(10,12,False,5),'victory':(8,8,False,None)}
TOAD={'transform_in':(14,14,False,9),'idle':(8,10,True,None),
      'attack':(8,14,False,4),'hurt':(6,12,False,None),'transform_out':(14,14,False,10)}
BROOM={'idle':(8,12,True,None),'attack':(12,24,False,6),'hurt':(8,24,False,None),
       'broom_in':(12,14,False,7),'broom_out':(12,14,False,6)}
FX={'toad_hop':(6,14),'poof_green':(8,14),'broom_spell':(8,14),'spell_break':(8,14)}

def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')

def cut_at_empty_gutter(occupied,expected,radius):
    lo=max(1,round(expected-radius));hi=min(len(occupied)-1,round(expected+radius))
    candidates=np.flatnonzero(~occupied[lo:hi])+lo
    if not len(candidates):raise ValueError(f'No transparent gutter near {expected}; inspect and supply explicit crop boxes')
    runs=np.split(candidates,np.flatnonzero(np.diff(candidates)!=1)+1)
    runs=[r for r in runs if len(r)>=2]
    if not runs:raise ValueError('No safe two-pixel gutter')
    best=min(runs,key=lambda r:abs((r[0]+r[-1])/2-expected)-min(len(r),20)*.1)
    return int((best[0]+best[-1])//2)

def measure_boxes(image,cols,rows):
    # Generated sheets often have uneven row/column spacing. Locate actual clear
    # gutters instead of assuming equal subdivisions, which caused #41.
    mask=np.asarray(image.getchannel('A'))>=8;h,w=mask.shape
    ys=[0]+[cut_at_empty_gutter(mask.any(axis=1),i*h/rows,h/rows*.48) for i in range(1,rows)]+[h]
    boxes=[]
    for row in range(rows):
        occupied=mask[ys[row]:ys[row+1]].any(axis=0)
        xs=[0]+[cut_at_empty_gutter(occupied,i*w/cols,w/cols*.48) for i in range(1,cols)]+[w]
        boxes.extend([[xs[col],ys[row],xs[col+1],ys[row+1]] for col in range(cols)])
    return boxes

def load_cels(key,cols,rows):
    entry=DATA['sources'][key];path=Path(entry['path'])
    assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'],key+' changed original'
    im=Image.open(path).convert('RGBA')
    if 'crop_boxes' not in entry:entry['crop_boxes']=measure_boxes(im,cols,rows)
    assert len(entry['crop_boxes'])==cols*rows,key+' grid count'
    return [im.crop(box) for box in entry['crop_boxes']]

def registered(raw,fit=440,size=512,center=False,offsets=None):
    boxes=[f.getchannel('A').point(lambda a:255 if a>=32 else 0).getbbox() for f in raw]
    valid=[b for b in boxes if b];assert valid,'empty source'
    scale=min(fit/max(b[2]-b[0] for b in valid),fit/max(b[3]-b[1] for b in valid))
    out=[]
    for i,(im,b) in enumerate(zip(raw,boxes)):
        cell=Image.new('RGBA',(size,size))
        if b:
            resized=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
            x=round(size/2-(b[0]+b[2])/2*scale)
            y=round((size/2-(b[1]+b[3])/2*scale) if center else (500-b[3]*scale))
            y+=(offsets or {}).get(i,0)
            cell.alpha_composite(resized,(x,y))
        out.append(cell)
    return out

def atlas(frames):
    im=Image.new('RGBA',(2048,512*math.ceil(len(frames)/4)))
    for i,f in enumerate(frames):im.alpha_composite(f,(i%4*512,i//4*512))
    return im

def vram(path):
    sidecar=Path(str(path)+'.import')
    if sidecar.exists():sidecar.write_text(sidecar.read_text().replace('compress/mode=0','compress/mode=2'))
    else:sidecar.write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\ncompress/mode=2\n')

def preview(name,frames,fps):
    # Three cycles make average GIF timing exact for 12/14/24fps within 10ms.
    images=[];times=[]
    for k in range(3*len(frames)):
        f=frames[k%len(frames)];bg=Image.new('RGBA',f.size,'#193444');bg.alpha_composite(f)
        images.append(bg.convert('RGB').resize((224,224),Image.Resampling.LANCZOS))
        times.append((round((k+1)*100/fps)-round(k*100/fps))*10)
    path=OUT/(name+'.gif')
    images[0].save(path,save_all=True,append_images=images[1:],duration=times,loop=0,disposal=2,optimize=False)
    assert path.stat().st_size<2_000_000,path

def clip_info(spec):
    n,fps,loop,impact=spec;info={'frames':n,'fps':fps,'loop':loop}
    if impact is not None:info['impact']=impact
    return info

def original_idle(cid):
    return Image.open(ROOT/f'assets/characters/{cid}/anim/fresh_idle.png').convert('RGBA').crop((0,0,512,512))

def save_clip(dest,name,frames,spec,prefix='fresh'):
    dest.mkdir(parents=True,exist_ok=True);path=dest/f'{prefix}_{name}.png'
    atlas(frames).save(path,optimize=True);vram(path)
    preview(dest.parent.name+'_'+prefix+'_'+name if dest.name=='anim' else 'broom_'+prefix+'_'+name,frames,spec[1])

def actors():
    witch=original_idle('toad_witch');giant=original_idle('toad_witch_giant');hero=original_idle('hero_rookie')
    for cid,specs,prefix,neutral in [('toad_witch',WITCH,'witch',witch),('toad_witch_giant',GIANT,'giant',giant)]:
        dest=ROOT/f'assets/characters/{cid}/anim';meta=json.loads((dest/'anim.json').read_text())
        for name,spec in specs.items():
            n=spec[0];fs=registered(load_cels(prefix+'_'+name,4,math.ceil(n/4))[:n])
            fs[0]=neutral.copy();fs[-1]=giant.copy() if name=='drink_transform' else neutral.copy()
            save_clip(dest,name,fs,spec);meta['clips'][name]=clip_info(spec)
            projectile={
                'cast_toads':{'embedded_frames':[6,7,8],'external_from_frame':9,'count':3,'asset':'res://assets/fx/curse/toad_hop.png'},
                'cast_broom':{'embedded_frames':[5,6,7],'external_from_frame':8,'count':1,'asset':'res://assets/fx/curse/broom_spell.png'},
                'throw_potion':{'embedded_frames':[6,7],'external_from_frame':8,'count':1,'asset':'res://assets/board/obstacles/potion_bottle.png'},
                'burp_toads':{'embedded_frames':[5,6],'external_from_frame':7,'count':2,'asset':'res://assets/fx/curse/toad_hop.png'},
            }.get(name)
            if projectile:meta['clips'][name]['projectile_visual']=projectile
            if cid=='toad_witch_giant' and name=='victory':fs[0].save(dest.parent/'victory.png',optimize=True)
        write(dest/'anim.json',meta)
        rig_path=dest.parent/'rig.json';rig=json.loads(rig_path.read_text())
        anchor=rig['anchors'].get('fresh_idle',{'head':[256,150],'mouth':[256,190]})
        for name in specs:rig['anchors']['fresh_'+name]=dict(anchor)
        write(rig_path,rig)
    # Standalone toad form is deliberately smaller, with brown hair/red scarf.
    dest=ROOT/'assets/characters/hero_toad';anim=dest/'anim';meta={'frame_size':[512,512],'columns':4,'clips':{}}
    idle=registered(load_cels('hero_toad_idle',4,2),fit=280);idle[-1]=idle[0].copy();toad=idle[0]
    for name,spec in TOAD.items():
        n=spec[0]
        if name=='idle':fs=idle
        else:
            fs=registered(load_cels('hero_toad_'+name,4,math.ceil(n/4))[:n],fit=440 if name.startswith('transform') or name=='attack' else 280,
                          offsets={2:-20,3:-35,4:-25} if name=='attack' else None)
            fs[0]=hero.copy() if name=='transform_in' else toad.copy()
            fs[-1]=hero.copy() if name=='transform_out' else toad.copy()
        save_clip(anim,name,fs,spec);meta['clips'][name]=clip_info(spec)
        if name in ['idle','attack','hurt']:fs[0].save(dest/f'fresh_{name}.png',optimize=True)
    toad.save(dest/'idle.png',optimize=True)
    write(anim/'anim.json',meta)
    write(dest/'rig.json',{'id':'hero_toad','canvas':[512,512],'feet':[256,500],
                          'anchors':{'fresh_'+name:{'head':[256,345],'mouth':[350,395]} for name in TOAD},
                          'facing':1,'source_identity':'hero_rookie','notes':'Brown hair and red scarf identify the hero; only fresh art, wear uses fallback.'})

def broom():
    dest=ROOT/'assets/characters/hero_rookie/anim/broom';neutral={}
    for wear in ['fresh','bruised','battered']:
        fs=registered(load_cels('broom_'+wear+'_idle',4,2));neutral[wear]=fs[0].copy()
        for name in ['idle','attack','hurt']:
            spec=BROOM[name];n=spec[0]
            frames=fs if name=='idle' else registered(load_cels('broom_'+wear+'_'+name,4,math.ceil(n/4))[:n])
            frames[0]=neutral[wear].copy();frames[-1]=neutral[wear].copy()
            save_clip(dest,name,frames,spec,wear)
    hero=original_idle('hero_rookie')
    for name in ['broom_in','broom_out']:
        spec=BROOM[name];frames=registered(load_cels(name,4,3))
        frames[0]=hero.copy() if name=='broom_in' else neutral['fresh'].copy()
        frames[-1]=neutral['fresh'].copy() if name=='broom_in' else hero.copy()
        save_clip(dest,name,frames,spec)
    write(dest/'anim.json',{'frame_size':[512,512],'columns':4,'variant':'broom','facing':1,
                           'wears':['fresh','bruised','battered'],'clips':{k:clip_info(v) for k,v in BROOM.items()},
                           'fresh_only':['broom_in','broom_out'],'requires_loader_support_for_subdirectory':True})

def world():
    dest=ROOT/'assets/board/obstacles';meta=json.loads((dest/'obstacles.json').read_text())
    for key,name,n,fps,loop in [('potion_idle','potion_bottle_idle',4,10,True),('potion_break','potion_break',4,14,False),('potion_burst','potion_burst',8,14,False)]:
        fs=registered(load_cels(key,4,math.ceil(n/4))[:n],center=True,fit=430)
        if not loop:fs[-1]=Image.new('RGBA',(512,512))
        path=dest/(name+'.png');atlas(fs).save(path,optimize=True);vram(path)
        meta['clips'][name]={'frame_width':512,'frame_height':512,'frames':n,'fps':fps,'loop':loop}
        preview(name,fs,fps)
        if loop:
            fs[0].resize((256,256),Image.Resampling.LANCZOS).save(dest/'potion_bottle.png',optimize=True)
            meta['layers']['potion_bottle']=['potion_bottle.png']
    write(dest/'obstacles.json',meta)
    dest=ROOT/'assets/fx/curse';meta={}
    for name,(n,fps) in FX.items():
        fs=registered(load_cels('fx_'+name,4,math.ceil(n/4))[:n],center=True,fit=430)
        if name!='toad_hop':fs[-1]=Image.new('RGBA',(512,512))
        path=dest/(name+'.png');dest.mkdir(parents=True,exist_ok=True);atlas(fs).save(path,optimize=True);vram(path)
        meta[name]={'frames':n,'fps':fps,'columns':4,'frame_size':[512,512],'loop':False}
        preview('curse_'+name,fs,fps)
    write(dest/'anim.json',meta)
    dest=ROOT/'assets/ui/status';dest.mkdir(parents=True,exist_ok=True)
    raw=load_cels('status_icons',3,1)
    fs=registered(raw,fit=112,size=128,center=True)
    for name,im in zip(['toad','broom','poison'],fs):im.save(dest/(name+'.png'),optimize=True)
    board=Image.new('RGBA',(480,170),'#193444');d=ImageDraw.Draw(board)
    for i,(name,im) in enumerate(zip(['toad','broom','poison'],fs)):
        board.alpha_composite(im,(i*160+16,16));d.text((i*160+16,149),name,fill='white')
    board.convert('RGB').save(OUT/'status_icons.gif')

def main(group):
    global DATA
    DATA=json.loads(MANIFEST.read_text());OUT.mkdir(parents=True,exist_ok=True);(OUT/'.gdignore').touch()
    if group in ['actors','all']:actors()
    if group in ['broom','all']:broom()
    if group in ['world','all']:world()
    write(MANIFEST,DATA)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--group',choices=['actors','broom','world','all'],default='all');main(p.parse_args().group)
