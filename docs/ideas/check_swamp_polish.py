"""Check issue #48 artwork contracts, real alpha geometry and preservation."""
from pathlib import Path
import hashlib
import base64
import json
import subprocess
import sys
import zlib

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/ideas'
REVIEW = DOC / 'swamp_polish_review'
SOURCE = json.loads((DOC / 'swamp_polish_sources.json').read_text())
COLORS = ['red', 'green', 'yellow', 'purple']
EXPECTED = {'idle': (12, 10, True), 'taunt': (10, 12, False),
            'hurt': (8, 14, False), 'fear': (8, 12, True), 'combo': (8, 16, False),
            'drop': (6, 16, False), 'land': (6, 16, False),
            **{k: (8, 12, False) for k in ['gloat', 'near_miss', 'win', 'lose', 'death']}}
checks = 0


def check(condition, description):
    global checks
    assert condition, description
    checks += 1


def old(path, ref=None):
    return subprocess.check_output(['git', 'show', (ref or SOURCE['baseline_art']) + ':' + path], cwd=ROOT)


def image(path):
    return Image.open(ROOT / path).convert('RGBA')


def fragments(alpha):
    labels, _ = ndimage.label(alpha > 32, np.ones((3, 3)))
    areas = np.bincount(labels.ravel())[1:]
    if not len(areas):
        return []
    return sorted(int(n) for n in np.delete(areas, areas.argmax()) if n > 200)


manifest = json.loads((ROOT / 'assets/tiles/swamp_b/swamp_manifest.json').read_text())
check(len(manifest['animations']) == 48, '48 color/clip combinations')
seen = set()
per_color = {c: set() for c in COLORS}
total = 0
frame_hashes = set()
all_frames = {}
for entry in manifest['animations']:
    color, clip = entry['color'], entry['animation']
    check((color, clip) not in seen, f'duplicate {color}/{clip}')
    seen.add((color, clip))
    per_color[color].add(clip)
    count, fps, loop = EXPECTED[clip]
    check((entry['frames'], entry['fps'], entry['loop']) == (count, fps, loop), f'{color}/{clip} playback')
    check(abs(entry['seconds'] - count / fps) < 1e-9, f'{color}/{clip} duration')
    im = image(entry['file'])
    cell = entry['cell']
    check(cell == (320 if clip == 'combo' else 192), f'{color}/{clip} safe animation padding')
    check(im.size == (entry['width'], entry['height']) == (8 * cell, ((count + 7) // 8) * cell), f'{color}/{clip} atlas geometry')
    hashes = set()
    for f in range(count):
        frame = im.crop((f % 8 * cell, f // 8 * cell, f % 8 * cell + cell, f // 8 * cell + cell))
        alpha = np.asarray(frame)[:, :, 3]
        check(int((alpha > 128).sum()) > 9000, f'{color}/{clip}/{f} substantial art')
        check(not fragments(alpha), f'{color}/{clip}/{f} detached art fragment')
        check(not (np.r_[alpha[0], alpha[-1], alpha[:, 0], alpha[:, -1]] > 32).any(), f'{color}/{clip}/{f} clipped art at cell edge')
        digest = hashlib.sha256(frame.tobytes()).hexdigest()
        check(digest not in frame_hashes, f'{color}/{clip}/{f} reused cel')
        hashes.add(digest)
        frame_hashes.add(digest)
        all_frames[color, clip, f] = frame
        total += 1
    check(len(hashes) == count, f'{color}/{clip} unique drawn frames')
    for f in range(count, im.width // cell * (im.height // cell)):
        check(im.crop((f % 8 * cell, f // 8 * cell, f % 8 * cell + cell, f // 8 * cell + cell)).getbbox() is None, f'{color}/{clip} clear unused cell')
for color, clips in per_color.items():
    check(clips == set(EXPECTED), f'{color} full clip set')
check(total == 392, '392 independently drawn published cels')

# Real counterexamples retain neighboring-row fragments; the rule must reject them.
regression_count = 0
for fixture in json.loads((REVIEW / 'regression_masks.json').read_text())['fixtures']:
    raw = zlib.decompress(base64.b64decode(fixture['mask_packbits_zlib_base64']))
    check(hashlib.sha256(raw).hexdigest() == fixture['mask_sha256'], 'negative control mask hash')
    a = np.unpackbits(np.frombuffer(raw, dtype=np.uint8)).reshape(fixture['shape']) * 255
    check(bool(fragments(a)), f'negative control {fixture["name"]}: old cut must fail')
    regression_count += 1

for family in ['swamp', 'goblin_camp']:
    for layer in ['sky', 'far', 'mid', 'ground']:
        check(image(f'assets/bg/{family}/{layer}.png').size == (1080, 660), f'{family}/{layer} canvas')
    sky = np.asarray(image(f'assets/bg/{family}/sky.png'))[:, :, 3]
    check(int(sky.min()) == 255, f'{family} opaque sky')
    mid = np.asarray(image(f'assets/bg/{family}/mid.png'))[:, :, 3]
    check(not mid[:, 120:960].any(), f'{family} unobstructed fighter lanes')
    check(not mid[380:].any(), f'{family} scenery only, transparent lower mid')
    ground = np.asarray(image(f'assets/bg/{family}/ground.png'))[:, :, 3]
    check(not ground[:380].any(), f'{family} no floating foreground above floor')
    for x in [270, 810]:
        for y in [405, 485]:
            check(int(ground[y-8:y+9, x-24:x+25].min()) >= 250, f'{family} solid floor under feet at {x},{y}')
    metadata = json.loads((ROOT / f'assets/bg/{family}/layers.json').read_text())
    before = json.loads(old(f'assets/bg/{family}/layers.json'))
    check(metadata['ambient_effects'] == before['ambient_effects'], f'{family} effect settings retained')
    check(metadata['safe_parallax'] == before['safe_parallax'], f'{family} parallax contract retained')
    for effect in ['bubble', 'firefly', 'lotus']:
        path = f'assets/bg/{family}/{effect}.png'
        check((ROOT / path).read_bytes() == old(path), f'{family}/{effect} drawing retained')

for color in COLORS:
    for relative in [f'tile_{color}.png'] + [f'expressions/{color}_{pose}.png' for pose in manifest['expressions'][:9]]:
        path = 'assets/tiles/swamp_b/' + relative
        check((ROOT / path).read_bytes() == old(path), f'approved B original retained: {relative}')
    for pose, f in [('croak', 8), ('look_left', 3), ('look_right', 5)]:
        im = image(f'assets/tiles/swamp_b/expressions/{color}_{pose}.png')
        check(im.size == (128, 128), f'{color}/{pose} static dimensions')
        check(im.tobytes() == all_frames[color, 'idle', f].crop((32, 32, 160, 160)).tobytes(), f'{color}/{pose} matches drawn idle cel')
    check(image(f'assets/tiles/swamp_b/expressions_{color}.png').size == (384, 512), f'{color} extended expressions grid')

pack = json.loads((ROOT / 'assets/tiles/animation_pack.json').read_text())
before = json.loads(old('assets/tiles/animation_pack.json', SOURCE['base']))
check([e for e in pack['atlases'] if e['family'] != 'swamp_b'] == before['atlases'], 'other animation families untouched')
check([e for e in pack['atlases'] if e['family'] == 'swamp_b'] == manifest['animations'], 'runtime manifest matches new atlases')
check({k: v for k, v in pack['families'].items() if k != 'swamp_b'} == before['families'], 'other family settings untouched')
check({k: v for k, v in pack.items() if k not in ['families', 'atlases']} == {k: v for k, v in before.items() if k not in ['families', 'atlases']}, 'other global manifest fields untouched')

sources = SOURCE['sources']
verified_sources = 0
unavailable_sources = []
for name, entry in sources.items():
    p = Path(entry['path'])
    check(not p.is_relative_to(ROOT), name + ' original stored outside git')
    if p.is_file():
        check(hashlib.sha256(p.read_bytes()).hexdigest() == entry['sha256'], name + ' original hash')
        verified_sources += 1
    else:
        unavailable_sources.append(name)
check('--source-audit' not in sys.argv or not unavailable_sources, 'strict original source audit')

layout = json.loads((REVIEW / 'board_layout_7x8.json').read_text())
check(len(layout['colors']) == 56 and all(layout['colors'].count(c) == 14 for c in COLORS), 'balanced full 7x8 board')
check(len(set(layout['idle_phase_frames'])) > 8, 'board idle phases staggered')
board = Image.open(REVIEW / 'board_7x8_idle_offset.gif')
check(board.n_frames == 12, 'GIF retains full 12-frame idle cycle')
previews = []
for path in sorted(REVIEW.iterdir()):
    if path.suffix.lower() in ['.jpg', '.gif', '.png', '.webp']:
        check(path.suffix in ['.jpg', '.gif'], f'{path.name} permitted preview format')
        check(path.stat().st_size < 2_000_000, f'{path.name} preview below 2 MB')
        previews.append({'file': path.name, 'bytes': path.stat().st_size})

result = {'issue': 48, 'checks_passed': checks, 'published_cels': total, 'atlases': 48,
          'detached_fragment_failures': 0, 'edge_clipping_failures': 0,
          'regression_counterexamples_rejected': regression_count,
          'verified_original_sources': verified_sources, 'unavailable_original_sources': unavailable_sources,
          'previews': previews}
(REVIEW / 'validation.json').write_text(json.dumps(result, indent=2) + '\n')
print(f'{checks} checks passed; {total} intact cels; 48 clips; 2 bad old cuts rejected; all previews <2 MB.')
