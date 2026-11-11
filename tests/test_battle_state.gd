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


## Builds a move whose chain rounds clear the given colors, e.g. [[R, R, R, R], [G, G, G, G]].
func _move(rounds: Array = []) -> MoveResult:
	var result := MoveResult.new()
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
	var report := battle.apply_move(_move([[R, R, R, R]]))
	assert_eq(report.damage, 8)
	assert_eq(battle.monster_hp, 72)


func test_shield_halves_red_damage() -> void:
	var battle := _battle(_monster(80, 3))
	assert_eq(battle.apply_move(_move([[R, R, R, R]])).damage, 4)


func test_purple_strips_the_shield_before_red_lands() -> void:
	var battle := _battle(_monster(80, 1))
	var report := battle.apply_move(_move([[P, P, P, P, P, R, R, R, R]]))
	assert_eq(report.shield_damage, 10)
	assert_eq(report.layers_broken, 1)
	assert_eq(battle.shield, 0)
	assert_eq(report.damage, 8, "no shield left, so red hits in full")


func test_each_chain_round_counts_more() -> void:
	var battle := _battle(_monster())
	assert_eq(battle.apply_move(_move([[R, R, R, R], [R, R, R, R]])).damage, 8 + 16)


func test_chain_of_three_smashes_a_shield_layer() -> void:
	var battle := _battle(_monster(80, 3))
	var report := battle.apply_move(_move([[Y, Y, Y, Y], [Y, Y, Y, Y], [Y, Y, Y, Y]]))
	assert_eq(report.layers_broken, 1)
	assert_eq(battle.shield_layers(), 2)


func test_green_heals_up_to_full() -> void:
	var battle := _battle(_monster())
	battle.hero_hp = 95
	var report := battle.apply_move(_move([[G, G, G, G, G, G, G, G]]))
	assert_eq(report.heal, 5)
	assert_eq(battle.hero_hp, 100)


func test_yellow_earns_gold() -> void:
	var battle := _battle(_monster())
	battle.apply_move(_move([[Y, Y, Y, Y]]))
	assert_eq(battle.gold, 4)


func test_monster_warns_then_attacks_when_countdown_runs_out() -> void:
	var battle := _battle(_monster(80, 0, 12, 4))
	for i in 3:
		assert_eq(battle.apply_move(_move()).monster_attack, 0)
	assert_true(battle.attacks_next_move())
	var report := battle.apply_move(_move())
	assert_eq(report.monster_attack, 12)
	assert_eq(battle.hero_hp, 88)
	assert_eq(battle.countdown, 4, "countdown restarts")
	assert_true(not battle.attacks_next_move())


func test_killing_blow_wins_before_the_monster_strikes() -> void:
	var battle := _battle(_monster(8, 0, 12, 1))
	var report := battle.apply_move(_move([[R, R, R, R, R, R]]))
	assert_eq(report.damage, 8, "damage stops at the monster's last hit point")
	assert_eq(report.outcome, BattleState.Outcome.WON)
	assert_eq(report.monster_attack, 0)
	assert_eq(battle.hero_hp, 100)


func test_hero_falling_loses_and_ends_the_fight() -> void:
	var battle := _battle(_monster(80, 0, 12, 1))
	battle.hero_hp = 10
	assert_eq(battle.apply_move(_move()).outcome, BattleState.Outcome.LOST)
	assert_eq(battle.hero_hp, 0)
	assert_eq(battle.apply_move(_move([[R, R, R, R]])).damage, 0, "nothing happens after the fight ends")


func test_full_board_loses() -> void:
	var battle := _battle(_monster())
	battle.lose()
	assert_eq(battle.outcome, BattleState.Outcome.LOST)


func test_training_dummy_never_hits_back() -> void:
	var dummy := _monster(80, 0, 12, 1)
	dummy.counterattacks = false
	var battle := _battle(dummy)
	for i in 10:
		assert_true(not battle.attacks_next_move())
		assert_eq(battle.apply_move(_move()).monster_attack, 0)
	assert_eq(battle.hero_hp, 100)
	assert_eq(battle.moves, 10)


func test_scarecrow_data_loads() -> void:
	var scarecrow: MonsterData = load("res://data/monsters/scarecrow.tres")
	assert_true(not scarecrow.counterattacks)
	assert_true(scarecrow.hints.size() >= 5)
	assert_eq(scarecrow.tile_theme, "training")


func test_orc_data_loads() -> void:
	var orc: MonsterData = load("res://data/monsters/orc_shield.tres")
	var battle := BattleState.new(load("res://data/balance.tres"), orc)
	assert_eq(battle.shield_layers(), 3)
	assert_eq(orc.tile_theme, "orc_shield")


func test_clearing_a_critical_tile_doubles_the_red_damage() -> void:
	var battle := _battle(_monster(80))
	var move := _move([[R, R, R]])
	move.steps[0].cleared_cells[1].critical = true
	var report := battle.apply_move(move)
	assert_true(report.critical)
	assert_eq(report.damage, 12, "3 red × 2 × crit 2")


func test_no_red_no_critical_hit() -> void:
	var battle := _battle(_monster(80))
	battle.rules.crit_chance = 1.0
	assert_true(not battle.apply_move(_move([[G, G, G]])).critical)
	assert_true(battle.apply_move(_move([[R, R, R]])).critical, "a sure lucky hit when red lands")


func test_monster_critical_comes_every_few_attacks_and_is_announced() -> void:
	var monster := _monster(80, 0, 12, 1)
	monster.crit_every = 3
	var battle := _battle(monster)
	assert_true(not battle.next_attack_is_critical())
	assert_eq(battle.apply_move(_move()).monster_attack, 12)
	assert_eq(battle.apply_move(_move()).monster_attack, 12)
	assert_true(battle.next_attack_is_critical(), "the third attack is announced as critical")
	var report := battle.apply_move(_move())
	assert_true(report.monster_critical)
	assert_eq(report.monster_attack, 18)
	assert_true(not battle.next_attack_is_critical())


func test_report_names_the_link_color() -> void:
	var battle := _battle(_monster(80))
	var move := _move([[P, P, P]])
	move.steps[0].clusters.append({"color": P, "cells": move.steps[0].cleared.duplicate()})
	assert_eq(battle.apply_move(move).link_color, P)


func test_the_link_picks_the_heros_move() -> void:
	var report := TurnReport.new()
	report.link_color = R
	report.link_length = 3
	assert_eq(BattleView.pick_move(report), &"slash")
	report.link_length = 5
	assert_eq(BattleView.pick_move(report), &"throw")
	report.link_length = 6
	assert_eq(BattleView.pick_move(report), &"leap")
	report.link_length = 7
	assert_eq(BattleView.pick_move(report), &"combo")
	report.link_length = 4
	report.chain = 2
	assert_eq(BattleView.pick_move(report), &"combo", "a chain is a combo too")
	report.chain = 1
	report.link_color = P
	report.shield_damage = 6
	assert_eq(BattleView.pick_move(report), &"bash")


func test_plain_squares_and_fusions_fill_rage_up_to_a_cap_per_move() -> void:
	var battle := _battle(_monster(500))
	var move := _move([[R, R, R, R], [G, G, G]])
	move.steps[0].cleared_cells.append(Cell.new(R, Cell.Special.BOMB))
	move.steps[0].fusions.append({"at": Vector2i.ZERO, "with": Vector2i.RIGHT, "kinds": []})
	var report := battle.apply_move(move)
	# 7 plain squares × 2, and 12 for the fusion; the bomb itself adds nothing.
	assert_eq(report.rage_gained, 7 * 2 + 12)
	assert_eq(battle.rage, 26)
	var huge: Array = []
	huge.resize(30)
	huge.fill(Y)
	assert_eq(battle.apply_move(_move([huge])).rage_gained, 40, "one move fills at most 40")


func test_rage_stops_at_full_and_the_skill_waits_for_it() -> void:
	var battle := _battle(_monster(500))
	battle.rage = 95
	assert_true(not battle.skill_ready())
	assert_eq(battle.use_skill().skill, "", "nothing happens before the bar is full")
	assert_eq(battle.apply_move(_move([[Y, Y, Y, Y]])).rage_gained, 5)
	assert_eq(battle.rage, 100)
	assert_true(battle.skill_ready())


func test_armor_breaker_strips_a_layer_then_hits_like_red_squares() -> void:
	var battle := _battle(_monster(60, 3))
	battle.rage = 100
	var report := battle.use_skill()
	assert_eq(report.skill, "armor_breaker")
	assert_eq(report.shield_damage, 10)
	assert_eq(report.layers_broken, 1)
	assert_eq(report.damage, 8, "8 red squares × 2, halved: two layers are left")
	assert_eq(battle.rage, 0)
	assert_eq(battle.countdown, 4, "a skill isn't a move: the countdown doesn't tick")
	assert_eq(battle.moves, 0)
	battle.shield = 10
	battle.rage = 100
	assert_eq(battle.use_skill().damage, 16, "the last layer goes first, so it hits in full")


func test_armor_breaker_hits_harder_with_a_better_sword() -> void:
	var battle := _battle(_monster(60))
	battle.rules.red_damage = 3.0
	battle.rage = 100
	assert_eq(battle.use_skill().damage, 24)


func test_armor_breaker_can_win_the_fight() -> void:
	var battle := _battle(_monster(10))
	battle.rage = 100
	assert_eq(battle.use_skill().outcome, BattleState.Outcome.WON)
	assert_true(not battle.skill_ready(), "nothing more once it's won")


func test_second_wind_heals_and_waits_until_the_hero_is_hurt() -> void:
	var battle := _battle(_monster())
	battle.rules.skill = "second_wind"
	battle.rage = 100
	assert_true(not battle.skill_ready(), "full health: nothing to heal")
	battle.hero_hp = 90
	var report := battle.use_skill()
	assert_eq(report.heal, 10, "up to full")
	assert_eq(battle.hero_hp, 100)
	assert_eq(battle.rage, 0)


func _skilled(skill: String, monster: MonsterData) -> BattleState:
	var state := _battle(monster)
	state.rules = state.rules.duplicate()
	state.rules.skill = skill
	state.rage = state.rules.rage_max
	return state


func test_thunder_slash_hits_and_holds_the_attack_back_once() -> void:
	var orc := _monster(80, 0, 12, 3)
	orc.counterattacks = true
	var state := _skilled("thunder_slash", orc)
	var report := state.use_skill()
	assert_eq(report.damage, roundi(state.rules.thunder_slash_squares * state.rules.red_damage))
	assert_true(report.delayed)
	assert_eq(state.countdown, 4)
	state.rage = state.rules.rage_max
	state.use_skill()
	assert_eq(state.countdown, 4, "not twice for the same attack")


func test_iron_guard_takes_the_edge_off_the_next_attack() -> void:
	var orc := _monster(80, 0, 20, 1)
	orc.counterattacks = true
	var state := _skilled("iron_guard", orc)
	state.use_skill()
	assert_eq(state.guard, state.rules.iron_guard_block)
	assert_true(not state.skill_ready(), "no second guard while one is up")
	var report := state.apply_move(_move([[G, G, G]]))
	assert_eq(report.guarded, state.rules.iron_guard_block)
	assert_eq(report.monster_attack, 20 - state.rules.iron_guard_block)
	assert_eq(state.guard, 0, "spent")


func test_blade_vortex_cuts_three_times() -> void:
	var state := _skilled("blade_vortex", _monster(80))
	var report := state.use_skill()
	assert_eq(report.hits, 3)
	assert_eq(report.damage, roundi(3 * state.rules.blade_vortex_squares * state.rules.red_damage))


func test_starfall_goes_through_the_shield_and_leaves_it() -> void:
	var state := _skilled("starfall_strike", _monster(80, 3))
	var shield := state.shield
	var report := state.use_skill()
	assert_eq(report.damage, roundi(state.rules.starfall_squares * state.rules.red_damage), "full damage, no halving")
	assert_eq(state.shield, shield)
	assert_true(report.pierced)


func test_tumble_cut_hits_and_washes_out_the_poison() -> void:
	var state := _skilled("tumble_cut", _monster(80))
	state.poison_hero(4)
	var report := state.use_skill()
	assert_eq(report.damage, roundi(state.rules.tumble_cut_squares * state.rules.red_damage))
	assert_true(report.cured)
	assert_eq(state.poison_turns, 0)
	state.rage = state.rules.rage_max
	assert_true(not state.use_skill().cured, "nothing to wash out the second time")


func test_shield_charge_smashes_two_layers_and_holds_the_attack_back() -> void:
	var orc := _monster(80, 3, 12, 3)
	orc.counterattacks = true
	var state := _skilled("shield_charge", orc)
	var report := state.use_skill()
	assert_eq(report.layers_broken, 2)
	assert_eq(state.shield_layers(), 1)
	assert_eq(report.damage, roundi(state.rules.shield_charge_squares * state.rules.red_damage * state.rules.shielded_damage_factor), "a layer is left, so it's halved")
	assert_eq(report.held, 1)
	assert_eq(state.countdown, 4)


func test_royal_rally_heals_and_strengthens_the_next_three_moves() -> void:
	var state := _skilled("royal_rally", _monster(200))
	state.hero_hp = 50
	var report := state.use_skill()
	assert_eq(report.heal, state.rules.royal_rally_heal)
	assert_eq(report.rallied, 3)
	for i in 3:
		assert_eq(state.apply_move(_move([[R, R, R, R]])).damage, 12, "x1.5 on move %d" % (i + 1))
	assert_eq(state.apply_move(_move([[R, R, R, R]])).damage, 8, "back to normal")


func test_obsidian_cleave_pierces_and_costs_health() -> void:
	var state := _skilled("obsidian_cleave", _monster(80, 3))
	var shield := state.shield
	var report := state.use_skill()
	assert_eq(report.damage, roundi(state.rules.obsidian_cleave_squares * state.rules.red_damage), "full damage through the shield")
	assert_eq(state.shield, shield)
	assert_eq(report.self_damage, state.rules.obsidian_cleave_cost)
	assert_eq(state.hero_hp, state.rules.hero_max_hp - state.rules.obsidian_cleave_cost)
	state.rage = state.rules.rage_max
	state.hero_hp = state.rules.obsidian_cleave_cost
	assert_true(not state.skill_ready(), "not with too little health to pay for it")


func test_frost_nova_freezes_the_monster_for_two_moves_once() -> void:
	var orc := _monster(80, 0, 12, 3)
	orc.counterattacks = true
	var state := _skilled("frost_nova", orc)
	var report := state.use_skill()
	assert_eq(report.held, 2)
	assert_eq(state.countdown, 5)
	state.rules.skill = "thunder_slash"
	state.rage = state.rules.rage_max
	assert_true(not state.use_skill().delayed, "the same attack can't be held twice")


func test_every_outfit_past_the_rookie_has_its_own_named_skill() -> void:
	for id in Gear.ladder("outfit"):
		var own := Gear.outfit_skill(id)
		assert_eq(own.is_empty(), id == "rookie", id)
		if own:
			assert_true(BattleState.SKILLS.has(own), own)
			assert_true(not Gear.SKILL_AFTER.has(own), "%s is not learned by winning" % own)
			assert_eq(Gear.skill_outfit(own), id)


func test_every_skill_can_be_learned_and_named() -> void:
	for id: String in Gear.SKILL_AFTER:
		assert_true(BattleState.SKILLS.has(id), id)
		var after: String = Gear.SKILL_AFTER[id]
		assert_true(after.is_empty() or Campaign.has_level(after), "%s is taught by a real level" % id)


func test_the_shield_takes_blows_the_armour_or_the_guard_mostly_stopped() -> void:
	var report := TurnReport.new()
	report.monster_attack = 6
	assert_true(not BattleView.blocks(report, 0), "no armour, no block")
	assert_true(not BattleView.blocks(report, 5), "more got through than the armour stopped")
	assert_true(BattleView.blocks(report, 6))
	report.guarded = 4
	assert_true(BattleView.blocks(report, 0), "Hộ Thể caught some of it")
	report.monster_critical = true
	assert_true(not BattleView.blocks(report, 9), "a critical blow gets through the guard")


func test_longer_chains_string_more_blows() -> void:
	var report := TurnReport.new()
	report.link_length = 7
	assert_eq(BattleView.combo_hits(report), 3)
	report.chain = 4
	assert_eq(BattleView.combo_hits(report), 5)
	report.chain = 20
	assert_eq(BattleView.combo_hits(report), BattleView.MAX_COMBO_HITS)
	assert_eq(BattleView.combo_sequence(3), [&"attack", &"attack", &"kick"] as Array[StringName])
	var five := BattleView.combo_sequence(5)
	assert_eq(five.size(), 5)
	assert_eq(five[-1], &"leap", "five and more end on a leaping slam")
	for hits in range(3, BattleView.MAX_COMBO_HITS + 1):
		assert_eq(BattleView.combo_sequence(hits).size(), hits)
