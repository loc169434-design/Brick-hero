from pathlib import Path
from PIL import Image, ImageDraw
import json

ROOT = Path(__file__).resolve().parent
BASE = ROOT / "orc_chief"
REPO = ROOT.parents[3]
CLIPS = {'idle': (8, 12, None), 'attack': (12, 24, 6), 'hurt': (8, 24, None),
         'special': (12, 24, 7), 'defeat': (12, 12, None), 'victory': (8, 12, None), 'rage': (10, 12, None)}
BG = (22, 29, 39, 255)
cards = []
for clip, (count, fps, impact) in CLIPS.items():
    sheet = Image.open(REPO / f'assets/characters/orc_chief/anim/fresh_{clip}.png').convert('RGBA')
    frames = []
    for i in range(count):
        frame = sheet.crop(((i % 4) * 512, (i // 4) * 512, (i % 4 + 1) * 512, (i // 4 + 1) * 512))
        bg = Image.new('RGBA', (512, 512), BG)
        bg.alpha_composite(frame)
        frames.append(bg.resize((320, 320), Image.Resampling.LANCZOS).convert('RGB'))
    durations = [int(round((i+1)*100/fps)*10 - round(i*100/fps)*10) for i in range(count)]
    frames[0].save(BASE / f'dark/orc_chief_{clip}.gif', save_all=True, append_images=frames[1:],
                   duration=durations, loop=0, optimize=False, disposal=2)
    grid = Image.new('RGB', (4*192, ((count+3)//4)*216), BG[:3])
    d = ImageDraw.Draw(grid)
    for i, f in enumerate(frames):
        x,y = (i % 4) * 192, (i // 4) * 216
        grid.paste(f.resize((192,192), Image.Resampling.LANCZOS), (x,y+24))
        d.text((x+8,y+6), f'{i}' + ('  IMPACT' if i == impact else ''), fill=(255,205,100) if i==impact else (220,230,240))
    grid.save(BASE / f'dark/orc_chief_{clip}_frames.png')
    cards.append(f'<article><h2>{clip}</h2><img src="dark/orc_chief_{clip}.gif" width="320" height="320"><p>{count} frames · {fps} fps' + (f' · impact {impact}' if impact is not None else '') + f'</p><a href="dark/orc_chief_{clip}_frames.png">Frames</a> · <a href="fresh_{clip}_report.json">Report</a></article>')
(BASE/'review.html').write_text('''<!doctype html><html lang="vi"><meta charset="utf-8"><title>Orc chief — duyệt đợt 1</title><style>body{background:#10151e;color:#e2e8f0;font:16px system-ui;margin:24px}main{display:flex;flex-wrap:wrap;gap:20px}article{background:#161d27;padding:12px;border-radius:12px}h2{margin:0 0 8px}a{color:#8dd3ff}p{max-width:1000px}</style><h1>orc_chief · 7 hoạt ảnh · chờ duyệt</h1><p>4 cột, ô 512 × 512; nền được tách bằng key_out.py --key ff00ff. Cả 7 sheet ĐẠT check_sheet.py. Attack chạm ở khung 6; special hai tay đập chùy chạm ở khung 7. Chưa cập nhật anim.json hoặc tích hợp runtime.</p><main>''' + ''.join(cards) + '</main></html>')
print('7 dark GIFs and frame contact sheets saved')
