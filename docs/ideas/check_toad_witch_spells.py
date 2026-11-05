"""Independent #42 asset contract/preservation/timing checks. Requires Pillow/numpy."""
from pathlib import Path
import hashlib,io,json,math,subprocess
import numpy as np
from PIL import Image,ImageSequence

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'docs/ideas/toad_witch_spells_review';BASE='2f51e32'
CONTRACT={
 'toad_witch':{'cast_toads':(12,14,False,7),'cast_broom':(12,14,False,6),'throw_potion':(12,14,False,6),'cackle':(8,10,True,None),'stomp_angry':(8,12,False,4),'drink_transform':(16,12,False,15)},
 'toad_witch_giant':{'burp_toads':(10,12,False,5),'victory':(8,8,False,None)},
 'hero_toad':{'transform_in':(14,14,False,9),'idle':(8,10,True,None),'attack':(8,14,False,4),'hurt':(6,12,False,None),'transform_out':(14,14,False,10)},
 'broom':{'idle':(8,12,True,None),'attack':(12,24,False,6),'hurt':(8,24,False,None),'broom_in':(12,14,False,7),'broom_out':(12,14,False,6)}}
CHECKS=0

def check(ok,message):
    global CHECKS
    assert ok,message
    CHECKS+=1

def cell(im,i):return im.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512))

def old_json(path):return json.loads(subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT))

def idle(cid,prefix='fresh',broom=False):
    p=f'assets/characters/{cid}/anim'+('/broom' if broom else '')+f'/{prefix}_idle.png'
    return cell(Image.open(ROOT/p).convert('RGBA'),0)

def check_atlas(path,n):
    im=Image.open(path);im.load()
    check(im.mode=='RGBA' and im.size==(2048,512*math.ceil(n/4)),'RGBA grid '+str(path))
    check('compress/mode=2' in Path(str(path)+'.import').read_text(),'VRAM import '+str(path))
    hashes=[]
    for i in range(math.ceil(n/4)*4):
        f=cell(im,i);a=np.asarray(f.getchannel('A'))
        if i>=n:check(not a.any(),'unused transparent cell '+str(path));continue
        check((a>=32).any(),'drawn cel '+str(path)+str(i))
        check(not (a[:,:12]>=32).any() and not (a[:,-12:]>=32).any(),'side alpha gutter '+str(path)+str(i))
        hashes.append(hashlib.sha256(f.tobytes()).hexdigest())
    check(len(set(hashes))>=max(2,n-2),'independent cel drawings '+str(path))
    return im

def check_gif(path,n,fps):
    with Image.open(path) as gif:
        duration=sum(f.info.get('duration',0) for f in ImageSequence.Iterator(gif))
    expected=3000*n/fps
    check(abs(duration-expected)<=10.01,'GIF timing '+path.name)
    check(path.stat().st_size<2_000_000,'GIF bytes '+path.name)

def main():
    outputs={};actor_frames=0;clip_count=0
    for cid,specs in CONTRACT.items():
        folder=ROOT/('assets/characters/hero_rookie/anim/broom' if cid=='broom' else f'assets/characters/{cid}/anim')
        meta=json.loads((folder/'anim.json').read_text())
        for name,(n,fps,loop,impact) in specs.items():
            m=meta['clips'][name]
            check((m['frames'],m['fps'],m['loop'],m.get('impact'))==(n,fps,loop,impact),f'metadata {cid}/{name}')
            wears=['fresh','bruised','battered'] if cid=='broom' and name in ['idle','attack','hurt'] else ['fresh']
            for wear in wears:
                path=folder/f'{wear}_{name}.png';im=check_atlas(path,n)
                key=f'{cid}/{wear}_{name}';outputs[key]=im;actor_frames+=n;clip_count+=1
                preview=OUT/((f'broom_{wear}_{name}' if cid=='broom' else f'{cid}_{wear}_{name}')+'.gif')
                check_gif(preview,n,fps)
    # Exact pixel bookends are a contract, including cross-character transitions.
    witch=idle('toad_witch');giant=idle('toad_witch_giant');hero=idle('hero_rookie');toad=idle('hero_toad')
    for cid,specs in CONTRACT.items():
        for name,spec in specs.items():
            wears=['fresh','bruised','battered'] if cid=='broom' and name in ['idle','attack','hurt'] else ['fresh']
            for wear in wears:
                im=outputs[f'{cid}/{wear}_{name}'];start=end=witch if cid=='toad_witch' else giant if cid=='toad_witch_giant' else toad
                if cid=='toad_witch' and name=='drink_transform':end=giant
                if cid=='hero_toad' and name=='transform_in':start=hero
                if cid=='hero_toad' and name=='transform_out':end=hero
                if cid=='broom':
                    start=end=idle('hero_rookie',wear,broom=True)
                    if name=='broom_in':start=hero
                    if name=='broom_out':end=hero
                check(cell(im,0).tobytes()==start.tobytes(),f'exact initial pose {cid}/{wear}/{name}')
                check(cell(im,spec[0]-1).tobytes()==end.tobytes(),f'exact final pose {cid}/{wear}/{name}')
    # Existing G2 clips/metadata/rig anchors and the sword hero remain intact.
    for cid in ['toad_witch','toad_witch_giant','hero_rookie']:
        path=f'assets/characters/{cid}/anim/anim.json';old=old_json(path);new=json.loads((ROOT/path).read_text())
        for name,entry in old['clips'].items():check(new['clips'][name]==entry,'existing clip metadata '+cid+'/'+name)
        if cid!='hero_rookie':
            path=f'assets/characters/{cid}/rig.json';old=old_json(path);new=json.loads((ROOT/path).read_text())
            for name,entry in old['anchors'].items():check(new['anchors'][name]==entry,'existing rig anchor '+cid+'/'+name)
    changed=subprocess.check_output(['git','diff',BASE,'--name-only'],cwd=ROOT,text=True).splitlines()
    old_paths=set(subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'assets'],cwd=ROOT,text=True).splitlines())
    check(not [p for p in changed if p in old_paths and p.endswith('.png')],'all old PNG assets preserved')
    obstacle=json.loads((ROOT/'assets/board/obstacles/obstacles.json').read_text());old=old_json('assets/board/obstacles/obstacles.json')
    for kind in ['layers','clips']:
        for key,value in old[kind].items():check(obstacle[kind][key]==value,'old obstacle '+key)
    for name,n,fps,loop in [('potion_bottle_idle',4,10,True),('potion_break',4,14,False),('potion_burst',8,14,False)]:
        info=obstacle['clips'][name];check((info['frames'],info['fps'],info['loop'])==(n,fps,loop),'potion metadata')
        im=Image.open(ROOT/f'assets/board/obstacles/{name}.png');check(im.mode=='RGBA' and im.size==(2048,512*math.ceil(n/4)),'potion atlas')
        if not loop:check(cell(im,n-1).getchannel('A').getextrema()==(0,0),'potion final transparency')
        check_gif(OUT/(name+'.gif'),n,fps)
    check(Image.open(ROOT/'assets/board/obstacles/potion_bottle.png').size==(256,256),'potion icon size')
    fx=json.loads((ROOT/'assets/fx/curse/anim.json').read_text())
    for name,n in [('toad_hop',6),('poof_green',8),('broom_spell',8),('spell_break',8)]:
        check(fx[name]['frames']==n and fx[name]['fps']==14 and fx[name]['frame_size']==[512,512],'FX metadata')
        im=Image.open(ROOT/f'assets/fx/curse/{name}.png');check(im.mode=='RGBA' and im.size==(2048,512*math.ceil(n/4)),'FX atlas size')
        if name!='toad_hop':check(cell(im,n-1).getchannel('A').getextrema()==(0,0),'FX dissipates')
        check_gif(OUT/('curse_'+name+'.gif'),n,14)
    for name in ['toad','broom','poison']:
        im=Image.open(ROOT/f'assets/ui/status/{name}.png');check(im.mode=='RGBA' and im.size==(128,128),'status '+name)
    data=json.loads((ROOT/'docs/ideas/toad_witch_spells_sources.json').read_text())
    check(len(data['sources'])==32,'complete original source set')
    for key,source in data['sources'].items():
        p=Path(source['path']);check(not p.is_relative_to(ROOT),'large originals outside repo')
        check(hashlib.sha256(p.read_bytes()).hexdigest()==source['sha256'],'source checksum '+key)
        check('crop_boxes' in source,'measured source rectangles '+key)
    timelines=json.loads((OUT/'scene_timelines.json').read_text());check(len(timelines)==3,'three composed scenes')
    for name,entry in timelines.items():
        path=OUT/(name+'.gif');gif=Image.open(path)
        duration=sum(f.info.get('duration',0) for f in ImageSequence.Iterator(gif))
        check(abs(duration-entry['seconds']*1000)<=10.01,'composite timing '+name)
        check(path.stat().st_size<2_000_000,'composite size '+name)
    previews=[]
    for p in OUT.iterdir():
        check(p.suffix.lower() not in ['.png','.jpg','.webp'],'only GIF previews')
        if p.suffix.lower()=='.gif':check(p.stat().st_size<2_000_000,'preview limit');previews.append(p.name)
    from check_issue41_contiguity import run as audit
    topology=audit();check(not topology['unapproved_large_islands'],'contiguous actor bodies')
    report={'passed':CHECKS,'new_actor_clip_variants':clip_count,'new_actor_cels':actor_frames,
            'new_fx_cels':30,'new_obstacle_cels':16,'status_icons':3,'preview_gifs':len(previews),
            'composed_scenes':timelines,'contiguity_cells':topology['actor_cells_checked'],
            'baseline':BASE,'existing_png_assets_preserved':True,'source_images_outside_repo':32}
    (OUT/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()
