"""Audit all G2 actor cells and prove the reported old fragments are rejected."""
from pathlib import Path
import io,json,subprocess
from PIL import Image
from connected_figure import ALPHA_THRESHOLD,MAX_SMALL_PARTICLE,parts,signature,large_islands,violations

ROOT=Path(__file__).resolve().parents[2]
IDS=['toad_spitter','goblin_archer','swamp_leech','goblin_thief','goblin_bomber','swamp_spider','frost_slime','crocodile','toad_witch','toad_witch_giant','fairy_fickle','fairy_crow']
OUT=ROOT/'docs/ideas/campaign_g2_review'

def frame(atlas,index):
    return atlas.crop((index%4*512,index//4*512,index%4*512+512,index//4*512+512))

def run():
    manifest=json.loads((ROOT/'docs/ideas/issue41_intentional_fx.json').read_text())
    rules=manifest['frames'];errors=[];cells=0;used=set();allowed=0
    for cid in IDS:
        dest=ROOT/'assets/characters'/cid
        metadata=json.loads((dest/'anim/anim.json').read_text())
        for clip,m in metadata['clips'].items():
            atlas=Image.open(dest/'anim'/f'fresh_{clip}.png').convert('RGBA')
            for i in range(m['frames']):
                key=f'{cid}/{clip}/{i}';f=frame(atlas,i);islands=large_islands(f)
                entry=rules.get(key,{'components':[]});exempt=entry['components']
                for p in exempt:
                    assert entry.get('reason'),f'FX exception needs a reason: {key}'
                    assert signature(p) in {signature(x) for x in islands},f'stale FX exception: {key}'
                    allowed+=1
                if exempt:used.add(key)
                errors.extend({'cell':key,**p} for p in violations(f,exempt))
                assert parts(f),f'empty actor: {key}'
                # The two witch attacks contain no intentional detached effects.
                if cid=='toad_witch' and clip=='attack' and i in [2,3]:
                    assert not [p for p in parts(f) if not p['body'] and p['area']>2],f'stray witch speck: {i}'
                if cid=='crocodile':
                    body=next(p for p in parts(f) if p['body'])
                    assert 498<=body['box'][3]<=502,f'feet registration: {key}'
                    assert f.getchannel('A').crop((0,0,512,180)).getextrema()==(0,0),f'fragment above crocodile: {key}'
                cells+=1
    assert used==set(rules),'unused FX frame exception'
    # Real regression fixtures remain in Git; no duplicate broken PNGs in repo.
    rejected=[]
    for clip,indices in [('attack',range(1,5)),('hurt',range(1,3)),('special',range(1,7)),('defeat',range(6))]:
        raw=subprocess.check_output(['git','show',f'10ccc4c:assets/characters/crocodile/anim/fresh_{clip}.png'],cwd=ROOT)
        old=Image.open(io.BytesIO(raw)).convert('RGBA')
        for i in indices:
            key=f'crocodile/{clip}/{i}'
            assert violations(frame(old,i),rules.get(key,{}).get('components',[])),f'old broken cell escaped detector: {key}'
            rejected.append(key)
    report={'alpha_threshold':ALPHA_THRESHOLD,'connectivity':8,'max_small_particle_pixels':MAX_SMALL_PARTICLE,
            'actor_cells_checked':cells,'reviewed_fx_components':allowed,'unapproved_large_islands':errors,
            'baseline':'10ccc4c','old_broken_crocodile_cells_rejected':rejected}
    (OUT/'contiguity_validation.json').write_text(json.dumps(report,indent=2)+'\n')
    assert not errors,json.dumps(errors,indent=2)
    print(json.dumps({'cells_checked':cells,'reviewed_fx_components':allowed,'unapproved_large_islands':len(errors),'old_broken_cells_rejected':len(rejected)}))
    return report

if __name__=='__main__':run()
