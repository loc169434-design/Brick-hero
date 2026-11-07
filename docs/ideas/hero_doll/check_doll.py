"""Nine independent checks for the original-frame paper doll.

Rotation checks use the GLOBAL assembled convex hull on an expanded canvas,
with parent transforms propagated to children. Thresholds are never relaxed.
"""
from pathlib import Path
import argparse
import json
import math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from scipy import ndimage as ndi
from scipy.optimize import least_squares
from scipy.spatial import ConvexHull

D=Path(__file__).resolve().parent;ROOT=D.parents[2];A=ROOT/'assets/characters/hero_doll'
NAMES=['cape','back_leg_upper','back_leg_lower','back_foot','pelvis','front_leg_upper','front_leg_lower','front_foot','torso','sword_arm_upper','head','sword_arm_lower','sword_hand','shield_arm_upper','shield_arm_lower','shield_hand','shield']
EXPRESSIONS=['normal','blink','angry','hurt','happy','scared']
PARENTS={'pelvis':None,'torso':'pelvis','head':'torso','cape':'torso','sword_arm_upper':'torso','sword_arm_lower':'sword_arm_upper','sword_hand':'sword_arm_lower','shield_arm_upper':'torso','shield_arm_lower':'shield_arm_upper','shield_hand':'shield_arm_lower','shield':'shield_arm_lower','back_leg_upper':'pelvis','back_leg_lower':'back_leg_upper','back_foot':'back_leg_lower','front_leg_upper':'pelvis','front_leg_lower':'front_leg_upper','front_foot':'front_leg_lower'}
ANCHORS={'pelvis':'hip','torso':'waist','head':'neck','cape':'cape','sword_arm_upper':'shoulder_sword','sword_arm_lower':'elbow_sword','sword_hand':'wrist_sword','shield_arm_upper':'shoulder_shield','shield_arm_lower':'elbow_shield','shield_hand':'wrist_shield','shield':'shield','back_leg_upper':'hip_back','back_leg_lower':'knee_back','back_foot':'ankle_back','front_leg_upper':'hip_front','front_leg_lower':'knee_front','front_foot':'ankle_front'}
HOLDS={'wood_sword':{'grip':[68,197],'turn':-40.9,'size':.77},'iron_sword':{'grip':[127,200],'turn':-.2,'size':1},'tempered_sword':{'grip':[128,203],'turn':-.3,'size':1}}
ICON_REGIONS={
 'wood_sword':{'guard':[[53,127],[70,128],[141,180],[139,195],[124,209],[46,155]],'hilt':[[66,166],[100,190],[65,225],[34,201]],'pommel':[[20,202],[49,201],[70,220],[63,244],[38,249],[20,235]]},
 'iron_sword':{'guard':[[75,147],[180,147],[180,179],[75,179]],'hilt':[[108,177],[146,177],[145,216],[109,216]],'pommel':[[102,214],[151,214],[151,248],[102,248]]},
 'tempered_sword':{'guard':[[79,151],[176,151],[176,181],[79,181]],'hilt':[[109,180],[146,180],[145,217],[109,217]],'pommel':[[103,214],[151,214],[151,248],[103,248]]}}
FONT=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',15)


def path(name):return A/'head/bare.png' if name=='head' else A/'parts'/f'{name}.png'


def affine(image,m,size=(512,512),resample=Image.Resampling.BICUBIC):
    q=np.linalg.inv(m)
    return image.transform(size,Image.Transform.AFFINE,tuple(q[:2].ravel()),resample)


def rotate_matrix(pivot,angle):
    x,y=pivot;t=math.radians(angle);c=math.cos(t);s=math.sin(t)
    return np.array([[c,-s,x-c*x+s*y],[s,c,y-s*x-c*y],[0,0,1]],float)


def matrices(joints,angles):
    result={}
    def visit(name):
        if name in result:return result[name]
        parent=PARENTS[name];p=np.eye(3) if parent is None else visit(parent)
        result[name]=p@rotate_matrix(joints[ANCHORS[name]],angles.get(name,0))
        return result[name]
    for name in NAMES:visit(name)
    return result


def assemble(images,joints,order,angles=None,expanded=False,sword=None):
    angles=angles or {};m=matrices(joints,angles)
    size=(768,768) if expanded else (512,512)
    shift=np.eye(3)
    if expanded:shift[:2,2]=128
    out=Image.new('RGBA',size)
    for name in order:
        if name=='sword':
            if sword is not None:out.alpha_composite(affine(sword,shift@m['sword_hand'],size))
            continue
        out.alpha_composite(affine(images[name],shift@m[name],size))
    return out,m,shift


def label_background(image,bg):
    out=Image.new('RGB',image.size,bg);out.paste(image,(0,0),image);return out


def convex_mask(alpha):
    ys,xs=np.where(alpha);points=np.column_stack([xs,ys])
    hull=ConvexHull(points);im=Image.new('1',(alpha.shape[1],alpha.shape[0]))
    ImageDraw.Draw(im).polygon([tuple(map(int,p)) for p in points[hull.vertices]],fill=1)
    return np.array(im,dtype=bool)


def region(points,size):
    im=Image.new('L',size);ImageDraw.Draw(im).polygon(points,fill=255);return im


def sword_fixture(name,grip):
    hold=HOLDS[name];scale=210/256*hold['size'];t=math.radians(hold['turn'])
    r=np.array([[math.cos(t),-math.sin(t)],[math.sin(t),math.cos(t)]])*scale
    m=np.eye(3);m[:2,:2]=r;m[:2,2]=np.array(grip)-r@np.array(hold['grip'])
    icon=Image.open(ROOT/'assets/ui/items'/f'{name}.png').convert('RGBA')
    fixture=affine(icon,m);masks={}
    for kind,points in ICON_REGIONS[name].items():
        raw=region(points,icon.size)
        pixels=np.array(raw);pixels[np.array(icon)[:,:,3]<128]=0;raw=Image.fromarray(pixels)
        masks[kind]=np.array(affine(raw,m,resample=Image.Resampling.NEAREST))>=128
    # The handle excludes gold pommel and guard; it includes its ink outline.
    masks['hilt']&=~masks['pommel']&~masks['guard']
    return fixture,masks,m


def run(round_number):
    assert 1<=round_number<=6
    data=json.loads((A/'joints.json').read_text());j=data['joints'];order=data['order']
    old=json.loads((ROOT/'assets/characters/hero_rig/joints.json').read_text())['joints']
    images={n:Image.open(path(n)).convert('RGBA') for n in NAMES}
    patches={e:Image.open(A/'faces'/f'{e}.png').convert('RGBA') for e in EXPRESSIONS}
    report={'round':round_number,'criteria':{},'parts':{},'poses':{},'swords':{},'faces':{},'joint_deviation':{}}
    body_pass={k:True for k in ('format','connected','outline','dust')}
    for name,im in {**images,**{f'face_{k}':v for k,v in patches.items()}}.items():
        actual=Image.open(path(name)) if name in images else Image.open(A/'faces'/f'{name[5:]}.png')
        a=np.array(im);mask=a[:,:,3]>=128;box=im.getbbox()
        good_format=actual.size==(512,512) and actual.mode=='RGBA' and box is not None and min(box[:2])>0 and max(box[2:])<512
        _,count=ndi.label(mask,structure=np.ones((3,3)));holes=int((ndi.binary_fill_holes(mask)&~mask).sum())
        edge=mask&~ndi.binary_erosion(mask,structure=np.ones((3,3)))
        ink=(a[:,:,:3].max(axis=2)<80)&(a[:,:,3]>=128)
        distance=ndi.distance_transform_edt(~ink)
        ink_gap=float(distance[edge].max()) if edge.any() else 999
        violating=int((edge&(distance>2)).sum())
        positive=a[:,:,3]>0;labels,_=ndi.label(positive,structure=np.ones((3,3)))
        strong_ids=np.unique(labels[a[:,:,3]>=200]);dust=((a[:,:,3]>=1)&(a[:,:,3]<=63))&~np.isin(labels,strong_ids)
        count_dust=int(dust.sum())
        report['parts'][name]={'size':actual.size,'mode':actual.mode,'bbox':box,'components_at_128':int(count),'holes':holes,'outline_max_ink_distance_px':ink_gap,'outline_bad_pixels':violating,'isolated_alpha_1_63_pixels':count_dust}
        body_pass['format']&=good_format;body_pass['connected']&=count==1 and holes==0;body_pass['dust']&=count_dust==0
        if not name.startswith('face_'):body_pass['outline']&=violating==0
    for name,point in j.items():report['joint_deviation'][name]=float(np.linalg.norm(np.array(point)-old[name]))
    joint_pass=max(report['joint_deviation'].values())<=6
    assembled,_,_=assemble(images,j,order)
    assembled.alpha_composite(patches['normal'])
    standing=np.array(assembled)[:,:,3]>=128
    ref=np.array(Image.open(D/'reference.png'))[:,:,3]>=128
    intersection=int((standing&ref).sum());union=int((standing|ref).sum());iou=intersection/union
    feet_bottom=max(int(np.where(np.array(images[k])[:,:,3]>=128)[0].max()) for k in ['front_foot','back_foot'])
    report['standing']={'iou':iou,'intersection':intersection,'union':union,'feet_bottom_y':feet_bottom}
    dual=Image.new('RGB',(1024,548));draw=ImageDraw.Draw(dual)
    for col,(title,bg,fg) in enumerate([('Nền sáng','#eee7da','#30241c'),('Nền tối','#202229','#f3eee4')]):
        dual.paste(Image.new('RGB',(512,548),bg),(col*512,0));dual.paste(assembled,(col*512,32),assembled)
        draw.text((col*512+12,8),title,font=FONT,fill=fg)
    dual.save(D/'assembled.png')
    compare=Image.new('RGB',(1024,548),'#eee7da');cd=ImageDraw.Draw(compare)
    for col,(title,im) in enumerate([('Ảnh tham chiếu',Image.open(D/'reference.png')),('Bộ mảnh mới',assembled)]):
        compare.paste(im,(col*512,32),im);cd.text((col*512+12,8),title,font=FONT,fill='#30241c')
    compare.save(D/'fixtures/compare_reference.png')
    # Use the shared normal patch when rotating the head.
    rotation_images={k:v.copy() for k,v in images.items()};rotation_images['head'].alpha_composite(patches['normal'])
    grid=Image.new('RGB',(2304,2304),'#eee7da');gd=ImageDraw.Draw(grid)
    py,px=np.mgrid[:768,:768]
    poses=[(n,a) for n in NAMES for a in (-(25 if n=='head' else 20 if n=='torso' else 40),25 if n=='head' else 20 if n=='torso' else 40)]
    for index,(name,angle) in enumerate(poses):
        frame,m,shift=assemble(rotation_images,j,order,{name:angle},expanded=True)
        parent=PARENTS[name];pm=np.eye(3) if parent is None else m[parent]
        center=shift@pm@np.array([*j[ANCHORS[name]],1])
        alpha=np.array(frame)[:,:,3]>=128;hull=convex_mask(alpha)
        disk=(px-center[0])**2+(py-center[1])**2<=24**2
        gaps=disk&hull&~alpha;gap_count=int(gaps.sum())
        key=f'{name}_{angle:+}'
        report['poses'][key]={'joint':ANCHORS[name],'angle':angle,'radius':24,'world_center':center[:2].tolist(),'transparent_inside_global_convex_hull':gap_count,'pass':gap_count==0}
        preview=label_background(frame,'#eee7da');pd=ImageDraw.Draw(preview)
        cx,cy=center[:2];pd.ellipse((cx-24,cy-24,cx+24,cy+24),outline='#c83e36' if gap_count else '#2b8b68',width=2)
        for yy,xx in zip(*np.where(gaps)):pd.point((int(xx),int(yy)),fill='#e00022')
        preview=preview.resize((360,360),Image.Resampling.LANCZOS)
        col,row=index%6,index//6;grid.paste(preview,(col*384+12,row*384+24));gd.text((col*384+8,row*384+5),key,font=FONT,fill='#30241c')
    grid.save(D/'rotate_test.png')
    # Fit a circle to the observed shield contour, not the declared radius.
    sa=np.array(images['shield'])[:,:,3]>=128;edge=sa&~ndi.binary_erosion(sa,structure=np.ones((3,3)))
    yy,xx=np.where(edge);cx0=float(xx.mean());cy0=float(yy.mean());r0=float(np.hypot(xx-cx0,yy-cy0).mean())
    fit=least_squares(lambda q:np.hypot(xx-q[0],yy-q[1])-q[2],[cx0,cy0,r0]).x
    sy,sx=np.mgrid[:512,:512];disk=(sx-fit[0])**2+(sy-fit[1])**2<=fit[2]**2
    coverage=float((sa&disk).sum()/disk.sum());notch=max(0,float(fit[2]-np.hypot(xx-fit[0],yy-fit[1]).min()))
    report['shield_circle']={'fit_center':fit[:2].tolist(),'fit_radius':float(fit[2]),'coverage':coverage,'max_inward_defect_px':notch}
    # Three exact game item transforms. No icon is written under assets/hero_doll.
    builds=json.loads((D/'build.json').read_text());source_grip=np.array([354,318,1.])
    channel=np.array(builds['hand_fit']['matrix'])@source_grip
    channel_error=float(np.linalg.norm(channel[:2]-j['grip']))
    hand=np.array(images['sword_hand'])[:,:,3]>=128
    hand_height=int(np.where(hand)[0].max()-np.where(hand)[0].min()+1)
    sword_grid=Image.new('RGB',(1056,600),'#eee7da');sg=ImageDraw.Draw(sword_grid)
    for col,name in enumerate(HOLDS):
        fixture,masks,transform=sword_fixture(name,j['grip'])
        hilt=masks['hilt'];guard=masks['guard'];fraction=float((hilt&hand).sum()/hilt.sum())
        columns=range(j['grip'][0]-15,j['grip'][0]+16);gaps=[]
        for x in columns:
            hy=np.where(hand[:,x])[0];gy=np.where(guard[:,x])[0]
            if len(hy) and len(gy):gaps.append(max(0,float(hy.min()-gy.max()-1)))
        guard_gap=min(gaps) if gaps else 999
        covered_guard=float((guard&hand).sum()/max(1,guard.sum()))
        report['swords'][name]={'icon_grip':HOLDS[name]['grip'],'turn':HOLDS[name]['turn'],'scale':210/256*HOLDS[name]['size'],'channel_center':channel[:2].tolist(),'channel_error_px':channel_error,'channel_width_px':30,'hand_height_px':hand_height,'handle_pixels':int(hilt.sum()),'handle_covered_fraction':fraction,'guard_to_hand_gap_px':guard_gap,'guard_covered_fraction_informational':covered_guard,'pass':channel_error<=2 and fraction>=.90 and guard_gap<=3 and 38<=hand_height<=44}
        frame,_,_=assemble(rotation_images,j,order,sword=fixture)
        crop=frame.crop((300,205,410,393)).resize((330,564),Image.Resampling.NEAREST)
        sword_grid.paste(crop,(col*352+11,32),crop);sg.text((col*352+11,8),name+' ×3',font=FONT,fill='#30241c')
        # Keep labeled masks for reviewer inspection of the occlusion measure.
        debug=label_background(fixture,'#eee7da');da=np.array(debug);da[hilt]=[0,175,205];da[hilt&hand]=[55,180,70]
        Image.fromarray(da).crop((310,275,400,365)).resize((360,360),Image.Resampling.NEAREST).save(D/'fixtures'/f'hilt_mask_{name}.png')
    sword_grid.save(D/'sword_test.png')
    mask=np.array(Image.open(D/'face_mask.png'))[:,:,3]>=128
    border=mask&(ndi.distance_transform_edt(mask)<=3);head=np.array(images['head'])
    face_grid=Image.new('RGB',(1440,280),'#eee7da');fd=ImageDraw.Draw(face_grid)
    for col,e in enumerate(EXPRESSIONS):
        a=np.array(patches[e]);support=a[:,:,3]>0
        coverage=float((a[mask,3]==255).mean());outside=int((support&~mask).sum())
        delta=int(np.abs(a[:,:,:3].astype(int)-head[:,:,:3].astype(int))[border].max())
        report['faces'][e]={'mask_pixels':int(mask.sum()),'coverage':coverage,'outside_mask_pixels':outside,'border_3px_max_rgb_error':delta,'pass':coverage==1 and outside==0 and delta<=10}
        complete=images['head'].copy();complete.alpha_composite(patches[e]);crop=complete.crop((165,95,335,245)).resize((238,210),Image.Resampling.LANCZOS)
        face_grid.paste(crop,(col*240+1,36),crop);fd.text((col*240+10,8),e,font=FONT,fill='#30241c')
    face_grid.save(D/'faces.png')
    c=report['criteria']
    c['1_format']={'pass':body_pass['format'] and len(images)==17 and len(patches)==6,'body_files':len(images),'face_files':len(patches)}
    c['2_connected_no_holes']={'pass':body_pass['connected']}
    c['3_closed_ink_outline']={'pass':body_pass['outline'],'max_distance_px':2,'applies_to':'17 body pieces; opaque skin patches are checked separately in item 9'}
    c['4_no_dust']={'pass':body_pass['dust']}
    c['5_standing']={'pass':iou>=.90 and joint_pass and feet_bottom==500,'minimum_iou':.90,'max_joint_deviation':6,'ground_y':500}
    c['6_rotation']={'pass':all(p['pass'] for p in report['poses'].values()),'tested_poses':len(report['poses']),'maximum_gap_pixels':max(p['transparent_inside_global_convex_hull'] for p in report['poses'].values())}
    c['7_round_shield']={'pass':report['shield_circle']['coverage']>=.97 and notch<=2,'minimum_coverage':.97,'maximum_notch_px':2}
    c['8_swords']={'pass':all(v['pass'] for v in report['swords'].values())}
    c['9_faces']={'pass':bool(all(v['pass'] for v in report['faces'].values()) and mask.sum()>=2000)}
    report['pass']=all(v['pass'] for v in c.values())
    (D/'check.json').write_text(json.dumps(report,indent=2)+'\n')
    history=D/'checks';history.mkdir(exist_ok=True)
    (history/f'round_{round_number:02}.json').write_text(json.dumps(report,indent=2)+'\n')
    (history/f'geometry_{round_number:02}.json').write_text((D/'geometry.json').read_text())
    rounds='''# Kiểm tra bộ mảnh hiệp sĩ

Theo trả lời mới, cắt trực tiếp từ `fresh_idle.png`, khung 0; không dùng ảnh rig đã ghép. Đầu cắt theo cằm–mang tai, cổ thuộc torso; khiên ở lớp trước tay cầm. `sheet.png` là bảng đóng gói 17 mảnh cắt/bù khớp, không phải ảnh sinh mới. Thay đổi quy trình nguồn này đến từ chỉ dẫn mới của người dùng, không tự nhận đã thực hiện bước sinh 17 mảnh một lần trong yêu cầu cũ.

Giữ nguyên ngưỡng của 9 mục. Riêng hốc chuôi là khoảng nằm dưới ngón tay đặc, không khoét alpha: mảnh phải liền và chuôi bị che ≥90%. Khung mặt nới theo vùng da, mép 3 px giữ RGB đầu gốc. Xoay kiểm tra cả cây con trên canvas 768, hull lấy từ toàn bộ hình ghép, không dùng hull cục bộ hay lấp pixel trong phép đo.

| Vòng | 1 Định dạng | 2 Liền | 3 Viền | 4 Bụi | 5 Dáng | 6 Xoay | 7 Khiên | 8 Kiếm | 9 Mặt | Tổng |
|---|---|---|---|---|---|---|---|---|---|---|
'''
    summaries=[]
    for p in sorted(history.glob('round_*.json')):
        r=json.loads(p.read_text());checks=r['criteria'];statuses=['ĐẠT' if v['pass'] else 'TRƯỢT' for v in checks.values()]
        rounds+='| '+str(r['round'])+' | '+' | '.join(statuses)+' | '+('ĐẠT' if r['pass'] else 'TRƯỢT')+' |\n'
        summaries.append(f"Vòng {r['round']}: IoU {r['standing']['iou']:.6f}; độ lệch khớp tối đa {max(r['joint_deviation'].values()):.2f}px; đáy chân y{r['standing']['feet_bottom_y']}; khe tối đa {r['criteria']['6_rotation']['maximum_gap_pixels']}px; phủ tròn khiên {r['shield_circle']['coverage']:.6%}; khuyết khiên {r['shield_circle']['max_inward_defect_px']:.3f}px; chuôi bị che wood/iron/tempered = "+'/'.join(f"{v['handle_covered_fraction']:.3%}" for v in r['swords'].values())+f"; mép mặt lệch {max(v['border_3px_max_rgb_error'] for v in r['faces'].values())}/255.")
    rounds+='\n'+'\n\n'.join(summaries)+'\n\nCác số đo từng mảnh, từng tư thế và icon nằm trong `check.json`, lịch sử từng vòng ở `checks/`. Các vùng hilt/guard dùng để chấm nằm trong `ICON_REGIONS` của script và có ảnh kiểm tra ở `fixtures/hilt_mask_*.png`. Sai khác màu dùng max từng kênh, không lấy trung bình cả nền.\n'
    (D/'rounds.md').write_text(rounds)
    print(json.dumps({'round':round_number,'pass':report['pass'],'criteria':c,'standing':report['standing'],'shield':report['shield_circle'],'swords':report['swords']},indent=2))
    if not report['pass']:raise SystemExit(1)


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--round',type=int,required=True)
    run(p.parse_args().round)
