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
	var neck: Vector2 = rig._joints["neck"]
	var waist: Vector2 = rig._joints["waist"]
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


func test_a_helmet_swaps_the_head_and_the_face_follows_the_clip() -> void:
	var rig := _rig()
	rig.set_outfit(Gear.outfit(["wood_sword"]))
	assert_eq(rig.head_texture().resource_path, HeroRig.DIR + "head/bare.png")
	assert_eq(rig.face_texture().resource_path, HeroRig.DIR + "faces/normal.png")
	rig.set_outfit(Gear.outfit(["wood_sword", "leather_helmet"]))
	assert_eq(rig.head_texture().resource_path, HeroRig.DIR + "head/leather_helmet.png",
		"a helmet comes on its own head, not as a layer over the hair")
	assert_eq(rig.face_texture().resource_path, HeroRig.DIR + "faces/normal.png", "the same face on every head")
	rig.play(&"attack")
	assert_eq(rig.mood, "angry")
	assert_eq(rig.head_texture().resource_path, HeroRig.DIR + "head/leather_helmet.png")
	assert_eq(rig.face_texture().resource_path, HeroRig.DIR + "faces/angry.png")
	rig.play(&"hurt")
	assert_eq(rig.mood, "hurt")
	rig.play(&"cheer")
	assert_eq(rig.mood, "happy")
	rig.play(&"idle")
	assert_eq(rig.mood, "normal")
	rig.set_mood("not a face")
	assert_eq(rig.mood, "normal")
	rig.free()


func test_the_clips_he_plays_move_his_own_bones() -> void:
	var rig := _rig()
	var player: AnimationPlayer = rig._player
	for clip: StringName in [&"idle", &"attack", &"hurt", &"cheer"]:
		assert_true(player.has_animation(clip), "plays %s" % clip)
	for clip: StringName in player.get_animation_list():
		var animation := player.get_animation(clip)
		for track in animation.get_track_count():
			if animation.track_get_type(track) == Animation.TYPE_METHOD:
				continue
			var path := animation.track_get_path(track)
			assert_true(rig._root.get_node_or_null(NodePath(path.get_concatenated_names())) != null,
				"%s moves a bone he has: %s" % [clip, path])
	var blow := rig.impact_seconds(&"attack")
	assert_true(blow > 0.0 and blow < player.get_animation(&"attack").length, "the blow lands partway through: %s" % blow)
	rig.free()


func test_every_head_and_armor_is_drawn() -> void:
	for kind: String in ["bare"] + Gear.ladder("helmet"):
		var path := HeroRig.DIR + "head/%s.png" % kind
		assert_true(ResourceLoader.exists(path), path)
	for face: String in HeroRig.MOODS:
		var path := HeroRig.DIR + "faces/%s.png" % face
		assert_true(ResourceLoader.exists(path), path)
	for armor: String in Gear.ladder("armor"):
		for part: String in HeroRig.GEAR_PARTS["armor"]:
			var path := HeroRig.DIR + "gear/%s/%s.png" % [armor, part]
			assert_true(ResourceLoader.exists(path), path)
