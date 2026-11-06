"""Composite final PNGs at (0,0), with no equipment transforms.

Usage: python compose_frame.py idle fresh 7 iron /tmp/frame.png
Raises on missing assets instead of silently inventing a layer.
"""
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
LAYERS = ROOT / "assets/characters/hero_rookie/anim/layers"
SETS = {"none": [], "wood": ["wood_sword"], "leather": ["reinforced_boots", "leather_armor", "leather_helmet", "iron_sword"],
        "iron": ["climbing_boots", "iron_armor", "iron_helmet", "tempered_sword"]}


def resolve(item, wear, clip, optional=False):
    paths = [LAYERS / item / f"{wear}_{clip}.png", LAYERS / item / f"fresh_{clip}.png"]
    for path in paths:
        if path.is_file():
            return path
    if optional:
        return None
    raise FileNotFoundError(f"No {wear}/{clip} layer for {item}")


def compose(clip, wear, frame, outfit):
    count = {"idle": 8, "attack": 12}[clip]
    if not 0 <= frame < count:
        raise ValueError("Frame outside clip")
    items = SETS[outfit]
    paths = [resolve(item + "_back", wear, clip, True) for item in items]
    paths += [resolve("body", wear, clip)]
    paths += [resolve(item, wear, clip) for item in items]
    result = Image.new("RGBA", (512, 512))
    rect = (frame % 4 * 512, frame // 4 * 512, (frame % 4 + 1) * 512, (frame // 4 + 1) * 512)
    for path in paths:
        if path:
            result = Image.alpha_composite(result, Image.open(path).convert("RGBA").crop(rect))
    return result


if __name__ == "__main__":
    clip, wear, frame, outfit, output = sys.argv[1:]
    compose(clip, wear, int(frame), outfit).save(output)
