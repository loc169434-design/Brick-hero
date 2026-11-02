extends "res://tests/test_case.gd"

const R := Cell.BlockColor.RED
const G := Cell.BlockColor.GREEN
const Y := Cell.BlockColor.YELLOW
const P := Cell.BlockColor.PURPLE


func _monster(hp := 80, layers := 0, attack := 12, countdown := 4) -> MonsterData:
	var m := MonsterData.new()
	m.max_hp = hp
	m.shield_layers = layers
	m.attack = attack
	m.countdown = countdown
	return m


func _battle(monster: MonsterData) -> BattleState:
	return BattleState.new(BattleRules.new(), monster)


## Builds a drop whose chain rounds clear the given colors, e.g. [[R, R, R, R], [G, G, G, G]].
func _drop(rounds: Array = [], combo := 1) -> DropResult:
	var result := DropResult.new()
	result.combo = combo if not rounds.is_empty() else 0
	for i in rounds.size():
		var step := ClearStep.new()
		step.chain = i + 1
		for color in rounds[i]:
			step.cleared.append(Vector2i(step.cleared.size(), 0))
			step.cleared_cells.append(Cell.new(color))
		result.steps.append(step)
	return result


func test_red_squares_hit_the_monster() -> void:
	var battle := _battle(_monster())
	var report := battle.apply_drop(_drop([[R, R, R, R]]))
	assert_eq(report.damage, 8)
	assert_eq(battle.monster_hp, 72)


func test_shield_halves_red_damage() -> void:
	var battle := _battle(_monster(80, 3))
	assert_eq(battle.apply_drop(_drop([[R, R, R, R]])).damage, 4)


func test_purple_strips_the_shield_before_red_lands() -> void:
	var battle := _battle(_monster(80, 1))
	var report := battle.apply_drop(_drop([[P, P, P, P, P, R, R, R, R]]))
	assert_eq(report.shield_damage, 10)
	assert_eq(report.layers_broken, 1)
	assert_eq(battle.shield, 0)
	assert_eq(report.damage, 8, "no shield left, so red hits in full")


func test_each_chain_round_counts_more() -> void:
	var battle := _battle(_monster())
	assert_eq(battle.apply_drop(_drop([[R, R, R, R], [R, R, R, R]])).damage, 8 + 16)


func test_combo_adds_a_quarter_per_drop_in_a_row() -> void:
	var battle := _battle(_monster())
	assert_eq(battle.apply_drop(_drop([[R, R, R, R]], 3)).damage, 12)


func test_chain_of_three_smashes_a_shield_layer() -> void:
	var battle := _battle(_monster(80, 3))
	var report := battle.apply_drop(_drop([[Y, Y, Y, Y], [Y, Y, Y, Y], [Y, Y, Y, Y]]))
	assert_eq(report.layers_broken, 1)
	assert_eq(battle.shield_layers(), 2)


func test_green_heals_up_to_full() -> void:
	var battle := _battle(_monster())
	battle.hero_hp = 95
	var report := battle.apply_drop(_drop([[G, G, G, G, G, G, G, G]]))
	assert_eq(report.heal, 5)
	assert_eq(battle.hero_hp, 100)


func test_yellow_earns_gold() -> void:
	var battle := _battle(_monster())
	battle.apply_drop(_drop([[Y, Y, Y, Y]]))
	assert_eq(battle.gold, 4)


func test_monster_warns_then_attacks_when_countdown_runs_out() -> void:
	var battle := _battle(_monster(80, 0, 12, 4))
	for i in 3:
		assert_eq(battle.apply_drop(_drop()).monster_attack, 0)
	assert_true(battle.attacks_next_drop())
	var report := battle.apply_drop(_drop())
	assert_eq(report.monster_attack, 12)
	assert_eq(battle.hero_hp, 88)
	assert_eq(battle.countdown, 4, "countdown restarts")
	assert_true(not battle.attacks_next_drop())


func test_killing_blow_wins_before_the_monster_strikes() -> void:
	var battle := _battle(_monster(8, 0, 12, 1))
	var report := battle.apply_drop(_drop([[R, R, R, R, R, R]]))
	assert_eq(report.damage, 8, "damage stops at the monster's last hit point")
	assert_eq(report.outcome, BattleState.Outcome.WON)
	assert_eq(report.monster_attack, 0)
	assert_eq(battle.hero_hp, 100)


func test_hero_falling_loses_and_ends_the_fight() -> void:
	var battle := _battle(_monster(80, 0, 12, 1))
	battle.hero_hp = 10
	assert_eq(battle.apply_drop(_drop()).outcome, BattleState.Outcome.LOST)
	assert_eq(battle.hero_hp, 0)
	assert_eq(battle.apply_drop(_drop([[R, R, R, R]])).damage, 0, "nothing happens after the fight ends")


func test_full_board_loses() -> void:
	var battle := _battle(_monster())
	battle.lose()
	assert_eq(battle.outcome, BattleState.Outcome.LOST)


func test_orc_data_loads() -> void:
	var orc: MonsterData = load("res://data/monsters/orc_shield.tres")
	var battle := BattleState.new(load("res://data/balance.tres"), orc)
	assert_eq(battle.shield_layers(), 3)
	assert_eq(orc.tile_theme, "orc_shield")
