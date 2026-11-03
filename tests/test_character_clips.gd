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
	rig.setup("scarecrow", 1)
	assert_true(not rig.has_clip(&"idle"))
	rig._update_clip(0.5)
	assert_eq(rig._clip, &"")
	rig._body.free()
	rig.free()
