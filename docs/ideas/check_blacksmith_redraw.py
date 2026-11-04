"""Check exported whole-frame art and render placement previews; never draw poses."""
from pathlib import Path
import hashlib
import json
import math
from PIL import Image
from pack_blacksmith_redraw import cell_data

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'assets/characters/blacksmith'
REVIEW = ROOT / 'docs/ideas/blacksmith_review'
SPECS = {'idle': (12, 12, True, None), 'talk': (8, 12, True, None),
         'hammer': (16, 24, False, 9), 'hammer_final': (20, 24, False, 12),
         'cheer': (16, 12, False, None), 'grin': (14, 12, False, None)}

def frame(sheet, index):
    x, y = index % 4 * 512, index // 4 * 512
    return sheet.crop((x, y, x + 512, y + 512))

def run():
    meta = json.loads((ART / 'anim/anim.json').read_text())
    rig = json.loads((ART / 'rig.json').read_text())
    assert meta['frame_size'] == [512, 512] and meta['columns'] == 4
    assert rig['feet'] == [256, 500]
    canonical = frame(Image.open(ART / 'anim/fresh_idle.png'), 0)
    report = {'clips': {}, 'feet': rig['feet'], 'canvas': [512, 512]}
    for name, (count, fps, loop, impact) in SPECS.items():
        info = meta['clips'][name]
        assert (info['frames'], info['fps'], info['loop'], info.get('impact')) == (count, fps, loop, impact)
        sheet = Image.open(ART / f'anim/fresh_{name}.png')
        assert sheet.mode == 'RGBA' and sheet.size == (2048, math.ceil(count / 4) * 512)
        frames = [frame(sheet, i) for i in range(count)]
        assert all(f.getchannel('A').getbbox() for f in frames)
        assert all(f.getchannel('A').getextrema()[0] == 0 for f in frames)
        assert frames[-1].tobytes() == canonical.tobytes()
        assert all(frame(sheet, i).getchannel('A').getbbox() is None for i in range(count, math.ceil(count / 4) * 4))
        unique = len({hashlib.sha256(f.tobytes()).hexdigest() for f in frames})
        assert unique >= count - 1
        measured = cell_data(ART / f'anim/fresh_{name}.png', count)
        deviation = [max(abs(x + 4 - 256), abs(y + 4 - 500)) for _, x, y, _ in measured]
        assert max(deviation) <= 5  # Rendered boot-color edges include antialiasing.
        assert 'head' in rig['anchors'][name] and 'mouth' in rig['anchors'][name]
        gif_path = REVIEW / f'{name}.gif'
        gif = Image.open(gif_path)
        durations = []
        for i in range(gif.n_frames):
            gif.seek(i)
            durations.append(gif.info['duration'])
        # GIF encoders may coalesce identical idle end/start cels across cycles.
        assert count * 3 - 3 <= gif.n_frames <= count * 3
        assert abs(sum(durations) - count * 3 / fps * 1000) <= 10
        assert gif_path.stat().st_size < 2_000_000
        report['clips'][name] = {'frames': count, 'fps': fps, 'impact': impact,
                                'unique_drawings': unique, 'last_matches_idle': True,
                                'max_measured_boot_edge_deviation_px': max(deviation),
                                'gif_bytes': gif_path.stat().st_size,
                                'gif_total_ms_three_cycles': sum(durations)}
    assert 'hammer' in rig['anchors']['hammer'] and 'hammer' in rig['anchors']['hammer_final']
    assert 'tooth' in rig['anchors']['grin']
    room = Image.open(ROOT / 'assets/bg/forge.png').convert('RGBA')
    assert room.size == (1080, 1920)
    placements = {}
    for clip, index in [('idle', 0), ('hammer', 9)]:
        sheet = Image.open(ART / f'anim/fresh_{clip}.png')
        cel = frame(sheet, index).resize((384, 384), Image.Resampling.LANCZOS)
        preview = room.copy()
        preview.alpha_composite(cel, (598, 505))  # (790,880) - 0.75 * (256,500)
        path = REVIEW / f'forge_{clip}.png'
        preview.convert('RGB').quantize(colors=256, dither=Image.Dither.NONE).save(path, optimize=True)
        assert path.stat().st_size < 2_000_000
        placements[clip] = {'feet': [790, 880], 'whole_canvas_scale': 0.75,
                            'body_height_approx': 300, 'frame': index}
    report['forge_previews'] = placements
    report['preview_images_under_2mb'] = all(p.stat().st_size < 2_000_000 for p in REVIEW.iterdir() if p.suffix in ('.png', '.gif'))
    assert report['preview_images_under_2mb']
    (REVIEW / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print('PASS: six atlases, 86 frames, alpha, metadata, exact idle endings, unique drawings, GIF timing/sizes, forge placement.')

if __name__ == '__main__':
    run()
