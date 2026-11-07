extends "res://tests/test_case.gd"
## The hero as a puppet on a skeleton (HeroRig).


func _rig() -> HeroRig:
	var rig := HeroRig.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	return rig


func test_every_part_hangs_on_its_joint() -> void:
	var rig := _rig()
	for part: String in HeroRig.PARTS:
		assert_true(rig.bone(part) != null, part)
	# At rest a bone sits at its joint's offset from its parent's, so layers land where drawn.
	var neck: Vector2 = HeroRig.JOINTS["neck"]
	var waist: Vector2 = HeroRig.JOINTS["waist"]
	assert_eq(rig.bone("head").position, neck - waist)
	assert_eq(rig.bone("head").get_parent(), rig.bone("torso"))
	assert_eq(rig.bone("sword").get_parent(), rig.bone("sword_hand"), "the sword is held in the hand")
	rig.free()


func test_the_outfit_can_change_at_any_time() -> void:
	var rig := _rig()
	rig.set_outfit(Gear.outfit(["iron_sword", "iron_armor", "iron_helmet"]))
	assert_eq(rig.outfit["weapon"], "iron_sword")
	assert_eq(rig.outfit["helmet"], "iron_helmet")
	rig.set_outfit(Gear.outfit(["wood_sword"]))
	assert_eq(rig.outfit["helmet"], "")
	rig.free()


func test_the_strike_calls_its_blow_once_at_the_impact() -> void:
	var rig := _rig()
	var attack: Animation = rig._player.get_animation(&"attack")
	var calls := []
	for track in attack.get_track_count():
		if attack.track_get_type(track) == Animation.TYPE_METHOD:
			for key in attack.track_get_key_count(track):
				calls.append([attack.track_get_key_time(track, key), attack.track_get_key_value(track, key)["method"]])
	assert_eq(calls.size(), 1)
	assert_true(absf(calls[0][0] - rig.impact_seconds(&"attack")) < 0.001)
	assert_eq(calls[0][1], &"_on_impact")
	assert_eq(attack.loop_mode, Animation.LOOP_NONE)
	assert_eq(rig._player.get_animation(&"idle").loop_mode, Animation.LOOP_LINEAR)
	# Every clip starts and ends at rest, so moving between them never jumps.
	for name: StringName in HeroRig.CLIPS:
		var keys: Dictionary = HeroRig.CLIPS[name]["keys"]
		var times: Array = keys.keys()
		times.sort()
		for part: String in keys[times[0]]:
			assert_eq(keys[times[0]][part], keys[times[-1]][part], "%s %s returns to rest" % [name, part])
	rig.free()
