extends "res://tests/test_case.gd"
## The made-up sound effects and how the monster's tiles answer a move.


func _report(damage := 0, shield_damage := 0, monster_attack := 0) -> TurnReport:
	var report := TurnReport.new()
	report.damage = damage
	report.shield_damage = shield_damage
	report.monster_attack = monster_attack
	return report


func _state(monster_hp := 80, hero_hp := 100, counterattacks := true) -> BattleState:
	var monster := MonsterData.new()
	monster.max_hp = 80
	monster.counterattacks = counterattacks
	var state := BattleState.new(BattleRules.new(), monster)
	state.monster_hp = monster_hp
	state.hero_hp = hero_hp
	return state


func test_every_recipe_builds_a_sound() -> void:
	for sound: String in SfxBank.names():
		var stream := SfxBank.build(sound)
		assert_true(stream != null, sound)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, sound)
		assert_true(stream.get_length() > 0.03 and stream.get_length() < 2.0, "%s lasts %.2f s" % [sound, stream.get_length()])


func test_sounds_are_not_silent() -> void:
	for sound: String in SfxBank.names():
		var data := SfxBank.build(sound).data
		var loudest := 0
		for i in range(0, data.size(), 2):
			loudest = maxi(loudest, absi(data.decode_s16(i)))
		assert_true(loudest > 3000, "%s peaks at %d" % [sound, loudest])


func test_sounds_come_out_the_same_every_time() -> void:
	assert_eq(SfxBank.build("pop").data, SfxBank.build("pop").data)


func test_unknown_sound_is_null() -> void:
	assert_true(SfxBank.build("no_such_sound") == null)


func test_a_hit_makes_the_tiles_hurt() -> void:
	assert_eq(BattleManager.board_reaction(_report(10), _state(60)), [&"hurt", 2])


func test_a_hit_that_leaves_it_nearly_dead_is_a_near_miss() -> void:
	assert_eq(BattleManager.board_reaction(_report(10), _state(8)), [&"near_miss", 2])


func test_a_move_that_does_not_hurt_it_gets_laughed_at() -> void:
	assert_eq(BattleManager.board_reaction(_report(), _state()), [&"taunt", 2])


func test_chipping_the_shield_is_not_laughed_at() -> void:
	assert_eq(BattleManager.board_reaction(_report(0, 4), _state()), [&"", 0])


func test_training_dummy_never_taunts() -> void:
	assert_eq(BattleManager.board_reaction(_report(), _state(80, 100, false)), [&"", 0])


func test_striking_a_nearly_beaten_hero_gloats() -> void:
	assert_eq(BattleManager.board_reaction(_report(10, 0, 12), _state(60, 20)), [&"gloat", 1])


func test_bigger_moves_earn_bigger_praise() -> void:
	var small := MoveResult.new()
	var step := ClearStep.new()
	for i in 3:
		step.cleared.append(Vector2i(i, 0))
		step.cleared_cells.append(Cell.new(0))
	small.steps.append(step)
	small.path.assign([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	assert_eq(BoardJuice.praise_for(small), -1, "a plain three is not praised")
	var chain := MoveResult.new()
	for i in 4:
		chain.steps.append(step)
	assert_eq(BoardJuice.praise_for(chain), 3, "four rounds")
	var blast := MoveResult.new()
	var big := ClearStep.new()
	for i in 34:
		big.cleared.append(Vector2i(i % 7, i / 7))
		big.cleared_cells.append(Cell.new(1))
	big.fusions.append({"at": Vector2i.ZERO})
	blast.steps.append(big)
	assert_eq(BoardJuice.praise_for(blast), 4, "a fusion clearing half the board")
