"""Whole-image scaling and review layouts for approved V2 comics, never pose edits.

Usage: python docs/ideas/pack_issue41_story.py 2 (or 3 on the G2 branch).
Image-tool originals remain outside the repository; the manifest records hashes.
"""
from pathlib import Path
import argparse, hashlib, io, json, subprocess
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/'docs/ideas'

def write(path,data):
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')

def jpg(im,path,width):
    im=im.convert('RGB');im.thumbnail((width,14000))
    im.save(path,quality=84,optimize=True)
    assert path.stat().st_size<2_000_000,path

def stack(panels,width=540):
    scaled=[p.resize((width,round(p.height*width/p.width)),Image.Resampling.LANCZOS) for p in panels]
    out=Image.new('RGB',(width,sum(p.height for p in scaled)+18*(len(scaled)-1)),'#faf3e7')
    y=0
    for p in scaled:out.paste(p,(0,y));y+=p.height+18
    return out

def main(chapter):
    manifest=DOC/f'story_chapter_{chapter:02}_sources.json'
    data=json.loads(manifest.read_text())
    assert data['style_approval']['user_reply']=='Duyệt V2'
    dest=ROOT/f'assets/story/chapter_{chapter:02}';dest.mkdir(parents=True,exist_ok=True)
    review=DOC/f'issue41_chapter{chapter}_review';review.mkdir(exist_ok=True)
    panels=[]
    for i,source in enumerate(data['sources'],1):
        path=Path(source['path']);sha=hashlib.sha256(path.read_bytes()).hexdigest()
        assert sha==source['sha256'],f'changed original: {path}'
        im=Image.open(path).convert('RGB')
        # Remove only a panel's outer frame for the final bleed composition.
        if source.get('crop'):
            im=im.crop(source['crop'])
        im=im.resize((1080,round(im.height*1080/im.width)),Image.Resampling.LANCZOS)
        im.save(dest/f'panel_{i:02}.png',optimize=True);panels.append(im)
        jpg(im,review/f'panel_{i:02}.jpg',720)
    meta={'chapter':chapter,'after_level':{2:18,3:36}[chapter],
          'panels':[f'panel_{i:02}.png' for i in range(1,len(panels)+1)],'text_baked':False,
          'style_revision':2,'style_review':'approved_v2_issue_41',
          'style_approval':data['style_approval'],'panel_heights':[im.height for im in panels],
          'layout':'vertical_variable_heights','gutter_px':36}
    write(dest/'chapter.json',meta)
    webtoon=stack(panels);jpg(webtoon,review/'webtoon.jpg',540)
    gallery=DOC/f'campaign_g{1 if chapter==2 else 2}_review'
    if gallery.exists():jpg(webtoon,gallery/f'chapter_{chapter:02}.jpg',540)
    # Original versus redraw is an overview; individual panels remain readable above.
    if data.get('baseline'):
        before=[]
        for i in range(1,len(panels)+1):
            raw=subprocess.check_output(['git','show',f"{data['baseline']}:assets/story/chapter_{chapter:02}/panel_{i:02}.png"],cwd=ROOT)
            before.append(Image.open(io.BytesIO(raw)).convert('RGB'))
        left=stack(before,460);right=stack(panels,460)
        comparison=Image.new('RGB',(940,max(left.height,right.height)+36),'#faf3e7')
        d=ImageDraw.Draw(comparison);d.text((12,10),'BEFORE',fill='#65412e');d.text((492,10),'AFTER - APPROVED V2 STYLE',fill='#65412e')
        comparison.paste(left,(0,36));comparison.paste(right,(480,36));jpg(comparison,review/'before_after.jpg',940)
    # Compare exact production identities against panel drawing at similar display size.
    refs=data['identity_refs'];board=Image.new('RGB',(1080,310+360*((len(panels)+1)//2)),'#faf3e7')
    d=ImageDraw.Draw(board);d.text((10,8),'GAME IDENTITIES / APPROVED V2 COMIC',fill='#65412e')
    cell=1080//len(refs)
    for i,ref in enumerate(refs):
        im=Image.open(ref['path']).convert('RGBA');im.thumbnail((cell-12,240))
        board.paste(im,(i*cell+(cell-im.width)//2,35),im);d.text((i*cell+6,280),ref['label'],fill='#65412e')
    for i,im in enumerate(panels):
        thumb=im.copy();thumb.thumbnail((530,330))
        x=i%2*540;y=310+i//2*360;board.paste(thumb,(x,y));d.text((x+8,y+335),f'Panel {i+1}',fill='#65412e')
    jpg(board,review/'sprite_comparison.jpg',1080)
    (review/'index.md').write_text(f'# Chapter {chapter} — approved V2 style\n\n[Read webtoon](webtoon.jpg) · [Game identity comparison](sprite_comparison.jpg)\n\n'+(' [Before / after](before_after.jpg)\n\n' if data.get('baseline') else '')+'\n'.join(f'- [Panel {i:02}](panel_{i:02}.jpg)' for i in range(1,len(panels)+1))+'\n')
    print(json.dumps({'chapter':chapter,'panels':len(panels),'heights':meta['panel_heights']}))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('chapter',type=int,choices=[2,3]);main(p.parse_args().chapter)
