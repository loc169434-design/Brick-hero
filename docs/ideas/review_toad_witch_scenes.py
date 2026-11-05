"""Offline scene previews using exported hand-drawn cels, not game screenshots."""
from pathlib import Path
import json,math
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'docs/ideas/toad_witch_spells_review'
FONT=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',17)
SMALL=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',12)
TIMELINES={}

def read(path,n):
    im=Image.open(ROOT/path).convert('RGBA')
    return [im.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512)) for i in range(n)]

def actor(cid,clip,n,prefix='fresh',broom=False):
    folder=f'assets/characters/{cid}/anim'+('/broom' if broom else '')
    return read(folder+f'/{prefix}_{clip}.png',n)

def paste_foot(canvas,frame,x,y,scale=.43):
    im=frame.resize((round(512*scale),round(512*scale)),Image.Resampling.LANCZOS)
    canvas.alpha_composite(im,(round(x-256*scale),round(y-500*scale)))

def paste_center(canvas,frame,x,y,size):
    im=frame.resize((size,size),Image.Resampling.LANCZOS)
    canvas.alpha_composite(im,(round(x-size/2),round(y-size/2)))

def background(title):
    im=Image.new('RGBA',(480,640),'#193444')
    bg=Image.new('RGBA',(1080,660))
    for layer in ['sky','far','mid','ground']:
        bg.alpha_composite(Image.open(ROOT/f'assets/bg/swamp/{layer}.png').convert('RGBA'))
    im.alpha_composite(bg.resize((480,293),Image.Resampling.LANCZOS),(0,47))
    d=ImageDraw.Draw(im);d.text((16,12),title,font=FONT,fill='#fff0ce')
    d.rounded_rectangle((54,357,426,623),radius=16,fill='#284c4d',outline='#91734e',width=3)
    tiles=[Image.open(ROOT/f'assets/tiles/swamp/tile_{c}.png').convert('RGBA').resize((52,52),Image.Resampling.LANCZOS) for c in ['red','green','yellow','purple']]
    for row in range(4):
        for col in range(6):im.alpha_composite(tiles[(row*3+col)%4],(67+col*58,374+row*58))
    return im

def stage(base,hero,witch,caption,giant=False,phase_scale=None):
    im=base.copy();paste_foot(im,hero,110,329)
    scale=phase_scale if phase_scale is not None else .57 if giant else .43
    x=369-29*(scale-.43)/.14
    paste_foot(im,witch,x,329,scale)
    d=ImageDraw.Draw(im);d.rectangle((0,338,480,356),fill='#193444');d.text((12,340),caption,font=SMALL,fill='#fff0ce')
    return im

def save(name,events,cues):
    frames=[];durations=[];elapsed=0;last_tick=0
    for im,seconds in events:
        elapsed+=seconds;tick=round(elapsed*100)
        frames.append(im.convert('RGB'));durations.append((tick-last_tick)*10);last_tick=tick
    path=OUT/(name+'.gif')
    # One shared palette keeps the static arena identical between frames instead
    # of recoloring the background whenever a character pose changes.
    samples=Image.new('RGB',(480,640))
    for j in range(16):
        thumb=frames[round(j*(len(frames)-1)/15)].resize((120,160))
        samples.paste(thumb,((j%4)*120,(j//4)*160))
    palette=samples.quantize(colors=256,method=Image.Quantize.MEDIANCUT)
    frames=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
    frames[0].save(path,save_all=True,append_images=frames[1:],duration=durations,loop=0,disposal=1,optimize=True)
    assert path.stat().st_size<2_000_000,(path,path.stat().st_size)
    TIMELINES[name]={'seconds':elapsed,'frames':len(frames),'bytes':path.stat().st_size,'cues':cues}

def main():
    OUT.mkdir(exist_ok=True)
    hero=actor('hero_rookie','idle',8)[0];witch=actor('toad_witch','idle',4)[0]
    giant=actor('toad_witch_giant','idle',4)[0]
    bottle=read('assets/board/obstacles/potion_bottle_idle.png',4)
    burst=read('assets/board/obstacles/potion_burst.png',8)
    toad_idle=actor('hero_toad','idle',8);toad_attack=actor('hero_toad','attack',8)
    toad_in=actor('hero_toad','transform_in',14);toad_out=actor('hero_toad','transform_out',14)
    # 1: throw -> vial reaches board -> burst -> frog hero -> tongue -> restore.
    base=background('Bình thuốc cóc');events=[];throw=actor('toad_witch','throw_potion',12)
    for i,f in enumerate(throw):
        im=stage(base,hero,f,'Mụ ném bình thuốc')
        # The vial is drawn in witch cels 6-7. External flight starts at 8,
        # preserving release timing without drawing a second bottle over it.
        if i>=8:
            t=(i-8)/8;paste_center(im,bottle[i%4],310-43*t,205+253*t-80*math.sin(math.pi*t),58)
        events.append((im,1/14))
    for j in range(4,9):
        t=j/8;im=stage(base,hero,witch,'Bình rơi xuống bảng')
        paste_center(im,bottle[j%4],310-43*t,205+253*t-80*math.sin(math.pi*t),58)
        events.append((im,1/14))
    for f in bottle:
        im=stage(base,hero,witch,'Bình sủi bọt');paste_center(im,f,267,458,70);events.append((im,1/10))
    for f in burst:
        im=stage(base,hero,witch,'Khói xanh bùng lên');paste_center(im,f,267,458,210);events.append((im,1/14))
    for f in toad_in:events.append((stage(base,f,witch,'Hiệp sĩ hóa cóc'),1/14))
    for f in toad_idle:events.append((stage(base,f,witch,'Vẫn nhận ra tóc nâu và khăn đỏ'),1/10))
    for f in toad_attack:events.append((stage(base,f,witch,'Lè lưỡi quất'),1/14))
    for f in toad_out:events.append((stage(base,f,witch,'Hết phép: trở lại hiệp sĩ'),1/14))
    events.append((stage(base,hero,witch,'Hồi phục'),.6))
    save('scene_01_potion_hero_toad',events,{'throw_release_frame':6,'external_vial_from_witch_frame':8,'hero_transform_in':14,'hero_transform_out':14,'order':['throw_potion','vial_flight','potion_burst','transform_in','idle','attack','transform_out']})
    # 2: purple cast -> sword to broom -> two sweeps -> break curse.
    base=background('Phép chổi');events=[]
    beam=read('assets/fx/curse/broom_spell.png',8)
    for i,f in enumerate(actor('toad_witch','cast_broom',12)):
        im=stage(base,hero,f,'Tia phép tím xoắn')
        if i>=8:paste_center(im,beam[i-8],300-18*(i-8),235,130)
        events.append((im,1/14))
    for i in range(4,8):
        f=beam[i]
        im=stage(base,hero,witch,'Phép chạm kiếm');paste_center(im,f,300-18*i,235,130);events.append((im,1/14))
    broom_idle=actor('hero_rookie','idle',8,broom=True)[0]
    for f in actor('hero_rookie','broom_in',12,broom=True):events.append((stage(base,f,witch,'Kiếm hóa chổi rơm'),1/14))
    for repeat in range(2):
        for f in actor('hero_rookie','attack',12,broom=True):events.append((stage(base,f,witch,'Quét chổi: bụi và rơm bay'),1/24))
    events.append((stage(base,broom_idle,witch,'Nối dài để bẻ gãy phép'),.3))
    for f in actor('hero_rookie','broom_out',12,broom=True):events.append((stage(base,f,witch,'Ánh vàng: chổi hóa lại kiếm'),1/14))
    events.append((stage(base,hero,witch,'Hiệp sĩ thở phào'),.6))
    save('scene_02_broom_curse',events,{'cast_release_frame':6,'broom_in_frames':12,'broom_attack_impact':6,'broom_out_frames':12,'order':['cast_broom','broom_spell','broom_in','attack','broom_out']})
    # 3: hand-drawn sixteen-cel growth -> burp -> two babies reach board.
    base=background('Mụ hóa cóc khổng lồ');events=[]
    for i,f in enumerate(actor('toad_witch','drink_transform',16)):
        scale=.43+.14*max(0,(i-9)/6)
        events.append((stage(base,hero,f,'Uống thuốc và biến hình',phase_scale=scale),1/12))
    events.append((stage(base,hero,giant,'Cóc khổng lồ',True),.4))
    hop=read('assets/fx/curse/toad_hop.png',6)
    for i,f in enumerate(actor('toad_witch_giant','burp_toads',10)):
        im=stage(base,hero,f,'Ợ ra hai cóc con',True)
        if i>=7:
            t=(i-7)/6
            for k in range(2):paste_center(im,hop[(i-7)%6],300-(91+k*58)*t,235+(223+k*58)*t-70*math.sin(math.pi*t),60)
        events.append((im,1/12))
    for j in range(3,7):
        t=j/6;im=stage(base,hero,giant,'Hai cóc con nhảy xuống bảng',True)
        for k in range(2):paste_center(im,hop[min(j,5)],300-(91+k*58)*t,235+(223+k*58)*t-70*math.sin(math.pi*t),60)
        events.append((im,1/12))
    small=Image.open(ROOT/'assets/board/obstacles/poison_toad.png').convert('RGBA').resize((55,55),Image.Resampling.LANCZOS)
    for f in actor('toad_witch_giant','victory',8):
        im=stage(base,hero,f,'Cóc độc đã xuống bảng',True);im.alpha_composite(small,(181,430));im.alpha_composite(small,(123,488));events.append((im,1/8))
    save('scene_03_transform_burp',events,{'witch_transform_frames':16,'burp_release_frame':5,'external_babies_from_giant_frame':7,'baby_toads':2,'order':['drink_transform','burp_toads','toad_hop','victory']})
    (OUT/'scene_timelines.json').write_text(json.dumps(TIMELINES,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(TIMELINES,ensure_ascii=False))

if __name__=='__main__':main()
