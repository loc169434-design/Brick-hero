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
	rig.setup("king", 1)
	assert_true(not rig.has_clip(&"idle"))
	rig._update_clip(0.5)
	assert_eq(rig._clip, &"")
	rig._body.free()
	rig.free()


func test_clip_duration_uses_a_full_pass_and_falls_back_for_still_art() -> void:
	var rig := _rig()
	assert_eq(rig.clip_seconds(&"attack"), 0.5)
	assert_eq(rig.clip_seconds(&"idle"), 8.0 / 12.0)
	assert_eq(rig.clip_seconds(&"missing", 0.32), 0.32)
	rig._body.free()
	rig.free()


func test_reacting_starts_the_clip_before_the_callers_timer_runs() -> void:
	var rig := _rig()
	rig.react(&"attack", 0.0)
	assert_eq(rig._clip, &"attack")
	assert_eq(rig._clip_time, 0.0)
	assert_eq(rig._clip_frame(), 0)
	rig._update_clip(0.2)
	rig.react(&"attack", 0.0)
	assert_eq(rig._clip_frame(), 0, "another reaction restarts this same clip immediately")
	rig._body.free()
	rig.free()


func test_the_smith_can_query_the_striking_pose_without_leaving_idle() -> void:
	var rig := CharacterRig.new()
	rig._ready()
	rig.setup("blacksmith", -1)
	var expected := (Vector2(128, 305) - Vector2(256, 500)) * (360.0 / 512.0)
	assert_eq(rig._anchor("hammer", &"hammer"), expected)
	assert_eq(rig._anchor("hammer", &"hammer_final"), expected)
	assert_eq(rig.mood, &"idle", "looking ahead must not play the strike")
	assert_eq(rig.clip_seconds(&"hammer"), 16.0 / 24.0)
	assert_eq(rig.clip_seconds(&"hammer_final"), 20.0 / 24.0)
	rig._body.free()
	rig.free()


func test_drawn_blacksmith_acting_can_disable_extra_breathing_and_cheer_hops() -> void:
	var rig := CharacterRig.new()
	rig._ready()
	rig.setup("blacksmith", -1)
	rig.procedural_motion = false
	rig.react(&"cheer", 0.0)
	rig._process(0.2)
	assert_eq(rig._body.scale, Vector2.ONE)
	assert_eq(rig._body.position, Vector2.ZERO)
	assert_true(rig._motion == null, "the drawing already contains the acting")
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


func test_the_outfit_follows_the_best_gear() -> void:
	var outfit := Gear.outfit(["wood_sword", "iron_sword", "leather_armor", "sword_plus_1", "sword_plus_2"])
	assert_eq(outfit["weapon"], "iron_sword")
	assert_eq(outfit["armor"], "leather_armor")
	assert_eq(outfit["helmet"], "")
	assert_eq(outfit["refine"], 2)


func test_without_a_bare_body_layer_a_clip_is_drawn_whole() -> void:
	var outfit := Gear.outfit(["wood_sword", "iron_armor"])
	assert_eq(CharacterRig.layer_paths("hero_rookie", outfit, "fresh", "idle"), [] as Array[String], "no layers drawn yet")


func test_gear_layers_stack_back_body_then_pieces() -> void:
	var root := "res://tests/fixtures/characters/"
	var outfit := {"weapon": "iron_sword", "armor": "leather_armor", "helmet": "iron_helmet", "boots": ""}
	var paths := CharacterRig.layer_paths("dummy", outfit, "battered", "idle", root)
	var names: Array[String] = []
	for path in paths:
		names.append(path.get_base_dir().get_file() + "/" + path.get_file())
	assert_eq(names, ["iron_sword_back/fresh_idle.png", "body/battered_idle.png", "leather_armor/fresh_idle.png", "iron_sword/fresh_idle.png"] as Array[String], "a missing helmet layer is skipped; the wear's body wins")
