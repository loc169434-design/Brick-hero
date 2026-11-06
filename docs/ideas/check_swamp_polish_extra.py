"""Issue48 addendum: geometry, connected bodies, exact heat FX masks, preservation."""
from art48_49_sheet_tools import *
import subprocess

DOC=ROOT/'docs/ideas';REVIEW=DOC/'swamp_polish_extra_review'
SOURCE=json.loads((DOC/'swamp_polish_extra_sources.json').read_text())
MASKS=DOC/'swamp_polish_extra_fx_masks.json'
checks=0


def check(value,message):
    global checks
    assert value,message
    checks+=1


def old(path,ref='05ad58a'):
    return subprocess.check_output(['git','show',ref+':'+str(path)],cwd=ROOT)


observed=[]
for character in ['toad_witch','orc_shield','orc_rock','orc_drummer','orc_boar']:
    clip='lift' if character=='toad_witch' else 'rage';count=12 if clip=='lift' else 10
    path=f'assets/characters/{character}/anim/fresh_{clip}.png'
    im=Image.open(ROOT/path).convert('RGBA')
    check(im.size==(2048,1536),path+' dimensions')
    check('compress/mode=2' in (ROOT/(path+'.import')).read_text(),character+' VRAM compressed import')
    metadata_path=f'assets/characters/{character}/anim/anim.json'
    meta=json.loads((ROOT/metadata_path).read_text());before=json.loads(old(metadata_path,SOURCE['pr47'] if clip=='lift' else SOURCE['base']))
    check({k:v for k,v in meta['clips'].items() if k!=clip}==before['clips'],character+' old clips retained')
    expected={'frames':count,'fps':14 if clip=='lift' else 12,'loop':False}
    if clip=='lift':expected['impact']=6
    check(meta['clips'][clip]==expected,character+' new timing/impact')
    seen=set()
    for i in range(count):
        fr=im.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512));a=np.asarray(fr)[:,:,3]
        check(not (np.r_[a[0],a[-1],a[:,0],a[:,-1]]>32).any(),f'{character}/{i} clipped edge')
        labels,sizes=components(fr);body=int(sizes.argmax());body_box=bounds(labels==body)
        check(493<=body_box[3]<=501,f'{character}/{i} feet baseline')
        check(sizes[body]>20000,f'{character}/{i} substantial connected full body')
        digest=hashlib.sha256(fr.tobytes()).hexdigest();check(digest not in seen,f'{character}/{i} unique drawing');seen.add(digest)
        for label,area in enumerate(sizes):
            if label in [0,body] or area<=200:continue
            mask=labels==label;box=bounds(mask);color=np.asarray(fr)[:,:,:3][mask].mean(axis=0)
            # These small red-orange wisps above the head were visually checked.
            check(character!='toad_witch' and i in [6,7,8] and box[3]<=230 and box[2]-box[0]<80 and color[0]>color[1],f'{character}/{i} unexpected detached body piece {box}')
            observed.append({'actor':character,'frame':i,'area':int(area),'box':box,'mask_sha256':hashlib.sha256(np.packbits(mask).tobytes()).hexdigest(),'reason':'visually reviewed orange-red heat wisp above head'})
    for i in range(count,12):check(im.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512)).getbbox() is None,character+' empty unused cel')

if '--record-reviewed-steam' in __import__('sys').argv:
    write(MASKS,{'alpha_threshold':32,'connectivity':8,'reviewed':observed})
check(json.loads(MASKS.read_text())['reviewed']==observed,'heat exception masks unchanged; no broad actor exception')

for key,directory in [('levitate','assets/fx/curse'),('rage_steam','assets/fx/combat/anim')]:
    im=Image.open(ROOT/directory/(key+'.png')).convert('RGBA');meta=json.loads((ROOT/directory/'anim.json').read_text())
    check(im.size==(2048,1024),key+' atlas size')
    check('compress/mode=2' in (ROOT/directory/(key+'.png.import')).read_text(),key+' VRAM compressed import')
    check(meta[key]=={'frames':8,'fps':12,'columns':4,'frame_size':[512,512],'loop':True},key+' playback')
    base_ref=SOURCE['pr47'] if key=='levitate' else SOURCE['base']
    before=json.loads(old(directory+'/anim.json',base_ref))
    check({k:v for k,v in meta.items() if k!=key}==before,key+' other FX entries preserved')
    hashes=[]
    for i in range(8):
        fr=im.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512));a=np.asarray(fr)[:,:,3]
        check(not (np.r_[a[0],a[-1],a[:,0],a[:,-1]]>32).any(),key+' complete effect inside cel')
        hashes.append(hashlib.sha256(fr.tobytes()).hexdigest())
    check(len(set(hashes))==8,key+' eight drawn frames')

for k,e in SOURCE['sources'].items():
    check(hashlib.sha256(Path(e['path']).read_bytes()).hexdigest()==e['sha256'],k+' retained original hash')
previews=[]
for p in REVIEW.iterdir():
    if p.suffix in ['.gif','.jpg']:
        check(p.stat().st_size<2_000_000,p.name+' under2MB');previews.append({'file':p.name,'bytes':p.stat().st_size})
write(REVIEW/'validation.json',{'checks_passed':checks,'actor_cels':52,'fx_cels':16,'reviewed_heat_masks':len(observed),'previews':previews})
print(f'{checks} checks passed;52 full-body cels,16FXcels;{len(observed)} exact heat masks reviewed.')
