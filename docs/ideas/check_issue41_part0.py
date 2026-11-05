"""Verify the exported fixes requested in issue #41, independent of packer."""
from pathlib import Path
from PIL import Image
import json, subprocess, hashlib

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/ideas/issue41_part0_review'
count=0
def check(ok,msg):
    global count
    assert ok,msg
    count+=1

def main():
    upper=Image.open(ROOT/'assets/bg/campaign/segment_02.png').convert('RGB')
    lower=Image.open(ROOT/'assets/bg/campaign/segment_01.png').convert('RGB')
    a=upper.crop((0,1720,1080,1920)).tobytes();b=lower.crop((0,0,1080,200)).tobytes()
    check(a==b,'200px overlap must be identical')
    layout=json.loads((ROOT/'assets/bg/campaign/layout_g1.json').read_text())
    check(layout['overlap_px']==200 and layout['origins']['1']==[0,1720],'overlap layout')
    idle=Image.open(ROOT/'assets/characters/orc_chief/fresh_idle.png').convert('RGBA')
    victory=Image.open(ROOT/'assets/characters/orc_chief/anim/fresh_victory.png').convert('RGBA')
    check(victory.crop((0,0,512,512)).tobytes()==idle.tobytes(),'victory starts at exact idle')
    check(len({hashlib.sha256(victory.crop((i*512,0,i*512+512,512)).tobytes()).hexdigest() for i in range(4)})==4,'victory four different poses')
    for clip,n in [('idle',4),('attack',6),('defeat',6)]:
        im=Image.open(ROOT/f'assets/characters/orc_boar/anim/fresh_{clip}.png')
        for i in range(n):
            f=im.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512)).getchannel('A')
            # The reported bleed is at cell sides; feet are registered at y=500.
            for box in [(0,0,18,512),(494,0,512,512)]:
                check(f.crop(box).getextrema()==(0,0),f'boar clean margins {clip}/{i}')
    npc=ROOT/'assets/characters/fairy_beggar'
    meta=json.loads((npc/'anim/anim.json').read_text())
    check(set(meta['clips'])=={'idle','beg','reveal'},'beggar clips')
    for clip,m in meta['clips'].items():
        im=Image.open(npc/'anim'/f'fresh_{clip}.png')
        check(im.mode=='RGBA' and im.size==(2048,512),'beggar sheet contract')
        check(m['frames']==4 and m['fps']==8,'beggar timing')
    heights=[]
    for i in range(1,7):
        im=Image.open(ROOT/f'assets/story/chapter_01/panel_{i:02}.png');check(im.width==1080,'panel width');heights.append(im.height)
    check(len(set(heights))>=3,'variable webtoon heights')
    # User explicitly asked not to redraw chapters 2 and 3 before approval.
    changed=subprocess.check_output(['git','diff','--name-only','f83b5fc'],cwd=ROOT,text=True).splitlines()
    check(not any(p.startswith(('assets/story/chapter_02/','assets/story/chapter_03/')) for p in changed),'chapters 2 and 3 untouched')
    previews=[]
    for p in OUT.iterdir():
        if p.suffix.lower() in ['.gif','.jpg']:
            check(p.stat().st_size<2_000_000,'preview size '+p.name);previews.append({'file':p.name,'bytes':p.stat().st_size})
        check(p.suffix.lower() not in ['.webp','.png'],'review only GIF/JPG')
    report={'passed':count,'overlap_pixels':[1080,200],'overlap_sha256':hashlib.sha256(a).hexdigest(),'panel_heights':heights,'previews':previews,'comic_style_approval':'pending_user'}
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

if __name__=='__main__':main()
