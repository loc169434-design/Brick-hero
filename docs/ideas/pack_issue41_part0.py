"""Pack image-tool redraws for #41. Never construct or paint poses in Python.

Whole-frame scaling/registration, shared overlap extraction and review layouts only.
Large generated source files stay outside the checkout, as requested in #41.
"""
from pathlib import Path
import json, io, subprocess, hashlib
from PIL import Image, ImageDraw
from pack_campaign_g1 import cells, register, sheet, preview

ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/'docs/ideas'
OUT=DOC/'issue41_part0_review'
MANIFEST=DOC/'issue41_part0_sources.json'

def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')

def original(path):
    raw=subprocess.check_output(['git','show',CONFIG['baseline']+':'+path],cwd=ROOT)
    return Image.open(io.BytesIO(raw)).copy()

def jpg(image,path,width=1000):
    image=image.convert('RGB');image.thumbnail((width,12000))
    image.save(path,quality=85,optimize=True)
    assert path.stat().st_size<2_000_000,path

def gif(name,frames,fps=8):
    rgb=[]
    for f in frames:
        b=Image.new('RGBA',(512,512),'#193444');b.alpha_composite(f)
        rgb.append(b.convert('RGB').resize((256,256)))
    rgb[0].save(OUT/(name+'.gif'),save_all=True,append_images=rgb[1:],duration=round(1000/fps),loop=0,disposal=2)

def preview_grid(name,frames):
    im=Image.new('RGB',(1024,290),'#193444');d=ImageDraw.Draw(im)
    for i,f in enumerate(frames):
        b=Image.new('RGBA',(512,512),'#193444');b.alpha_composite(f)
        im.paste(b.convert('RGB').resize((256,256)),(i*256,30));d.text((i*256+10,10),str(i),fill='white')
    jpg(im,OUT/(name+'.jpg'))

def main():
    global CONFIG
    CONFIG=json.loads(MANIFEST.read_text());sources={k:Path(v['path']) for k,v in CONFIG['sources'].items()}
    for k,p in sources.items():CONFIG['sources'][k]['sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
    write(MANIFEST,CONFIG);OUT.mkdir(exist_ok=True)
    # Same 200-pixel band is contained in both maps. Renderer must overlap 200px.
    band=Image.open(sources['41map_clean']).convert('RGB').resize((1080,600),Image.Resampling.LANCZOS)
    upper=original('assets/bg/campaign/segment_02.png').convert('RGB')
    lower=original('assets/bg/campaign/segment_01.png').convert('RGB')
    upper.paste(band.crop((0,0,1080,400)),(0,1520))
    lower.paste(band.crop((0,200,1080,600)),(0,0))
    upper.save(ROOT/'assets/bg/campaign/segment_02.png',optimize=True)
    lower.save(ROOT/'assets/bg/campaign/segment_01.png',optimize=True)
    write(ROOT/'assets/bg/campaign/layout_g1.json',{'segment_size':[1080,1920],'overlap_px':200,'top_to_bottom':[2,1],'origins':{'2':[0,0],'1':[0,1720]},'combined_size':[1080,3640]})
    nodes=json.loads((ROOT/'assets/bg/campaign/nodes_g1.json').read_text())
    for n in nodes:
        if n['level']==7:n['x']=610
    write(ROOT/'assets/bg/campaign/nodes_g1.json',nodes)
    for seg,im in [(1,lower.copy()),(2,upper.copy())]:
        d=ImageDraw.Draw(im)
        for n in nodes:
            if n['segment']!=seg:continue
            x,y=n['x'],n['y'];d.ellipse((x-32,y-32,x+32,y+32),fill='#b83228',outline='white',width=3);d.text((x-9,y-7),str(n['level']),fill='white')
        jpg(im,DOC/f'campaign_g1_review/map_{seg:02}_nodes.jpg',540)
    before=Image.new('RGB',(1080,800));before.paste(original('assets/bg/campaign/segment_02.png').crop((0,1520,1080,1920)));before.paste(original('assets/bg/campaign/segment_01.png').crop((0,0,1080,400)),(0,400))
    compare=Image.new('RGB',(2160,840),'#eee4cf');compare.paste(before,(0,40));compare.paste(band.resize((1080,800)),(1080,40));d=ImageDraw.Draw(compare);d.text((20,12),'BEFORE',fill='black');d.text((1100,12),'AFTER - 200px shared overlap',fill='black');jpg(compare,OUT/'map_join_before_after.jpg',1400)
    combined=Image.new('RGB',(1080,3640));combined.paste(upper);combined.paste(lower.crop((0,200,1080,1920)),(0,1920));jpg(combined,OUT/'map_combined.jpg',540)
    # Victory starts at existing exact idle; new drawings supply the upward flourish.
    dest=ROOT/'assets/characters/orc_chief';fs=register(cells(sources['41victory'],4,1));fs[0]=Image.open(dest/'fresh_idle.png').convert('RGBA')
    sheet(fs).save(dest/'anim/fresh_victory.png',optimize=True);fs[0].save(dest/'victory.png',optimize=True)
    gif('chief_victory_after',fs);preview_grid('chief_victory_after',fs)
    preview('orc_chief_victory',fs,8)
    old=original('assets/characters/orc_chief/anim/fresh_victory.png');oldframes=[old.crop((i*512,0,i*512+512,512)) for i in range(4)];gif('chief_victory_before',oldframes)
    # Cleanup was performed by the image tool, not masks or body-part edits.
    raw=register(cells(sources['41boar'],4,8));neutral=raw[0].copy()
    dest=ROOT/'assets/characters/orc_boar'
    for clip,start,count in [('idle',0,4),('attack',4,6),('hurt',10,4),('special',14,8),('defeat',22,6),('victory',28,4)]:
        fs=[f.copy() for f in raw[start:start+count]]
        if clip in ['idle','attack','hurt','special']:fs[0]=neutral.copy();fs[-1]=neutral.copy()
        sheet(fs).save(dest/'anim'/f'fresh_{clip}.png',optimize=True)
        fs[-1 if clip=='defeat' else 0].save(dest/(clip+'.png' if clip in ['defeat','victory'] else 'fresh_'+clip+'.png'),optimize=True)
        if clip in ['idle','attack','defeat']:gif('boar_'+clip+'_after',fs,8 if clip=='idle' else 12)
        preview('orc_boar_'+clip,fs,8 if clip in ['idle','victory'] else (10 if clip=='defeat' else 12))
    # NPC reveal intentionally ends in true fairy, not back in disguise.
    fs=register(cells(sources['41beggar'],4,3));dest=ROOT/'assets/characters/fairy_beggar';(dest/'anim').mkdir(parents=True,exist_ok=True)
    metadata={'frame_size':[512,512],'columns':4,'clips':{}}
    for i,clip in enumerate(['idle','beg','reveal']):
        clipframes=fs[i*4:i*4+4]
        if clip!='reveal':clipframes[-1]=fs[0].copy()
        sheet(clipframes).save(dest/'anim'/f'fresh_{clip}.png',optimize=True)
        clipframes[0].save(dest/f'fresh_{clip}.png',optimize=True)
        (dest/'anim'/f'fresh_{clip}.png.import').write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\ncompress/mode=2\n')
        metadata['clips'][clip]={'frames':4,'fps':8,'loop':clip=='idle'};gif('fairy_beggar_'+clip,clipframes)
    fs[0].save(dest/'idle.png',optimize=True)
    write(dest/'anim/anim.json',metadata);write(dest/'rig.json',{'id':'fairy_beggar','canvas':[512,512],'feet':[256,500],'anchors':{f'fresh_{c}':{'head':[256,150],'mouth':[256,190]} for c in metadata['clips']}})
    # Independent panels retain their native aspect ratios, not a uniform grid.
    after=[];before=[];chapter=ROOT/'assets/story/chapter_01'
    for i in range(1,7):
        im=Image.open(sources['41panel'+str(i)]).convert('RGB')
        if i==6:im=im.crop((30,30,im.width-30,im.height-30))
        im=im.resize((1080,round(im.height*1080/im.width)),Image.Resampling.LANCZOS)
        im.save(chapter/f'panel_{i:02}.png',optimize=True);after.append(im)
        before.append(original(f'assets/story/chapter_01/panel_{i:02}.png').convert('RGB'))
        jpg(im,OUT/f'chapter1_panel_{i:02}_after.jpg',720)
    meta=json.loads((chapter/'chapter.json').read_text());meta.update({'style_review':'pending_user_approval_issue_41','panel_heights':[im.height for im in after],'layout':'vertical_variable_heights','gutter_px':36});write(chapter/'chapter.json',meta)
    tall=Image.new('RGB',(1080,sum(im.height for im in after)+36*5),'#f6e8cc');y=0
    for im in after:tall.paste(im,(0,y));y+=im.height+36
    jpg(tall,OUT/'chapter1_after_webtoon.jpg',540)
    jpg(tall,DOC/'campaign_g1_review/chapter_01.jpg',540)
    thumbwidth=440;rows=[]
    for i,(old,new) in enumerate(zip(before,after),1):
        old=old.resize((thumbwidth,round(old.height*thumbwidth/old.width)));new=new.resize((thumbwidth,round(new.height*thumbwidth/new.width)))
        h=max(old.height,new.height)+48;row=Image.new('RGB',(920,h),'#f6e8cc');row.paste(old,(10,38));row.paste(new,(470,38));d=ImageDraw.Draw(row);d.text((10,10),f'{i} BEFORE',fill='#4c2d1c');d.text((470,10),f'{i} AFTER',fill='#4c2d1c');rows.append(row)
    compare=Image.new('RGB',(920,sum(im.height for im in rows)),'#f6e8cc');y=0
    for im in rows:compare.paste(im,(0,y));y+=im.height
    jpg(compare,OUT/'chapter1_before_after.jpg',920)
    # Character reference board uses unchanged game sprites beside the new panels.
    board=Image.new('RGB',(1080,700),'#f6e8cc');d=ImageDraw.Draw(board)
    for j,(cid,pose) in enumerate([('hero_rookie','fresh_idle'),('princess','idle'),('king','idle')]):
        sprite=Image.open(ROOT/f'assets/characters/{cid}/{pose}.png').convert('RGBA');sprite.thumbnail((240,240));board.paste(sprite,(j*360+60,35),sprite);d.text((j*360+60,10),cid+' GAME SPRITE',fill='#4c2d1c')
    board.paste(after[0].resize((540,270)),(0,340));board.paste(after[1].resize((540,360)),(540,300));jpg(board,OUT/'chapter1_sprite_comparison.jpg',1080)

if __name__=='__main__':main()
