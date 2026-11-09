"""Opaque-sheet layout, repo keying/checking, and dark previews. Never edits final alpha."""
from pathlib import Path
from PIL import Image, ImageDraw
from scipy import ndimage
import numpy as np
import argparse, json, subprocess, hashlib

P=argparse.ArgumentParser();P.add_argument('monster');a=P.parse_args();m=a.monster
BASE=Path(__file__).resolve().parent;REPO=BASE.parents[3];OUT=BASE/m
OUT.mkdir(exist_ok=True);(OUT/'dark').mkdir(exist_ok=True)
CLIPS={'idle':(8,12,None),'attack':(12,24,6),'hurt':(8,24,None),'special':(12,24,7),'defeat':(12,12,None),'victory':(8,12,None)}
if m in ['orc_chief_enraged','orc_rock','orc_drummer','orc_boar']:CLIPS['rage']=(10,12,None)
KEY=np.array([255,0,255],dtype=np.uint8)
ref=np.array(Image.open(BASE/f'ref/{m}_frame0.png').convert('RGBA'))
y,x=np.where(ref[...,3]>=128);target_h=int(y.max()-y.min()+1);target_w=int(x.max()-x.min()+1)
canonical=None;layout={}
for clip,(count,fps,impact) in CLIPS.items():
 im=np.array(Image.open(OUT/f'generated/{clip}.png').convert('RGB'));hh,ww=im.shape[:2];rows=(count+3)//4
 dist=np.linalg.norm(im.astype(float)-KEY,axis=2);lab,n=ndimage.label(dist>140);sizes=np.bincount(lab.ravel());boxes=ndimage.find_objects(lab)
 main=[(i,b) for i,b in enumerate(boxes,1) if b is not None and sizes[i]>3000]
 main=sorted(main,key=lambda v:sizes[v[0]],reverse=True)[:count]
 main.sort(key=lambda v:(int((v[1][0].start+v[1][0].stop)/2/(hh/rows)),v[1][1].start))
 # A missing final ready cel can reuse the final generated ready (canonical below).
 if len(main)==count-1 and clip=='rage':main.append(main[-1])
 assert len(main)==count,(m,clip,len(main),count)
 assert [int((b[0].start+b[0].stop)/2/(hh/rows)) for _,b in main]==[i//4 for i in range(count)],(m,clip,'rows')
 groups=[{label} for label,_ in main];main_ids={v[0] for v in main}
 for label,box in enumerate(boxes,1):
  if box is None or label in main_ids or sizes[label]<20:continue
  yy,xx=box;i=int((yy.start+yy.stop)/2/(hh/rows))*4+min(3,int((xx.start+xx.stop)/2/(ww/4)))
  if i<count:groups[i].add(label)
 drawings=[]
 for i,((label,body),ids) in enumerate(zip(main,groups)):
  mask=np.isin(lab,list(ids));yy,xx=np.where(mask)
  y0,y1=max(0,int(yy.min())-3),min(hh,int(yy.max())+4);x0,x1=max(0,int(xx.min())-3),min(ww,int(xx.max())+4)
  rgb=im[y0:y1,x0:x1].copy();near=ndimage.binary_dilation(mask[y0:y1,x0:x1],iterations=3)
  rgb[~near]=KEY;rgb[np.linalg.norm(rgb.astype(float)-KEY,axis=2)<=60]=KEY
  bm=lab==label;by=body[0].stop-1;xs=np.where(bm[max(0,by-19):by+1].any(0))[0];anchor=float((xs[0]+xs[-1])/2)
  drawings.append((rgb,x0,y0,by,anchor,body,[int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1]))
 first=main[0][1];sy=target_h/(first[0].stop-first[0].start)
 sx=min(target_w/(first[1].stop-first[1].start),492/max(d[0].shape[1] for d in drawings),288/max(d[4]-d[1] for d in drawings),288/max(d[1]+d[0].shape[1]-d[4] for d in drawings))
 if max(d[0].shape[0]*sy for d in drawings)>490:sy=490/max(d[0].shape[0] for d in drawings)
 assert abs(sy*(first[0].stop-first[0].start)-target_h)/target_h<=.08,(m,clip,'too tall; redraw')
 sheet=Image.new('RGB',(2048,rows*512),tuple(KEY));info={'scale_x':sx,'scale_y':sy,'target_height':target_h,'target_width':target_w,'frames':[]}
 for i,(rgb,x0,y0,by,anchor,body,bbox) in enumerate(drawings):
  drawing=Image.fromarray(rgb).resize((round(rgb.shape[1]*sx),round(rgb.shape[0]*sy)),Image.Resampling.LANCZOS)
  px=round(256+(x0-anchor)*sx);py=round(500-(by-y0)*sy)
  px=max(5,min(px,507-drawing.width));assert py>=5 and py+drawing.height<=512,(m,clip,i,'vertical bounds',py,drawing.height)
  cell=Image.new('RGB',(512,512),tuple(KEY));cell.paste(drawing,(px,py))
  if clip=='idle' and i==0:canonical=cell.copy()
  shared=i==0 or (i==count-1 and clip!='defeat')
  if shared:cell=canonical.copy()
  sheet.paste(cell,((i%4)*512,(i//4)*512));info['frames'].append({'frame':i,'bbox':bbox,'xy':[px,py],'shared_ready':shared})
 sheet.save(BASE/f'raw/{m}_{clip}_key.png',optimize=True);layout[clip]=info
(OUT/'layout.json').write_text(json.dumps(layout,indent=2)+'\n')
round_path=OUT/'round_history.json';history=json.loads(round_path.read_text()) if round_path.exists() else []
assert len(history)<5,(m,'five checks already run')
round_no=len(history)+1;summary={};cards=[];all_ok=True
for clip,(count,fps,impact) in CLIPS.items():
 rows=(count+3)//4
 dest=REPO/f'assets/characters/{m}/anim/fresh_{clip}.png'
 subprocess.run(['python3',str(REPO/'tools/sprites/key_out.py'),str(BASE/f'raw/{m}_{clip}_key.png'),str(dest),'--key','ff00ff'],check=True)
 cmd=['python3',str(REPO/'tools/sprites/check_sheet.py'),str(dest),'--frames',str(count),'--fps',str(fps),'--key','ff00ff','--ref',str(BASE/f'ref/{m}_idle_old.png'),'--out',str(OUT)]
 if clip=='defeat':cmd+=['--airborne']
 r=subprocess.run(cmd,capture_output=True,text=True);(OUT/f'fresh_{clip}_check.log').write_text(r.stdout+r.stderr)
 report=json.loads((OUT/f'fresh_{clip}_report.json').read_text());ok=report['pass'] and r.returncode==0
 drift=max(abs(f['feet'][1]-256) for f in report['per_frame'] if f['feet'])
 summary[clip]={'pass':ok,'frames':count,'fps':fps,'impact':impact,'height_0':report['per_frame'][0]['height'],'ref_height':target_h,'max_ground_band_x_deviation':drift,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()}
 all_ok &= ok and drift<=40
 print(m,clip,'PASS' if ok else 'FAIL',f'drift={drift:g}',flush=True)
 if not ok:print(r.stdout,flush=True)
 sheet=Image.open(dest).convert('RGBA');frames=[]
 for i in range(count):
  cell=sheet.crop(((i%4)*512,(i//4)*512,(i%4+1)*512,(i//4+1)*512));bg=Image.new('RGBA',(512,512),(22,29,39,255));bg.alpha_composite(cell);frames.append(bg.resize((320,320),Image.Resampling.LANCZOS).convert('RGB'))
 durations=[int(round((i+1)*100/fps)*10-round(i*100/fps)*10) for i in range(count)]
 frames[0].save(OUT/f'dark/{clip}.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=False,disposal=2)
 grid=Image.new('RGB',(768,rows*216),(22,29,39));d=ImageDraw.Draw(grid)
 for i,f in enumerate(frames):
  gx,gy=i%4*192,i//4*216;grid.paste(f.resize((192,192),Image.Resampling.LANCZOS),(gx,gy+24));d.text((gx+6,gy+5),str(i)+(' IMPACT' if i==impact else ''),fill=(255,205,100) if i==impact else (220,230,240))
 grid.save(OUT/f'dark/{clip}_frames.png')
 cards.append(f'<article><h2>{clip}</h2><img src="dark/{clip}.gif" width="320" height="320"><p>{count} frames · {fps} fps · impact {impact if impact is not None else "—"}</p><a href="dark/{clip}_frames.png">Frames</a> · <a href="fresh_{clip}_report.json">Report</a></article>')
history.append({'round':round_no,'results':summary});round_path.write_text(json.dumps(history,indent=2)+'\n');(OUT/'validation.json').write_text(json.dumps(summary,indent=2)+'\n')
(OUT/'review.html').write_text('<!doctype html><html lang="vi"><meta charset="utf-8"><title>'+m+'</title><style>body{background:#10151e;color:#e2e8f0;font:16px system-ui;margin:24px}main{display:flex;flex-wrap:wrap;gap:20px}article{background:#161d27;padding:12px;border-radius:12px}a{color:#8dd3ff}</style><h1>'+m+'</h1><p>Sheet 4 cột × 512 px · #FF00FF · key_out.py và check_sheet.py nguyên bản</p><main>'+''.join(cards)+'</main></html>')
with (BASE/'rounds.md').open('a') as f:
 f.write(f'\n\n## {m} — vòng kiểm {round_no}/5\n\n| Sheet | Khung | fps | impact | Cao 0 / mẫu | Lệch x dải chân tối đa | Kết quả |\n|---|---:|---:|---:|---|---:|---|\n')
 for c,s in summary.items():f.write(f'| `{c}` | {s["frames"]} | {s["fps"]} | {s["impact"] if s["impact"] is not None else "—"} | {s["height_0"]} / {target_h} px | {s["max_ground_band_x_deviation"]:g} px | '+('**ĐẠT**' if s['pass'] else '**TRƯỢT**')+' |\n')
 f.write(f'\nHồ sơ từng khung, log kiểm, GIF nền tối và review: [`{m}/review.html`]({m}/review.html). Ảnh RGB gốc nằm ở `{m}/generated/`, bản nền hồng chuẩn lưới ở `raw/{m}_<clip>_key.png`. Dùng cùng ready ở đầu/cuối (trừ defeat), hệ số cỡ người cố định từng clip; chỉ key_out.py tạo alpha. Idle thở/nhún rõ hơn, hurt bật ngửa mạnh hơn. Chưa đổi anim.json hoặc .import; chưa tích hợp gameplay.\n')
raise SystemExit(0 if all_ok else 1)
