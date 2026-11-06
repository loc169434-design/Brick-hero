"""Issue49 part4: map FX, exact global placements, source-preserving reviews."""
from world_life_sheet_tools import *
import copy
import sys

DOC=ROOT/'docs/ideas';DATA=DOC/'world_life_sources.json';DEST=ROOT/'assets/bg/campaign';REVIEW=DOC/'world_life_review/map'
SMOKE=[(1,[159,510],.15),(2,[373,1357],.55)]
FLAGS=[(2,[635,788],[36,64],.0),(2,[270,1328],[30,58],.4)]
WATER=[(1,[195,341]),(1,[255,358]),(1,[874,970]),(1,[989,929]),(1,[816,966]),(3,[235,465]),(3,[220,950]),(3,[810,1035]),(3,[420,1230]),(3,[930,1395]),(3,[185,1710])]
FALLS=[(1,[158,298],[60,90]),(1,[936,920],[84,126])]


def profile(count,textures):
    def global_point(segment,point):return [point[0],(count-segment)*1920+point[1]]
    result={'version':1,'map_size':[1080,count*1920],'segment_size':[1080,1920],
        'segment_count':count,'top_to_bottom':list(range(count,0,-1)),
        'segment_origins':{str(i):[0,(count-i)*1920] for i in range(1,count+1)},
        'coordinate_contract':'Game map:segment1atbottom;eachsegment1920px,no200pxart-contact-sheetoverlap.',
        'loop_seconds':4,'preview_fps':12,'textures':textures,
        'smoke':[{'segment':s,'local_position':p,'position':global_point(s,p),'phase':phase} for s,p,phase in SMOKE if s<=count],
        'water_glints':[global_point(s,p) for s,p in WATER if s<=count],
        'water_glint_sources':[{'segment':s,'local_position':p} for s,p in WATER if s<=count],
        'flags':[{'segment':s,'local_position':p,'position':global_point(s,p),'size_px':size,'origin':[64,20],'phase':phase} for s,p,size,phase in FLAGS if s<=count],
        'waterfalls':[{'segment':s,'local_position':p,'position':global_point(s,p),'size_px':size,'origin':[128,192],'phase':i*.5} for i,(s,p,size) in enumerate(FALLS) if s<=count],
        'smoke_motion':{'size_px':82,'rise_px':56,'drift_px':12,'opacity':.72,'tint':[245,240,227]},
        'water_motion':{'size_px':[5,18],'travel_y_px':8,'period_seconds':2,'opacity':.55,'tint':[190,239,255]},
        'cloud_motion':{'opacity':.5,'shadow_opacity':.13,'shadow_offset':[90,260],'speed_px_per_second':[12,25],'wrap_x':[-700,1180]},
        'clouds':[]}
    for s in range(1,count+1):
        result['clouds'].append({'segment':s,'texture':f'cloud_{(s-1)%3+1}','position':global_point(s,[720,240]),'scale':.8,'speed':18+s*2})
    return result


def export():
    data=json.loads(DATA.read_text());resources=json.loads((DOC/'world_life_resources.json').read_text());items={e['file']:e for e in resources['textures']}
    raw=cells(data['sources']['map_clouds'],1,3,3)
    for i,source in enumerate(raw,1):
        cloud=source.crop(bounds(np.asarray(source)[:,:,3]>32));cloud.thumbnail((590,250),Image.Resampling.LANCZOS);image=Image.new('RGBA',(600,260));image.alpha_composite(cloud,((600-cloud.width)//2,(260-cloud.height)//2));save_png(DEST/f'map_cloud_{i}.png',image)
    raw=cells(data['sources']['map_smoke_flags'],3,4,12)
    smoke=fx_frames(raw[:6],(192,192),.82);save_png(DEST/'map_smoke.png',atlas(smoke,3))
    # Register cloth by its stationary top bar, retaining the entire drawn cel.
    flags=[];boxes=[bounds(np.asarray(im)[:,:,3]>32) for im in raw[6:]]
    anchors=[]
    for im,b in zip(raw[6:],boxes):
        alpha=np.asarray(im)[:,:,3]>32;yy,xx=np.where(alpha & (np.indices(alpha.shape)[0]<b[1]+max(3,round((b[3]-b[1])*.06))))
        anchors.append(float(np.median(xx)))
    scale=min(min(56/max(anchor-b[0],b[2]-anchor),164/(b[3]-b[1])) for b,anchor in zip(boxes,anchors))
    data['sources']['map_smoke_flags']['flag_registration']={'top_bar_anchors':anchors,'uniform_scale':scale,'destination_origin':[64,20]}
    for im,b,anchor in zip(raw[6:],boxes,anchors):
        drawn=im.crop(b);drawn=drawn.resize((round(drawn.width*scale),round(drawn.height*scale)),Image.Resampling.LANCZOS);canvas=Image.new('RGBA',(128,192));canvas.alpha_composite(drawn,(round(64-(anchor-b[0])*scale),20));flags.append(canvas)
    save_png(DEST/'map_flag.png',atlas(flags,3))
    raw=cells(data['sources']['waterfall'],3,2,6);falls=fx_frames(raw,(256,384),.90);save_png(DEST/'waterfall.png',atlas(falls,3))
    # Reuse the established twinkle drawing byte-for-byte, tint in runtime only.
    (DEST/'map_water_glint.png').write_bytes((ROOT/'assets/bg/world_map_fx/sparkle.png').read_bytes())
    animations={n:{'file':f,'frame_size':size,'columns':3,'frames':6,'fps':12,'loop':True} for n,f,size in [('smoke','map_smoke.png',[192,192]),('flag','map_flag.png',[128,192]),('waterfall','waterfall.png',[256,384])]}
    animations['flag']['origin']=[64,20];animations['waterfall']['origin']=[128,192];write(DEST/'anim.json',animations)
    textures=copy.deepcopy(animations)
    textures['sparkle']={'file':'map_water_glint.png','frame_size':[128,128],'columns':1,'frames':1}
    for i in range(1,4):textures[f'cloud_{i}']={'file':f'map_cloud_{i}.png','frame_size':[600,260],'columns':1,'frames':1}
    primary=profile(2,textures);primary['profiles']={'2':'ambience.json','3':'ambience_g2.json'};primary['target']='Current main:two map segments. Select ambience_g2.json when Campaign.segments is3 after PR47.'
    write(DEST/'ambience.json',primary);write(DEST/'ambience_g2.json',profile(3,textures))
    obsolete=DEST/'ambience_g1.json'
    if obsolete.exists():obsolete.unlink()  # only our earlier generated draft
    for name in ['map_cloud_1','map_cloud_2','map_cloud_3','map_smoke','map_flag','waterfall','map_water_glint']:
        path=DEST/(name+'.png');items[str(path.relative_to(ROOT))]={'file':str(path.relative_to(ROOT)),'size':list(Image.open(path).size)}
    resources['textures']=list(items.values());resources['metadata']=sorted(set([p for p in resources['metadata'] if p!='assets/bg/campaign/ambience_g1.json']+[str((DEST/(n+'.json')).relative_to(ROOT)) for n in ['ambience','ambience_g2','anim']]));write(DOC/'world_life_resources.json',resources);write(DATA,data)
    REVIEW.mkdir(parents=True,exist_ok=True)
    gif(REVIEW/'map_smoke.gif',preview_frames(smoke,'map smoke'),12);gif(REVIEW/'map_flag.gif',preview_frames(flags,'Orc cloth banner'),12);gif(REVIEW/'waterfall.gif',preview_frames(falls,'waterfall'),12)
    clouds=[]
    for i in range(1,4):
        frame=Image.new('RGBA',(620,300),'#27343a');frame.alpha_composite(Image.open(DEST/f'map_cloud_{i}.png').convert('RGBA'),(10,30));ImageDraw.Draw(frame).text((10,7),f'map_cloud_{i} 600x260',font=ImageFont.truetype(FONT,17),fill='#f6e8bf');clouds.append(frame)
    gif(REVIEW/'map_clouds.gif',clouds,1)
    print('Packed3clouds,6smoke/6banner/6waterfallcels,twinkle;G2andG1coordinateprofiles.')


def reviews():
    data=json.loads(DATA.read_text());meta=json.loads((DEST/'ambience_g2.json').read_text());canvas=Image.new('RGB',(1080,5760))
    for segment in [3,2,1]:canvas.paste(Image.open(data['map_reference_segments'][str(segment)]['path']).convert('RGB'),(0,(3-segment)*1920))
    image=canvas.resize((540,2880),Image.Resampling.LANCZOS);draw=ImageDraw.Draw(image);font=ImageFont.truetype(FONT,13)
    for name,color in [('smoke','#ffbd56'),('flags','#ff6580'),('waterfalls','#73e5ff')]:
        for point in meta[name]:
            x,y=point['position'];x/=2;y/=2;draw.ellipse((x-5,y-5,x+5,y+5),outline=color,width=2);draw.text((x+8,y-6),name,font=font,fill=color,stroke_width=2,stroke_fill='#20282d')
    for x,y in meta['water_glints']:draw.ellipse((x/2-3,y/2-3,x/2+3,y/2+3),fill='#a8efff')
    for segment in [3,2,1]:
        y=(3-segment)*960;draw.text((10,y+12),f'Segment{segment} | global y={(3-segment)*1920}',font=ImageFont.truetype(FONT,17),fill='white',stroke_width=2,stroke_fill='#20282d')
    jpg(REVIEW/'map_positions_3_segments.jpg',image)
    render=Path('/workspace/issue49_sources/rendered_map')
    if not (render/'village_00.png').exists():return
    for scene in ['village','orc_camp']:
        film=[]
        for i in range(12):
            image=Image.open(render/f'{scene}_{i:02}.png').convert('RGBA').resize((432,448),Image.Resampling.LANCZOS);frame=Image.new('RGBA',(432,478),'#27343a');frame.alpha_composite(image,(0,30));ImageDraw.Draw(frame).text((8,7),scene+' map ambience',font=ImageFont.truetype(FONT,17),fill='#f6e8bf');film.append(frame)
        gif(REVIEW/(scene+'_life.gif'),film,12);jpg(REVIEW/(scene+'_life.jpg'),film[5])
    print('Map placements and actual Godot scene GIFs exported.')


if __name__=='__main__':
    if '--reviews-only' not in sys.argv:export()
    reviews()
