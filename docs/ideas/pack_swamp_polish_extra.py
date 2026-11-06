"""Issue48 addendum: drawn lift/rage cels and two spell overlays."""
from art48_49_sheet_tools import *

DOC=ROOT/'docs/ideas'
REVIEW=DOC/'swamp_polish_extra_review'
SOURCE=DOC/'swamp_polish_extra_sources.json'


def main():
    data=json.loads(SOURCE.read_text())
    REVIEW.mkdir(exist_ok=True);(REVIEW/'.gdignore').write_text('')
    output={}
    for character in ['toad_witch','orc_shield','orc_rock','orc_drummer','orc_boar']:
        count=12 if character=='toad_witch' else 10
        name='lift' if character=='toad_witch' else 'rage'
        fps=14 if name=='lift' else 12
        entry=data['sources'][character]
        raw=cells(entry,4,3,count)
        frames,registration=actor_frames(raw,Path('/workspace/issue48_extra_sources')/(character+'_ref.png'))
        entry['registration']=registration
        path=ROOT/f'assets/characters/{character}/anim/fresh_{name}.png'
        save_png(path,atlas(frames))
        meta_path=path.parent/'anim.json';meta=json.loads(meta_path.read_text())
        meta['clips'][name]={'frames':count,'fps':fps,'loop':False}
        if name=='lift':meta['clips'][name]['impact']=6
        write(meta_path,meta)
        gif(REVIEW/f'{character}_{name}.gif',preview_frames(frames,character+' '+name),fps)
        output[character]=frames
    for key,directory in [('levitate','assets/fx/curse'),('rage_steam','assets/fx/combat/anim')]:
        entry=data['sources'][key]
        raw=cells(entry,4,2,8)
        frames=fx_frames(raw)
        path=ROOT/directory/(key+'.png');save_png(path,atlas(frames))
        metadata_path=path.parent/'anim.json';metadata=json.loads(metadata_path.read_text())
        metadata[key]={'frames':8,'fps':12,'columns':4,'frame_size':[512,512],'loop':True}
        write(metadata_path,metadata)
        gif(REVIEW/(key+'.gif'),preview_frames(frames,key),12)
        output[key]=frames
    film=[]
    for f in range(24):
        canvas=Image.new('RGBA',(660,370),'#27343a')
        witch=output['toad_witch'][f%12].resize((320,320),Image.Resampling.LANCZOS)
        canvas.alpha_composite(witch,(5,38))
        ring=output['levitate'][f%8].resize((210,210),Image.Resampling.LANCZOS)
        tile=Image.open(ROOT/'assets/tiles/swamp_b/tile_purple.png').convert('RGBA')
        canvas.alpha_composite(tile,(440,140))
        canvas.alpha_composite(ring,(400,100))
        ImageDraw.Draw(canvas).text((12,8),'Lift cast + tile levitation (timing reference)',font=ImageFont.truetype(FONT,18),fill='#f6e8bf')
        film.append(canvas)
    gif(REVIEW/'lift_scene.gif',film,14)
    write(SOURCE,data)
    print('Packed52 actor cels,16FXcels;5 actor atlases and2FXatlases.')


if __name__=='__main__':main()
