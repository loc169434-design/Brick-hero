#!/usr/bin/env python3
"""
Verification & review renderer for Brickbound Hero cut-out skeletal rig v2.
Checks Criteria A, B, C, D, E and outputs deliverables in docs/ideas/hero_rig_v2/.
"""
import json
import math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import binary_dilation, binary_erosion, label

ROOT = Path(__file__).resolve().parents[3]
RIG_DIR = ROOT / "assets/characters/hero_rig"
PARTS_DIR = RIG_DIR / "parts"
GEAR_DIR = RIG_DIR / "gear"
OUT_DIR = ROOT / "docs/ideas/hero_rig_v2"
FRESH_IDLE_PATH = ROOT / "assets/characters/hero_rookie/anim/fresh_idle.png"

TREE = {
    "pelvis": ("hip", None),
    "torso": ("waist", "pelvis"),
    "head": ("neck", "torso"),
    "cape": ("cape", "torso"),
    "shield_arm_upper": ("shoulder_shield", "torso"),
    "shield_arm_lower": ("elbow_shield", "shield_arm_upper"),
    "shield_hand": ("wrist_shield", "shield_arm_lower"),
    "shield": ("shield", "shield_arm_lower"),
    "sword_arm_upper": ("shoulder_sword", "torso"),
    "sword_arm_lower": ("elbow_sword", "sword_arm_upper"),
    "sword_hand": ("wrist_sword", "sword_arm_lower"),
    "back_leg_upper": ("hip_back", "pelvis"),
    "back_leg_lower": ("knee_back", "back_leg_upper"),
    "back_foot": ("ankle_back", "back_leg_lower"),
    "front_leg_upper": ("hip_front", "pelvis"),
    "front_leg_lower": ("knee_front", "front_leg_upper"),
    "front_foot": ("ankle_front", "front_leg_lower"),
}

TEST_JOINTS = [
    "waist", "neck",
    "shoulder_shield", "elbow_shield", "wrist_shield",
    "shoulder_sword", "elbow_sword", "wrist_sword",
    "hip_back", "knee_back", "ankle_back",
    "hip_front", "knee_front", "ankle_front",
]
TEST_ANGLES = [-35, -20, 20, 35]


def get_swordless_source(f0_rgba: np.ndarray) -> np.ndarray:
    """Returns fresh_idle frame 0 with the wooden sword removed per 'Không vẽ kiếm'."""
    im_poly = Image.new("L", (512, 512), 0)
    drw = ImageDraw.Draw(im_poly)
    upper_poly = [
        (325, 140), (430, 140), (430, 315),
        (376, 315), (366, 293), (350, 290), (344, 294), (340, 285), (325, 275),
    ]
    lower_poly = [
        (343, 336), (366, 336), (368, 368), (330, 368), (330, 341), (341, 339),
    ]
    drw.polygon(upper_poly, fill=255)
    drw.polygon(lower_poly, fill=255)
    sword_mask = np.array(im_poly) > 128
    main_body_im = (f0_rgba[:, :, 3] > 16) & (~sword_mask)
    labs_mb, _ = label(main_body_im)
    mb_counts = np.bincount(labs_mb.ravel())
    mb_counts[0] = 0
    clean_body_mask = binary_dilation(labs_mb == mb_counts.argmax(), iterations=2) & (~sword_mask)
    no_sword = f0_rgba.copy()
    no_sword[~clean_body_mask] = [0, 0, 0, 0]
    no_sword[501:, :] = [0, 0, 0, 0]
    return no_sword


def load_rig():
    jdata = json.loads((RIG_DIR / "joints.json").read_text(encoding="utf-8"))
    joints = jdata["joints"]
    order = [p for p in jdata["order"] if p != "sword"]
    parts = {p: Image.open(PARTS_DIR / f"{p}.png").convert("RGBA") for p in order}
    gear = {}
    if GEAR_DIR.exists():
        for gdir in sorted(GEAR_DIR.iterdir()):
            if gdir.is_dir():
                gear[gdir.name] = {
                    png.stem: Image.open(png).convert("RGBA")
                    for png in sorted(gdir.glob("*.png"))
                }
    return joints, order, parts, gear


def render_pose(joints, order, parts, gear, pose=None, outfit=None) -> Image.Image:
    pose = pose or {}
    if outfit == "leather":
        active_gear = ("leather_armor", "leather_helmet", "reinforced_boots")
    elif outfit == "iron":
        active_gear = ("iron_armor", "iron_helmet", "climbing_boots")
    else:
        active_gear = ()

    world_angle = {}
    world_pos = {}

    def get_xform(part):
        if part in world_angle:
            return world_angle[part], world_pos[part]
        jname, parent = TREE[part]
        jx, jy = joints[jname]
        local_deg = float(pose.get(jname, 0.0))
        if parent is None:
            world_angle[part] = local_deg
            world_pos[part] = (float(jx), float(jy))
        else:
            pa, (px, py) = get_xform(parent)
            pjname, _ = TREE[parent]
            pjx, pjy = joints[pjname]
            dx, dy = jx - pjx, jy - pjy
            rad = math.radians(pa)
            rx = dx * math.cos(rad) - dy * math.sin(rad)
            ry = dx * math.sin(rad) + dy * math.cos(rad)
            world_pos[part] = (px + rx, py + ry)
            world_angle[part] = pa + local_deg
        return world_angle[part], world_pos[part]

    out = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    for part in order:
        ang, (wx, wy) = get_xform(part)
        jname, _ = TREE[part]
        jx, jy = joints[jname]
        im = parts[part].copy()
        for gname in active_gear:
            if gname in gear and part in gear[gname]:
                im.alpha_composite(gear[gname][part])
        if abs(ang) > 1e-5:
            im = im.rotate(-ang, resample=Image.Resampling.BICUBIC, center=(jx, jy))
        dx, dy = int(round(wx - jx)), int(round(wy - jy))
        if dx != 0 or dy != 0:
            shifted = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
            shifted.paste(im, (dx, dy))
            im = shifted
        out.alpha_composite(im)
    return out


def run_checks(save_deliverables=True):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    joints, order, parts, gear = load_rig()
    f0_im = Image.open(FRESH_IDLE_PATH).crop((0, 0, 512, 512)).convert("RGBA")
    f0_rgba = np.array(f0_im)
    ref_rgba = get_swordless_source(f0_rgba)

    rest_im = render_pose(joints, order, parts, gear, {}, outfit=None)
    rest_rgba = np.array(rest_im)

    # --- CRITERION A: Rest match against original ---
    ref_sil = ref_rgba[:, :, 3] > 32
    rest_sil = rest_rgba[:, :, 3] > 32
    inter = int((ref_sil & rest_sil).sum())
    union = int((ref_sil | rest_sil).sum())
    iou = inter / max(1, union)

    raw_sil = f0_rgba[:, :, 3] > 32
    raw_iou = int((raw_sil & rest_sil).sum()) / max(1, int((raw_sil | rest_sil).sum()))

    common = ref_sil & rest_sil
    rgb_diff = np.abs(ref_rgba[:, :, :3].astype(float) - rest_rgba[:, :, :3].astype(float)).mean(axis=2)
    mean_diff_255 = float(rgb_diff[common].mean()) if common.any() else 999.0

    bad_px = common & (rgb_diff > 40.0)
    # Region > 3x3 px means a connected component whose bounding box exceeds 3x3 or area > 9
    bad_labs, n_bad = label(bad_px)
    large_bad_regions = 0
    for cid in range(1, n_bad + 1):
        ys, xs = np.where(bad_labs == cid)
        if (ys.max() - ys.min() + 1 > 3) or (xs.max() - xs.min() + 1 > 3) or len(xs) > 9:
            large_bad_regions += 1

    pass_A = (iou >= 0.97) and (mean_diff_255 <= 6.0) and (large_bad_regions == 0)

    # --- CRITERION B & C: Rotation gap & continuous outline ---
    yy, xx = np.ogrid[:512, :512]
    rest_solid = rest_rgba[:, :, 3] >= 200
    b_total_samples = 0
    b_passed_samples = 0
    b_missing_pixels_total = 0
    b_failures = []

    c_total_samples = 0
    c_passed_samples = 0
    c_leaked_pixels_total = 0
    c_failures = []

    rot_cache = {}
    for jname in TEST_JOINTS:
        jx, jy = joints[jname]
        disk20 = ((xx - jx) ** 2 + (yy - jy) ** 2) <= 20 ** 2
        disk28 = ((xx - jx) ** 2 + (yy - jy) ** 2) <= 28 ** 2
        rest_d20 = rest_solid & disk20

        for ang in TEST_ANGLES:
            rot_im = render_pose(joints, order, parts, gear, {jname: ang}, outfit=None)
            rot_arr = np.array(rot_im)
            rot_cache[(jname, ang, None)] = rot_im

            # B: opacity retention in 20px radius
            b_total_samples += 1
            rot_solid = (rot_arr[:, :, 3] >= 200) & disk20
            missing = int((rest_d20 & (~rot_solid)).sum())
            b_missing_pixels_total += missing
            if missing == 0:
                b_passed_samples += 1
            else:
                b_failures.append({"joint": jname, "angle": ang, "missing_px": missing})

            # C: flood fill from (0,0) across non-outline pixels cannot enter body interior near joint
            c_total_samples += 1
            a = rot_arr[:, :, 3].astype(float)
            lum = 0.299 * rot_arr[:, :, 0] + 0.587 * rot_arr[:, :, 1] + 0.114 * rot_arr[:, :, 2]
            dark_barrier = (a >= 150) & (lum <= 85)
            labs_c, _ = label(~dark_barrier)
            outside_flood = labs_c == labs_c[0, 0]
            body_interior = binary_erosion(a >= 200, iterations=3) & (~dark_barrier)
            leaked = int((outside_flood & body_interior & disk28).sum())
            c_leaked_pixels_total += leaked
            if leaked == 0:
                c_passed_samples += 1
            else:
                c_failures.append({"joint": jname, "angle": ang, "leaked_px": leaked})

    pass_B = (b_passed_samples == b_total_samples) and (b_missing_pixels_total == 0)
    pass_C = (c_passed_samples == c_total_samples) and (c_leaked_pixels_total == 0)

    # --- CRITERION D: Leather (and Iron) gear fit & face preservation ---
    d_layer_checks = {}
    d_outside_total = 0
    for gname in ("leather_armor", "leather_helmet", "reinforced_boots", "iron_armor", "iron_helmet", "climbing_boots"):
        if gname not in gear:
            continue
        for pname, gim in gear[gname].items():
            g_alpha = np.array(gim)[:, :, 3] > 0
            h_alpha = np.array(parts[pname])[:, :, 3] > 0
            allowed = binary_dilation(h_alpha, iterations=24)
            outside = int((g_alpha & (~allowed)).sum())
            d_layer_checks[f"{gname}/{pname}"] = outside
            if gname in ("leather_armor", "leather_helmet", "reinforced_boots"):
                d_outside_total += outside

    leather_im = render_pose(joints, order, parts, gear, {}, outfit="leather")
    iron_im = render_pose(joints, order, parts, gear, {}, outfit="iron")
    leather_rgba = np.array(leather_im)
    iron_rgba = np.array(iron_im)

    # Face region (eyes, nose, mouth: x in 244..312, y in 160..235)
    face_box = (slice(160, 235), slice(244, 312))
    face_diff_leather = int(np.abs(rest_rgba[face_box].astype(int) - leather_rgba[face_box].astype(int)).max())
    face_diff_iron = int(np.abs(rest_rgba[face_box].astype(int) - iron_rgba[face_box].astype(int)).max())
    pass_D = (d_outside_total == 0) and (face_diff_leather == 0)

    # --- CRITERION E: Every PNG 512x512 RGBA and does not touch canvas border ---
    e_violations = []
    all_pngs = list(PARTS_DIR.glob("*.png")) + list(GEAR_DIR.glob("*/*.png"))
    for p in sorted(all_pngs):
        im = Image.open(p)
        arr = np.array(im.convert("RGBA"))
        a = arr[:, :, 3] > 0
        border_px = int(a[0, :].sum() + a[-1, :].sum() + a[:, 0].sum() + a[:, -1].sum())
        if im.size != (512, 512) or im.mode != "RGBA" or border_px > 0:
            e_violations.append({
                "file": str(p.relative_to(ROOT)),
                "size": list(im.size),
                "mode": im.mode,
                "border_px": border_px,
            })
    pass_E = len(e_violations) == 0

    results = {
        "all_passed": bool(pass_A and pass_B and pass_C and pass_D and pass_E),
        "A_rest_match": {
            "passed": bool(pass_A),
            "iou_alpha_gt_32": round(iou, 6),
            "iou_vs_raw_with_sword": round(raw_iou, 6),
            "mean_color_diff_255": round(mean_diff_255, 4),
            "bad_regions_gt_3x3": large_bad_regions,
        },
        "B_no_gap_on_rotation": {
            "passed": bool(pass_B),
            "passed_samples": b_passed_samples,
            "total_samples": b_total_samples,
            "missing_opaque_pixels_total": b_missing_pixels_total,
            "failures": b_failures,
        },
        "C_continuous_outline": {
            "passed": bool(pass_C),
            "passed_samples": c_passed_samples,
            "total_samples": c_total_samples,
            "leaked_pixels_total": c_leaked_pixels_total,
            "failures": c_failures,
        },
        "D_leather_gear": {
            "passed": bool(pass_D),
            "outside_24px_total": d_outside_total,
            "face_max_diff_leather": face_diff_leather,
            "face_max_diff_iron": face_diff_iron,
            "layers_outside_24px": d_layer_checks,
        },
        "E_canvas_format": {
            "passed": bool(pass_E),
            "checked_files": len(all_pngs),
            "violations": e_violations,
        },
    }

    if save_deliverables:
        (OUT_DIR / "check_result.json").write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        leather_im.save(OUT_DIR / "leather.png")
        iron_im.save(OUT_DIR / "iron.png")

        # 1. compare.png: original (swordless ref) | assembled | heatmap diff
        comp = Image.new("RGBA", (512 * 3, 512), (28, 28, 34, 255))
        comp.alpha_composite(Image.fromarray(ref_rgba), (0, 0))
        comp.alpha_composite(rest_im, (512, 0))

        heat = np.zeros((512, 512, 4), dtype=np.uint8)
        heat[:, :, 3] = 255
        heat[:, :, :3] = [28, 28, 34]
        diff_mag = np.abs(ref_rgba.astype(float) - rest_rgba.astype(float)).max(axis=2)
        union_mask = (ref_rgba[:, :, 3] > 0) | (rest_rgba[:, :, 3] > 0)
        heat[union_mask, 0] = np.clip(diff_mag[union_mask] * 4.0, 40, 255).astype(np.uint8)
        heat[union_mask, 1] = np.clip(180 - diff_mag[union_mask] * 3.0, 20, 180).astype(np.uint8)
        heat[union_mask, 2] = 60
        comp.alpha_composite(Image.fromarray(heat), (1024, 0))
        comp.save(OUT_DIR / "compare.png")

        # 2. onion.png: assembled blended 50/50 over original with cyan/magenta tint for any mismatch
        onion = Image.new("RGBA", (512, 512), (28, 28, 34, 255))
        orig_tint = ref_rgba.copy().astype(float)
        orig_tint[:, :, 0] *= 0.5
        rest_tint = rest_rgba.copy().astype(float)
        rest_tint[:, :, 1] *= 0.5
        blend = np.clip(0.5 * orig_tint + 0.5 * rest_tint, 0, 255).astype(np.uint8)
        onion.alpha_composite(Image.fromarray(blend), (0, 0))
        onion.save(OUT_DIR / "onion.png")

        # 3. rotation_grid.png: 14 joints rows x 8 cols (4 angles bare + 4 angles leather)
        cell_w, cell_h = 180, 190
        grid = Image.new("RGBA", (cell_w * 8, cell_h * len(TEST_JOINTS)), (30, 30, 36, 255))
        gdraw = ImageDraw.Draw(grid)
        for r_idx, jname in enumerate(TEST_JOINTS):
            for c_idx, ang in enumerate(TEST_ANGLES):
                im_bare = rot_cache[(jname, ang, None)]. crop((60, 80, 440, 510)).resize((cell_w, cell_h), Image.Resampling.LANCZOS)
                im_eq = render_pose(joints, order, parts, gear, {jname: ang}, outfit="leather").crop((60, 80, 440, 510)).resize((cell_w, cell_h), Image.Resampling.LANCZOS)
                grid.alpha_composite(im_bare, (c_idx * cell_w, r_idx * cell_h))
                grid.alpha_composite(im_eq, ((c_idx + 4) * cell_w, r_idx * cell_h))
                gdraw.text((c_idx * cell_w + 6, r_idx * cell_h + 4), f"{jname} {ang:+d}d", fill=(230, 230, 230, 255))
                gdraw.text(((c_idx + 4) * cell_w + 6, r_idx * cell_h + 4), f"{jname} {ang:+d}d (gear)", fill=(255, 220, 150, 255))
        grid.save(OUT_DIR / "rotation_grid.png")

    return results


if __name__ == "__main__":
    res = run_checks(save_deliverables=True)
    print(json.dumps(res, indent=2, ensure_ascii=False))
