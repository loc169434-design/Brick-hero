"""Validate the actual exported G1 assets, not placeholder paths."""
from pathlib import Path
import json, hashlib
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
checks=0
def check(ok,message):
    global checks
    assert ok,message
    checks+=1

def run():
    counts={}
    for cid in ['orc_rock','orc_drummer','orc_boar','orc_chief','orc_chief_enraged','scarecrow_wood','scarecrow_straw_shield']:
        dest=ROOT/'assets/characters'/cid
        meta=json.loads((dest/'anim/anim.json').read_text())
        if cid in ['orc_rock','orc_drummer','orc_boar','orc_chief']:
            check(set(meta['clips'])=={'idle','attack','hurt','special','defeat','victory'},cid+' six clips')
        check(json.loads((dest/'rig.json').read_text())['feet']==[256,500],cid+' feet')
        counts[cid]=0
        idle=None
        for clip,m in meta['clips'].items():
            im=Image.open(dest/'anim'/f'fresh_{clip}.png')
            check(im.mode=='RGBA',cid+' alpha')
            check(im.size==(2048,((m['frames']+3)//4)*512),cid+' sheet dimensions')
            check(m['fps']>0 and m['frames']>0,cid+' timing')
            if 'impact' in m:check(0<=m['impact']<m['frames'],cid+' impact')
            frames=[]
            for i in range(((m['frames']+3)//4)*4):
                f=im.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512))
                if i>=m['frames']:
                    check(f.getchannel('A').getextrema()==(0,0),cid+' unused transparent')
                else:
                    box=f.getchannel('A').getbbox();check(box is not None,cid+' nonempty')
                    check(f.getchannel('A').getextrema()[0]==0,cid+' transparent outside')
                    frames.append(f)
            check(len({hashlib.sha256(f.tobytes()).hexdigest() for f in frames})>=3,cid+' actual distinct drawings')
            if clip=='idle':idle=frames[0].tobytes()
            if clip in ['attack','hurt','special']:
                check(frames[0].tobytes()==idle and frames[-1].tobytes()==idle,cid+' neutral boundaries')
            counts[cid]+=m['frames']
    nodes=json.loads((ROOT/'assets/bg/campaign/nodes_g1.json').read_text())
    check([n['level'] for n in nodes]==list(range(1,19)),'18 unique ordered levels')
    for n in nodes:check(0<n['x']<1080 and 0<n['y']<1920,'node bounds')
    for segment in [1,2]:
        ns=[n for n in nodes if n['segment']==segment]
        check(all(a['y']>b['y'] for a,b in zip(ns,ns[1:])),'map ascending route')
        check(Image.open(ROOT/f'assets/bg/campaign/segment_{segment:02}.png').size==(1080,1920),'map size')
    for ch in [1,2]:
        dest=ROOT/f'assets/story/chapter_{ch:02}'
        meta=json.loads((dest/'chapter.json').read_text())
        check(len(meta['panels'])==6,'six comic panels')
        for p in meta['panels']:check(Image.open(dest/p).width==1080,'comic panel width')
    dest=ROOT/'assets/board/obstacles'
    meta=json.loads((dest/'obstacles.json').read_text())
    for name in ['crate_1','crate_2','crate_3','rock','rock_cracked']:
        im=Image.open(dest/(name+'.png'));check(im.mode=='RGBA' and im.size==(256,256),'obstacle shape')
    for name,m in meta['clips'].items():
        im=Image.open(dest/(name+'.png'));check(im.size==(2048,512),'break sheet size')
        check(im.crop((1536,0,2048,512)).getchannel('A').getextrema()==(0,0),'break fades completely')
    for name in ['node_hard','node_boss','node_bonus','node_petal','golden_petal','orc_flag','rescue_cage','brass_key']:
        im=Image.open(ROOT/'assets/ui/campaign'/(name+'.png'))
        check(im.mode=='RGBA' and im.size==(256,256),'campaign icon shape')
        check(im.getchannel('A').getextrema()[0]==0 and im.getchannel('A').getbbox() is not None,'icon alpha/content')
    result={'checks':checks,'passed':checks,'frames':counts,'total_character_frames':sum(counts.values())}
    (ROOT/'docs/ideas/campaign_g1_review/validation.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result))

if __name__=='__main__':run()
