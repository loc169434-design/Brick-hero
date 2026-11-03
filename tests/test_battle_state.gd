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
	report.chain = 3
	assert_eq(BattleView.pick_move(report), &"combo", "a long chain is a combo too")
	report.chain = 1
	report.link_color = P
	report.shield_damage = 6
	assert_eq(BattleView.pick_move(report), &"bash")
