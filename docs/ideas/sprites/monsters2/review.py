from pathlib import Path
import json
from PIL import Image,ImageDraw
root=Path('docs/ideas/sprites/monsters2')
lines=['# Quái đợt 2 — kết quả kiểm', '', 'Nhánh `art/monsters-2` từ `e68e8554e5164e486d15e968523817557492f550`. Chỉ sửa ảnh và hồ sơ trong phạm vi cho phép. RGB được sinh từ ảnh tham chiếu; assemble.py chỉ cắt/sắp lưới với hệ số cố định trong mỗi clip, key_out.py tạo alpha. Không thay anim.json.', '', '| Quái | Sheet | Kiểm | Vòng kiểm | Cao 0 / mẫu | Chân đầu/cuối (y,x) |', '|---|---|---|---:|---|---|']
for report in sorted(root.glob('*/*_report.json')):
 r=json.loads(report.read_text()); monster=report.parent.name; clip=report.stem.removeprefix('fresh_').removesuffix('_report')
 sheet=Image.open(r['sheet']).convert('RGBA'); frames=[]
 for i in range(r['frames']):
  f=sheet.crop((i%4*512,i//4*512,i%4*512+512,i//4*512+512)); bg=Image.new('RGBA',(512,512),(30,34,43,255)); bg.alpha_composite(f); frames.append(bg.resize((256,256)))
 frames[0].convert('RGB').save(report.parent/f'{clip}_dark.gif',save_all=True,append_images=[f.convert('RGB') for f in frames[1:]],duration=round(1000/(12 if clip in ('idle','defeat','victory') else 24)),loop=0)
 contact=Image.new('RGB',(1024,256*((len(frames)+3)//4)),(30,34,43))
 for i,f in enumerate(frames): contact.paste(f,(i%4*256,i//4*256))
 contact.save(report.parent/f'{clip}_dark.png')
 lines.append(f"| {monster} | {clip} | {'ĐẠT' if r['pass'] else 'TRƯỢT'} | 1 | {r['checks'].get('size',{}).get('detail','')} | {r['per_frame'][0]['feet']} / {r['per_frame'][-1]['feet']} |")
(root/'rounds.md').write_text('\n'.join(lines)+'\n')
