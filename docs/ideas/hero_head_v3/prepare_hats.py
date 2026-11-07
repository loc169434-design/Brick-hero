"""Align each full-body helmet edit by the unchanged body, then cut its head."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi
from scipy.optimize import minimize

D = Path(__file__).resolve().parent
ROOT = D.parents[2]
A = ROOT/'assets/characters/hero_rig'


def run(round_number):
    assert 1 <= round_number <= 6
    ref = Image.open(ROOT/'docs/ideas/hero_rig_v2/assembled_bare.png').convert('RGBA')
    b = np.array(Image.open(A/'head/bare.png'))
    r = np.array(ref)
    y,x = np.mgrid[:512,:512]
    body = ndi.binary_dilation(r[:,:,3]>127,iterations=5) & (y>=250)
    body128 = np.array(Image.fromarray(np.uint8(body)*255).resize((128,128),Image.Resampling.NEAREST))>127
    def premult(a):
        a=a.astype(float);a[:,:,:3]*=a[:,:,3:4]/255;return a
    reference = premult(np.array(ref.resize((128,128),Image.Resampling.LANCZOS)))
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',12)
    for kind in ['leather_helmet','iron_helmet']:
        source = D/'raw/sources'/f'{kind}_r{round_number}.png'
        if not source.exists():
            # Later pipeline checks may reuse the latest image edit.
            candidates = sorted(p for p in (D/'raw/sources').glob(f'{kind}_r*.png') if re.fullmatch(kind+r'_r[1-6]',p.stem))
            source = candidates[-1]
        original=Image.open(source).convert('RGBA')
        raw=original.resize((512,512),Image.Resampling.LANCZOS)
        small=raw.resize((128,128),Image.Resampling.LANCZOS)
        cache=D/'raw/sources'/f'{source.stem}_alignment.json'
        digest=hashlib.sha256(source.read_bytes()).hexdigest()
        previous=json.loads(cache.read_text()) if cache.exists() else {}
        if previous.get('source_sha256')==digest:
            q=previous['tx_ty_sx_sy']
        else:
            def cost(q):
                tx,ty,sx,sy=q
                a=np.array(small.transform((128,128),Image.Transform.AFFINE,
                           (1/sx,0,-tx/(4*sx),0,1/sy,-ty/(4*sy)),Image.Resampling.BICUBIC))
                return float(np.abs(premult(a)-reference)[body128].mean())
            opt=minimize(cost,[0,0,1,1],method='Powell',bounds=[(-15,15),(-15,15),(.94,1.06),(.94,1.06)],options={'maxiter':18,'xtol':.003})
            q=list(map(float,opt.x))
        tx,ty,sx,sy=q
        aligned=raw.transform((512,512),Image.Transform.AFFINE,
                              (1/sx,0,-tx/sx,0,1/sy,-ty/sy),Image.Resampling.BICUBIC)
        cache.write_text(json.dumps({'source_sha256':digest,'source_size':original.size,'tx_ty_sx_sy':q,'body_roi':'y>=250, reference foreground dilated 5px'},indent=2)+'\n')
        aligned.save(D/'raw'/f'{kind}_raw.png')
        aligned.save(D/'raw/sources'/f'{source.stem}_aligned.png')
        # The source is a full person; only its head/neck support is exported.
        a=np.array(aligned)
        support=(x>=160)&(x<=335)&(y>=90)&(y<=250)&((y<222)|ndi.binary_dilation(b[:,:,3]>127,iterations=2))
        a[~support]=0
        labels,_=ndi.label(a[:,:,3]>127);counts=np.bincount(labels.ravel());counts[0]=0
        keep=ndi.binary_dilation(labels==counts.argmax(),iterations=2)
        a[~keep]=0
        Image.fromarray(a).save(A/'head'/f'{kind}.png')
        crop=aligned.crop((175,100,330,220)).resize((775,600),Image.Resampling.NEAREST)
        grid=Image.new('RGB',crop.size,'#eee7da');grid.paste(crop,(0,0),crop);draw=ImageDraw.Draw(grid)
        for xx in range(180,331,10):
            px=(xx-175)*5;draw.line((px,0,px,600),fill='#aaa');draw.text((px,0),str(xx),font=font,fill='black')
        for yy in range(110,221,10):
            py=(yy-100)*5;draw.line((0,py,775,py),fill='#aaa');draw.text((0,py),str(yy),font=font,fill='black')
        grid.save(D/'raw/sources'/f'{source.stem}_grid.png')
    compare=Image.new('RGB',(1536,548),'#eee7da');draw=ImageDraw.Draw(compare)
    for col,(title,im) in enumerate([('Gốc',ref)]+[(k,Image.open(D/'raw'/f'{k}_raw.png')) for k in ['leather_helmet','iron_helmet']]):
        compare.paste(im,(col*512,32),im);draw.text((col*512+12,8),title,font=font,fill='#30241d')
    compare.save(D/'raw/compare.png')


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--round',type=int,required=True)
    run(parser.parse_args().round)
