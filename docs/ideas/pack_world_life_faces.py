"""Issue49 part2: crop drawn faces, preserve original expressions and clip art."""
from art48_49_sheet_tools import *

DOC=ROOT/'docs/ideas';DATA=DOC/'world_life_sources.json';DEST=ROOT/'assets/tiles/swamp_b';REVIEW=DOC/'world_life_review/faces'


def main():
    data=json.loads(DATA.read_text());raw=cells(data['sources']['toad_faces'],4,2,8)
    colors=['red','green','yellow','purple'];packed={}
    for row,pose in enumerate(['sly','dizzy']):
        for col,color in enumerate(colors):
            source=raw[row*4+col];source=source.crop(bounds(np.asarray(source)[:,:,3]>32)).resize((126,126),Image.Resampling.LANCZOS)
            tile=Image.new('RGBA',(128,128));tile.alpha_composite(source,(1,1));save_png(DEST/'expressions'/f'{color}_{pose}.png',tile);packed[color,pose]=tile
    path=DEST/'swamp_manifest.json';meta=json.loads(path.read_text());old_poses=[p for p in meta['expressions'] if p not in ['sly','dizzy']]
    for color in colors:
        expressions=[Image.open(DEST/'expressions'/f'{color}_{p}.png').convert('RGBA') for p in old_poses]+[packed[color,p] for p in ['sly','dizzy']]
        save_png(DEST/f'expressions_{color}.png',atlas(expressions,3))
    meta['expressions']=old_poses+['sly','dizzy'];meta['expression_grid']={'columns':3,'cell':128,'rows':5};write(path,meta)
    path=ROOT/'assets/tiles/animation_pack.json';global_meta=json.loads(path.read_text());global_meta['families']['swamp_b']['expressions']=meta['expressions'];write(path,global_meta)
    REVIEW.mkdir(parents=True,exist_ok=True);film=[]
    for pose in ['sly','dizzy']:
        out=Image.new('RGBA',(600,258),'#27343a');draw=ImageDraw.Draw(out);draw.text((10,8),pose+' | 128px +46px',font=ImageFont.truetype(FONT,18),fill='#f6e8bf')
        for i,c in enumerate(colors):
            out.alpha_composite(packed[c,pose],(i*148+8,40));out.alpha_composite(packed[c,pose].resize((46,46),Image.Resampling.LANCZOS),(i*148+49,184))
        film.append(out)
    gif(REVIEW/'sly_dizzy_four_colors.gif',film,1)
    combined=Image.new('RGBA',(600,516),'#27343a');combined.alpha_composite(film[0]);combined.alpha_composite(film[1],(0,258));jpg(REVIEW/'sly_dizzy_128_46.jpg',combined)
    write(DATA,data);print('8 drawn static faces;14expressions percolor;old cels retained.')


if __name__=='__main__':main()
