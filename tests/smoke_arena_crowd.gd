## Run: godot --headless --path . -s res://tests/smoke_arena_crowd.gd
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _crowd(arena: ArenaBackdrop) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	for node in arena.find_children("*", "Sprite2D", true, false):
		if node.texture and "/crowd_" in node.texture.resource_path:
			result.append(node)
	return result

func _expect(arena: ArenaBackdrop, folder: String, pose: String) -> void:
	var sprites := _crowd(arena)
	assert(sprites.size() == 3, "Expected exactly three spectators")
	for sprite in sprites:
		assert(sprite.texture.resource_path.contains(folder))
		assert(sprite.texture.resource_path.ends_with("_%s.png" % pose))
		assert(sprite.scale.is_equal_approx(Vector2.ONE * 0.55))

func _run() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var battle: BattleView = game.get_node("Battle")
	var manager: BattleManager = game.get_node("BattleManager")
	_expect(battle._backdrop, "crowd_farmers", "idle")
	var report := TurnReport.new()
	report.damage = 10
	report.link_color = Cell.BlockColor.RED
	report.link_length = 6
	await battle.play_report(report)
	_expect(battle._backdrop, "crowd_farmers", "cheer")
	var heal_combo := TurnReport.new()
	heal_combo.heal = 10
	heal_combo.link_color = Cell.BlockColor.GREEN
	heal_combo.link_length = 6
	await battle.play_report(heal_combo)
	_expect(battle._backdrop, "crowd_farmers", "cheer")
	await create_timer(0.6).timeout
	report.monster_attack = 10
	battle._hero_hit(report, "bonk", &"dizzy")
	_expect(battle._backdrop, "crowd_farmers", "boo")
	manager._start()
	_expect(battle._backdrop, "crowd_farmers", "idle")
	manager.encounter_index = 1
	manager._start()
	await process_frame
	await process_frame
	_expect(battle._backdrop, "crowd_orcs", "idle")
	report.monster_attack = 0
	report.critical = true
	battle._land_hit(report, "pow")
	_expect(battle._backdrop, "crowd_orcs", "cheer")
	report.monster_attack = 10
	battle._hero_hit(report, "bonk", &"dizzy")
	_expect(battle._backdrop, "crowd_orcs", "boo")
	await create_timer(1.6).timeout
	_expect(battle._backdrop, "crowd_orcs", "idle")
	manager.encounter_index = 0
	manager._start()
	await process_frame
	await process_frame
	_expect(battle._backdrop, "crowd_farmers", "idle")
	report = TurnReport.new()
	report.outcome = BattleState.Outcome.WON
	await battle.play_report(report)
	_expect(battle._backdrop, "crowd_farmers", "cheer")
	await create_timer(1.5).timeout
	manager._start()
	report.outcome = BattleState.Outcome.LOST
	await battle.play_report(report)
	_expect(battle._backdrop, "crowd_farmers", "boo")
	manager._start()
	_expect(battle._backdrop, "crowd_farmers", "idle")
	await create_timer(1.5).timeout
	print("Actual main scene: training and Orc crowds, combo, critical, hero hit, timeout encounter restart, win and loss passed")
	game.queue_free()
	await process_frame
	quit(0)
