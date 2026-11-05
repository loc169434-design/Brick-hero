"""Pack #41 A/B hand-drawn whole tiles. No procedural drawing or recoloring.

Only rectangular crops, uniform scale/registration, atlas assembly, and requested
grayscale/review layouts. Large original image-tool sheets remain outside repo.
"""
from pathlib import Path
import argparse,hashlib,json,subprocess
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageOps

ROOT=Path(__file__).resolve().parents[2];DOC=ROOT/'docs/ideas';OUT=DOC/'swamp_variants_review'
SOURCE=DOC/'swamp_variants_sources.json'
COLORS=['red','green','yellow','purple']
POSES=['idle','blink','chuckle','laugh','fear','relief','scream','gloat','hurt','combo','drop','land']
ACTIONS={'idle':'idle','drop':'drop','land':'land','combo':'combo','hurt':'hurt','taunt':'laugh','fear':'fear','near_miss':'relief','gloat':'gloat','death':'scream','win':'scream','lose':'laugh'}
FONT_PATH='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
FONT=ImageFont.truetype(FONT_PATH,18);SMALL=ImageFont.truetype(FONT_PATH,14)

def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')

def gutter(occupied,center,radius):
    lo=max(1,round(center-radius));hi=min(len(occupied)-1,round(center+radius))
    zeros=np.flatnonzero(~occupied[lo:hi])+lo
    assert len(zeros),f'no transparent gutter near {center}; inspect source before cropping'
    runs=np.split(zeros,np.flatnonzero(np.diff(zeros)!=1)+1);runs=[r for r in runs if len(r)>=2]
    assert runs,'no safe gutter'
    run=min(runs,key=lambda r:abs((r[0]+r[-1])/2-center)-min(len(r),20)*.1)
    return int((run[0]+run[-1])//2)

def source_cels(key):
    s=DATA['sources'][key];p=Path(s['path'])
    assert hashlib.sha256(p.read_bytes()).hexdigest()==s['sha256'],key+' changed source'
    im=Image.open(p).convert('RGBA');cols,rows=s['grid']
    if 'crop_boxes' not in s:
        mask=np.asarray(im.getchannel('A'))>=16;h,w=mask.shape
        ys=[0]+[gutter(mask.any(1),i*h/rows,h/rows*.45) for i in range(1,rows)]+[h]
        boxes=[]
        for row in range(rows):
            occupied=mask[ys[row]:ys[row+1]].any(0)
            xs=[0]+[gutter(occupied,i*w/cols,w/cols*.45) for i in range(1,cols)]+[w]
            boxes.extend([[xs[c],ys[row],xs[c+1],ys[row+1]] for c in range(cols)])
        s['crop_boxes']=boxes
    assert len(s['crop_boxes'])==cols*rows,key+' source cell count'
    return [im.crop(box) for box in s['crop_boxes']]

def tile(im):
    box=im.getchannel('A').point(lambda a:255 if a>=32 else 0).getbbox()
    assert box,'blank tile source'
    l,t,r,b=box;im=im.crop((max(0,l-1),max(0,t-1),min(im.width,r+1),min(im.height,b+1)))
    im.thumbnail((126,126),Image.Resampling.LANCZOS)
    canvas=Image.new('RGBA',(128,128));canvas.alpha_composite(im,((128-im.width)//2,(128-im.height)//2));return canvas

def cel(im):
    out=Image.new('RGBA',(192,192));out.alpha_composite(im,(32,32));return out

def atlas(frames,columns):
    w,h=frames[0].size;out=Image.new('RGBA',(w*columns,h*((len(frames)+columns-1)//columns)))
    for i,f in enumerate(frames):out.alpha_composite(f,(i%columns*w,i//columns*h))
    return out

def vram(path):
    p=Path(str(path)+'.import')
    if p.exists():p.write_text(p.read_text().replace('compress/mode=0','compress/mode=2'))
    else:p.write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\ncompress/mode=2\n')

def jpg(im,name):
    path=OUT/name;im.convert('RGB').save(path,quality=91,subsampling=0,optimize=True)
    assert path.stat().st_size<2_000_000,path

def gray(im):
    result=ImageOps.grayscale(im).convert('RGBA');result.putalpha(im.getchannel('A'));return result

def metrics(tiles):
    values={}
    for c,im in tiles.items():
        small=im.resize((46,46),Image.Resampling.LANCZOS);a=np.asarray(small.getchannel('A'));g=np.asarray(ImageOps.grayscale(small))
        values[c]={'mean_gray46':float(g[a>=224].mean())}
    ordered=sorted(values,key=lambda c:values[c]['mean_gray46']);gap=min(values[b]['mean_gray46']-values[a]['mean_gray46'] for a,b in zip(ordered,ordered[1:]))
    return {'roles':values,'dark_to_light':ordered,'min_adjacent_mean_gray46_gap':gap}

def reviews(a,b):
    sets=[('Goblin/Orc hiện tại',{c:Image.open(ROOT/f'assets/tiles/orc_shield/tile_{c}.png').convert('RGBA') for c in COLORS}),('A — có huy hiệu',a),('B — không huy hiệu',b)]
    groups=[('128 px',128,False),('46 px',46,False),('Ảnh xám 128 px',128,True),('Ảnh xám 46 px',46,True)]
    widths=[4*size+3*8 for _,size,_ in groups];width=190+sum(widths)+3*30+30
    board=Image.new('RGB',(width,610),'#243844');d=ImageDraw.Draw(board)
    x=190
    for (label,_,_),w in zip(groups,widths):d.text((x,16),label,font=FONT,fill='#fff2d0');x+=w+30
    for row,(label,tiles) in enumerate(sets):
        y=70+row*175;d.text((12,y+48),label,font=SMALL,fill='white');x=190
        for (_,size,grayscale),w in zip(groups,widths):
            for j,c in enumerate(COLORS):
                im=gray(tiles[c]) if grayscale else tiles[c];im=im.resize((size,size),Image.Resampling.LANCZOS)
                board.paste(im,(x+j*(size+8),y+(128-size)//2),im)
            x+=w+30
    d.text((190,587),'RED: sát thương  |  GREEN: hồi máu  |  YELLOW: vàng  |  PURPLE: phá khiên',font=SMALL,fill='#fff2d0')
    jpg(board,'comparison_3_rows.jpg')
    # A narrow companion remains easy to inspect on a phone without scaling the
    # requested 46px samples. The full comparison above retains native 128px.
    for grayscale,name in [(False,'comparison_46px.jpg'),(True,'comparison_gray_46px.jpg')]:
        im=Image.new('RGB',(470,290),'#243844');draw=ImageDraw.Draw(im)
        for row,(label,tiles) in enumerate(sets):
            y=28+row*82;draw.text((12,y+15),label,font=SMALL,fill='white')
            for j,c in enumerate(COLORS):
                f=gray(tiles[c]) if grayscale else tiles[c];f=f.resize((46,46),Image.Resampling.LANCZOS);im.paste(f,(210+j*58,y),f)
        jpg(ImageOps.grayscale(im).convert('RGB') if grayscale else im,name)
    rng=np.random.default_rng(4102);layout=np.array(COLORS*14,dtype=object);rng.shuffle(layout);layout=layout.reshape(8,7).tolist()
    write(OUT/'board_layout_7x8.json',{'seed':4102,'columns':7,'rows':8,'counts':{c:14 for c in COLORS},'layout':layout})
    def whole_board(tiles,size,label):
        gap=4;w=7*size+8*gap;h=8*size+9*gap;im=Image.new('RGB',(w,h+48),'#243844');draw=ImageDraw.Draw(im);draw.text((10,13),label,font=FONT if size==128 else SMALL,fill='#fff2d0')
        for row in range(8):
            for col in range(7):
                f=tiles[layout[row][col]].resize((size,size),Image.Resampling.LANCZOS);im.paste(f,(gap+col*(size+gap),48+gap+row*(size+gap)),f)
        return im
    for label,tiles in sets:
        slug='current' if label.startswith('Goblin') else 'a' if label.startswith('A') else 'b'
        jpg(whole_board(tiles,128,label+' · 7×8'),'board_'+slug+'_128px.jpg')
    for grayscale,name in [(False,'boards_46px.jpg'),(True,'boards_gray_46px.jpg')]:
        previews=[whole_board({c:gray(t) for c,t in tiles.items()} if grayscale else tiles,46,label) for label,tiles in sets]
        im=Image.new('RGB',(sum(p.width for p in previews)+24,max(p.height for p in previews)),'#243844');x=0
        for p in previews:im.paste(p,(x,0));x+=p.width+12
        jpg(ImageOps.grayscale(im).convert('RGB') if grayscale else im,name)
    write(OUT/'palette_metrics.json',metrics(b))

def pack_family(family,letter,masters,original):
    dest=ROOT/'assets/tiles'/family;(dest/'expressions').mkdir(parents=True,exist_ok=True);(dest/'animations').mkdir(exist_ok=True)
    entries=[]
    for color in COLORS:
        raw=source_cels(f'{letter}_{color}_0')+source_cels(f'{letter}_{color}_1');assert len(raw)==48
        frames=[cel(tile(f)) for f in raw];clips={p:frames[i*4:i*4+4] for i,p in enumerate(POSES)}
        clips['idle'][0]=cel(masters[color]);clips['idle'][-1]=cel(masters[color])
        expressions=[]
        for pose in POSES[:9]:
            im=clips[pose][0 if pose=='idle' else 1].crop((32,32,160,160));expressions.append(im)
            im.save(dest/'expressions'/f'{color}_{pose}.png',optimize=True)
        atlas(expressions,3).save(dest/f'expressions_{color}.png',optimize=True);masters[color].save(dest/f'tile_{color}.png',optimize=True)
        for action,pose in ACTIONS.items():
            fs=[f.copy() for f in clips[pose]]
            if action=='near_miss':fs=[clips['fear'][1],clips['relief'][0],clips['relief'][2],clips['laugh'][1]]
            if action in ['death','win']:fs=[clips['fear'][0],clips['scream'][1],clips['scream'][2],Image.new('RGBA',(192,192))]
            path=dest/'animations'/f'{color}_{action}.png';atlas(fs+[Image.new('RGBA',(192,192))]*4,8).save(path,optimize=True);vram(path)
            entry=dict(next(e for e in original if e['color']==color and e['animation']==action));entry.update({'family':family,'file':str(path.relative_to(ROOT))});entries.append(entry)
        source=ROOT/f'assets/tiles/swamp/sprite_frames_{color}.tres';text=source.read_text()
        (dest/f'sprite_frames_{color}.tres').write_text(text.replace('/swamp/','/'+family+'/'))
        if letter=='a':
            from pack_campaign_g2 import preview
            preview('tiles_'+color,[clips[p][0].resize((512,512)) for p in POSES],8)
    write(dest/'swamp_manifest.json',{'family':family,'variant':letter.upper(),'expressions':POSES[:9],'animations':entries,
        'role_names_unchanged':True,'role_badges':letter=='a','palette':DATA['palette_b'] if letter=='b' else {'red':'red','green':'green','yellow':'yellow','purple':'purple'},
        'shared_drawn_cels':{'death/win':'fear+scream','taunt/lose':'laugh','near_miss':'fear+relief+laugh'},
        'notes':'4 independently hand-drawn cels per source action; intentional reuse documented, no pose interpolation.'})
    return entries

def main(review_only=False):
    global DATA
    DATA=json.loads(SOURCE.read_text());OUT.mkdir(exist_ok=True);(OUT/'.gdignore').touch()
    a=dict(zip(COLORS,[tile(f) for f in source_cels('a_master')]))
    b=dict(zip(COLORS,[tile(f) for f in source_cels('b_master')]))
    if not review_only:
        path=ROOT/'assets/tiles/animation_pack.json';manifest=json.loads(path.read_text())
        original=[e for e in manifest['atlases'] if e['family']=='swamp']
        new=pack_family('swamp','a',a,original)+pack_family('swamp_b','b',b,original)
        manifest['atlases']=[e for e in manifest['atlases'] if e['family'] not in ['swamp','swamp_b']]+new
        manifest['families']['swamp']={'label':'Đầm lầy Cóc — A','animations':list(ACTIONS)}
        manifest['families']['swamp_b']={'label':'Đầm lầy Cóc — B, không huy hiệu','animations':list(ACTIONS)}
        write(path,manifest)
    reviews(a,b)
    if not review_only:
        (DOC/'campaign_g2_review/tiles_46px.jpg').write_bytes((OUT/'comparison_3_rows.jpg').read_bytes())
    write(SOURCE,DATA)
    print(json.dumps(metrics(b),ensure_ascii=False))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--review-only',action='store_true');main(p.parse_args().review_only)
