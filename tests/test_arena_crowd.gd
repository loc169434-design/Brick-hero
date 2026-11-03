extends "res://tests/test_case.gd"


func _spectators(arena: ArenaBackdrop) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	for node in arena.find_children("*", "Sprite2D", true, false):
		if node.texture and "/crowd_" in node.texture.resource_path:
			result.append(node)
	return result


func test_both_arenas_load_three_distant_spectators() -> void:
	for id in ["training_field", "orc_camp"]:
		var arena := ArenaBackdrop.new()
		arena.load_background(id)
		var spectators := _spectators(arena)
		assert_eq(spectators.size(), 3, id)
		for sprite in spectators:
			assert_eq(sprite.scale, Vector2.ONE * 0.55)
			assert_eq(sprite.offset, -Vector2(128, 248))
			assert_true(sprite.position.y >= 330 and sprite.position.y <= 370)
			assert_true(sprite.position.x < 170 or (sprite.position.x > 370 and sprite.position.x < 710) or sprite.position.x > 910)
		arena.free()


func test_reactions_expire_and_new_reactions_replace_them() -> void:
	for id in ["training_field", "orc_camp"]:
		var arena := ArenaBackdrop.new()
		arena.load_background(id)
		arena.react_crowd(&"cheer", 0.2)
		for sprite in _spectators(arena):
			assert_true(sprite.texture.resource_path.ends_with("_cheer.png"))
		arena._process(0.1)
		arena.react_crowd(&"boo", 0.2)
		for sprite in _spectators(arena):
			assert_true(sprite.texture.resource_path.ends_with("_boo.png"))
		arena._process(0.3)
		for sprite in _spectators(arena):
			assert_true(sprite.texture.resource_path.ends_with("_idle.png"))
		arena.react_crowd(&"cheer")
		arena.react_crowd(&"idle", 0.0)
		for sprite in _spectators(arena):
			assert_true(sprite.texture.resource_path.ends_with("_idle.png"))
		arena.free()
