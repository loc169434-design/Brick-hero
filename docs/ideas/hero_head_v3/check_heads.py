"""Independent asset checks, measured rounds, assembly and neck rotation review."""
from pathlib import Path
import argparse
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi

D=Path(__file__).resolve().parent
ROOT=D.parents[2]
A=ROOT/'assets/characters/hero_rig'
KINDS=['bare','leather_helmet','iron_helmet']
EXPRESSIONS=['normal','blink','angry','hurt','happy','scared']
Y,X=np.mgrid[:512,:512]


def polygon(points):
    im=Image.new('1',(512,512));ImageDraw.Draw(im).polygon(points,fill=1)
    return np.array(im,dtype=bool)


def thickness(upper,lower):
    upper=np.array(upper,float);lower=np.array(lower,float);maximum=0
    for a,b in zip(lower[:-1],lower[1:]):
        for t in np.linspace(0,1,max(2,int(np.linalg.norm(b-a))*4)):
            point=a+t*(b-a);distances=[]
            for c,d in zip(upper[:-1],upper[1:]):
                delta=d-c;u=np.clip(np.dot(point-c,delta)/max(1e-9,np.dot(delta,delta)),0,1)
                distances.append(np.linalg.norm(point-(c+u*delta)))
            maximum=max(maximum,min(distances))
    return float(maximum)


def body():
    im=Image.new('RGBA',(512,512))
    for part in json.loads((A/'joints.json').read_text())['order']:
        path=A/'parts'/f'{part}.png'
        if part not in ('head','sword') and path.exists():im.alpha_composite(Image.open(path))
    return im


def run(round_number):
    assert 1<=round_number<=6
    geometry=json.loads((D/'geometry.json').read_text())
    heads={k:Image.open(A/'head'/f'{k}.png') for k in KINDS}
    faces={e:Image.open(A/'faces'/f'{e}.png') for e in EXPRESSIONS}
    arrays={k:np.array(v) for k,v in heads.items()}
    b=arrays['bare'];mask=np.array(Image.open(D/'face_mask.png'))[:,:,3]>127
    skin=np.array(Image.open(D/'fixtures/face_skin.png'))[:,:,3]>127
    border=mask&(ndi.distance_transform_edt(mask)<=3)
    report={'round':round_number,'neck':[262,237],'thresholds':{
        'outside_helmet_rgb_error_max':6,'width_ratio_max':1.06,
        'brim_thickness_max_px':14,'brow_clearance_min_px':6,
        'mask_brim_clearance_min_px':4,'hair_above_brim_outside_cap_max':0,'unallowed_hair_outside_cap_max':0,
        'face_coverage':1.0,'border_3px_rgb_error_max':10},
        'files':{},'helmets':{},'faces':{},'neck_rotation':{}}
    files={**{f'head/{k}.png':im for k,im in heads.items()},**{f'faces/{e}.png':im for e,im in faces.items()}}
    for name,im in files.items():
        box=im.getbbox()
        report['files'][name]={'size':list(im.size),'mode':im.mode,'bbox':box,
            'pass':im.size==(512,512) and im.mode=='RGBA' and bool(box) and min(box[:2])>0 and max(box[2:])<512}
    report['file_count']=len(files)
    report['joint_neck_matches']=json.loads((A/'joints.json').read_text())['joints']['neck']==[262,237]
    report['face_mask_in_skin']=bool(not (mask&~skin).any())
    report['face_mask_pixels']=int(mask.sum())
    report['internal_alpha_holes']={k:int((ndi.binary_fill_holes(a[:,:,3]>127)&(a[:,:,3]<128)).sum()) for k,a in arrays.items()}
    landmarks=[(262,168),(276,180),(294,181),(276,205),(283,216)]
    report['face_mask_feature_coverage']=bool(mask.sum()>=2000 and all(mask[py,px] for px,py in landmarks))
    original=np.array(Image.open(A/'heads/bare_normal.png'))
    unchanged=np.any(b!=original,axis=2)&(b[:,:,3]>0)
    report['bare_retained_pixels_changed']=int(unchanged.sum())
    report['bare_removed_noise_pixels']=int(((original[:,:,3]>0)&(b[:,:,3]==0)).sum())
    xs=np.where(b[geometry['forehead_y'],:,3]>127)[0]
    head_width=int(xs.max()-xs.min()+1)
    hair_top=int(np.where(b[:,:,3]>0)[0].min())
    report['reference']={'forehead_y':geometry['forehead_y'],'head_width_px':head_width,'hair_top_y':hair_top}
    regions={
        'ear':((X-230)/13)**2+((Y-200)/12)**2<=1,
        'cheek':polygon([(242,195),(258,190),(278,192),(299,201),(304,214),(280,225),(254,216)]),
        'chin':polygon([(253,220),(305,222),(308,228),(283,233),(262,229)]),
        'neck':polygon([(234,222),(261,234),(274,240),(269,249),(250,240),(233,229)])}
    palette_pixels=b[(Y<=160)&(b[:,:,3]>127),:3]
    palette=np.unique((palette_pixels//12)*12,axis=0).astype(float)
    for kind in KINDS[1:]:
        a=arrays[kind];ann=geometry['helmets'][kind]
        cap=polygon(ann['cap_polygon'])&(a[:,:,3]>127)
        yy,xx=np.where(cap);width=int(xx.max()-xx.min()+1);top=int(yy.min())
        line=sorted(ann['brim_lower']);lower=np.interp(X,[v[0] for v in line],[v[1] for v in line])
        allowed_hair=((Y>=lower)&(Y<=lower+12)&(X>=218)&(X<=315))
        for points in geometry['allowed_hair_polygons']:allowed_hair|=polygon(points)
        protected=np.array(Image.open(D/'fixtures/protected_head_frame.png'))[:,:,3]>127
        outside_allowed=(a[:,:,3]>127)&~ndi.binary_dilation(cap,iterations=1)&~allowed_hair&~protected&~polygon(geometry['feature_envelope_polygon'])
        ay,ax=np.where(outside_allowed);unallowed=0
        if len(ay):
            d=np.min(np.mean(np.abs(a[ay,ax,:3].astype(float)[:,None,:]-palette[None,:,:]),axis=2),axis=1)
            unallowed=int((d<=18).sum())
        candidate=(a[:,:,3]>127)&(X>=175)&(X<=330)&(Y>=95)&(Y<lower)&~ndi.binary_dilation(cap,iterations=1)
        cy,cx=np.where(candidate);hair_count=0
        diagnostic=Image.new('RGB',(512,512),'#eee7da');diagnostic.paste(heads[kind],(0,0),heads[kind]);dd=ImageDraw.Draw(diagnostic)
        if len(ay):
            for px,py in zip(ax[d<=18],ay[d<=18]):dd.point((int(px),int(py)),fill='#e400d5')
        if len(cy):
            colors=a[cy,cx,:3].astype(float)
            nearest=np.min(np.mean(np.abs(colors[:,None,:]-palette[None,:,:]),axis=2),axis=1)
            flagged=nearest<=18;hair_count=int(flagged.sum())
            for px,py in zip(cx[flagged],cy[flagged]):dd.point((int(px),int(py)),fill='red')
        diagnostic.crop((170,95,335,240)).resize((660,580),Image.Resampling.NEAREST).save(D/'fixtures'/f'hair_check_{kind}.png')
        outside={}
        for name,roi in regions.items():
            roi=roi&(b[:,:,3]>240)
            delta=np.abs(a[:,:,:3].astype(int)-b[:,:,:3].astype(int))[roi]
            outside[name]={'pixels':int(roi.sum()),'rgb_mae':float(delta.mean()),'rgb_max':int(delta.max()),
                          'alpha_max_error':int(np.abs(a[:,:,3].astype(int)-b[:,:,3].astype(int))[roi].max())}
        face_y,face_x=np.where(mask)
        clearance=float((face_y-lower[face_y,face_x]).min())
        brow_clearance=geometry['brow_top_y']-float(np.interp(np.arange(255,306),[v[0] for v in line],[v[1] for v in line]).max())
        thick=thickness(ann['brim_upper'],ann['brim_lower'])
        checks={'outside_helmet':all(v['rgb_max']<=6 and v['alpha_max_error']<=6 for v in outside.values()),
                'width':width/head_width<=1.06,'top':top>=hair_top,
                'brim':thick<=14,'brows':brow_clearance>=6,'hair':hair_count==0 and unallowed==0,
                'face_mask_below_brim':clearance>=4}
        report['helmets'][kind]={'outside_helmet':outside,'cap_width_px':width,'head_width_px':head_width,
            'width_ratio':width/head_width,'cap_top_y':top,'bare_hair_top_y':hair_top,
            'brim_thickness_px':thick,'brow_clearance_px':brow_clearance,
            'face_mask_clearance_px':clearance,'hair_color_candidates_above_brim_outside_cap':hair_count,
            'unallowed_hair_color_candidates_outside_cap':unallowed,'checks':checks,'pass':all(checks.values())}
        overlay=diagnostic.copy();od=ImageDraw.Draw(overlay)
        od.line(ann['cap_polygon']+[ann['cap_polygon'][0]],fill='#00a3a3',width=1)
        od.line(ann['brim_upper'],fill='#2354ee',width=1);od.line(ann['brim_lower'],fill='#d82250',width=1)
        edge=mask&~ndi.binary_erosion(mask)
        for py,px in zip(*np.where(edge)):od.point((int(px),int(py)),fill='#2bcd40')
        overlay.save(D/'fixtures'/f'measurement_{kind}.png')
    for name,im in faces.items():
        a=np.array(im);support=a[:,:,3]>0
        coverage=float((a[mask,3]==255).mean())
        edges={kind:int(np.abs(a[:,:,:3].astype(int)-arrays[kind][:,:,:3].astype(int))[border].max()) for kind in KINDS}
        checks={'only_in_mask':bool(not (support&~mask).any()),'opaque_coverage':coverage==1,
                'border_colors':max(edges.values())<=10}
        changed=int((np.any(a[:,:,:3]!=b[:,:,:3],axis=2)&mask).sum())
        checks['expression_present']=(changed==0 if name=='normal' else changed>=100)
        report['faces'][name]={'mask_pixels':int(mask.sum()),'coverage':coverage,
            'outside_mask_pixels':int((support&~mask).sum()),'changed_rgb_pixels_from_normal':changed,'border_3px_max_rgb_error':edges,
            'checks':checks,'pass':all(checks.values())}
    base_body=body()
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',16)
    grid=Image.new('RGB',(3072,1644),'#eee7da');gd=ImageDraw.Draw(grid)
    rotation=Image.new('RGB',(1536,1644),'#eee7da');rd=ImageDraw.Draw(rotation)
    for row,kind in enumerate(KINDS):
        for col,expression in enumerate(EXPRESSIONS):
            head=heads[kind].copy();head.alpha_composite(faces[expression])
            assembled=base_body.copy();assembled.alpha_composite(head)
            grid.paste(assembled,(col*512,row*548+32),assembled)
            gd.text((col*512+12,row*548+8),f'{kind} / {expression}',font=font,fill='#392b22')
        for col,angle in enumerate([-20,0,20]):
            head=heads[kind].copy();head.alpha_composite(faces['normal'])
            turned=head.rotate(angle,resample=Image.Resampling.BICUBIC,center=(262,237))
            assembled=base_body.copy();assembled.alpha_composite(turned)
            alpha=np.array(assembled)[:,:,3]
            socket=(X-262)**2+(Y-237)**2<=10**2
            gaps=int((socket&(alpha<240)).sum())
            if angle:report['neck_rotation'][f'{kind}_{angle:+}']={'radius_px':10,'alpha_threshold':240,'gap_pixels':gaps,'pass':gaps==0}
            rotation.paste(assembled,(col*512,row*548+32),assembled)
            rd.text((col*512+12,row*548+8),f'{kind} / {angle:+}°',font=font,fill='#392b22')
    grid.save(D/'grid.png');rotation.save(D/'rotate.png')
    grid.resize((1536,822),Image.Resampling.LANCZOS).save(D/'fixtures/grid_overview.png')
    rotation.resize((768,822),Image.Resampling.LANCZOS).save(D/'fixtures/rotate_overview.png')
    preview=Image.new('RGB',(2040,400),'#eee7da');pd=ImageDraw.Draw(preview)
    for col,expression in enumerate(EXPRESSIONS):
        head=heads['iron_helmet'].copy();head.alpha_composite(faces[expression])
        crop=head.crop((235,145,320,235)).resize((340,360),Image.Resampling.NEAREST)
        preview.paste(crop,(col*340,32),crop)
        pd.text((col*340+10,8),expression,font=font,fill='#392b22')
    preview.save(D/'fixtures/face_patch_review.png')
    compare=Image.new('RGB',(1536,548),'#eee7da');cd=ImageDraw.Draw(compare)
    pictures=[('Gốc',Image.open(ROOT/'docs/ideas/hero_rig_v2/assembled_bare.png'))]+[(k,Image.open(D/'raw'/f'{k}_raw.png')) for k in KINDS[1:]]
    for col,(title,im) in enumerate(pictures):
        compare.paste(im,(col*512,32),im);cd.text((col*512+12,8),title,font=font,fill='#392b22')
    compare.save(D/'raw/compare.png')

    report['pass']=report['joint_neck_matches'] and report['file_count']==9 and all(v['pass'] for v in report['files'].values()) and report['face_mask_in_skin'] and report['face_mask_feature_coverage'] and not any(report['internal_alpha_holes'].values()) and report['bare_retained_pixels_changed']==0 and all(v['pass'] for v in report['helmets'].values()) and all(v['pass'] for v in report['faces'].values()) and all(v['pass'] for v in report['neck_rotation'].values())
    (D/'check.json').write_text(json.dumps(report,indent=2)+'\n')
    history=D/'checks';history.mkdir(exist_ok=True)
    (history/f'round_{round_number:02}.json').write_text(json.dumps(report,indent=2)+'\n')
    (history/f'geometry_{round_number:02}.json').write_text(json.dumps(geometry,indent=2)+'\n')
    rounds='''# Kiểm tra bộ đầu ghép lớp

Tối đa 6 vòng; tất cả kích thước tính trên canvas 512×512, neck=(262,237). Giữ đủ 9 asset mới; không sửa/xóa `heads/` cũ. Ngưỡng ngang 1,06 được áp dụng lại đầy đủ cho việc này.

Mask là bao mắt, mày và miệng nới 6 px, **dừng ở biên da theo trả lời của người dùng**. Miếng mặt đặc alpha 255, không feather alpha. Dải màu 3 px ở mép lấy từ da gốc, rồi chuyển màu trong 1 px tiếp theo. Mask được lấp kín các lỗ bên trong để nét mày không chạm vào một mép alpha ở giữa miếng mặt. Phần tai, má, cằm và cổ gốc được bảo vệ pixel khi tách đầu từ ảnh sửa; ảnh sinh nguyên bản và ảnh căn chưa bảo vệ vẫn giữ trong `raw/sources/` để đối chiếu. Không co đầu vào bề ngang cố định.

| Vòng | Nón | Rộng/đầu ≤1,06 | Đỉnh y ≥ tóc gốc | Vành ≤14 px | Cách mày ≥6 px | Mask cách vành ≥4 px | Tóc trên vành / ngoài vùng cho phép | Kết quả |
|---|---|---:|---:|---:|---:|---:|---:|---|
'''
    summaries=[]
    for path in sorted(history.glob('round_*.json')):
        r=json.loads(path.read_text())
        for k,v in r['helmets'].items():
            rounds+=f"| {r['round']} | {k} | {v['cap_width_px']}/{v['head_width_px']}={v['width_ratio']:.4f} | {v['cap_top_y']}/{v['bare_hair_top_y']} | {v['brim_thickness_px']:.2f} | {v['brow_clearance_px']:.2f} | {v['face_mask_clearance_px']:.2f} | {v['hair_color_candidates_above_brim_outside_cap']} / {v.get('unallowed_hair_color_candidates_outside_cap', '—')} | {'ĐẠT' if v['pass'] else 'CHƯA ĐẠT'} |\n"
        maximum=max(v['border_3px_max_rgb_error'][k] for v in r['faces'].values() for k in KINDS)
        outside=max(v['rgb_max'] for h in r['helmets'].values() for v in h['outside_helmet'].values())
        gaps=sum(v['gap_pixels'] for v in r['neck_rotation'].values())
        summaries.append(f"Vòng {r['round']}: {r['file_count']}/9 file; mask {r.get('face_mask_pixels',r['faces']['normal']['mask_pixels'])} pixel; mặt phủ kín {min(v['coverage'] for v in r['faces'].values()):.0%}; mép 3 px lệch tối đa {maximum}/255; tai/má/cằm/cổ lệch tối đa {outside}/255; khe cổ ±20°: {gaps} pixel. Tổng: **{'ĐẠT' if r['pass'] else 'CHƯA ĐẠT'}**.")
    rounds+='\n\n'+'\n\n'.join(summaries)+'\n\n'
    rounds+='''
Vòng 5–6 hoàn thiện đường cắt: loại phần khăn lẫn trong crop đầu, giữ vùng trán mới từ ảnh sửa thay cho đường tóc cũ, khép đường cắt vành–mái, giữ tai/khung mặt/cổ gốc. Vòng 6 kiểm tra thêm không có lỗ alpha bên trong cả ba đầu. Bộ nón cuối dùng ảnh sửa vòng 4, không sinh thêm nón ở vòng 5–6.\n\nVòng 1 phát hiện mask ban đầu chỉ có 8 pixel: alpha của ảnh gốc chủ yếu 253–254, không phải 255. Từ vòng 2, lấy vùng da có alpha>240 từ ảnh gốc, bổ sung kiểm tra đủ landmark mắt/mày/miệng và biểu cảm thật sự khác normal. Alpha đầu ra của **mọi miếng mặt vẫn bắt buộc 255**, không nới tiêu chí phủ kín.

Kiểm tra tóc xét phía trên vành và mọi vùng ngoài nón không thuộc phần tóc được phép: mái ngắn tối đa 12 px dưới vành và hai vùng tóc mai ở thái dương, trước tai. Phần tai/mặt/cổ gốc được bảo vệ và vùng mắt/mày/miệng (mực vẽ cùng màu nâu đậm) loại khỏi phân loại màu tóc; đây là vùng mặt đã được kiểm tra phủ kín bằng miếng da đặc. Tóc sau gáy dài hoặc tua ở sau đầu không được miễn kiểm tra. Bảng màu lấy từ tóc gốc, lượng tử 12 mức/kênh; ứng viên cách màu trung bình ≤18/255 ngoài contour (dung sai AA 1 px) được đánh dấu đỏ (trên vành) và tím (ngoài vùng tóc được phép) ở `fixtures/hair_check_*.png`. Cần xem ảnh cùng contour vì mực viền và da nón có thể gần màu tóc. Contour chỉ dùng đo, không xuất thành trang bị rời.

Sai khác tai/má/cằm/cổ và dải mép mặt là **max từng kênh RGB**, đồng thời kiểm tra alpha ở phần đầu, không lấy trung bình cả nền trong suốt. Cổ xoay được đo bằng số pixel alpha<240 trong bán kính 10 px quanh neck, trên thân thật lắp từ `parts/`.

Chạy lại: `python docs/ideas/hero_head_v3/check_heads.py --round N` (1≤N≤6). Kết quả vòng cuối ở `check.json`; từng vòng và contour ở `checks/`. Script chỉ cần Pillow, NumPy, SciPy.
'''
    (D/'rounds.md').write_text(rounds)
    print(json.dumps({'round':round_number,'pass':report['pass'],'helmets':report['helmets'],'face_border_max':max(v['border_3px_max_rgb_error'][k] for v in report['faces'].values() for k in KINDS),'rotation':report['neck_rotation']},indent=2))
    if not report['pass']:
        raise SystemExit(1)


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--round',type=int,required=True)
    run(p.parse_args().round)
