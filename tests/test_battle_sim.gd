extends "res://tests/test_case.gd"
## The balance bot: it must play legal links and finish fights, or its numbers mean nothing.


func _monster(hp := 30, counterattacks := false) -> MonsterData:
	var m := MonsterData.new()
	m.max_hp = hp
	m.counterattacks = counterattacks
	return m


func _sim(strategy: BattleSim.Strategy) -> BattleSim:
	return BattleSim.new(BoardRules.new(), BattleRules.new(), strategy)


func test_every_strategy_plays_legal_links() -> void:
	for strategy in BattleSim.Strategy.values():
		var game := LinkGame.new(BoardRules.new(), 7)
		var state := BattleState.new(BattleRules.new(), _monster())
		for i in 5:
			var path := _sim(strategy).choose(game, state)
			assert_true(game.is_valid(path), "%s move %d" % [BattleSim.STRATEGY_NAMES[strategy], i])
			game.play(path)


func test_longest_finds_the_longest_link() -> void:
	var game := LinkGame.new(BoardRules.new(), 3)
	game.board.fill_from_pattern([
		"R R R R R G Y",
		"G Y P G Y P G",
		"Y P G Y P G Y",
		"P G Y P G Y P",
		"R Y P G Y P G",
		"G P G Y P G Y",
		"Y G Y P G Y P",
		"P Y P G Y P G",
	])
	var path := _sim(BattleSim.Strategy.LONGEST).choose(game, BattleState.new(BattleRules.new(), _monster()))
	assert_eq(path.size(), 5)


func test_a_fight_runs_to_the_end() -> void:
	var stats := _sim(BattleSim.Strategy.SMART).play_fight(_monster(), 11)
	assert_eq(stats["outcome"], BattleState.Outcome.WON)
	assert_true(stats["moves"] > 0 and stats["moves"] <= BattleSim.MAX_MOVES)
	assert_true(stats["rounds"] >= stats["moves"], "every move has at least the link's round")


func test_same_seed_same_fight() -> void:
	var a := _sim(BattleSim.Strategy.RANDOM).play_fight(_monster(), 5)
	var b := _sim(BattleSim.Strategy.RANDOM).play_fight(_monster(), 5)
	assert_eq(a, b)
