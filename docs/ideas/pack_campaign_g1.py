"""Pack generated complete drawings; no body-part rigging or pose synthesis.

Only crop grid cells, scale whole drawings uniformly, register, and export.
Sources are retained beside this script so outputs can be reproduced.
"""
from pathlib import Path
import json, math, hashlib, shutil
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/ideas'
REVIEW = DOC / 'campaign_g1_review'
SOURCES = DOC / 'campaign_g1_sources'
SPEC = [('idle',0,4,8,True,None),('attack',4,6,12,False,4),
        ('hurt',10,4,12,False,None),('special',14,8,12,False,5),
        ('defeat',22,6,10,False,None),('victory',28,4,8,False,None)]
REPORT = {'characters':{},'sources':{},'maps':[], 'chapters':[]}

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')

def cells(path, columns, rows):
    im = Image.open(path).convert('RGBA')
    return [im.crop((round(x*im.width/columns),round(y*im.height/rows),
                    round((x+1)*im.width/columns),round((y+1)*im.height/rows)))
            for y in range(rows) for x in range(columns)]

def register(frames):
    boxes = [f.getchannel('A').point(lambda a:255 if a>64 else 0).getbbox() for f in frames]
    assert all(boxes), 'empty character source cell'
    # ONE scale across the entire character, never stretch individual limbs/cels.
    scale = min(440/max(b[2]-b[0] for b in boxes),440/max(b[3]-b[1] for b in boxes))
    out=[]
    for f,b in zip(frames, boxes):
        x=(b[0]+b[2])/2; y=b[3]
        resized=f.resize((round(f.width*scale),round(f.height*scale)),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',(512,512))
        canvas.alpha_composite(resized,(round(256-x*scale),round(500-y*scale)))
        out.append(canvas)
    return out

def sheet(frames, columns=4):
    w,h=frames[0].size
    out=Image.new('RGBA',(columns*w,math.ceil(len(frames)/columns)*h))
    for i,f in enumerate(frames): out.alpha_composite(f,(i%columns*w,i//columns*h))
    return out

def preview(name, frames, fps):
    rgb=[]
    for f in frames:
        bg=Image.new('RGBA',f.size,'#193444');bg.alpha_composite(f)
        rgb.append(bg.resize((224,224)).convert('RGB'))
    durations=[(round((i+1)*100/fps)-round(i*100/fps))*10 for i in range(len(rgb))]
    rgb[0].save(REVIEW/f'{name}.gif',save_all=True,append_images=rgb[1:],duration=durations,loop=0,disposal=2)
    grid=Image.new('RGB',(896,math.ceil(len(rgb)/4)*250),'#193444'); d=ImageDraw.Draw(grid)
    for i,f in enumerate(rgb):
        x=i%4*224;y=i//4*250;grid.paste(f,(x,y+26));d.text((x+8,y+6),str(i),fill='white')
    grid.save(REVIEW/f'{name}.jpg',quality=88)

def character(cid, raw, specs=SPEC, canonical=None):
    frames=register(raw); dest=ROOT/'assets/characters'/cid
    (dest/'anim').mkdir(parents=True,exist_ok=True)
    meta={'frame_size':[512,512],'columns':4,'clips':{}}
    anchors={}; counts={}
    neutral=canonical or frames[0]
    for clip,start,n,fps,loop,impact in specs:
        fs=[f.copy() for f in frames[start:start+n]]
        if clip in ('attack','hurt','special'): fs[0]=neutral.copy();fs[-1]=neutral.copy()
        if clip=='idle': fs[-1]=neutral.copy()
        info={'frames':n,'fps':fps,'loop':loop}
        if impact is not None: info['impact']=impact
        meta['clips'][clip]=info
        sheet(fs).save(dest/'anim'/f'fresh_{clip}.png',optimize=True)
        imp=dest/'anim'/f'fresh_{clip}.png.import'
        if imp.exists():
            imp.write_text(imp.read_text().replace('compress/mode=0','compress/mode=2'))
        else:
            imp.write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\ncompress/mode=2\n')
        fs[0 if clip!='defeat' else -1].save(dest/(f'{clip}.png' if clip in ('defeat','victory') else f'fresh_{clip}.png'),optimize=True)
        anchors['fresh_'+clip]={'head':[256,150],'mouth':[256,190]}
        preview(cid+'_'+clip,fs,fps)
        counts[clip]={'frames':n,'unique':len({hashlib.sha256(f.tobytes()).hexdigest() for f in fs})}
    write(dest/'anim/anim.json',meta)
    write(dest/'rig.json',{'id':cid,'canvas':[512,512],'feet':[256,500],'anchors':anchors})
    REPORT['characters'][cid]=counts

def main():
    REVIEW.mkdir(exist_ok=True);SOURCES.mkdir(exist_ok=True)
    manifest=json.loads((DOC/'campaign_g1_sources.json').read_text())
    paths={}
    for key,path in manifest.items():
        path=Path(path); path=path if path.is_absolute() else DOC/path
        target=SOURCES/(key+'.png')
        if path.resolve()!=target.resolve(): shutil.copy2(path,target)
        paths[key]=target
        REPORT['sources'][key]={'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'size':list(Image.open(target).size)}
    write(DOC/'campaign_g1_sources.json',{k:'campaign_g1_sources/'+k+'.png' for k in paths})
    if 'icons' in paths: export_icons(paths['icons'])
    for key,cid in [('rock','orc_rock'),('drummer','orc_drummer'),('boar','orc_boar'),('chief','orc_chief')]:
        character(cid,cells(paths[key],4,8))
    character('orc_chief_enraged',cells(paths['chief_rage'],4,4),[
        ('idle',0,4,8,True,None),('attack',4,8,16,False,4),('special',12,4,8,False,2)])
    dummy=cells(paths['scarecrows'],4,4)
    character('scarecrow_wood',dummy[:8],[('idle',0,4,8,True,None),('attack',4,4,8,False,2)])
    character('scarecrow_straw_shield',dummy[8:],[('idle',0,4,8,True,None),('hurt',4,4,12,False,None)])
    obs=cells(paths['obstacles'],4,4); dest=ROOT/'assets/board/obstacles';dest.mkdir(parents=True,exist_ok=True)
    for name,index in [('crate_3',0),('crate_2',1),('crate_1',2),('rock',4),('rock_cracked',5)]:
        f=obs[index];f.thumbnail((240,240));out=Image.new('RGBA',(256,256));out.alpha_composite(f,((256-f.width)//2,(256-f.height)//2));out.save(dest/(name+'.png'))
    fx={}
    for name,start in [('crate_break',8),('rock_break',12)]:
        fs=[]
        for f in obs[start:start+3]:
            f.thumbnail((480,480));out=Image.new('RGBA',(512,512));out.alpha_composite(f,((512-f.width)//2,(512-f.height)//2));fs.append(out)
        fs.append(Image.new('RGBA',(512,512)))
        sheet(fs).save(dest/(name+'.png'));fx[name]={'frame_width':512,'frame_height':512,'frames':4,'fps':12,'loop':False}
        preview(name,fs,12)
    write(dest/'obstacles.json',{'layers':{'crate':['crate_1.png','crate_2.png','crate_3.png'],'rock':['rock.png']},'clips':fx})
    mapdir=ROOT/'assets/bg/campaign';mapdir.mkdir(parents=True,exist_ok=True)
    mapcoords=[[(520,1760),(460,1500),(760,1360),(330,1100),(610,680)],
        [(540,1840),(400,1660),(220,1500),(570,1390),(750,1240),(480,1115),(250,990),(630,875),(800,750),(420,650),(300,540),(740,425),(575,230)]]
    nodes=[]
    for seg in range(1,3):
        im=Image.open(paths['map'+str(seg)]).convert('RGB').resize((1080,1920),Image.Resampling.LANCZOS)
        im.save(mapdir/f'segment_{seg:02}.png',optimize=True)
        marked=im.copy();d=ImageDraw.Draw(marked)
        for x,y in mapcoords[seg-1]:
            level=len(nodes)+1;node={'level':level,'segment':seg,'x':x,'y':y,'hard':level==14,'boss':level==18,'bonus':level==15,'petal':level==5};nodes.append(node)
            d.ellipse((x-32,y-32,x+32,y+32),fill='#b83228',outline='white',width=3);d.text((x-9,y-7),str(level),fill='white')
        marked.resize((540,960)).save(REVIEW/f'map_{seg:02}_nodes.jpg',quality=90)
    write(mapdir/'nodes_g1.json',nodes)
    for ch in range(1,3):
        raw=cells(paths['chapter'+str(ch)],2,3);dest=ROOT/'assets/story'/f'chapter_{ch:02}';dest.mkdir(parents=True,exist_ok=True)
        panels=[]
        for i,f in enumerate(raw,1):
            # Remove narrow panel gutters, uniformly scale full panel, never repaint.
            f=f.crop((5,5,f.width-5,f.height-5)).convert('RGB')
            f=f.resize((1080,round(f.height*1080/f.width)),Image.Resampling.LANCZOS)
            filename=f'panel_{i:02}.png';f.save(dest/filename,optimize=True);panels.append(filename)
        write(dest/'chapter.json',{'chapter':ch,'after_level':5 if ch==1 else 18,'panels':panels,'text_baked':False})
        Image.open(paths['chapter'+str(ch)]).convert('RGB').resize((720,1080)).save(REVIEW/f'chapter_{ch:02}.jpg',quality=90)
    write(REVIEW/'packing_report.json',REPORT)
    # Preserve approved follow-up redraws when rebuilding the original G1 batch.
    if (DOC/'issue41_part0_sources.json').exists():
        from pack_issue41_part0 import main as pack_part0
        pack_part0()

def export_icons(path):
    names=['node_hard','node_boss','node_bonus','node_petal','golden_petal','orc_flag','rescue_cage','brass_key']
    dest=ROOT/'assets/ui/campaign';dest.mkdir(parents=True,exist_ok=True)
    for name,f in zip(names,cells(path,4,2)):
        f.thumbnail((240,240))
        out=Image.new('RGBA',(256,256));out.alpha_composite(f,((256-f.width)//2,(256-f.height)//2))
        out.save(dest/(name+'.png'),optimize=True)

if __name__=='__main__':main()
