#!/bin/sh
# Cleans up freshly delivered hero rig art (assets/characters/hero_rig), once per delivery:
# fills the nape under the helmets, outlines the scarf behind the neck, runs the helmet flaps
# to the ear, clears faint stray pixels, tidies the crotch and the front thigh's hem sliver,
# underpaints the torso and pelvis where arms, shield and thighs hide them at rest, and
# re-cuts the sword arm from the assembled hero (see rebuild_sword_arm.py).
# Some passes target this art's coordinates; re-check them on new art.
#
#   sh tools/rig_cleanup/run.sh
#
# Then check every outfit and pose for see-through spots (cyan on the sheet):
#   godot --path . --resolution 640x640 -s tools/rig_cleanup/scan_rig.gd -- /tmp/scan
#   python3 tools/rig_cleanup/holes.py /tmp/scan /tmp/scan_sheet.png
set -e
T=$(cd "$(dirname "$0")" && pwd)
cd "$T/../../assets/characters/hero_rig"
for pass in fix_nape fix_scarf fix_ears despeckle fix_crotch fix_thigh underpaint rebuild_sword_arm fix_neck despeckle; do
	python3 "$T/$pass.py" .
done
