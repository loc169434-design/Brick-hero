"""Direct original-frame cuts, with closed hidden joint overlaps.

Workflow revised by the user: original pixels, not the old layered rig renders.
No existing hero_rig artwork is used as a painting source.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

D=Path(__file__).resolve().parent
ROOT=D.parents[2]
A=ROOT/'assets/characters/hero_doll'
Y,X=np.mgrid[:512,:512]
INK=np.array([47,23,12],float)
EXPRESSIONS=['normal','blink','angry','hurt','happy','scared']


def polygon(points):
    im=Image.new('1',(512,512));ImageDraw.Draw(im).polygon(points,fill=1)
    return np.array(im,dtype=bool)


def main_component(mask):
    lab,_=ndi.label(mask,structure=np.ones((3,3)))
    counts=np.bincount(lab.ravel());counts[0]=0
    return lab==counts.argmax()


def matrix(pivot,angle=0,scale=1):
    t=math.radians(angle);c=math.cos(t)*scale;s=math.sin(t)*scale
    x,y=pivot
    return np.array([[c,-s,x-c*x+s*y],[s,c,y-s*x-c*y],[0,0,1]],float)


def warp(image,matrix,size=(512,512),resample=Image.Resampling.BICUBIC):
    q=np.linalg.inv(matrix)
    return image.transform(size,Image.Transform.AFFINE,tuple(q[:2,:].ravel()),resample)


def style(mask,visible,source,color,role=None):
    mask=ndi.binary_fill_holes(main_component(mask))
    # Source geometry has subpixel outlines; the new closed contour is explicit.
    distance=ndi.distance_transform_edt(mask)
    rgb=np.zeros((512,512,3),float);rgb[:]=color
    if role is not None:rgb=role
    # A subdued shadow on hidden material, matching the original cel palette.
    rgb*=np.clip(.94+.07*(X/512)+.025*(1-Y/512),.92,1.03)[:,:,None]
    visible=visible&mask&(source[:,:,3]>=128)
    rgb[visible]=source[visible,:3]
    edge=distance<=3
    # Preserve original dark ink where it already follows the same contour.
    source_ink=(source[:,:,:3].max(axis=2)<80)&visible
    rgb[edge]=INK;rgb[edge&source_ink]=source[edge&source_ink,:3]
    alpha=np.rint(ndi.gaussian_filter(mask.astype(float),.50)*255).astype(np.uint8)
    rgb[~mask]=INK
    out=np.zeros((512,512,4),np.uint8)
    out[:,:,:3]=np.clip(rgb,0,255).astype(np.uint8);out[:,:,3]=alpha
    out[alpha==0]=0
    return Image.fromarray(out)


def fit_hand(image,grip):
    # Fit the ORIGINAL fist to the three upright game grips, not a new hand icon.
    candidates=[]
    for angle in range(-35,26):
        for scale in np.linspace(.75,1.05,31):
            m=matrix(grip,angle,float(scale));im=warp(image,m)
            alpha=np.array(im)[:,:,3]>=128
            yy,xx=np.where(alpha)
            if not len(yy):continue
            height=int(yy.max()-yy.min()+1)
            top_clearance=float(grip[1]-yy.min())
            if not 38<=height<=44:continue
            # Hilt guard bottoms sit about 19px above grip for all three icons.
            score=abs(top_clearance-20)*6+abs(scale-1)*15+abs(angle+18)*.05
            candidates.append((score,angle,float(scale),height,top_clearance,m,im))
    assert candidates,'No original-fist transform satisfies height.'
    best=min(candidates,key=lambda q:q[0])
    return best[-1],{'angle_degrees':best[1],'scale':best[2],'height_px':best[3],
                     'grip_to_top_px':best[4],'matrix':best[-2].tolist()}


def prepare_expression(name):
    source=ROOT/'docs/ideas/hero_rig_v2/inputs'/f'head_{name}_edit.png'
    a=np.array(Image.open(source).convert('RGBA'))
    strong=main_component(a[:,:,3]>=128)
    a[~ndi.binary_dilation(strong,iterations=2)]=0
    crop=Image.fromarray(a);box=crop.getbbox();crop=crop.crop(box).resize((155,145),Image.Resampling.LANCZOS)
    im=Image.new('RGBA',(512,512));im.alpha_composite(crop,(174,105))
    registration=ROOT/'docs/ideas/hero_head_v3/fixtures'/f'expression_{name}_registration.json'
    q=json.loads(registration.read_text())
    assert hashlib.sha256(source.read_bytes()).hexdigest()==q['source_sha256']
    tx,ty,sx,sy=q['tx_ty_sx_sy']
    im=im.transform((512,512),Image.Transform.AFFINE,(1/sx,0,-tx/sx,0,1/sy,-ty/sy),Image.Resampling.BICUBIC)
    im.save(D/'fixtures'/f'expression_{name}_aligned.png')
    return np.array(im),{'input':str(source.relative_to(ROOT)),'source_sha256':q['source_sha256'],
                         'initial_crop':box,'initial_size':[155,145],'initial_position':[174,105],
                         'translation_scale':q['tx_ty_sx_sy']}


def run(round_number):
    assert 1<=round_number<=6
    g=json.loads((D/'geometry.json').read_text());j=g['joints']
    source=Image.open(ROOT/g['source']).convert('RGBA').crop(g['frame'])
    source.save(D/'source_frame_0.png');s=np.array(source)
    D.joinpath('fixtures').mkdir(exist_ok=True)
    for sub in ('parts','head','faces'):(A/sub).mkdir(exist_ok=True,parents=True)
    images={};meta={'round':round_number,'workflow':g['revision'],'parts':{},'expressions':{}}
    # Assign ORIGINAL visible pixels once. A hidden arm must not carry pixels
    # belonging to the shield, a hand, the scarf or the adjacent garment.
    rgb=s[:,:,:3].astype(float);den=np.maximum(1,rgb[:,:,0]-rgb[:,:,2])
    hue=(rgb[:,:,1]-rgb[:,:,2])/(6*den)
    red=(rgb[:,:,0]>70)&(rgb[:,:,0]>rgb[:,:,1]*1.4)&(hue<.030)
    flesh=(rgb[:,:,0]>185)&(rgb[:,:,1]>110)&(rgb[:,:,2]>75)
    neck_visible=polygon(g['neck_visible_polygon'])&flesh&(s[:,:,3]>=128)
    neck_red=polygon(g['neck_visible_polygon'])&red&(s[:,:,3]>=128)
    neck_overlap=np.zeros((512,512),bool)
    if 'neck_underlap' in g:
        spec=g['neck_underlap'];a=np.array(spec['top'],float);b=np.array(spec['base'],float)
        t=np.clip(((X-a[0])*(b[0]-a[0])+(Y-a[1])*(b[1]-a[1]))/np.dot(b-a,b-a),0,1)
        nx=a[0]+t*(b[0]-a[0]);ny=a[1]+t*(b[1]-a[1])
        neck_overlap=(X-nx)**2+(Y-ny)**2<=spec['radius']**2
        # Preserve the original red fold where this hidden support crosses
        # the scarf. It must not turn that visible red area into neck skin.
        neck_red|=neck_overlap&red&(s[:,:,3]>=128)
    collar=np.zeros((512,512),bool)
    for key in ('shoulder_sword','shoulder_shield'):
        cx,cy=j[key]
        collar|=((X-cx)**2+(Y-cy)**2<=26**2)&red&(Y<=cy-8)
    original_visible={}
    for name,p in g['parts'].items():
        if name=='shield_hand':continue
        if name=='head':v=polygon(p['head_polygon'])&~red&~((Y>210)&(X<242)&flesh)
        elif name=='shield':
            cx,cy,rx,ry=p['source_ellipse'];v=((X-cx)/rx)**2+((Y-cy)/ry)**2<=1
        else:v=polygon(p['visible'])
        if name=='torso':
            v&=~polygon(p['belt_notch'])
            v&=~(flesh&(Y>=260)&(Y<=320))
            v|=neck_visible|neck_red|collar
        if name=='pelvis' or 'leg_' in name:
            cream=(rgb[:,:,0]>190)&(rgb[:,:,1]>140)&(rgb[:,:,2]>90)
            blue=(rgb[:,:,2]>60)&(rgb[:,:,2]>rgb[:,:,0]*.8)&(rgb[:,:,2]>rgb[:,:,1]*1.1)
            v&=~cream&~blue
        if 'arm_' in name:v&=~red
        if name=='cape':v&=red|(s[:,:,:3].max(axis=2)<80)
        original_visible[name]=v&(s[:,:,3]>=128)
    owners=np.zeros((512,512),np.int16);ids={name:i+1 for i,name in enumerate(g['order'])}
    for name in g['order']:
        if name in original_visible:owners[original_visible[name]]=ids[name]
    for name,p in g['parts'].items():
        if name=='shield_hand':continue
        if name=='head':
            mask=polygon(p['head_polygon'])&(s[:,:,3]>=128)
            # Red scarf belongs to torso, never the original head cut.
            rgb=s[:,:,:3].astype(float);den=np.maximum(1,rgb[:,:,0]-rgb[:,:,2])
            hue=(rgb[:,:,1]-rgb[:,:,2])/(6*den)
            red=(rgb[:,:,0]>70)&(rgb[:,:,0]>rgb[:,:,1]*1.4)&(hue<.030)
            mask&=~red;mask=ndi.binary_fill_holes(main_component(mask))
            mask&=~((Y>210)&(X<242)&flesh)
            mask=ndi.binary_fill_holes(main_component(mask))
            visible=mask.copy();role=None
        elif 'circle' in p:
            cx,cy,r=p['circle'];mask=(X-cx)**2+(Y-cy)**2<=r*r
            ecx,ecy,rx,ry=p['source_ellipse']
            m=np.array([[r/rx,0,cx-ecx*r/rx],[0,r/ry,cy-ecy*r/ry],[0,0,1]])
            shield_source=np.array(warp(source,m))
            images[name]=style(mask,mask,shield_source,p['color'])
            meta['parts'][name]={'circle':p['circle'],'source_ellipse':p['source_ellipse']}
            continue
        else:
            mask=polygon(p['shape']);visible=polygon(p['visible'])
            for joint,r in p.get('caps',[]):
                cx,cy=j[joint];mask|=(X-cx)**2+(Y-cy)**2<=r*r
            if p.get('trim_proximal'):
                a,b=[np.array(j[k],float) for k in p['bone']]
                unit=(b-a)/np.linalg.norm(b-a)
                along=(X-a[0])*unit[0]+(Y-a[1])*unit[1]
                across=-(X-a[0])*unit[1]+(Y-a[1])*unit[0]
                # The foreground piece closes with a shallow curved lip;
                # the full 26px disc is on the piece underneath.
                mask&=along>=-4+7*(across/26)**2
            if name=='torso':
                # Belt is on pelvis. A closed side bridge sits behind the shield.
                mask&=~polygon(p['belt_notch'])
                neck=(X-j['neck'][0])**2+(Y-j['neck'][1])**2<=26**2
                mask|=neck|neck_overlap|neck_visible|collar
                role=np.zeros((512,512,3),float);role[:]=p['color']
                role[neck|neck_overlap]=[250,178,116]
            elif name.endswith('arm_upper'):
                a,b=[np.array(j[k],float) for k in p['bone']]
                t=((X-a[0])*(b[0]-a[0])+(Y-a[1])*(b[1]-a[1]))/np.dot(b-a,b-a)
                role=np.zeros((512,512,3),float);role[:]=[246,171,111]
                role[t<.40]=[239,214,162];role[t<.08]=[52,80,128]
            elif name.endswith('leg_lower'):
                role=np.zeros((512,512,3),float);role[:]=p['color']
                role[Y<438]=[100,59,47];role[(Y>=438)&(Y<459)]=[175,82,31]
            else:role=None
        visible&=owners==ids[name]
        im=style(mask,visible,s,p['color'],role)
        if name=='sword_hand':im,meta['hand_fit']=fit_hand(im,j['grip'])
        images[name]=im
        meta['parts'][name]={'source_visible_polygon':p.get('visible',p.get('head_polygon')),
                              'round_overlaps':p.get('caps',[]),'bbox':im.getbbox(),
                              'original_visible_pixels':int(visible.sum())}
    # The completely hidden shield fist is another direct original-fist cut.
    shift=np.eye(3);shift[0,2]=j['wrist_shield'][0]-j['grip'][0];shift[1,2]=j['wrist_shield'][1]-j['grip'][1]
    images['shield_hand']=warp(images['sword_hand'],shift)
    for name,im in images.items():
        path=A/'head/bare.png' if name=='head' else A/'parts'/f'{name}.png'
        im.save(path)
    (A/'joints.json').write_text(json.dumps({'joints':j,'order':g['order']},indent=2)+'\n')
    # Build the shared opaque face region from original anatomical coordinates.
    b=np.array(images['head']);v3=json.loads((ROOT/'docs/ideas/hero_head_v3/geometry.json').read_text())
    skin=polygon(v3['face_skin_polygon'])&(b[:,:,3]>=200)
    rgb=b[:,:,:3].astype(int);flesh=(rgb[:,:,0]>170)&(rgb[:,:,1]>115)&(rgb[:,:,2]>65)
    skin|=ndi.binary_dilation(skin,iterations=3)&flesh&(b[:,:,3]>=200)
    clear=(rgb[:,:,0]>=225)&(rgb[:,:,1]>=145)&(rgb[:,:,2]>=90)
    skin&=(Y>=164)|clear;skin=ndi.binary_fill_holes(skin)
    envelope=polygon(v3['feature_envelope_polygon'])
    face_mask=(ndi.distance_transform_edt(~envelope)<=6)&skin
    face_mask=ndi.binary_fill_holes(main_component(face_mask))
    mask_image=np.zeros((512,512,4),np.uint8);mask_image[face_mask]=255
    Image.fromarray(mask_image).save(D/'face_mask.png')
    distance=ndi.distance_transform_edt(face_mask)
    for expression in EXPRESSIONS:
        patch=b.copy()
        if expression!='normal':
            edit,record=prepare_expression(expression);meta['expressions'][expression]=record
            weight=np.clip(distance-3,0,1)
            patch[:,:,:3]=np.rint(b[:,:,:3]*(1-weight[:,:,None])+edit[:,:,:3]*weight[:,:,None]).astype(np.uint8)
        patch[~face_mask]=0;patch[face_mask,3]=255
        Image.fromarray(patch).save(A/'faces'/f'{expression}.png')
    # One packed sheet of the direct cuts, with at least 16px clear cell margins.
    sheet=Image.new('RGBA',(1024,1280));layout={}
    names=['head','torso','cape','shield','pelvis','sword_arm_upper','sword_arm_lower','sword_hand',
           'shield_arm_upper','shield_arm_lower','shield_hand','back_leg_upper','back_leg_lower',
           'back_foot','front_leg_upper','front_leg_lower','front_foot']
    for index,name in enumerate(names):
        im=images[name];box=im.getbbox();piece=im.crop(box)
        x=(index%4)*256+(256-piece.width)//2;y=(index//4)*256+(256-piece.height)//2
        assert piece.width<=224 and piece.height<=224,(name,piece.size)
        sheet.alpha_composite(piece,(x,y));layout[name]={'sheet_bbox':[x,y,x+piece.width,y+piece.height],'canvas_bbox':box}
    sheet.save(D/'sheet.png');(D/'sheet_layout.json').write_text(json.dumps(layout,indent=2)+'\n')
    meta['source_sha256']=hashlib.sha256((ROOT/g['source']).read_bytes()).hexdigest()
    meta['groove']={'center':j['grip'],'width_px':30,'opaque_fingers':True,
                    'note':'Grip channel is hidden by curled fingers, not an alpha hole.'}
    (D/'build.json').write_text(json.dumps(meta,indent=2)+'\n')
    print(json.dumps({'round':round_number,'parts':len(images),'hand':meta['hand_fit'],'face_pixels':int(face_mask.sum())},indent=2))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--round',type=int,required=True)
    run(p.parse_args().round)
