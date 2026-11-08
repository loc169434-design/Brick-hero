from pathlib import Path
import argparse,json,subprocess
p=argparse.ArgumentParser();p.add_argument('monster');p.add_argument('--chief-move',action='store_true');a=p.parse_args();m=a.monster
b=Path(__file__).resolve().parent;r=b.parents[3];subprocess.run(['git','diff','--check'],cwd=r,check=True)
summary=json.loads((b/m/'validation.json').read_text());assert len(summary)==(7 if m.startswith('orc_') else 6)
assert all(s['pass'] and s['max_ground_band_x_deviation']<=40 for s in summary.values())
assert json.loads((b/m/'browser_review.json').read_text())['animated_captures_differ']
lines=['# Quái đợt 1 — kết quả và preview','','Tất cả dùng nền #FF00FF, key_out.py/check_sheet.py nguyên bản. Mỗi quái có báo cáo/GIF riêng. `anim.json` và `.import` giữ nguyên để Claude tích hợp sau duyệt.','','| Quái | Sheet | Kết quả | GIF / báo cáo |','|---|---:|---|---|']
for name in ['orc_chief','orc_chief_enraged','orc_rock','orc_drummer','orc_boar','goblin_thief','goblin_archer','goblin_bomber','crocodile','frost_slime']:
 f=b/name/'validation.json'
 if f.exists():
  s=json.loads(f.read_text());ok=all(v['pass'] for v in s.values());lines.append(f'| `{name}` | {len(s)} | '+('ĐẠT' if ok else 'ĐANG SỬA')+f' | [{name}]({name}/review.html) · [dark GIFs]({name}/dark/) |')
(b/'index.md').write_text('\n'.join(lines)+'\n')
paths=[f'assets/characters/{m}/anim/fresh_{c}.png' for c in summary]
paths += [f'docs/ideas/sprites/monsters1/{m}',f'docs/ideas/sprites/monsters1/ref/{m}_idle_old.png',f'docs/ideas/sprites/monsters1/ref/{m}_frame0.png']
paths += [f'docs/ideas/sprites/monsters1/raw/{m}_{c}_key.png' for c in summary]
paths += ['docs/ideas/sprites/monsters1/rounds.md','docs/ideas/sprites/monsters1/index.md','docs/ideas/sprites/monsters1/finish_monster.py','docs/ideas/sprites/monsters1/review_browser.py','docs/ideas/sprites/monsters1/commit_monster.py']
if a.chief_move:
 subprocess.run(['git','add','-u','--','docs/ideas/sprites/monsters1'],cwd=r,check=True)
 paths += ['docs/ideas/sprites/monsters1/orc_chief','docs/ideas/sprites/monsters1/assemble_key.py','docs/ideas/sprites/monsters1/make_previews.py']
subprocess.run(['git','add','--',*paths],cwd=r,check=True)
changed=subprocess.check_output(['git','diff','--cached','--name-only'],cwd=r,text=True).splitlines()
assert all(x.startswith(f'assets/characters/{m}/anim/fresh_') and x.endswith('.png') or x.startswith('docs/ideas/sprites/monsters1/') for x in changed),changed
subprocess.run(['git','diff','--cached','--check'],cwd=r,check=True)
subprocess.run(['git','commit','-m',f'art: redraw {m} animations with keyed sheets and per-monster reports'],cwd=r,check=True)
subprocess.run(['git','push','origin','art/monsters-1'],cwd=r,check=True)
sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=r,text=True).strip()
remote=subprocess.check_output(['git','ls-remote','--heads','origin','art/monsters-1'],cwd=r,text=True).split()[0]
assert sha==remote
print('PUSH VERIFIED',m,sha,flush=True)
