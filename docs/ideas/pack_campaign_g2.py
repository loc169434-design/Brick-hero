"""Pack complete image-tool drawings for #41; no pose rigging or painting.

Generated sources stay outside repo. Run --group priority/characters/tiles/world/npcs/story.
"""
from pathlib import Path
import argparse, json, math, hashlib, io, subprocess
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2];DOC=ROOT/'docs/ideas';REVIEW=DOC/'campaign_g2_review'
SPEC=[('idle',0,4,8,True,None),('attack',4,6,12,False,4),('hurt',10,4,12,False,None),('special',14,8,12,False,5),('defeat',22,6,10,False,None),('victory',28,4,8,False,None)]
NAMES=['toad_spitter','goblin_archer','swamp_leech','goblin_thief','goblin_bomber','swamp_spider','frost_slime','crocodile','toad_witch','toad_witch_giant']

def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def source(key):return Path(MANIFEST['sources'][key]['path'])
def cells(path,cols,rows):
    im=Image.open(path).convert('RGBA')
    return [im.crop((round(x*im.width/cols),round(y*im.height/rows),round((x+1)*im.width/cols),round((y+1)*im.height/rows))) for y in range(rows) for x in range(cols)]
def register(raw,size=512,fit=440,center=None):
    boxes=[f.getchannel('A').point(lambda a:255 if a>64 else 0).getbbox() for f in raw]
    assert all(boxes),'empty source drawing'
    scale=min(fit/max(b[2]-b[0] for b in boxes),fit/max(b[3]-b[1] for b in boxes));out=[]
    for f,b in zip(raw,boxes):
        x=(b[0]+b[2])/2;y=b[3] if center is None else (b[1]+b[3])/2
        dx=size/2;dy=500 if center is None else center
        im=Image.new('RGBA',(size,size));res=f.resize((round(f.width*scale),round(f.height*scale)),Image.Resampling.LANCZOS);im.alpha_composite(res,(round(dx-x*scale),round(dy-y*scale)));out.append(im)
    return out
def sheet(frames,cols=4):
    w,h=frames[0].size;im=Image.new('RGBA',(w*cols,h*math.ceil(len(frames)/cols)))
    for i,f in enumerate(frames):im.alpha_composite(f,(i%cols*w,i//cols*h))
    return im
def vram(path):
    p=Path(str(path)+'.import')
    if p.exists():p.write_text(p.read_text().replace('compress/mode=0','compress/mode=2'))
    else:p.write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\ncompress/mode=2\n')
def jpg(im,path,width=1000):
    im=im.convert('RGB');im.thumbnail((width,10000));im.save(path,quality=85,optimize=True);assert path.stat().st_size<2_000_000,path
def preview(name,frames,fps):
    rgb=[]
    for f in frames:
        bg=Image.new('RGBA',f.size,'#193444');bg.alpha_composite(f);rgb.append(bg.resize((224,224)).convert('RGB'))
    duration=[(round((i+1)*100/fps)-round(i*100/fps))*10 for i in range(len(frames))]
    rgb[0].save(REVIEW/(name+'.gif'),save_all=True,append_images=rgb[1:],duration=duration,loop=0,disposal=2)
    im=Image.new('RGB',(896,250*math.ceil(len(frames)/4)),'#193444');d=ImageDraw.Draw(im)
    for i,f in enumerate(rgb):x=i%4*224;y=i//4*250;im.paste(f,(x,y+26));d.text((x+8,y+7),str(i),fill='white')
    jpg(im,REVIEW/(name+'.jpg'))
def anchor_points(cid,neutral):
    box=neutral.getchannel('A').point(lambda a:255 if a>64 else 0).getbbox();x,y,r,b=box;w=r-x;h=b-y
    fractions={'toad_spitter':(.34,.26,.10,.52),'toad_witch_giant':(.35,.35,.12,.57),'swamp_leech':(.14,.35,.06,.45),'swamp_spider':(.27,.35,.19,.58),'frost_slime':(.46,.44,.40,.60),'crocodile':(.40,.24,.12,.38),'fairy_crow':(.35,.25,.14,.38)}
    if cid not in fractions:return {'head':[256,150],'mouth':[256,190]}
    hx,hy,mx,my=fractions[cid];return {'head':[round(x+hx*w),round(y+hy*h)],'mouth':[round(x+mx*w),round(y+my*h)]}
def character(cid,raw,specs=SPEC):
    fs=register(raw);dest=ROOT/'assets/characters'/cid;(dest/'anim').mkdir(parents=True,exist_ok=True);neutral=fs[0].copy()
    meta={'frame_size':[512,512],'columns':4,'clips':{}}
    for clip,start,n,fps,loop,impact in specs:
        frames=[f.copy() for f in fs[start:start+n]]
        if cid=='goblin_archer' and clip=='special':
            frames=[neutral.copy(),fs[16],fs[17],fs[19],fs[20],fs[21],fs[22],neutral.copy()]
        if cid=='toad_witch' and clip=='defeat':frames[-1]=fs[26].copy()
        if clip in ['idle','attack','hurt','special','special2','wave','laugh','talk','victory']:frames[0]=neutral.copy()
        if clip in ['idle','attack','hurt','special','special2','wave','laugh','talk']:frames[-1]=neutral.copy()
        p=dest/'anim'/f'fresh_{clip}.png';sheet(frames).save(p,optimize=True);vram(p)
        frames[-1 if clip=='defeat' else 0].save(dest/(clip+'.png' if clip in ['victory','defeat'] else 'fresh_'+clip+'.png'),optimize=True)
        info={'frames':n,'fps':fps,'loop':loop}
        if impact is not None:info['impact']=impact
        if cid=='goblin_archer' and clip=='special':info['hits']=[2,3,5]
        meta['clips'][clip]=info;preview(cid+'_'+clip,frames,fps)
    write(dest/'anim/anim.json',meta);write(dest/'rig.json',{'id':cid,'canvas':[512,512],'feet':[256,500],'anchors':{'fresh_'+c:anchor_points(cid,neutral) for c in meta['clips']}})
def monsters(ids):
    for cid in ids:
        specs=SPEC if cid!='toad_witch_giant' else SPEC[:-1]+[('special2',28,4,8,False,2)]
        character(cid,cells(source(cid),4,8),specs)

def tiles():
    manifest=json.loads((ROOT/'assets/tiles/animation_pack.json').read_text())
    template=[a for a in manifest['atlases'] if a['family']=='orc_shield'];new=[]
    poses=['idle','blink','chuckle','laugh','fear','relief','scream','gloat','hurt','combo','drop','land']
    actions={'idle':'idle','drop':'drop','land':'land','combo':'combo','hurt':'hurt','taunt':'laugh','fear':'fear','near_miss':'relief','gloat':'gloat','death':'scream','win':'scream','lose':'laugh'}
    dest=ROOT/'assets/tiles/swamp';(dest/'animations').mkdir(parents=True,exist_ok=True);(dest/'expressions').mkdir(exist_ok=True)
    for color in ['red','green','yellow','purple']:
        raw=cells(source('tile_'+color+'_0'),4,6)+cells(source('tile_'+color+'_1'),4,6);fs=register(raw,192,126,96)
        clips={p:fs[i*4:i*4+4] for i,p in enumerate(poses)}
        expr=[]
        for p in poses[:9]:
            frame=clips[p][1 if p!='idle' else 0].crop((32,32,160,160));expr.append(frame);frame.save(dest/'expressions'/f'{color}_{p}.png',optimize=True)
        sheet(expr,3).save(dest/f'expressions_{color}.png',optimize=True);expr[0].save(dest/f'tile_{color}.png',optimize=True)
        for action,pose in actions.items():
            frames=[f.copy() for f in clips[pose]]
            if action=='near_miss':frames=[clips['fear'][1],clips['relief'][0],clips['relief'][2],clips['laugh'][1]]
            if action in ['death','win']:frames=[clips['fear'][0],clips['scream'][1],clips['scream'][2],Image.new('RGBA',(192,192))]
            p=dest/'animations'/f'{color}_{action}.png';sheet(frames,8).save(p,optimize=True);vram(p)
            t=next(a for a in template if a['color']==color and a['animation']==action);entry=dict(t);entry.update({'family':'swamp','file':str(p.relative_to(ROOT)),'width':1536,'height':192,'columns':8,'cell':192,'frames':4,'fps':4/float(t['seconds'])});new.append(entry)
        preview('tiles_'+color,[f.resize((512,512)) for f in [clips[p][0] for p in poses]],8)
    manifest['atlases']=[a for a in manifest['atlases'] if a['family']!='swamp']+new
    manifest['families']['swamp']={'label':'Đầm lầy Cóc','animations':list(actions)}
    # Preserve existing metadata; TileArt selects family from atlas entries.
    write(ROOT/'assets/tiles/animation_pack.json',manifest)
    write(dest/'swamp_manifest.json',{'family':'swamp','expressions':poses[:9],'animations':new,'shared_drawn_cels':{'death/win':'fear+scream','taunt/lose':'laugh','near_miss':'fear+relief+laugh'},'notes':'4 independently drawn cels per source action; no body-part interpolation'})
    # Ready-made SpriteFrames, same on-disk contract as other themes.
    for color in ['red','green','yellow','purple']:
        entries=[e for e in new if e['color']==color];lines=['[gd_resource type="SpriteFrames" load_steps=61 format=3]']
        for j,e in enumerate(entries):lines.append(f'[ext_resource type="Texture2D" path="res://{e["file"]}" id="{j+1}"]')
        for j,e in enumerate(entries):
            for i in range(4):lines.append(f'[sub_resource type="AtlasTexture" id="Atlas_{j}_{i}"]\natlas = ExtResource("{j+1}")\nregion = Rect2({i*192}, 0, 192, 192)')
        lines+=['[resource]','animations = [']
        for j,e in enumerate(entries):
            frames=', '.join('{"duration":1.0,"texture":SubResource("Atlas_%d_%d")}'%(j,i) for i in range(4));lines.append('{"frames":['+frames+'],"loop":'+str(e['loop']).lower()+',"name":&"'+e['animation']+'","speed":'+str(e['fps'])+'}'+(',' if j<11 else ''))
        lines.append(']');(dest/f'sprite_frames_{color}.tres').write_text('\n\n'.join(lines)+'\n')

def npcs():
    character('fairy_fickle',cells(source('npc_fairy_fickle'),4,3),[('idle',0,4,8,True,None),('wave',4,4,8,False,None),('laugh',8,4,8,False,None)])
    character('fairy_crow',cells(source('npc_fairy_crow'),4,2),[('idle',0,4,8,True,None),('talk',4,4,8,False,None)])
    raw=register(cells(source('npc_swamp_npcs'),3,2));specs={'swamp_old_man':{'idle':0,'talk':1},'bin':{'idle':2,'talk':3,'cheer':4}}
    for cid,poses in specs.items():
        dest=ROOT/'assets/characters'/cid;dest.mkdir(parents=True,exist_ok=True)
        for pose,index in poses.items():raw[index].save(dest/(pose+'.png'),optimize=True);raw[index].save(dest/('fresh_'+pose+'.png'),optimize=True)
        write(dest/'rig.json',{'id':cid,'canvas':[512,512],'feet':[256,500],'anchors':{pose:{'head':[256,150],'mouth':[256,190]} for pose in poses}})

def world():
    for family in ['swamp','goblin_camp']:
        dest=ROOT/'assets/bg'/family;dest.mkdir(parents=True,exist_ok=True)
        drawings=cells(source('layers_'+family),3,1)
        bottom=max(f.getchannel('A').point(lambda a:255 if a>64 else 0).getbbox()[3] for f in drawings)
        # Remove common export gutter so foreground banks reach canvas bottom.
        drawings=[f.crop((0,0,f.width,bottom)) for f in drawings]
        layers=[Image.open(source('sky')).convert('RGBA')]+drawings
        for name,f in zip(['sky','far','mid','ground'],layers):f.resize((1080,660),Image.Resampling.LANCZOS).save(dest/(name+'.png'),optimize=True)
        ambient=cells(source('ambient'),4,3);effects={}
        for i,name in enumerate(['firefly','bubble','lotus']):
            chosen=ambient[i*4:i*4+(3 if name=='bubble' else 4)]
            fs=register(chosen,256,210,128)
            if name=='bubble':fs=fs[:3]+[Image.new('RGBA',(256,256))]
            while len(fs)<4:fs.append(fs[0].copy())
            sheet(fs).save(dest/(name+'.png'),optimize=True)
            if family=='swamp':preview('ambient_'+name,[f.resize((512,512)) for f in fs],8)
            effects[name]={'file':name+'.png','columns':4,'frame_size':[256,256],'origin':[128,128],'scale':{'firefly':0.15,'bubble':0.2,'lotus':0.5}[name],'frames':4,'fps':8,'loop':True,'positions':{'firefly':[[210,350],[850,300],[640,200]],'bubble':[[400,570],[800,580]],'lotus':[[200,590],[900,600]]}[name]}
        write(dest/'layers.json',{'canvas':[1080,660],'static_order':['sky','far','mid','ground'],'flag':None,'smoke':[],'torch':[],'grass':[],'bird_lane_y':[],'ambient_effects':effects,'safe_parallax':{'zoom_min_when_panning':1.1,'zoom_max':1.15,'x_offsets':{'sky':0,'far':-8,'mid':8,'ground':12},'y_offset':0}})
        composite=Image.new('RGBA',(1080,660),'#a3b59a')
        for name in ['sky','far','mid','ground']:composite.alpha_composite(Image.open(dest/(name+'.png')).convert('RGBA'))
        jpg(composite,REVIEW/(family+'_background.jpg'),1080)
    # Retain original G1 obstacles in the shared manifest when starting from old main.
    prefix='assets/board/obstacles';dest=ROOT/prefix;dest.mkdir(parents=True,exist_ok=True)
    files=subprocess.check_output(['git','ls-tree','-r','--name-only','8241c12','--',prefix],cwd=ROOT,text=True).splitlines()
    for filename in files:
        target=ROOT/filename
        if not target.exists():target.write_bytes(subprocess.check_output(['git','show','8241c12:'+filename],cwd=ROOT))
    meta=json.loads((dest/'obstacles.json').read_text())
    # Cleanup export has a large outer gutter and slightly unequal row spacing.
    # Explicit measured crop boxes prevent neighboring-row fragments in cells.
    atlas=Image.open(source('obstacles')).convert('RGBA')
    assert atlas.size==(887,1774),'remeasure obstacle crop boxes for a new source'
    xs=[28,236,444,652,860];ys=[120,322,532,744,944,1148,1350,1544,1740]
    raw=[atlas.crop((xs[x],ys[y],xs[x+1],ys[y+1])) for y in range(8) for x in range(4)]
    static={'poison_toad':0,'mud':4,'web':5,'time_bomb':6,'gold_mark':7,'ice_1':8,'ice_2':9}
    for name,index in static.items():
        f=raw[index];f.thumbnail((240,240));out=Image.new('RGBA',(256,256));out.alpha_composite(f,((256-f.width)//2,(256-f.height)//2));out.save(dest/(name+'.png'),optimize=True)
    animations={'poison_toad_idle':(0,False),'ice_break':(8,True),'mud_break':(12,True),'web_break':(16,True),'time_bomb_break':(20,True),'poison_toad_break':(24,True),'gold_mark_break':(28,True)}
    for name,(start,emptyend) in animations.items():
        frames=[]
        selection=raw[start:start+4]
        if name=='ice_break':selection=[raw[9],raw[8],raw[10],raw[11]]
        for f in selection:
            f.thumbnail((480,480));out=Image.new('RGBA',(512,512));out.alpha_composite(f,((512-f.width)//2,(512-f.height)//2));frames.append(out)
        if emptyend:frames[-1]=Image.new('RGBA',(512,512))
        sheet(frames).save(dest/(name+'.png'),optimize=True)
        meta['clips'][name]={'frame_width':512,'frame_height':512,'frames':4,'fps':12,'loop':not emptyend}
        preview(name,frames,12)
    meta['layers'].update({'poison_toad':['poison_toad.png'],'mud':['mud.png'],'web':['web.png'],'time_bomb':['time_bomb.png'],'ice':['ice_1.png','ice_2.png'],'gold_mark':['gold_mark.png']});write(dest/'obstacles.json',meta)
    mapdir=ROOT/'assets/bg/campaign';mapdir.mkdir(parents=True,exist_ok=True)
    im=Image.open(source('map')).convert('RGB').resize((1080,1920),Image.Resampling.LANCZOS)
    # Shared band comes from the corrected G1 export; no painted seam approximation.
    lower=Image.open(io.BytesIO(subprocess.check_output(['git','show','8241c12:assets/bg/campaign/segment_02.png'],cwd=ROOT))).convert('RGB')
    band=Image.open(source('map_join')).convert('RGB').resize((1080,600),Image.Resampling.LANCZOS)
    im.paste(band.crop((0,0,1080,400)),(0,1520))
    lower.paste(band.crop((0,200,1080,600)),(0,0))
    im.save(mapdir/'segment_03.png',optimize=True);lower.save(mapdir/'segment_02.png',optimize=True)
    join=Image.new('RGB',(1080,900));join.paste(im.crop((0,1320,1080,1920)));join.paste(lower.crop((0,200,1080,500)),(0,600));jpg(join,REVIEW/'map_03_02_join.jpg',720)
    # Coordinates are finalized after visual review of the generated map.
    coords=MANIFEST.get('map_nodes',[])
    assert len(coords)==18,'measure all 18 map nodes before world export'
    nodes=[];marked=im.copy();draw=ImageDraw.Draw(marked)
    for level,(x,y) in enumerate(coords,19):
        node={'level':level,'segment':3,'x':x,'y':y,'hard':level in [28,34],'bonus':level==30,'boss':level==36,'petal':level==33};nodes.append(node)
        draw.ellipse((x-25,y-25,x+25,y+25),fill='#b83228',outline='white',width=2);draw.text((x-8,y-6),str(level),fill='white')
    write(mapdir/'nodes_g2.json',nodes);write(mapdir/'layout_g2.json',{'segment_size':[1080,1920],'overlap_px':200,'top_to_bottom':[3,2,1],'origins':{'3':[0,0],'2':[0,1720],'1':[0,3440]},'requires_g1_commit':'8241c12','updates_segment_02_top_px':400})
    jpg(marked,REVIEW/'map_03_nodes.jpg',540)

def main():
    global MANIFEST
    p=argparse.ArgumentParser();p.add_argument('--group',choices=['priority','characters','tiles','world','npcs','story'],required=True);args=p.parse_args()
    if args.group=='story':
        from pack_issue41_story import main as pack_story
        pack_story(3)
        return
    MANIFEST=json.loads((DOC/'campaign_g2_sources.json').read_text());REVIEW.mkdir(exist_ok=True);(REVIEW/'.gdignore').touch()
    for info in MANIFEST['sources'].values():
        path=Path(info['path']);info['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
    write(DOC/'campaign_g2_sources.json',MANIFEST)
    if args.group=='priority':monsters(NAMES[:2])
    elif args.group=='characters':monsters(NAMES[2:])
    elif args.group=='tiles':tiles()
    elif args.group=='npcs':npcs()
    else:world()

if __name__=='__main__':main()
