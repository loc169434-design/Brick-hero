"""Validate exported G2 assets, including unchanged original tile families."""
from pathlib import Path
from PIL import Image
import json, hashlib, subprocess, io

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'docs/ideas/campaign_g2_review';n=0
def check(ok,msg):
    global n
    assert ok,msg
    n+=1
def run():
    ids=['toad_spitter','goblin_archer','swamp_leech','goblin_thief','goblin_bomber','swamp_spider','frost_slime','crocodile','toad_witch','toad_witch_giant','fairy_fickle','fairy_crow'];counts={}
    for cid in ids:
        dest=ROOT/'assets/characters'/cid;meta=json.loads((dest/'anim/anim.json').read_text());counts[cid]=0;idle=Image.open(dest/'anim/fresh_idle.png').crop((0,0,512,512)).tobytes()
        expected={'idle','attack','hurt','special','defeat','victory'}
        if cid=='toad_witch_giant':expected.remove('victory');expected.add('special2')
        if cid=='fairy_fickle':expected={'idle','wave','laugh'}
        if cid=='fairy_crow':expected={'idle','talk'}
        check(set(meta['clips'])==expected,cid+' clip inventory')
        check(json.loads((dest/'rig.json').read_text())['feet']==[256,500],cid+' feet')
        for clip,m in meta['clips'].items():
            p=dest/'anim'/f'fresh_{clip}.png';im=Image.open(p)
            check(im.mode=='RGBA' and im.size==(2048,((m['frames']+3)//4)*512),cid+' atlas dimensions')
            check('compress/mode=2' in Path(str(p)+'.import').read_text(),cid+' vram compression')
            if 'impact' in m:check(0<=m['impact']<m['frames'],cid+' impact')
            for hit in m.get('hits',[]):check(0<=hit<m['frames'],cid+' multihit')
            hashes=[]
            for i in range(im.height//512*4):
                f=im.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512))
                if i>=m['frames']:check(f.getchannel('A').getextrema()==(0,0),cid+' unused cell')
                else:
                    check(f.getchannel('A').getbbox() is not None,cid+' drawn cel');hashes.append(hashlib.sha256(f.tobytes()).hexdigest())
            check(len(set(hashes))>=2,cid+' actual pose changes')
            if clip=='victory':check(im.crop((0,0,512,512)).tobytes()==idle,cid+' victory starts neutral')
            counts[cid]+=m['frames']
    for cid,poses in [('swamp_old_man',['idle','talk']),('bin',['idle','talk','cheer'])]:
        for pose in poses:check(Image.open(ROOT/f'assets/characters/{cid}/{pose}.png').size==(512,512),cid+' standing pose')
    manifest=json.loads((ROOT/'assets/tiles/animation_pack.json').read_text());old=json.loads(subprocess.check_output(['git','show','36db7f9:assets/tiles/animation_pack.json'],cwd=ROOT))
    check([a for a in manifest['atlases'] if a['family']!='swamp']==old['atlases'],'existing tile atlases unchanged')
    entries=[a for a in manifest['atlases'] if a['family']=='swamp'];check(len(entries)==48,'48 tile clips')
    for a in entries:
        im=Image.open(ROOT/a['file']);check(im.mode=='RGBA' and im.size==(a['width'],a['height']),'tile contract')
        check(a['frames']==4 and a['columns']==8 and a['cell']==192,'tile grid metadata')
    for color in ['red','green','yellow','purple']:
        check(Image.open(ROOT/f'assets/tiles/swamp/tile_{color}.png').size==(128,128),'tile static')
        check(Image.open(ROOT/f'assets/tiles/swamp/expressions_{color}.png').size==(384,384),'expression grid')
    for family in ['swamp','goblin_camp']:
        for layer in ['sky','far','mid','ground']:
            im=Image.open(ROOT/f'assets/bg/{family}/{layer}.png').convert('RGBA');check(im.size==(1080,660),'backdrop layer size')
            if layer=='sky':check(im.getchannel('A').getextrema()==(255,255),'opaque sky')
            # A very light mist/soft alpha is allowed; reject opaque canvas fill.
            else:check(im.getpixel((540,100))[3]<=16,'background upper center nearly clear')
    obstacles=json.loads((ROOT/'assets/board/obstacles/obstacles.json').read_text())
    for name in ['poison_toad','mud','web','time_bomb','ice_1','ice_2','gold_mark']:
        check(Image.open(ROOT/f'assets/board/obstacles/{name}.png').size==(256,256),'obstacle static')
    for name in ['ice_1','ice_2']:
        check(Image.open(ROOT/f'assets/board/obstacles/{name}.png').getpixel((128,128))[3]<128,'ice center reveals tile color')
    for name,m in obstacles['clips'].items():
        im=Image.open(ROOT/f'assets/board/obstacles/{name}.png');check(im.size==(2048,512),'obstacle animation')
        if not m['loop']:check(im.crop((1536,0,2048,512)).getchannel('A').getextrema()==(0,0),'break final alpha 0')
    map3=Image.open(ROOT/'assets/bg/campaign/segment_03.png').convert('RGB');map2=Image.open(ROOT/'assets/bg/campaign/segment_02.png').convert('RGB')
    oldmap2=Image.open(io.BytesIO(subprocess.check_output(['git','show','8241c12:assets/bg/campaign/segment_02.png'],cwd=ROOT))).convert('RGB')
    check(map2.crop((0,400,1080,1920)).tobytes()==oldmap2.crop((0,400,1080,1920)).tobytes(),'G1 map2 outside upper join unchanged')
    check(map3.crop((0,1720,1080,1920)).tobytes()==map2.crop((0,0,1080,200)).tobytes(),'map overlap200 exact')
    nodes=json.loads((ROOT/'assets/bg/campaign/nodes_g2.json').read_text());check([x['level'] for x in nodes]==list(range(19,37)),'18 ordered levels')
    check([x['level'] for x in nodes if x['hard']]==[28,34],'hard flags');check([x['level'] for x in nodes if x['bonus']]==[30],'bonus');check([x['level'] for x in nodes if x['boss']]==[36],'boss');check([x['level'] for x in nodes if x['petal']]==[33],'petal')
    for node in nodes:check(0<node['x']<1080 and 0<node['y']<1920,'node bounds')
    previews=[]
    for p in OUT.iterdir():
        check(p.suffix.lower() not in ['.png','.webp'],'preview formats')
        if p.suffix.lower() in ['.jpg','.gif']:check(p.stat().st_size<2_000_000,'preview bytes');previews.append(p.name)
    story=json.loads((ROOT/'assets/story/chapter_03/chapter.json').read_text())
    check(story['after_level']==36 and 6<=len(story['panels'])<=8,'chapter3 trigger and panel count')
    check(story['style_review']=='approved_v2_issue_41','chapter3 uses approved V2')
    for panel in story['panels']:
        check(Image.open(ROOT/'assets/story/chapter_03'/panel).width==1080,'chapter3 panel resource')
    from check_issue41_contiguity import run as check_contiguity
    topology=check_contiguity()
    check(not topology['unapproved_large_islands'],'one connected actor silhouette; only reviewed intentional FX may detach')
    result={'passed':n,'actor_frames':counts,'total_actor_frames':sum(counts.values()),'tile_atlases':48,'levels':[19,36],'previews':len(previews),'contiguity_cells':topology['actor_cells_checked'],'unapproved_large_islands':0,'chapter_2':'delivered_on_art/campaign-100-g1_at_5725afb','chapter_3':{'style':'approved_v2_issue_41','panels':len(story['panels']),'after_level':36}};OUT.mkdir(exist_ok=True);(OUT/'validation.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
if __name__=='__main__':run()
