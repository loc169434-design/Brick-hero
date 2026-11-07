"""Build the requested 3 bases + 6 opaque, registered face patches.

Helmet art comes from full-body image edits, never from pasted item icons.
The original skin/frame is protected during the cut so the head and neck
cannot change scale or jump when equipment changes.
"""
from pathlib import Path
import argparse
import json
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

D = Path(__file__).resolve().parent
ROOT = D.parents[2]
A = ROOT/'assets/characters/hero_rig'
EXPRESSIONS=['normal','blink','angry','hurt','happy','scared']


def polygon(points):
    im=Image.new('1',(512,512));ImageDraw.Draw(im).polygon(points,fill=1)
    return np.array(im,dtype=bool)


def save_mask(mask,path):
    a=np.zeros((512,512,4),np.uint8);a[mask]=255;Image.fromarray(a).save(path)


def body_without_head():
    result=Image.new('RGBA',(512,512))
    order=json.loads((A/'joints.json').read_text())['order']
    for part in order:
        if part in ('head','sword'):continue
        path=A/'parts'/f'{part}.png'
        if path.exists():result.alpha_composite(Image.open(path).convert('RGBA'))
    return result


def run(round_number):
    assert 1<=round_number<=6
    geometry=json.loads((D/'geometry.json').read_text())
    bare=Image.open(A/'head/bare.png').convert('RGBA');b=np.array(bare)
    y,x=np.mgrid[:512,:512]
    skin=polygon(geometry['face_skin_polygon']) & (b[:,:,3]>240)
    # Recover the real skin margin up to the hairline, without swallowing hair.
    rgb=b[:,:,:3].astype(int)
    flesh=(rgb[:,:,0]>170)&(rgb[:,:,1]>115)&(rgb[:,:,2]>65)&(b[:,:,3]>240)
    skin |= ndi.binary_dilation(skin,iterations=3)&flesh
    clear_skin=(rgb[:,:,0]>=225)&(rgb[:,:,1]>=145)&(rgb[:,:,2]>=90)
    # Mixed hairline pixels are not part of an opaque skin patch.
    skin&=(y>=164)|clear_skin
    skin=ndi.binary_fill_holes(skin)
    features=polygon(geometry['feature_envelope_polygon'])
    padding=ndi.distance_transform_edt(~features)<=6
    mask=padding&skin
    save_mask(skin,D/'fixtures/face_skin.png')
    save_mask(features,D/'fixtures/feature_envelope.png')
    save_mask(mask,D/'face_mask.png')
    distance=ndi.distance_transform_edt(mask)
    border=mask&(distance<=3)
    save_mask(border,D/'fixtures/face_border_3px.png')
    # Complete original face, ear, jaw contour and neck pixels are invariant.
    protect=polygon(geometry['protected_head_frame_polygon'])|skin|((y>=222)&(x>=232))
    protect&=(y>=164)|clear_skin
    protect|=mask
    protected_pixels=protect&(b[:,:,3]>0)
    save_mask(protected_pixels,D/'fixtures/protected_head_frame.png')
    for kind in ['leather_helmet','iron_helmet']:
        generated=Image.open(D/'raw'/f'{kind}_raw.png').convert('RGBA')
        a=np.array(generated)
        # Cut the head using the generated silhouette, not a fixed-width box.
        support=(x>=160)&(x<=335)&(y>=90)&(y<=250)&((y<222)|ndi.binary_dilation(b[:,:,3]>127,iterations=2))
        a[~support]=0
        labels,_=ndi.label(a[:,:,3]>127);counts=np.bincount(labels.ravel());counts[0]=0
        connected=ndi.binary_dilation(labels==counts.argmax(),iterations=2)
        a[~connected]=0
        ann=geometry['helmets'][kind]
        line=sorted(ann['brim_lower'])
        brim=np.interp(x,[v[0] for v in line],[v[1] for v in line])
        hair=((y>=brim)&(y<=brim+12)&(x>=218)&(x<=315))
        for points in geometry['allowed_hair_polygons']:hair|=polygon(points)
        cap=ndi.binary_dilation(polygon(ann['cap_polygon']),iterations=1)
        # Remove scarf pixels accidentally enclosed by the rectangular head cut,
        # and retain only the cap, fixed frame, short fringe and both sideburns.
        forehead=polygon(geometry['generated_forehead_polygon'])&(y>=brim)
        a[~(cap|hair|protect|forehead)]=0
        # Fixed original frame fulfils the pixel-preservation part of image edit.
        # No resizing or repositioning of the face/neck occurs here.
        a[protect&~(cap|hair)]=b[protect&~(cap|hair)]
        a[protected_pixels]=b[protected_pixels]
        # Remove disconnected cutout specks while retaining edge antialiasing.
        labels,_=ndi.label(a[:,:,3]>127);counts=np.bincount(labels.ravel());counts[0]=0
        main=labels==counts.argmax();edge=ndi.binary_dilation(main,iterations=2)
        a[((a[:,:,3]>127)&~main)|((a[:,:,3]<=127)&~edge)]=0
        complete=Image.fromarray(a)
        complete.save(A/'head'/f'{kind}.png')
        raw=body_without_head();raw.alpha_composite(complete)
        raw.save(D/'raw'/f'{kind}_raw.png')
    (A/'faces').mkdir(exist_ok=True)
    for expression in EXPRESSIONS:
        a=b.copy()
        if expression!='normal':
            registered=np.array(Image.open(D/'fixtures'/f'expression_{expression}_aligned.png'))
            # Opaque patch: harmonize only the skin seam, never its alpha.
            # The outer 3px retain original skin; a 1px transition avoids a seam.
            weight=np.clip(distance-3,0,1)
            a[:,:,:3]=np.rint(b[:,:,:3]*(1-weight[:,:,None])+registered[:,:,:3]*weight[:,:,None]).astype(np.uint8)
        a[~mask]=0;a[mask,3]=255
        Image.fromarray(a).save(A/'faces'/f'{expression}.png')
    (D/'build.json').write_text(json.dumps({'round':round_number,'neck':[262,237],
        'method':'Full-body helmet image edits; generated head silhouette + original protected face/ear/chin/neck; shared opaque face patches.',
        'face_padding_px':6,'clip_padding_to_skin':'Approved by user when padding reaches hairline.',
        'border_color_harmonization':'Outer 3px original skin RGB, then 1px transition; alpha remains 255 throughout face mask.',
        'face_mask_pixels':int(mask.sum()),'protected_frame_pixels':int(protected_pixels.sum()),
        'expression_inputs':'docs/ideas/hero_rig_v2/inputs/head_<expression>_edit.png',
        'old_heads_modified':False},indent=2)+'\n')


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--round',type=int,required=True)
    run(p.parse_args().round)
