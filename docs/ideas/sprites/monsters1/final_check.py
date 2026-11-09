"""Verify all delivered sheets without reassembling or modifying sprite images."""
from pathlib import Path
import json,subprocess,hashlib
b=Path(__file__).resolve().parent;r=b.parents[3]
monsters=['orc_chief','orc_chief_enraged','orc_rock','orc_drummer','orc_boar','goblin_thief','goblin_archer','goblin_bomber','crocodile','frost_slime']
clips={'idle':(8,12),'attack':(12,24),'hurt':(8,24),'special':(12,24),'defeat':(12,12),'victory':(8,12)}
rows=[];data={};all_ok=True
for m in monsters:
 spec=dict(clips)
 if m.startswith('orc_'):spec['rage']=(10,12)
 data[m]={};out=b/'final_check'/m;out.mkdir(parents=True,exist_ok=True)
 for c,(n,fps) in spec.items():
  sheet=r/f'assets/characters/{m}/anim/fresh_{c}.png'
  cmd=['python3',str(r/'tools/sprites/check_sheet.py'),str(sheet),'--frames',str(n),'--fps',str(fps),'--key','ff00ff','--ref',str(b/f'ref/{m}_idle_old.png'),'--out',str(out)]
  if c=='defeat':cmd+=['--airborne']
  result=subprocess.run(cmd,capture_output=True,text=True);(out/f'fresh_{c}_check.log').write_text(result.stdout+result.stderr)
  p=json.loads((out/f'fresh_{c}_report.json').read_text());drift=max(abs(f['feet'][1]-256) for f in p['per_frame'] if f['feet'])
  ok=result.returncode==0 and p['pass'] and drift<=40
  data[m][c]={'pass':ok,'frames':n,'fps':fps,'max_ground_band_x_deviation':drift,'height_0':p['per_frame'][0]['height'],'sha256':hashlib.sha256(sheet.read_bytes()).hexdigest()}
  all_ok &= ok
  print(m,c,'PASS' if ok else 'FAIL',flush=True)
  rows.append(f'| `{m}` | `{c}` | {n} | {fps} | {drift:g} | '+('ĐẠT' if ok else 'TRƯỢT')+f' | [JSON](final_check/{m}/fresh_{c}_report.json) |')
(b/'final_check/results.json').write_text(json.dumps(data,indent=2)+'\n')
header='# Quái đợt 1 — kiểm cuối từng sheet\n\nChạy check_sheet.py nguyên bản trên các PNG đích sau tách bằng key_out.py. Mỗi sheet 4 cột, ô 512×512; defeat dùng --airborne. Độ lệch ngang dải chân toàn clip phải ≤40 px. Mẫu cỡ người là bản idle cũ đã lưu trước khi ghi đè.\n\n| Quái | Sheet | Khung | fps | Lệch x tối đa (px) | Kết quả | Chi tiết |\n|---|---|---:|---:|---:|---|---|\n'
(b/'final_results.md').write_text(header+'\n'.join(rows)+'\n\n65 sheet. Chỉ bàn giao art, chưa cập nhật anim.json hoặc tích hợp gameplay.\n')
assert len(rows)==65
raise SystemExit(0 if all_ok else 1)
