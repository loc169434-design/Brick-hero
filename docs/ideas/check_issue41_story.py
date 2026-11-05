"""Validate exported story resources independently of the image packer."""
from pathlib import Path
import argparse, hashlib, json
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]

def main(chapter):
    count=0
    def check(condition,message):
        nonlocal count
        assert condition,message
        count+=1
    folder=ROOT/f'assets/story/chapter_{chapter:02}'
    meta=json.loads((folder/'chapter.json').read_text())
    check(meta['chapter']==chapter,'chapter number')
    check(meta['after_level']=={2:18,3:36}[chapter],'chapter trigger')
    check(meta['text_baked'] is False,'dialogue must be rendered by code')
    check(meta['style_review']=='approved_v2_issue_41' and meta['style_revision']==2,'approved style')
    check(meta['style_approval']['user_reply']=='Duyệt V2','explicit approval record')
    n=len(meta['panels']);check(n==6 if chapter==2 else 6<=n<=8,'panel count')
    check(meta['panels']==[f'panel_{i:02}.png' for i in range(1,n+1)],'sequential filenames')
    heights=[];hashes=set()
    for name in meta['panels']:
        im=Image.open(folder/name);im.load()
        check(im.format=='PNG' and im.mode=='RGB','opaque PNG panel')
        check(im.width==1080 and 400<=im.height<=2000,'production dimensions')
        heights.append(im.height);hashes.add(hashlib.sha256(im.tobytes()).hexdigest())
    check(len(hashes)==n,'no duplicate panels')
    check(heights==meta['panel_heights'],'declared heights match PNG')
    check(len(set(heights))>=3,'varied webtoon panel heights')
    manifest=json.loads((ROOT/f'docs/ideas/story_chapter_{chapter:02}_sources.json').read_text())
    check(len(manifest['sources'])==n,'source provenance per panel')
    for entry in manifest['sources']:
        source=Path(entry['path'])
        check(not source.is_relative_to(ROOT),'large original stays outside checkout')
        check(hashlib.sha256(source.read_bytes()).hexdigest()==entry['sha256'],'original checksum')
    review=ROOT/f'docs/ideas/issue41_chapter{chapter}_review';previews=[]
    for path in sorted(review.iterdir()):
        if path.suffix.lower() in ['.jpg','.gif']:
            check(path.stat().st_size<2_000_000,'preview size '+path.name)
            Image.open(path).verify();previews.append({'file':path.name,'bytes':path.stat().st_size})
    check(len(previews)>=n+2,'panel and overview previews present')
    report={'passed':count,'chapter':chapter,'style':'approved_v2_issue_41','panels':n,'heights':heights,'previews':previews}
    (review/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('chapter',type=int,choices=[2,3]);main(p.parse_args().chapter)
