"""Register whole image edits by the BODY and measure the two raw helmets.
No layers, face patches, cut-out heads or pixel replacement are produced.
All outputs stay in this raw directory. At most five image-edit rounds.
"""
from pathlib import Path
import argparse,json,math,hashlib
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from scipy import ndimage as ndi
from scipy.optimize import minimize
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
p=argparse.ArgumentParser();p.add_argument('--round',type=int,required=True);p.add_argument('--align-only',action='store_true');args=p.parse_args();N=args.round
assert 1<=N<=5
ref=Image.open(ROOT/'docs/ideas/hero_rig_v2/assembled_bare.png').convert('RGBA')
head=Image.open(ROOT/'assets/characters/hero_rig/heads/bare_normal.png').convert('RGBA')
r=np.array(ref);h=np.array(head);Y,X=np.mgrid[:512,:512]
lab,n=ndi.label(h[:,:,3]>127);sizes=np.bincount(lab.ravel());sizes[0]=0;main=lab==sizes.argmax()
hair_support=ndi.binary_dilation(main,iterations=2)&(h[:,:,3]>0)
forehead_y=158;xs=np.where(main[forehead_y])[0];head_width=int(xs.max()-xs.min()+1);hair_top=int(np.where(hair_support)[0].min())
BROW_TOP=161;BROW_SPAN=(257,305)
# Fixed anatomical original hair region; excludes original eyes/face/ear interiors.
def polygon(points):
 im=Image.new('1',(512,512));ImageDraw.Draw(im).polygon(points,fill=1);return np.array(im,dtype=bool)
hair_region=polygon([(170,100),(335,100),(335,181),(317,190),(301,168),(283,160),(273,164),(256,162),(245,179),(254,194),(241,195),(232,188),(222,190),(218,202),(225,211),(222,221),(199,227),(170,220)])&hair_support
(D/'reference_measurements.json').write_text(json.dumps({'forehead_y':forehead_y,'head_forehead_x':[int(xs.min()),int(xs.max())],'head_forehead_width':head_width,'hair_top_y':hair_top,'brow_top_y':BROW_TOP,'front_brow_x_span':BROW_SPAN,'max_width_ratio':1.06,'max_brim_thickness':14,'min_brow_clearance':6,'max_outside_mae':6},indent=2)+'\n')
font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',12)
# Registration uses no head pixels: body silhouette + colors below y240.
body=ndi.binary_dilation(r[:,:,3]>127,iterations=5)&(Y>=240)
mask128=np.array(Image.fromarray(np.uint8(body)*255).resize((128,128),Image.Resampling.NEAREST))>127
ref128=np.array(ref.resize((128,128),Image.Resampling.LANCZOS)).astype(float)
def premult(a):
 out=a.astype(float).copy();out[:,:,:3]*=out[:,:,3:4]/255.;return out
ref128=premult(ref128)
aligned={};transforms={}
kinds=['leather','iron']+(['leather_ranger'] if (D/'sources'/f'leather_ranger_r{N}.png').exists() else [])
for kind in kinds:
 source=D/'sources'/f'{kind}_r{N}.png'
 assert source.exists(),source
 original=Image.open(source).convert('RGBA');raw=original.resize((512,512),Image.Resampling.LANCZOS);small=raw.resize((128,128),Image.Resampling.LANCZOS)
 cache=D/'sources'/f'alignment_{kind}_r{N}.json';digest=hashlib.sha256(source.read_bytes()).hexdigest()
 previous=json.loads(cache.read_text()) if cache.exists() else {}
 if previous.get('source_sha256')==digest:params=np.array(previous['tx_ty_sx_sy'])
 else:
  def loss(q):
   tx,ty,sx,sy=q
   a=np.array(small.transform((128,128),Image.Transform.AFFINE,(1/sx,0,-tx/(4*sx),0,1/sy,-ty/(4*sy)),Image.Resampling.BICUBIC))
   return float(np.abs(premult(a)-ref128)[mask128].mean())
  opt=minimize(loss,[0,0,1,1],method='Powell',bounds=[(-20,20),(-20,20),(.9,1.1),(.9,1.1)],options={'maxiter':18,'xtol':.005});params=opt.x
  cache.write_text(json.dumps({'source_sha256':digest,'body_roi':'y>=240; foreground silhouette dilated5px','source_size':original.size,'tx_ty_sx_sy':list(map(float,params))},indent=2)+'\n')
 tx,ty,sx,sy=params
 im=raw.transform((512,512),Image.Transform.AFFINE,(1/sx,0,-tx/sx,0,1/sy,-ty/sy),Image.Resampling.BICUBIC)
 im.save(D/'sources'/f'aligned_{kind}_r{N}.png');im.save(D/(f'{kind}_helmet_raw.png' if kind in ('leather','iron') else f'{kind}_raw.png'));aligned[kind]=im;transforms[kind]=list(map(float,params))
 # Coordinate grid for measurement annotation, never an exported art layer.
 crop=im.crop((165,90,340,220)).resize((700,520),Image.Resampling.NEAREST);grid=Image.new('RGB',crop.size,'#eee9df');grid.paste(crop,(0,0),crop);draw=ImageDraw.Draw(grid)
 for x in range(170,341,10):draw.line(((x-165)*4,0,(x-165)*4,520),fill='#bcb4a7');draw.text(((x-165)*4+1,0),str(x),font=font,fill='black')
 for y in range(100,221,10):draw.line((0,(y-90)*4,700,(y-90)*4),fill='#bcb4a7');draw.text((0,(y-90)*4),str(y),font=font,fill='black')
 grid.save(D/'sources'/f'grid_{kind}_r{N}.png')
if 'leather_ranger' in aligned:
 gallery=Image.new('RGB',(2048,554),'#eee9df');gd=ImageDraw.Draw(gallery)
 for col,(title,picture) in enumerate([('Gốc',ref),('Da chiến binh',aligned['leather']),('Da ranger',aligned['leather_ranger']),('Sắt trung cổ',aligned['iron'])]):
  gallery.paste(picture,(col*512,36),picture);gd.text((col*512+15,12),title,font=font,fill='#332b24')
 gallery.save(D/'style_options.png')
if args.align_only:
 print('Whole-image registration complete; add measurement contours then run without --align-only.');raise SystemExit
annotations=json.loads((D/'sources'/f'annotations_r{N}.json').read_text())
# Hair palette comes only from original crown, not the brown leather helmet.
hair_pixels=h[(Y<=160)&main,:3];palette=np.unique((hair_pixels//12)*12,axis=0).astype(float)
def interpolate(line,x):
 line=sorted(line);return np.interp(x,[v[0] for v in line],[v[1] for v in line])
def thickness(upper,lower):
 upper=np.array(upper,float);lower=np.array(lower,float)
 points=[]
 for a,b in zip(lower[:-1],lower[1:]):
  points.extend(a+(b-a)*t for t in np.linspace(0,1,max(2,int(np.linalg.norm(b-a))*4)))
 points=np.array(points);dist=[]
 for point in points:
  candidates=[]
  for a,b in zip(upper[:-1],upper[1:]):
   v=b-a;t=np.clip(np.dot(point-a,v)/max(1e-9,np.dot(v,v)),0,1);candidates.append(np.linalg.norm(point-(a+t*v)))
  dist.append(min(candidates))
 return float(max(dist))
report={'round':N,'reference':{'head_width':head_width,'hair_top':hair_top,'brow_top':BROW_TOP},'helmets':{}}
comparison=Image.new('RGB',(1536,554),'#eee9df');draw=ImageDraw.Draw(comparison)
for col,(title,im) in enumerate([('Gốc',ref),('Nón da',aligned['leather']),('Nón sắt',aligned['iron'])]):comparison.paste(im,(col*512,36),im);draw.text((col*512+15,12),title,font=font,fill='#332b24')
comparison.save(D/'compare.png')
for kind,im in aligned.items():
 ann=annotations[kind];a=np.array(im);cap=polygon(ann['cap_polygon'])&(a[:,:,3]>127)
 yy,xx=np.where(cap);width=int(xx.max()-xx.min()+1);top=int(yy.min());ratio=width/head_width
 edit_zone=ndi.binary_dilation(cap|hair_region,iterations=2)
 delta=np.abs(premult(a)-premult(r));outside=~edit_zone
 mae=float(delta[outside].mean())
 foreground=outside&((r[:,:,3]>127)|(a[:,:,3]>127));foreground_mae=float(delta[:,:,:3][foreground].mean())
 thick=thickness(ann['brim_upper'],ann['brim_lower'])
 bx=np.arange(BROW_SPAN[0],BROW_SPAN[1]+1);bottom=float(interpolate(ann['brim_lower'],bx).max());clearance=BROW_TOP-bottom
 lower=interpolate(ann['brim_lower'],X)
 possible=(a[:,:,3]>127)&(X>=165)&(X<=340)&(Y>=85)&(Y<lower)&~ndi.binary_dilation(cap,iterations=1)
 py,px=np.where(possible);hair_count=0
 if len(py):
  colors=a[py,px,:3].astype(float);nearest=np.min(np.mean(np.abs(colors[:,None,:]-palette[None,:,:]),axis=2),axis=1)
  hair_count=int((nearest<=18).sum())
  diagnostic=Image.new('RGB',(512,512),'#eee9df');diagnostic.paste(im,(0,0),im);dd=ImageDraw.Draw(diagnostic)
  for hx,hy in zip(px[nearest<=18],py[nearest<=18]):dd.point((int(hx),int(hy)),fill='red')
  diagnostic.crop((155,85,345,250)).resize((760,660),Image.Resampling.NEAREST).save(D/'sources'/f'hair_check_{kind}_r{N}.png')
 component,ncomponents=ndi.label(a[:,:,3]>127);counts=np.bincount(component.ravel());counts[0]=0
 body_component=int(counts.argmax());cap_component=int(np.bincount(component[cap]).argmax())
 anchored=(body_component==cap_component) and a[237,262,3]>127
 checks={'outside_mae':mae<=6,'width':ratio<=1.06 if N<3 else True,'top':top>=hair_top,'brim':thick<=14,'brows':clearance>=6,'hair':hair_count==0,'anchor_connected':bool(anchored)}
 data={'size':list(im.size),'mode':im.mode,'transparent_pixels':int((a[:,:,3]==0).sum()),'width_limit_revised_by_user':N>=3,'cap_connected_to_character':bool(anchored),'outside_premult_rgba_mae':mae,'outside_foreground_rgb_mae_informational':foreground_mae,'cap_width_px':width,'head_width_px':head_width,'width_ratio':ratio,'cap_top_y':top,'original_hair_top_y':hair_top,'brim_max_thickness_px':thick,'front_brim_max_bottom_y':bottom,'brow_clearance_px':clearance,'hair_pixels_outside_cap_above_brim':hair_count,'whole_image_transform':transforms[kind],'checks':checks,'all_pass':all(checks.values())}
 report['helmets'][kind]=data
 overlay=Image.new('RGB',(512,512),'#eee9df');overlay.paste(im,(0,0),im);d=ImageDraw.Draw(overlay)
 d.line(ann['cap_polygon']+[ann['cap_polygon'][0]],fill='#2e9d9b',width=1)
 d.line(ann['brim_upper'],fill='#176bc4',width=1);d.line(ann['brim_lower'],fill='#d83748',width=1)
 d.line((257,BROW_TOP,305,BROW_TOP),fill='#8e39b3',width=1);d.line((int(xx.min()),top,int(xx.max()),top),fill='#2e9d9b',width=1)
 overlay.save(D/'sources'/f'measurement_{kind}_r{N}.png')
report['all_pass']=all(x['all_pass'] for x in report['helmets'].values())
(D/f'metrics_r{N}.json').write_text(json.dumps(report,indent=2)+'\n')
rounds = """# Số đo từng vòng — tối đa 5 vòng sửa ảnh

Bản bàn giao dùng **vòng 5**. Hai nón chính và một biến thể da ranger đều là ảnh sửa toàn thân từ ảnh gốc. Hậu kỳ chỉ dịch/co giãn toàn ảnh theo thân (y ≥ 240). Không cắt lớp hay ghép mặt; không chép lại pixel thân để ép sai số.

Từ vòng 3, người dùng yêu cầu nón trung cổ ngầu hơn và cho phép không quá bó đầu. Vì vậy tỷ lệ ngang 1,06 vẫn được báo cáo, nhưng không còn là điều kiện đánh trượt. Vòng 4–5 sửa lại nét cho cùng phong cách nhân vật: viền nâu đậm, mảng màu lớn và bóng cel đơn giản. Các ngưỡng còn lại giữ nguyên.

Cố định từ đầu: ngang trán y=158, bề ngang đầu 127 px; đỉnh tóc y=105; đỉnh lông mày y=161; khoảng đo vành trước x=257…305. Contour nón và hai mép vành được đánh dấu thủ công trên ảnh đã căn. Chiều dày là khoảng cách vuông góc xấp xỉ giữa hai đường vành. Số đo phụ thuộc độ chính xác contour; các overlay được lưu để kiểm tra lại.

MAE ngoài vùng sửa có đơn vị **0…255**: lấy trung bình bốn kênh RGBA, với RGB nhân alpha/255. Vùng sửa bao gồm nón và phần tóc gốc cần giấu. Phép đo có cả nền trong suốt; vì vậy báo thêm MAE RGB chỉ trên foreground ngoài vùng sửa. MAE toàn vùng đạt không đồng nghĩa mặt/thân giữ nguyên từng pixel.

Ngưỡng giữ nguyên: MAE ≤ 6; đỉnh nón y ≥ 105; vành ≤ 14 px; cách lông mày ≥ 6 px; không có pixel tóc phía trên vành nằm ngoài contour nón. Khoảng cách mày âm nghĩa là đáy vành thấp hơn mốc đỉnh mày gốc.

| Vòng | Nón | MAE ngoài | MAE foreground, tham khảo | Rộng / đầu | Đỉnh y | Dày vành px | Cách mày px | Pixel gần màu tóc ngoài viền | Kết quả |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
"""
for f in sorted(D.glob('metrics_r*.json')):
 row = json.loads(f.read_text())
 for kind,v in row['helmets'].items():
  rounds += f"| {row['round']} | {kind} | {v['outside_premult_rgba_mae']:.3f} | {v['outside_foreground_rgb_mae_informational']:.3f} | {v['cap_width_px']}/{head_width}={v['width_ratio']:.4f} | {v['cap_top_y']} | {v['brim_max_thickness_px']:.2f} | {v['brow_clearance_px']:.2f} | {v['hair_pixels_outside_cap_above_brim']} | {'ĐẠT' if v['all_pass'] else 'CHƯA ĐẠT'} |\n"
rounds += """
Màu tóc lấy từ tóc gốc, lượng tử 12 mức/kênh. Đếm pixel alpha > 127 phía trên đường vành, ngoài contour nón (dung sai viền AA 1 px), có khoảng cách màu RGB trung bình ≤ 18 tới bảng màu tóc. Màu tóc, mực viền và da nón có thể gần nhau: xem ảnh `sources/hair_check_*` có điểm đỏ và overlay contour. Ở vòng 5, contour được sửa để bao đúng mực viền nón từng bị nhận nhầm là tóc; giữ bản contour và số đo nháp trong `sources/*r5*draft.json`. Không sửa pixel ảnh khi chỉnh contour.

Kiểm tra neo: nón thuộc cùng thành phần alpha với nhân vật và điểm cổ (262,237) còn đục. Cả ba bản cuối đều đạt kiểm tra này; đây là kiểm tra ảnh raw, chưa phải thử gắn vào rig của game.

**Kết quả vòng cuối: CHƯA ĐẠT toàn bộ tiêu chí.** Cả ba còn chưa đạt khoảng cách vành–mày 6 px. Nón sắt còn dày vành 17,86 px, vượt 14 px. Tỷ lệ ngang nón sắt 1,0709 và ranger 1,0945 vượt giới hạn ban đầu 1,06; giới hạn này đã được người dùng nới ở vòng 3. Không nới các ngưỡng còn lại. Dừng sau đúng 5 vòng sửa ảnh theo giới hạn yêu cầu, bàn giao bản raw để duyệt hình dáng và nét vẽ.

Chạy lại phép đo vòng cuối từ thư mục repo:

```sh
OPENBLAS_NUM_THREADS=1 python docs/ideas/hero_head_v3/raw/check.py --round 5
```

Cần Python, Pillow, NumPy và SciPy. Nguồn ảnh sinh, thông số căn toàn ảnh và contour từng vòng nằm trong `sources/`; kết quả máy đọc nằm trong `metrics_r1.json` đến `metrics_r5.json`. Chạy vòng khác sẽ xuất lại ảnh bàn giao của vòng đó; chạy vòng 5 sau cùng để khôi phục bản cuối.
"""
(D/'rounds.md').write_text(rounds)
print(json.dumps(report,indent=2))
