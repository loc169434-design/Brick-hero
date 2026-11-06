"""Map data invariants, semantic coordinate origins, intact FX and unchanged map art."""
from world_life_sheet_tools import *
import subprocess
DOC=ROOT/'docs/ideas';DEST=ROOT/'assets/bg/campaign';REVIEW=DOC/'world_life_review/map';checks=0
def check(condition,message):
    global checks
    assert condition,message
    checks+=1
for count,file in [(2,'ambience.json'),(3,'ambience_g2.json')]:
    meta=json.loads((DEST/file).read_text());check(meta['map_size']==[1080,count*1920],file+' whole-map size')
    check(meta['top_to_bottom']==list(range(count,0,-1)),file+' segment1atbottom')
    for key in ['smoke','flags','waterfalls']:
        for p in meta[key]:
            local=p['local_position'];segment=p['segment'];check(p['position']==[local[0],(count-segment)*1920+local[1]],key+' exact game global coordinates')
            check(0<=local[0]<1080 and 0<=local[1]<1920,key+' local within segment')
    for point,origin in zip(meta['water_glints'],meta['water_glint_sources']):
        local=origin['local_position'];check(point==[local[0],(count-origin['segment'])*1920+local[1]],'waterglint global position')
    for name,e in meta['textures'].items():
        im=Image.open(DEST/e['file']).convert('RGBA');w,h=e['frame_size'];check(im.size==(e['columns']*w,math.ceil(e['frames']/e['columns'])*h),name+' dimensions/metadata')
for name in ['map_smoke','map_flag','waterfall']:
    check('compress/mode=2' in (DEST/(name+'.png.import')).read_text(),name+' VRAM compressed')
    meta=json.loads((DEST/'anim.json').read_text());key={'map_smoke':'smoke','map_flag':'flag','waterfall':'waterfall'}[name];e=meta[key];im=Image.open(DEST/(name+'.png')).convert('RGBA');w,h=e['frame_size'];seen=[]
    for i in range(6):
        fr=im.crop((i%3*w,i//3*h,i%3*w+w,i//3*h+h));a=np.array(fr)[:,:,3];check(int((a>32).sum())>40,name+str(i)+' visible drawn cel');check(not np.r_[a[0],a[-1],a[:,0],a[:,-1]].any(),name+str(i)+' no clipped edge');seen.append(hashlib.sha256(fr.tobytes()).hexdigest())
    check(len(set(seen))==6,name+' six individual cels')
for i in range(1,4):
    im=Image.open(DEST/f'map_cloud_{i}.png').convert('RGBA');check(im.size==(600,260),'cloud600x260');a=np.array(im)[:,:,3];check(not np.r_[a[0],a[-1],a[:,0],a[:,-1]].any(),'cloud clear margin')
for n in [1,2]:
    p=f'assets/bg/campaign/segment_{n:02}.png';check((ROOT/p).read_bytes()==subprocess.check_output(['git','show','c0fa9ec:'+p],cwd=ROOT),'existing map segment unchanged')
for name in ['layout_g1.json','nodes_g1.json']:
    p='assets/bg/campaign/'+name;check((ROOT/p).read_bytes()==subprocess.check_output(['git','show','c0fa9ec:'+p],cwd=ROOT),'layout/nodes untouched')
check((DEST/'map_water_glint.png').read_bytes()==(ROOT/'assets/bg/world_map_fx/sparkle.png').read_bytes(),'established twinkle reused exactly')
previews=[]
for p in REVIEW.iterdir():
    if p.suffix in ['.gif','.jpg']:
        check(p.stat().st_size<2_000_000,p.name+' below2MB');previews.append({'file':p.name,'bytes':p.stat().st_size})
for name in ['village_life.gif','orc_camp_life.gif','map_positions_3_segments.jpg']:check((REVIEW/name).exists(),name+' review exists')
write(REVIEW/'validation.json',{'checks_passed':checks,'clouds':3,'drawn_smoke_flag_waterfall_cels':18,'coordinate_profiles':[3,2],'previews':previews})
print(f'{checks} checks passed;3clouds,18FXcels;2/3segmentprofiles correct;map PNGs and nodes unchanged.')
