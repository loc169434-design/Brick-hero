extends "res://tests/test_case.gd"

## A rig with made-up clips; the sheets are blank images, only the timing matters here.
func _rig() -> CharacterRig:
	var rig := CharacterRig.new()
	rig._ready()
	rig.setup("hero_rookie", 1)
	rig._anim = {"columns": 4, "frame_size": [512, 512], "clips": {
		"idle": {"frames": 8, "fps": 12, "loop": true},
		"attack": {"frames": 12, "fps": 24, "impact": 6},
	}}
	var blank := ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))
	for clip in ["idle", "attack"]:
		rig._sheets["res://assets/characters/hero_rookie/anim/fresh_%s.png" % clip] = blank
	return rig


func test_idle_clip_loops() -> void:
	var rig := _rig()
	rig._update_clip(0.0)
	assert_eq(rig._clip, &"idle")
	rig._update_clip(9.5 / 12.0)
	assert_eq(rig._clip_frame(), 1, "frame 9 of 8 wraps to 1")
	rig._body.free()
	rig.free()


func test_a_one_shot_clip_holds_its_last_frame_and_reports_its_impact() -> void:
	var rig := _rig()
	rig.mood = &"attack"
	rig._mood_serial += 1
	rig._update_clip(0.0)
	assert_eq(rig._clip, &"attack")
	assert_eq(rig.impact_seconds(&"attack"), 0.25)
	var hits := []
	rig.clip_impact.connect(func(clip: StringName) -> void: hits.append(clip))
	rig._update_clip(0.2)
	assert_eq(hits.size(), 0)
	rig._update_clip(0.1)
	assert_eq(hits, [&"attack"], "the impact frame came up")
	rig._update_clip(2.0)
	assert_eq(rig._clip_frame(), 11, "holds the last frame")
	rig.mood = &"idle"
	rig._update_clip(0.0)
	assert_eq(rig._clip, &"idle", "back to idle")
	rig._body.free()
	rig.free()


func test_landing_a_blow_jumps_the_swing_to_its_impact_frame() -> void:
	var rig := _rig()
	rig.mood = &"attack"
	rig._mood_serial += 1
	rig._update_clip(0.0)
	rig._update_clip(0.2)
	assert_eq(rig._clip_frame(), 4, "still swinging")
	rig.reach_impact()
	assert_eq(rig._clip_frame(), 6, "the blow lands")
	rig._clip_time = 0.4
	rig.reach_impact()
	assert_eq(rig._clip_frame(), 9, "never jumps back")
	rig._body.free()
	rig.free()


func test_a_mood_with_a_still_pose_but_no_clip_shows_the_pose() -> void:
	var rig := _rig()
	rig.mood = &"hurt"
	rig._mood_serial += 1
	rig._update_clip(0.0)
	assert_eq(rig._clip, &"", "the hurt pose, not the idle clip")
	rig._body.free()
	rig.free()


func test_no_anim_file_no_clips() -> void:
	var rig := CharacterRig.new()
	rig._ready()
	rig.setup("blacksmith", 1)
	assert_true(not rig.has_clip(&"idle"))
	rig._update_clip(0.5)
	assert_eq(rig._clip, &"")
	rig._body.free()
	rig.free()


## Clip sheets are big (2048 px, up to 16 frames): uncompressed, a fighter's clips alone would
## take hundreds of MB of video memory on a phone.
func test_clip_sheets_import_vram_compressed() -> void:
	var folders := ["res://assets/fx/combat/anim/"]
	for id in DirAccess.get_directories_at("res://assets/characters/"):
		folders.append("res://assets/characters/%s/anim/" % id)
	var checked := 0
	for folder: String in folders:
		if not DirAccess.dir_exists_absolute(folder):
			continue
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".png.import"):
				continue
			var config := ConfigFile.new()
			config.load(folder + file)
			assert_eq(config.get_value("params", "compress/mode"), 2, folder + file)
			checked += 1
	assert_true(checked > 80, "found the clip sheets")
