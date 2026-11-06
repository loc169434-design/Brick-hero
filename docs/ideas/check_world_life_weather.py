"""Issue49 weather integrity: real seams, blank eyes, placements and preservation."""
from art48_49_sheet_tools import *
import subprocess

DOC=ROOT/'docs/ideas';REVIEW=DOC/'world_life_review/weather';checks=0
def check(condition,message):
    global checks
    assert condition,message
    checks+=1
def previous(path):return subprocess.check_output(['git','show','9c39169:'+path],cwd=ROOT)
families=['training_field','orc_camp','swamp','goblin_camp'];hours=['morning','noon','dusk','night']
for family in families:
    means=[]
    for hour in hours:
        im=Image.open(ROOT/f'assets/bg/{family}/sky_{hour}.png').convert('RGBA');a=np.array(im)
        check(im.size==(1080,660),family+hour+' canvas');check(a[:,:,3].min()==255,family+hour+' opaque sky')
        means.append(float(np.asarray(im.convert('L')).mean()))
    check(means[3]<means[1]*.65,family+' night has clear dark value separation')
    for layer in ['sky','far','mid','ground']:
        path=f'assets/bg/{family}/{layer}.png';check((ROOT/path).read_bytes()==previous(path),family+'/'+layer+' existing painting preserved')
    path=f'assets/bg/{family}/layers.json';meta=json.loads((ROOT/path).read_text());old=json.loads(previous(path))
    check({k:v for k,v in meta.items() if k not in ['eyes','sky_times','time_lighting','time_lighting_note']}==old,family+' effect/parallax/floor metadata preserved')
    check(3<=len(meta['eyes'])<=5,family+' 3-5 red-eye positions')
    for x,y in meta['eyes']:
        check(0<=x<1080 and 0<=y<660,family+' eyes within canvas')
        check(not (150<=x<=390 or 690<=x<=930),family+' eyes outside fighter standing lanes')
    for c in ['hero_rookie','orc_shield']:
        path=f'assets/characters/{c}/fresh_idle.png';check((ROOT/path).read_bytes()==previous(path),'character bytes unchanged')
fx=json.loads((ROOT/'assets/fx/weather/anim.json').read_text())
for name,e in fx.items():
    check('compress/mode=2' in (ROOT/f'assets/fx/weather/{name}.png.import').read_text(),name+' VRAM compressed')
    im=Image.open(ROOT/f'assets/fx/weather/{name}.png').convert('RGBA');w,h=e['frame_size'];cols=e['columns']
    check(im.size==(cols*w,math.ceil(e['frames']/cols)*h),name+' atlas dimensions')
    signatures=[]
    for i in range(e['frames']):
        fr=im.crop((i%cols*w,i//cols*h,i%cols*w+w,i//cols*h+h));a=np.array(fr)
        if i in e.get('blank_frames',[]):check(not a.any(),name+str(i)+' fully off')
        else:
            check(int((a[:,:,3]>32).sum())>40,name+str(i)+' visible drawn effect')
            signatures.append(hashlib.sha256(fr.tobytes()).hexdigest())
        check(not np.concatenate((a[0].ravel(),a[-1].ravel(),a[:,0].ravel(),a[:,-1].ravel())).any(),name+str(i)+' transparent equal edges, no clipping')
        if name in ['rain','fog']:
            tiled=Image.new('RGBA',(w*2,h));tiled.alpha_composite(fr);tiled.alpha_composite(fr,(w,0));seam=np.asarray(tiled)[:,w-1:w+1,:]
            check(not seam.any(),name+str(i)+' repeated seam remains transparent')
    check(len(set(signatures))==len(signatures),name+' independent visible cels')
for name in hours+['rain','storm','fog']:
    im=Image.open(ROOT/f'assets/fx/weather/icon_{name}.png').convert('RGBA');check(im.size==(128,128),name+' icon dimensions');a=np.array(im)[:,:,3];check(not np.r_[a[0],a[-1],a[:,0],a[:,-1]].any(),name+' icon padding')
previews=[]
for p in REVIEW.iterdir():
    if p.suffix in ['.gif','.jpg']:
        check(p.stat().st_size<2_000_000,p.name+' under2MB');previews.append({'file':p.name,'bytes':p.stat().st_size})
for family in families:
    check((REVIEW/(family+'_four_hours.jpg')).is_file(),family+' four-hour comparison exists')
    check((REVIEW/(family+'_day_cycle.gif')).is_file(),family+' day-cycle GIF exists')
write(REVIEW/'validation.json',{'checks_passed':checks,'sky_variants':16,'weather_cels':26,'icons':7,'previews':previews})
print(f'{checks} checks passed;16skies,26weather cels,7icons; real tile seams/blank blink frames/old paintings preserved.')
