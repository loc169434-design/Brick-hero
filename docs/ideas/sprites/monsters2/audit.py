"""Audit final sprite reports, retained files and all-frame ground drift."""
import hashlib,json,subprocess
from pathlib import Path
root=Path('docs/ideas/sprites/monsters2')
items=[];bad=[]
for p in sorted(root.glob('*/*_report.json')):
 r=json.loads(p.read_text()); clip=p.stem.removeprefix('fresh_').removesuffix('_report')
 drift=max(abs(f['feet'][1]-256) for f in r['per_frame'] if f['feet'])
 if not r['pass']:bad.append(str(p))
 if clip!='defeat' and drift>40:bad.append(f'{p}: drift {drift}')
 sheet=Path(r['sheet']);items.append({'monster':p.parent.name,'clip':clip,'frames':r['frames'],'pass':r['pass'],'max_ground_x_drift':drift,'sha256':hashlib.sha256(sheet.read_bytes()).hexdigest()})
files=subprocess.check_output(['git','diff','--name-only','origin/art/monsters-1'],text=True).splitlines()
for f in files:
 if not (f.startswith(str(root)+'/') or (f.startswith('assets/characters/') and '/anim/' in f and f.endswith('.png'))):bad.append('protected: '+f)
for m,clips in [('scarecrow',['idle','hurt']),('toad_witch',['cast_toads','cast_broom','throw_potion','cackle','stomp_angry','drink_transform']),('toad_witch_giant',['burp_toads','special2'])]:
 for clip in clips:
  f=f'assets/characters/{m}/anim/fresh_{clip}.png'
  if subprocess.run(['git','diff','--quiet','origin/art/monsters-1','--',f]).returncode:bad.append('retained changed: '+f)
result={'sheets':len(items),'frames':sum(i['frames'] for i in items),'all_pass':not bad and len(items)==42,'failures':bad,'items':items}
(root/'final_audit.json').write_text(json.dumps(result,indent=2));print(json.dumps({k:v for k,v in result.items() if k!='items'}))
raise SystemExit(0 if result['all_pass'] else 1)
