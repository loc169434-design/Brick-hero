"""Independent A/B tile contract, preservation and grayscale-readability checks."""
from pathlib import Path
from collections import Counter
import hashlib,json,subprocess
import numpy as np
from PIL import Image,ImageOps

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'docs/ideas/swamp_variants_review';BASE='2f51e32'
COLORS=['red','green','yellow','purple']
POSES=['idle','blink','chuckle','laugh','fear','relief','scream','gloat','hurt']
ACTIONS=['idle','drop','land','combo','hurt','taunt','fear','near_miss','gloat','death','win','lose']
N=0

def check(ok,why):
    global N
    assert ok,why
    N+=1

def gray46(im):
    f=im.convert('RGBA').resize((46,46),Image.Resampling.LANCZOS)
    a=np.asarray(f.getchannel('A'));g=np.asarray(ImageOps.grayscale(f))
    return float(g[a>=224].mean())

def rim_gray(im):
    a=np.asarray(im.getchannel('A'));g=np.asarray(ImageOps.grayscale(im));mask=np.zeros((128,128),bool)
    mask[8:16,20:108]=True;mask[112:120,20:108]=True;mask[20:108,8:16]=True;mask[20:108,112:120]=True
    return float(np.median(g[mask&(a>=96)]))

def no_badge(im,label):
    rgb=np.asarray(im.convert('RGB'))[94:122,94:122].astype(int)
    cream=(rgb.min(axis=2)>175)&((rgb.max(axis=2)-rgb.min(axis=2))<55)
    check(int(cream.sum())<100,'unexpected cream badge-sized patch at lower right: '+label)

def main():
    path=ROOT/'assets/tiles/animation_pack.json';pack=json.loads(path.read_text())
    old=json.loads(subprocess.check_output(['git','show',BASE+':assets/tiles/animation_pack.json'],cwd=ROOT))
    check([e for e in pack['atlases'] if e['family'] not in ['swamp','swamp_b']]==[e for e in old['atlases'] if e['family']!='swamp'],'other animation families preserved')
    for family,entry in old['families'].items():
        if family!='swamp':check(pack['families'][family]==entry,'other family metadata '+family)
    original=[e for e in old['atlases'] if e['family']=='swamp']
    check([e for e in pack['atlases'] if e['family']=='swamp']==original,'A timing/grid metadata preserved')
    metrics={};expression_metrics={};atlas_count=0
    for family in ['swamp','swamp_b']:
        folder=ROOT/'assets/tiles'/family;entries=[e for e in pack['atlases'] if e['family']==family]
        check(len(entries)==48,family+' 48 animation atlases')
        check(len(list(folder.rglob('*.png')))==92,family+' complete PNG inventory')
        meta=json.loads((folder/'swamp_manifest.json').read_text())
        check(meta['family']==family and meta['expressions']==POSES,'family expression metadata')
        check(meta['role_badges']==(family=='swamp'),'badge variant declaration')
        expression_metrics[family]={p:{} for p in POSES};metrics[family]={}
        for color in COLORS:
            tile=Image.open(folder/f'tile_{color}.png').convert('RGBA')
            check(tile.size==(128,128),'128px tile size')
            alpha=np.asarray(tile.getchannel('A'))
            check(not alpha[0].any() and not alpha[-1].any() and not alpha[:,0].any() and not alpha[:,-1].any(),'transparent outer tile padding')
            check(all(alpha[y,x]>=96 for x,y in [(64,9),(9,64),(118,64),(64,118)]),'rounded square frame, not unframed blob')
            metrics[family][color]=gray46(tile)
            expr=Image.open(folder/f'expressions_{color}.png').convert('RGBA');check(expr.size==(384,384),'3x3 expressions')
            for i,pose in enumerate(POSES):
                frame=Image.open(folder/'expressions'/f'{color}_{pose}.png').convert('RGBA')
                check(frame.size==(128,128),'expression size')
                check(expr.crop((i%3*128,i//3*128,i%3*128+128,i//3*128+128)).tobytes()==frame.tobytes(),'expression grid equals individual file')
                if pose=='idle':check(frame.tobytes()==tile.tobytes(),'static idle matches tile')
                expression_metrics[family][pose][color]=rim_gray(frame)
                if family=='swamp_b':no_badge(frame,color+'/'+pose)
            check((folder/f'sprite_frames_{color}.tres').exists(),'SpriteFrames present')
            for action in ACTIONS:
                entry=next(e for e in entries if e['color']==color and e['animation']==action)
                reference=next(e for e in original if e['color']==color and e['animation']==action)
                check(all(entry[k]==reference[k] for k in ['seconds','fps','frames','columns','cell','loop']),'original action timing '+color+'/'+action)
                im=Image.open(ROOT/entry['file']);check(im.mode=='RGBA' and im.size==(1536,192),'8-column 192px atlas')
                check(entry['frames']==4 and entry['columns']==8,'four authored cels; no fake frame inflation')
                check('compress/mode=2' in Path(str(ROOT/entry['file'])+'.import').read_text(),'VRAM atlas import')
                check(im.crop((4*192,0,8*192,192)).getchannel('A').getextrema()==(0,0),'unused four cells transparent')
                hashes=set()
                for i in range(4):
                    f=im.crop((i*192,0,(i+1)*192,192));a=np.asarray(f.getchannel('A'))
                    check(not a[:24].any() and not a[-24:].any() and not a[:,:24].any() and not a[:,-24:].any(),'clear cell margins')
                    hashes.add(hashlib.sha256(f.tobytes()).hexdigest())
                check(len(hashes)>=2,'actual distinct cels')
                if action=='idle':check(im.crop((32,32,160,160)).tobytes()==tile.tobytes(),'idle frame0 exact tile')
                if action in ['death','win']:check(im.crop((576,0,768,192)).getchannel('A').getextrema()==(0,0),'disappear final cel')
                atlas_count+=1
    order=['purple','red','green','yellow'];means=metrics['swamp_b']
    check(sorted(means,key=means.get)==order,'dark-to-light order indigo/coral/teal/honey')
    min_gap=min(means[b]-means[a] for a,b in zip(order,order[1:]))
    check(min_gap>=18,'46px full-tile gray means must differ by at least 18/255')
    rim_gaps={}
    for pose,levels in expression_metrics['swamp_b'].items():
        check(sorted(levels,key=levels.get)==order,'consistent frame value order '+pose)
        gap=min(levels[b]-levels[a] for a,b in zip(order,order[1:]));rim_gaps[pose]=gap
        check(gap>=18,'expression frame brightness separation '+pose)
    changed=subprocess.check_output(['git','diff',BASE,'--name-only'],cwd=ROOT,text=True).splitlines()
    old_paths=set(subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'assets'],cwd=ROOT,text=True).splitlines())
    check(not [p for p in changed if p in old_paths and p.endswith('.png') and not p.startswith('assets/tiles/swamp/')],'all non-swamp PNG assets preserved')
    source=json.loads((ROOT/'docs/ideas/swamp_variants_sources.json').read_text());check(len(source['sources'])==18,'18 hand-drawn source sheets')
    for key,entry in source['sources'].items():
        p=Path(entry['path']);check(not p.is_relative_to(ROOT),'large source outside repo')
        check(hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'],'source checksum '+key)
        check(len(entry['crop_boxes'])==entry['grid'][0]*entry['grid'][1],'measured/verified source boxes')
    layout=json.loads((OUT/'board_layout_7x8.json').read_text());check(len(layout['layout'])==8 and all(len(row)==7 for row in layout['layout']),'7 columns by8 rows')
    check(Counter(v for row in layout['layout'] for v in row)==Counter({c:14 for c in COLORS}),'balanced identical random board pattern')
    for name in ['current','a','b']:check(Image.open(OUT/f'board_{name}_128px.jpg').size==(928,1108),'full 7x8 native128 board')
    for name in ['comparison_gray_46px.jpg','boards_gray_46px.jpg']:
        rgb=np.asarray(Image.open(OUT/name).convert('RGB'));check((rgb[:,:,0]==rgb[:,:,1]).all() and (rgb[:,:,1]==rgb[:,:,2]).all(),'true grayscale preview '+name)
    previews=[]
    for p in sorted(OUT.iterdir()):
        check(p.suffix.lower() not in ['.png','.webp'],'JPG/GIF previews only')
        if p.suffix.lower() in ['.jpg','.gif']:
            check(p.stat().st_size<2_000_000,'preview bytes '+p.name);Image.open(p).verify();previews.append({'file':p.name,'bytes':p.stat().st_size})
    report={'passed':N,'families':['swamp','swamp_b'],'animation_atlases':atlas_count,'sprite_frames_resources':8,'mean_gray46':means,
            'dark_to_light':order,'min_gray46_gap':min_gap,'min_expression_frame_gap':min(rim_gaps.values()),'expression_frame_gaps':rim_gaps,
            'board':[7,8],'board_cells_per_color':14,'previews':previews,'baseline':BASE,'non_swamp_png_preserved':True}
    (OUT/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()
