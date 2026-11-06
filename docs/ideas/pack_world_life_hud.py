"""Issue49 part1: complete-object crops and HUD preview assembly."""
from world_life_sheet_tools import *

DOC=ROOT/'docs/ideas';REVIEW=DOC/'world_life_review/hud'
DATA=DOC/'world_life_sources.json';DEST=ROOT/'assets/ui/hud'


def main():
    data=json.loads(DATA.read_text());e=data['sources']['hud']
    source=Image.open(e['path']).convert('RGBA');labels,sizes=components(source)
    objects=ndimage.find_objects(labels)
    boxes=[(int(sizes[i+1]),[b[1].start,b[0].start,b[1].stop,b[0].stop]) for i,b in enumerate(objects) if b and sizes[i+1]>10000]
    assert len(boxes)==3
    boxes=sorted(boxes,key=lambda b:b[1][1]);plate=boxes[0][1];swords=sorted([b[1] for b in boxes[1:]],key=lambda b:b[0])
    e['sha256']=hashlib.sha256(Path(e['path']).read_bytes()).hexdigest();e['object_crops']=[plate]+swords
    plaque=Image.new('RGBA',(360,116));plaque.alpha_composite(source.crop(plate).resize((356,112),Image.Resampling.LANCZOS),(2,2));save_png(DEST/'turn_plaque.png',plaque)
    for name,box in zip(['sword_left','sword_right'],swords):
        sword=source.crop(box);sword.thumbnail((148,148),Image.Resampling.LANCZOS);canvas=Image.new('RGBA',(160,160));canvas.alpha_composite(sword,((160-sword.width)//2,(160-sword.height)//2));save_png(DEST/(name+'.png'),canvas)
    raw=cells(data['sources']['clash_spark'],3,2,6);sparks=fx_frames(raw,(160,160),.78)
    save_png(DEST/'clash_spark.png',atlas(sparks,3))
    write(DEST/'anim.json',{'clash_spark':{'frames':6,'fps':24,'columns':3,'frame_size':[160,160],'loop':False}})
    write(DEST/'hud_manifest.json',{'plaque':{'file':'turn_plaque.png','size':[360,116],'text_rect':[22,18,316,80],'text_embedded':False},'swords':{'left':'sword_left.png','right':'sword_right.png','size':[160,160],'pivot':[80,80],'tip':'up','native_lean_degrees':10},'clash_period_seconds':2,'clash_spark':'anim.json'})
    REVIEW.mkdir(parents=True,exist_ok=True);(REVIEW.parent/'.gdignore').write_text('')
    font=ImageFont.truetype(FONT,32);film=[]
    for i in range(48):
        out=Image.new('RGBA',(660,200),'#27343a');out.alpha_composite(plaque,(150,42));draw=ImageDraw.Draw(out);draw.text((330,100),'Lượt 12',font=font,anchor='mm',fill='#ffe1a5',stroke_width=1,stroke_fill='#2e2017')
        t=i/24;swing=max(0,1-abs(t-.62)/.5);spread=.5*swing
        for x in [110,550]:
            for side,name in [(-1,'sword_left'),(1,'sword_right')]:
                sword=Image.open(DEST/(name+'.png')).convert('RGBA');sword=sword.rotate(side*math.degrees(.62-spread),Image.Resampling.BICUBIC,expand=True);out.alpha_composite(sword,(x-sword.width//2,100-sword.height//2))
            if .62<=t<.87:out.alpha_composite(sparks[min(5,int((t-.62)*24))],(x-80,20))
        film.append(out)
    gif(REVIEW/'turn_plaque_clash.gif',film,24)
    jpg(REVIEW/'turn_plaque_preview.jpg',film[15])
    gif(REVIEW/'clash_spark.gif',preview_frames(sparks,'clash spark',(220,250)),24)
    write(DATA,data)
    print('HUD:360x116 plaque,two160x160 swords,6spark cels;all previews<2MB')


if __name__=='__main__':main()
