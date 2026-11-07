"""Clean the REF cut and register the five supplied expression edits.

This script prepares diagnostics, not the final face mask. Registration uses
ear, nose, chin and neck, excluding changing eyes/brows/mouth.
"""
from pathlib import Path
import json
import hashlib
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi
from scipy.optimize import minimize

D = Path(__file__).resolve().parent
ROOT = D.parents[2]
A = ROOT / 'assets/characters/hero_rig'
V2 = ROOT / 'docs/ideas/hero_rig_v2'
F = D / 'fixtures'
F.mkdir(exist_ok=True, parents=True)
EXPRESSIONS = ['normal', 'blink', 'angry', 'hurt', 'happy', 'scared']


def polygon(points):
    mask = Image.new('1', (512, 512))
    ImageDraw.Draw(mask).polygon(points, fill=1)
    return np.array(mask, dtype=bool)


def clean(image):
    a = np.array(image.convert('RGBA'))
    labels, _ = ndi.label(a[:, :, 3] > 127)
    counts = np.bincount(labels.ravel())
    counts[0] = 0
    keep = ndi.binary_dilation(labels == counts.argmax(), iterations=2)
    a[~keep] = 0
    return Image.fromarray(a)


def transform(image, q):
    tx, ty, sx, sy = q
    return image.transform((512, 512), Image.Transform.AFFINE,
                           (1/sx, 0, -tx/sx, 0, 1/sy, -ty/sy),
                           Image.Resampling.BICUBIC)


def run():
    bare = clean(Image.open(A/'heads/bare_normal.png'))
    (A/'head').mkdir(exist_ok=True)
    bare.save(A/'head/bare.png')
    b = np.array(bare)
    ear = polygon([(219,192),(230,186),(243,190),(245,203),(234,214),(220,206)])
    nose = polygon([(299,187),(306,188),(310,195),(306,201),(299,198)])
    chin = polygon([(251,220),(290,224),(307,220),(307,226),(284,233),(261,229)])
    neck = polygon([(238,223),(248,226),(266,238),(269,245),(254,240),(239,230)])
    anchor = (ear | nose | chin | neck) & (b[:,:,3] > 127)
    Image.fromarray(np.uint8(anchor)*255).save(F/'expression_registration_roi.png')
    metadata = {}
    for name in EXPRESSIONS[1:]:
        source = V2/'inputs'/f'head_{name}_edit.png'
        original = clean(Image.open(source))
        cropped = original.crop(original.getbbox()).resize((155,145), Image.Resampling.LANCZOS)
        initial = Image.new('RGBA',(512,512))
        initial.alpha_composite(cropped,(174,105))
        cache = F/f'expression_{name}_registration.json'
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        previous = json.loads(cache.read_text()) if cache.exists() else {}
        if previous.get('source_sha256') == digest:
            q = previous['tx_ty_sx_sy']
        else:
            def cost(q):
                a = np.array(transform(initial,q)).astype(float)
                return np.abs(a[:,:,:3]-b[:,:,:3])[anchor].mean()
            opt = minimize(cost,[0,0,1,1], method='Powell',
                           bounds=[(-10,10),(-10,10),(.94,1.06),(.94,1.06)],
                           options={'maxiter':18,'xtol':.002})
            q = list(map(float,opt.x))
        aligned = transform(initial,q)
        aligned.save(F/f'expression_{name}_aligned.png')
        record = {'source':str(source.relative_to(ROOT)), 'source_sha256':digest,
                  'initial_crop':list(original.getbbox()),
                  'initial_size':[155,145], 'initial_position':[174,105],
                  'tx_ty_sx_sy':q,
                  'anchor_rgb_mae':float(np.abs(np.array(aligned)[:,:,:3].astype(float)-b[:,:,:3])[anchor].mean())}
        cache.write_text(json.dumps(record,indent=2)+'\n')
        metadata[name] = record
    # Coordinates are printed on the actual output frame, not source coordinates.
    font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',12)
    sheet = Image.new('RGB',(1920,610),'#eee7da')
    for col,name in enumerate(EXPRESSIONS):
        im = bare if name=='normal' else Image.open(F/f'expression_{name}_aligned.png')
        crop = im.crop((235,145,320,235)).resize((340,360),Image.Resampling.NEAREST)
        grid = Image.new('RGB',crop.size,'#eee7da');grid.paste(crop,(0,0),crop)
        draw = ImageDraw.Draw(grid)
        for x in range(240,321,10):
            xx=(x-235)*4;draw.line((xx,0,xx,360),fill='#aaa');draw.text((xx,0),str(x),font=font,fill='black')
        for y in range(150,236,10):
            yy=(y-145)*4;draw.line((0,yy,340,yy),fill='#aaa');draw.text((0,yy),str(y),font=font,fill='black')
        grid.save(F/f'feature_grid_{name}.png')
        thumb = im.crop((165,95,335,255)).resize((300,282))
        sheet.paste(thumb,(col*320+10,40),thumb)
        ImageDraw.Draw(sheet).text((col*320+10,12),name,font=font,fill='#30241d')
    sheet.crop((0,0,1920,340)).save(F/'expression_alignment.png')
    (F/'expression_registration.json').write_text(json.dumps(metadata,indent=2)+'\n')
    print(json.dumps({k:v['anchor_rgb_mae'] for k,v in metadata.items()},indent=2))


if __name__ == '__main__':
    run()
