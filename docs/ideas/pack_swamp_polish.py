"""Issue #48: crop/scale complete drawn cels, assemble layers/atlases and reviews.

No recoloring, synthesized poses, paint-over, or frame interpolation. Originals
remain outside git. Review annotations and GIF playback do not alter game art.
"""
from pathlib import Path
import hashlib
import json
import math
import random
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / 'docs/ideas'
REVIEW = DOC / 'swamp_polish_review'
SOURCES = DOC / 'swamp_polish_sources.json'
DEST = ROOT / 'assets/tiles/swamp_b'
COLORS = ['red', 'green', 'yellow', 'purple']
CLIPS = {
    'idle': ('idle', 0, 12, 10, True),
    'drop': ('move', 8, 6, 16, False),
    'land': ('move', 14, 6, 16, False),
    'combo': ('move', 0, 8, 16, False),
    'hurt': ('react', 10, 8, 14, False),
    'taunt': ('react', 0, 10, 12, False),
    'fear': ('react', 18, 8, 12, True),
    'near_miss': ('end', 0, 8, 12, False),
    'gloat': ('move', 20, 8, 12, False),
    'death': ('end', 24, 8, 12, False),
    'win': ('end', 8, 8, 12, False),
    'lose': ('end', 16, 8, 12, False),
}
ROWS = {'idle': 3, 'react': 7, 'move': 7, 'end': 8}
EXTRA = {'croak': 8, 'look_left': 3, 'look_right': 5}
OLD_EXPRESSIONS = ['idle', 'blink', 'chuckle', 'laugh', 'fear', 'relief', 'scream', 'gloat', 'hurt']
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def strong_box(image):
    a = np.asarray(image)[:, :, 3] >= 128
    ys, xs = np.where(a)
    assert len(xs), 'empty source drawing'
    return (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)


def frame_box(image):
    """Find the main filled tile, ignoring small incidental alpha specks."""
    labels, count = ndimage.label(np.asarray(image)[:, :, 3] >= 128, np.ones((3, 3)))
    areas = np.bincount(labels.ravel())
    areas[0] = 0
    ys, xs = np.where(labels == areas.argmax())
    return (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)


def cel(image, band, cell_size=192):
    # Scale the entire drawn cell as one piece, registering by frame width/bottom.
    l, t, r, b = frame_box(image)
    scale_x = 128 / (r - l)
    scale_y = 128 / (band[1] - band[0])
    size = (round(image.width * scale_x), round(image.height * scale_y))
    drawing = image.resize(size, Image.Resampling.LANCZOS)
    x = round(cell_size / 2 - (l + r) / 2 * scale_x)
    y = round(cell_size / 2 + 64 - band[1] * scale_y)
    result = Image.new('RGBA', (cell_size, cell_size))
    result.alpha_composite(drawing, (x, y))
    return result, {'frame_box': [l, band[0], r, band[1]], 'scale': [scale_x, scale_y], 'offset': [x, y], 'cell': cell_size}


def measured_grid(image, rows):
    """Measure the drawn gutters; requested grid spacing need not be uniform."""
    alpha = np.asarray(image)[:, :, 3] >= 128
    def bands(occupied, minimum):
        ranges = ndimage.find_objects(ndimage.label(occupied > minimum)[0])
        return [(r[0].start, r[0].stop) for r in ranges if r and r[0].stop - r[0].start > 12]
    ys = bands(alpha.sum(axis=1), image.width * 0.3)
    xs = bands(alpha.sum(axis=0), image.height * 0.3)
    assert len(ys) == rows and len(xs) == 4, (image.size, rows, xs, ys)
    xcuts = [0] + [round((xs[i][1] + xs[i + 1][0]) / 2) for i in range(3)] + [image.width]
    ycuts = [0] + [round((ys[i][1] + ys[i + 1][0]) / 2) for i in range(rows - 1)] + [image.height]
    boxes = [[xcuts[x], ycuts[y], xcuts[x + 1], ycuts[y + 1]] for y in range(rows) for x in range(4)]
    return boxes, ys


def sheets(data):
    packed = {}
    for color in COLORS:
        kinds = dict(ROWS)
        if color + '_combo' in data['sources']:
            kinds['combo'] = 2
        for kind, rows in kinds.items():
            entry = data['sources'][f'{color}_{kind}']
            image = Image.open(entry['path']).convert('RGBA')
            boxes, bands = measured_grid(image, rows)
            labels, _ = ndimage.label(np.asarray(image)[:, :, 3] > 32, np.ones((3, 3)))
            objects = ndimage.find_objects(labels)
            entry['grid'] = [4, rows]
            entry['crop_boxes'] = boxes
            entry['measured_frame_row_bands'] = bands
            entry['registration'] = []
            frames = []
            for i, box in enumerate(boxes):
                if kind == 'react' and i >= 26:
                    break
                if kind == 'move' and color in ['red', 'green'] and i < 8:
                    frames.append(None)
                    entry['registration'].append({'unused': 'combo replaced by separate clean 8-cel sheet'})
                    continue
                # A jumping head can extend into a nominal row gutter. Locate
                # the filled frame, then crop its entire connected drawing by
                # its real bounding rectangle, not an equal-height grid cut.
                row_band = bands[i // 4]
                samples = labels[row_band[0]:row_band[1], box[0]:box[2]]
                counts = np.bincount(samples.ravel())
                counts[0] = 0
                obj = objects[int(counts.argmax()) - 1]
                box = [max(0, obj[1].start - 2), max(0, obj[0].start - 2),
                       min(image.width, obj[1].stop + 2), min(image.height, obj[0].stop + 2)]
                entry['crop_boxes'][i] = box
                is_combo = kind == 'combo' or (kind == 'move' and i < 8)
                band = (bands[i // 4][0] - box[1], bands[i // 4][1] - box[1])
                frame, registration = cel(image.crop(box), band, 320 if is_combo else 192)
                frames.append(frame)
                entry['registration'].append(registration)
            packed[color, kind] = frames
    return packed


def atlas(frames, cell=192, columns=8):
    image = Image.new('RGBA', (columns * cell, math.ceil(len(frames) / columns) * cell))
    for i, frame in enumerate(frames):
        image.alpha_composite(frame, (i % columns * cell, i // columns * cell))
    return image


def sprite_frames(color, entries):
    parts = [f'[gd_resource type="SpriteFrames" load_steps={len(entries) + sum(e["frames"] for e in entries) + 1} format=3]']
    for i, entry in enumerate(entries):
        parts.append(f'[ext_resource type="Texture2D" path="res://{entry["file"]}" id="{i + 1}"]')
    for i, entry in enumerate(entries):
        for f in range(entry['frames']):
            cell = entry['cell']
            parts.append(f'[sub_resource type="AtlasTexture" id="Atlas_{i}_{f}"]\natlas = ExtResource("{i + 1}")\nregion = Rect2({f % 8 * cell}, {f // 8 * cell}, {cell}, {cell})')
    animations = []
    for i, entry in enumerate(entries):
        frames = ',\n'.join('{"duration": 1.0, "texture": SubResource("Atlas_%d_%d")}' % (i, f) for f in range(entry['frames']))
        animations.append('{"frames": [\n' + frames + '\n], "loop": ' + str(entry['loop']).lower() + ', "name": &"' + entry['animation'] + '", "speed": ' + str(float(entry['fps'])) + '}')
    parts.append('[resource]\nanimations = [\n' + ',\n'.join(animations) + '\n]')
    (DEST / f'sprite_frames_{color}.tres').write_text('\n\n'.join(parts) + '\n')


def pack_tiles(data, packed):
    entries = []
    clips = {}
    manifest_path = DEST / 'swamp_manifest.json'
    manifest = json.loads(manifest_path.read_text())
    base_poses = OLD_EXPRESSIONS + list(EXTRA)
    retained_poses = [p for p in manifest.get('expressions', []) if p not in base_poses]
    for color in COLORS:
        color_entries = []
        for name, (kind, start, count, fps, loop) in CLIPS.items():
            source_kind = 'combo' if name == 'combo' and (color, 'combo') in packed else kind
            frames = packed[color, source_kind][start:start + count]
            assert len(frames) == count
            cell_size = frames[0].width
            image = atlas(frames, cell=cell_size)
            path = DEST / 'animations' / f'{color}_{name}.png'
            image.save(path, optimize=True)
            entry = {'family': 'swamp_b', 'color': color, 'animation': name,
                     'file': str(path.relative_to(ROOT)), 'width': image.width,
                     'height': image.height, 'cell': cell_size, 'columns': 8,
                     'frames': count, 'fps': fps, 'seconds': count / fps, 'loop': loop}
            entries.append(entry)
            color_entries.append(entry)
            clips[color, name] = frames
        sprite_frames(color, color_entries)
        expressions = [Image.open(DEST / 'expressions' / f'{color}_{p}.png').convert('RGBA') for p in OLD_EXPRESSIONS]
        for name, f in EXTRA.items():
            image = packed[color, 'idle'][f].crop((32, 32, 160, 160))
            image.save(DEST / 'expressions' / f'{color}_{name}.png', optimize=True)
            expressions.append(image)
        # Later approved stills (issue49 sly/dizzy) survive an issue48 rebuild.
        for pose in retained_poses:
            expressions.append(Image.open(DEST / 'expressions' / f'{color}_{pose}.png').convert('RGBA'))
        atlas(expressions, cell=128, columns=3).save(DEST / f'expressions_{color}.png', optimize=True)
    manifest['animations'] = entries
    manifest['expressions'] = base_poses + retained_poses
    manifest['expression_grid'] = {'columns': 3, 'cell': 128, 'rows': math.ceil(len(manifest['expressions']) / 3)}
    manifest['shared_drawn_cels'] = {}
    manifest['notes'] = 'Issue #48: 98 independently drawn cels per color, 392 total. No synthesized poses, no shared clips. Original B static tiles and nine existing individual expressions preserved.'
    write(manifest_path, manifest)
    global_path = ROOT / 'assets/tiles/animation_pack.json'
    global_manifest = json.loads(global_path.read_text())
    global_manifest['atlases'] = [e for e in global_manifest['atlases'] if e['family'] != 'swamp_b'] + entries
    global_manifest['families']['swamp_b'] = {'label': 'Đầm lầy Cóc — B đã duyệt', 'animations': list(CLIPS), 'expressions': manifest['expressions']}
    write(global_path, global_manifest)
    return clips


def pack_backgrounds(data):
    sky = Image.open(data['sources']['sky']['path']).convert('RGBA').resize((1080, 660), Image.Resampling.LANCZOS)
    for family in ['swamp', 'goblin_camp']:
        directory = ROOT / 'assets/bg' / family
        sky.save(directory / 'sky.png', optimize=True)
        far = Image.open(data['sources'][family + '_far']['path']).convert('RGBA').resize((1080, 660), Image.Resampling.LANCZOS)
        far.save(directory / 'far.png', optimize=True)
        entry = data['sources'][family + '_mid']
        source = Image.open(entry['path']).convert('RGBA')
        mid = Image.new('RGBA', (1080, 660))
        entry['whole_prop_crops'] = []
        for side in range(2):
            half = source.crop((side * (source.width // 2), 0, (side + 1) * (source.width // 2), source.height))
            box = strong_box(half)
            prop = half.crop(box)
            scale = min(110 / prop.width, 240 / prop.height)
            prop = prop.resize((round(prop.width * scale), round(prop.height * scale)), Image.Resampling.LANCZOS)
            position = (0 if side == 0 else 1080 - prop.width, 380 - prop.height)
            mid.alpha_composite(prop, position)
            entry['whole_prop_crops'].append({'half': side, 'box': list(box), 'position': list(position), 'size': list(prop.size)})
        mid.save(directory / 'mid.png', optimize=True)
        entry = data['sources'][family + '_ground']
        source = Image.open(entry['path']).convert('RGBA')
        coverage = (np.asarray(source)[:, :, 3] >= 128).sum(axis=1)
        top = int(np.flatnonzero(coverage > source.width * 0.3)[0]) - 5
        box = (0, max(top, 0), source.width, source.height)
        strip = source.crop(box).resize((1080, 280), Image.Resampling.LANCZOS)
        ground = Image.new('RGBA', (1080, 660))
        ground.alpha_composite(strip, (0, 380))
        ground.save(directory / 'ground.png', optimize=True)
        entry['whole_strip_crop'] = list(box)
        entry['destination'] = [0, 380, 1080, 660]
        metadata_path = directory / 'layers.json'
        metadata = json.loads(metadata_path.read_text())
        metadata['standing_floor'] = {'top_y': 380, 'bottom_y': 525, 'feet_native': [[270, 405], [810, 405]], 'feet_with_game_backdrop_shift': [[270, 485], [810, 485]], 'backdrop_shift': [0, -80]}
        metadata['fighter_clear_zones'] = [[150, 150, 390, 485], [690, 150, 930, 485]]
        metadata['art_revision'] = 'issue48_warm_flat_floor'
        write(metadata_path, metadata)


def font(size):
    return ImageFont.truetype(FONT, size)


def jpeg(image, name):
    image.convert('RGB').save(REVIEW / name, quality=87, optimize=True)
    assert (REVIEW / name).stat().st_size < 2_000_000


def gif(frames, name, fps):
    # GIF durations are centiseconds; use accumulated rounding to avoid drift.
    durations = [round((i + 1) * 100 / fps) * 10 - round(i * 100 / fps) * 10 for i in range(len(frames))]
    palette = frames[0].convert('RGB').quantize(colors=160)
    images = [f.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    images[0].save(REVIEW / name, save_all=True, append_images=images[1:], duration=durations, loop=0, optimize=True, disposal=2)
    assert (REVIEW / name).stat().st_size < 2_000_000


def composite(family, old=False, shift=0):
    image = Image.new('RGBA', (1080, 660))
    for layer in ['sky', 'far', 'mid', 'ground']:
        path = f'assets/bg/{family}/{layer}.png'
        if old and family != 'orc_camp':
            import io
            raw = subprocess.check_output(['git', 'show', 'art/campaign-100-g2:' + path], cwd=ROOT)
            source = Image.open(io.BytesIO(raw)).convert('RGBA')
        else:
            source = Image.open(ROOT / path).convert('RGBA')
        image.alpha_composite(source, (0, shift))
    return image


def actors(image, monster='orc_shield'):
    for character, at, mirror in [('hero_rookie', (270, 405), False), (monster, (810, 405), True)]:
        path = ROOT / 'assets/characters' / character / 'fresh_idle.png'
        if not path.exists() and character == 'goblin_thief':
            import io
            raw = subprocess.check_output(['git', 'show', 'origin/pr47:assets/characters/goblin_thief/fresh_idle.png'], cwd=ROOT)
            sprite = Image.open(io.BytesIO(raw)).convert('RGBA')
        else:
            sprite = Image.open(path).convert('RGBA')
        if mirror:
            sprite = ImageOps.mirror(sprite)
        sprite = sprite.resize((round(512 * 0.7), round(512 * 0.7)), Image.Resampling.LANCZOS)
        image.alpha_composite(sprite, (round(at[0] - 256 * 0.7), round(at[1] - 500 * 0.7)))
    return image


def reviews(clips):
    REVIEW.mkdir(exist_ok=True)
    (REVIEW / '.gdignore').write_text('')
    for shift, name, label in [(0, 'backgrounds_native_feet.jpg', 'Canvas1080x660; feet(270,405)/(810,405), scale0.7'), (-80, 'backgrounds_game_layout.jpg', 'Game: backdrop shift y=-80; feet(270,405)/(810,405), scale0.7')]:
        panel_height = 250 if shift else 330
        row_step = panel_height + 28
        out = Image.new('RGB', (1620, 2 * row_step + 55), '#e9dfca')
        draw = ImageDraw.Draw(out)
        draw.text((15, 5), label, font=font(20), fill='#352819')
        for row, family in enumerate(['swamp', 'goblin_camp']):
            for col, (f, old, title) in enumerate([('orc_camp', False, 'Orc reference'), (family, True, family + ' BEFORE'), (family, False, family + ' AFTER')]):
                monster = 'goblin_thief' if f == 'goblin_camp' else 'orc_shield'
                panel = actors(composite(f, old, shift), monster).convert('RGB')
                if shift:
                    panel = panel.crop((0, 0, 1080, 500))
                out.paste(panel.resize((540, panel_height), Image.Resampling.LANCZOS), (col * 540, 55 + row * row_step))
                draw.text((col * 540 + 10, 32 + row * row_step), title, font=font(17), fill='#352819')
        jpeg(out, name)
    for family in ['swamp', 'goblin_camp']:
        image = composite(family)
        jpeg(image, family + '_background.jpg')
        overlay = image.copy()
        draw = ImageDraw.Draw(overlay)
        draw.rectangle((0, 380, 1079, 480), outline='#ffeb95', width=3)
        for x in [270, 810]:
            draw.ellipse((x - 8, 397, x + 8, 413), fill='#ffef73', outline='#3b1a10', width=2)
        jpeg(actors(overlay), family + '_feet_overlay.jpg')
    for name, (_, _, count, fps, _) in CLIPS.items():
        frames = []
        for f in range(count):
            display_cell = 320 if name == 'combo' else 192
            out = Image.new('RGBA', (4 * display_cell, display_cell + 36), '#243039')
            draw = ImageDraw.Draw(out)
            for i, color in enumerate(COLORS):
                out.alpha_composite(clips[color, name][f], (i * display_cell, 28))
                draw.text((i * display_cell + 12, 7), f'{color} | {name}', font=font(15), fill='#f8e8b4')
            frames.append(out)
        gif(frames, name + '_four_colors.gif', fps)
    rng = random.Random(48)
    layout = COLORS * 14
    rng.shuffle(layout)
    phases = [rng.randrange(12) for _ in layout]
    write(REVIEW / 'board_layout_7x8.json', {'seed': 48, 'columns': 7, 'rows': 8, 'cell_display': 46, 'colors': layout, 'idle_phase_frames': phases, 'fps': 10})
    frames = []
    for t in range(12):
        out = Image.new('RGBA', (364, 466), '#243039')
        draw = ImageDraw.Draw(out)
        draw.text((10, 5), '7x8 | 46px | idle 12f @10fps', font=font(17), fill='#f8e8b4')
        for i, (color, phase) in enumerate(zip(layout, phases)):
            sprite = clips[color, 'idle'][(t + phase) % 12].resize((69, 69), Image.Resampling.LANCZOS)
            out.alpha_composite(sprite, (i % 7 * 50 - 4, i // 7 * 50 + 31))
        frames.append(out)
    gif(frames, 'board_7x8_idle_offset.gif', 10)
    jpeg(frames[0], 'board_7x8_46px.jpg')
    out = Image.new('RGB', (1024, 580), '#e9dfca')
    draw = ImageDraw.Draw(out)
    for row, color in enumerate(COLORS):
        for col, pose in enumerate(['croak', 'look_left', 'look_right']):
            sprite = Image.open(DEST / 'expressions' / f'{color}_{pose}.png').convert('RGBA')
            x = col * 320 + 20
            y = row * 140 + 20
            out.paste(sprite, (x, y), sprite)
            draw.text((x + 142, y + 32), color + '\n' + pose, font=font(18), fill='#352819')
    jpeg(out, 'new_expressions.jpg')


def main():
    data = json.loads(SOURCES.read_text())
    for entry in data['sources'].values():
        path = Path(entry['path'])
        assert not path.is_relative_to(ROOT)
        entry['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
    packed = sheets(data)
    clips = pack_tiles(data, packed)
    pack_backgrounds(data)
    reviews(clips)
    write(SOURCES, data)
    print('Packed 392 drawn cels, 48 atlases, 12 new stills, 4 SpriteFrames and two layered backgrounds.')


if __name__ == '__main__':
    main()
