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
		var anim := "res://assets/characters/%s/anim/" % id
		folders.append(anim)
		# outfit and variant clip sets
		if DirAccess.dir_exists_absolute(anim):
			for sub in DirAccess.get_directories_at(anim):
				folders.append(anim + sub + "/")
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


func test_the_outfit_follows_the_best_gear_or_the_look_picked() -> void:
	var owned := ["rookie", "leather", "iron", "sword_plus_1", "sword_plus_2"]
	assert_eq(Gear.outfit(owned), {"outfit": "iron", "refine": 2})
	assert_eq(Gear.outfit(owned, "leather")["outfit"], "leather", "an outfit he owns can be worn for its look")
	assert_eq(Gear.outfit(owned, "frost")["outfit"], "iron", "not one he doesn't own")
	var rules := Gear.apply(BattleRules.new(), owned, "leather")
	assert_eq(rules.outfit["outfit"], "leather", "the fight dresses him as picked")
	assert_eq(rules.armor, 5, "while the numbers stay those of his best")


func test_an_outfit_plays_its_own_clip_set_and_the_rookie_the_usual_one() -> void:
	var rig := _rig()
	rig._base_clips = rig._anim["clips"].duplicate(true)
	rig.set_outfit({"outfit": "rookie", "refine": 0})
	assert_eq(rig._outfit_folder(), "")
	assert_eq(rig._clip_sheet_for(&"idle"), rig._sheets["res://assets/characters/hero_rookie/anim/fresh_idle.png"])
	var usual: Dictionary = (load("res://assets/characters/hero_rookie/anim/anim.json") as JSON).data["clips"]
	for worn in ["leather", "iron"]:
		rig.set_outfit({"outfit": worn, "refine": 0})
		assert_eq(rig._outfit_folder(), worn)
		assert_eq(rig._outfit_clips.keys(), usual.keys(), worn + " is drawn for every clip")
		for clip: String in usual:
			var sheet := rig._clip_sheet_for(StringName(clip))
			assert_true(sheet != null and sheet.resource_path.contains("/anim/%s/" % worn), "%s %s" % [worn, clip])
	# An outfit not drawn yet: the usual clips stand in.
	rig.set_outfit({"outfit": "frost", "refine": 0})
	assert_eq(rig._outfit_clips, {})
	assert_eq(rig._clip_sheet_for(&"idle"), rig._sheets["res://assets/characters/hero_rookie/anim/fresh_idle.png"])
	rig._body.free()
	rig.free()


func test_a_clip_of_several_blows_times_each_and_one_blow_its_impact() -> void:
	var rig := _rig()
	rig._anim["clips"]["combo"] = {"frames": 16, "fps": 24, "impact": 4, "impacts": [4, 9, 14]}
	rig._sheets["res://assets/characters/hero_rookie/anim/fresh_combo.png"] = rig._sheets["res://assets/characters/hero_rookie/anim/fresh_attack.png"]
	assert_eq(rig.impact_times(&"combo"), [4.0 / 24.0, 9.0 / 24.0, 14.0 / 24.0] as Array[float])
	assert_eq(rig.impact_times(&"attack"), [0.25] as Array[float])
	assert_eq(rig.impact_times(&"idle"), [] as Array[float])
	assert_eq(rig.impact_times(&"block"), [] as Array[float], "not drawn")
	rig._body.free()
	rig.free()


func test_moves_drawn_without_the_broom_wait_while_he_holds_it() -> void:
	var rig := _rig()
	rig._base_clips = rig._anim["clips"].duplicate(true)
	assert_true(rig.fits_look(&"attack"))
	rig.variant = "broom"
	rig._variant_clips = {"idle": {"frames": 8, "fps": 12, "loop": true}}
	assert_true(rig.fits_look(&"idle"), "the broom has its own idle")
	assert_true(not rig.fits_look(&"attack"), "the usual attack is drawn without the broom")
	assert_true(not rig.fits_look(&"combo"), "nor anything not drawn at all")
	rig._body.free()
	rig.free()


func test_the_hero_has_every_new_move_drawn_in_every_outfit() -> void:
	var rig := CharacterRig.new()
	rig._ready()
	rig.setup("hero_rookie", 1)
	for worn in ["rookie", "leather", "iron"]:
		rig.set_outfit({"outfit": worn, "refine": 0})
		for clip in [&"combo", &"block", &"dash", &"skill_armor_breaker", &"skill_second_wind", &"skill_thunder_slash", &"skill_iron_guard", &"skill_blade_vortex", &"skill_starfall_strike"]:
			assert_true(rig.fits_look(clip), "%s %s" % [worn, clip])
		assert_eq(rig.impact_times(&"combo").size(), 3, worn + " combo cuts three times")
		assert_eq(rig.impact_times(&"skill_blade_vortex").size(), 3, worn + " vortex cuts three times")
	rig._body.free()
	rig.free()


func test_a_light_384_sheet_shows_as_big_as_a_512_one() -> void:
	var rig := _rig()
	rig._update_clip(0.0)
	var full := rig.frame_layout()
	rig._clip_info = rig._clip_info.duplicate()
	rig._clip_info["frame_size"] = [384, 384]
	var light := rig.frame_layout()
	assert_eq(light[0].size, Vector2(384, 384), "read at its own size")
	assert_eq(light[1], full[1], "drawn the same size and place")
	rig._body.free()
	rig.free()
