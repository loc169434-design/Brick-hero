"""Issue49 part3: sky crops, weather atlas assembly, actual rendered reviews."""
from world_life_sheet_tools import *
import sys

DOC=ROOT/'docs/ideas';DATA=DOC/'world_life_sources.json';REVIEW=DOC/'world_life_review/weather';DEST=ROOT/'assets/fx/weather'
FAMILIES=['training_field','orc_camp','swamp','goblin_camp'];HOURS=['morning','noon','dusk','night']
LIGHTING={'morning':[1.0,.96,.86,1.0],'noon':[1.0,1.0,1.0,1.0],'dusk':[1.0,.74,.58,1.0],'night':[.32,.40,.64,1.0]}
EYES={'training_field':[[65,390],[1015,365],[116,410]],'orc_camp':[[70,390],[1000,395],[130,351]],'swamp':[[65,344],[1005,351],[78,285]],'goblin_camp':[[52,315],[1018,350],[1048,284]]}
FX={'rain':(2,2,4,(1080,660),12,True,.96),
    'rain_splash':(3,2,6,(512,512),16,False,.78),
    'lightning_bolt':(3,2,6,(512,1024),18,False,.88),
    'fog':(2,2,4,(1080,660),8,True,.96),
    'red_eyes':(3,2,6,(256,128),8,False,.72)}


def export():
    data=json.loads(DATA.read_text());resources=json.loads((DOC/'world_life_resources.json').read_text())
    new_resources={e['file']:e for e in resources['textures']}
    for family in FAMILIES:
        e=data['sources']['sky_'+family];source=Image.open(e['path']).convert('RGBA');boxes=[]
        for i,hour in enumerate(HOURS):
            box=[round(i%2*source.width/2),round(i//2*source.height/2),round((i%2+1)*source.width/2),round((i//2+1)*source.height/2)]
            boxes.append(box);sky=source.crop(box).resize((1080,660),Image.Resampling.LANCZOS)
            path=ROOT/f'assets/bg/{family}/sky_{hour}.png';save_png(path,sky);new_resources[str(path.relative_to(ROOT))]={'file':str(path.relative_to(ROOT)),'size':[1080,660]}
        e['grid']=[2,2];e['crop_boxes']=boxes;e['sha256']=hashlib.sha256(Path(e['path']).read_bytes()).hexdigest()
        path=ROOT/f'assets/bg/{family}/layers.json';metadata=json.loads(path.read_text());metadata['eyes']=EYES[family]
        metadata['sky_times']={h:f'sky_{h}.png' for h in HOURS};metadata['time_lighting']=LIGHTING
        metadata['time_lighting_note']='Suggested runtime modulation for far/mid/ground and fighters; sky uses its own painted variant, eyes are drawn after modulation. No layer artwork recolored.'
        write(path,metadata)
    metadata={}
    for name,(columns,rows,count,size,fps,loop,fill) in FX.items():
        e=data['sources'][name];raw=cells(e,columns,rows,count)
        frames=fx_frames(raw,size,fill,blank=(0,5) if name=='red_eyes' else (),anchor_y=.82 if name=='rain_splash' else None)
        image=atlas(frames,columns);path=DEST/(name+'.png');save_png(path,image)
        metadata[name]={'frames':count,'fps':fps,'columns':columns,'frame_size':list(size),'loop':loop}
        if name in ['rain','fog']:metadata[name]['tileable']=['x','y'] if name=='rain' else ['x']
        if name=='red_eyes':metadata[name]['blank_frames']=[0,5]
        if name=='rain_splash':metadata[name]['origin']=[256,420]
        if name=='lightning_bolt':metadata[name]['origin']=[256,900]
        new_resources[str(path.relative_to(ROOT))]={'file':str(path.relative_to(ROOT)),'size':list(image.size)}
    write(DEST/'anim.json',metadata)
    e=data['sources']['weather_icons'];raw=cells(e,4,2,7)
    for name,source in zip(HOURS+['rain','storm','fog'],raw):
        tile=source.crop(bounds(np.asarray(source)[:,:,3]>32));tile.thumbnail((122,122),Image.Resampling.LANCZOS);canvas=Image.new('RGBA',(128,128));canvas.alpha_composite(tile,((128-tile.width)//2,(128-tile.height)//2));path=DEST/f'icon_{name}.png';save_png(path,canvas)
        new_resources[str(path.relative_to(ROOT))]={'file':str(path.relative_to(ROOT)),'size':[128,128]}
    resources['textures']=list(new_resources.values());resources['metadata']=sorted(set(resources['metadata']+['assets/fx/weather/anim.json']+[f'assets/bg/{f}/layers.json' for f in FAMILIES]));write(DOC/'world_life_resources.json',resources)
    write(DATA,data);print('Exported16skyvariants,5FXatlases,7icons;fourbackgrounds eyes/lights metadata.')


def load_fx(name):
    meta=json.loads((DEST/'anim.json').read_text())[name];image=Image.open(DEST/(name+'.png')).convert('RGBA');w,h=meta['frame_size'];cols=meta['columns']
    return [image.crop((i%cols*w,i//cols*h,i%cols*w+w,i//cols*h+h)) for i in range(meta['frames'])]


def reviews():
    REVIEW.mkdir(parents=True,exist_ok=True)
    for name,spec in FX.items():
        gif(REVIEW/(name+'.gif'),preview_frames(load_fx(name),name,(420,330)),spec[4])
    icons=Image.new('RGBA',(1008,170),'#27343a');draw=ImageDraw.Draw(icons)
    for i,name in enumerate(HOURS+['rain','storm','fog']):
        icon=Image.open(DEST/f'icon_{name}.png').convert('RGBA');icons.alpha_composite(icon,(i*144+8,5));draw.text((i*144+8,140),name,font=ImageFont.truetype(FONT,17),fill='#f6e8bf')
    jpg(REVIEW/'weather_icons.jpg',icons)
    # These PNGs are actual Godot renders outside git, not repainting base art.
    render_dir=Path('/workspace/issue49_sources/rendered')
    if not (render_dir/'training_field_morning.png').exists():return
    for family in FAMILIES:
        contact=Image.new('RGBA',(1080,558),'#27343a');draw=ImageDraw.Draw(contact);film=[]
        for i,hour in enumerate(HOURS):
            image=Image.open(render_dir/f'{family}_{hour}.png').convert('RGBA').resize((540,250),Image.Resampling.LANCZOS)
            contact.alpha_composite(image,(i%2*540,i//2*279+29));draw.text((i%2*540+10,i//2*279+6),family+' | '+hour,font=ImageFont.truetype(FONT,17),fill='#f6e8bf')
            movie=Image.new('RGBA',(540,279),'#27343a');movie.alpha_composite(image,(0,29));ImageDraw.Draw(movie).text((10,6),family+' | '+hour,font=ImageFont.truetype(FONT,17),fill='#f6e8bf');film.append(movie)
        jpg(REVIEW/(family+'_four_hours.jpg'),contact);gif(REVIEW/(family+'_day_cycle.gif'),film,1)
    base=Image.open(render_dir/'swamp_dusk.png').convert('RGBA')
    for name in ['rain','fog','lightning_bolt']:
        frames=[]
        for effect in load_fx(name):
            scene=base.copy()
            if name in ['rain','fog']:scene.alpha_composite(effect,(0,-80))
            else:
                effect=effect.resize((179,358),Image.Resampling.LANCZOS);scene.alpha_composite(effect,(450,90))
            scene=scene.resize((540,250),Image.Resampling.LANCZOS);frame=Image.new('RGBA',(540,279),'#27343a');frame.alpha_composite(scene,(0,29));ImageDraw.Draw(frame).text((10,6),'swamp dusk + '+name,font=ImageFont.truetype(FONT,17),fill='#f6e8bf');frames.append(frame)
        gif(REVIEW/(name+'_scene.gif'),frames,FX[name][4])
    print('Created actual game-layout four-hour comparisons/cycles and weather scene GIFs.')


if __name__=='__main__':
    if '--reviews-only' not in sys.argv:export()
    reviews()
