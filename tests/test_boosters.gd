extends "res://tests/test_case.gd"
## The hammer, the shuffle, the potion and the opening bombs (Boosters).

const R := Cell.BlockColor.RED
const G := Cell.BlockColor.GREEN


func _orc() -> MonsterData:
	var m := MonsterData.new()
	m.max_hp = 80
	m.attack = 12
	m.countdown = 3
	m.counterattacks = true
	return m


func test_the_hammer_clears_one_tile_and_the_board_settles() -> void:
	var game := LinkGame.new(BoardRules.new(), 3)
	var p := Vector2i(3, 7)
	var hit := game.board.get_cell(p)
	var result := game.smash(p)
	assert_true(result != null)
	assert_true(result.path.is_empty(), "nothing was linked")
	assert_true(result.steps[0].cleared.has(p))
	assert_true(result.steps[0].cleared_cells.has(hit))
	assert_true(game.board.get_cell(p) != null, "the board is full again")
	assert_true(game.board.get_cell(p) != hit)


func test_the_hammer_knocks_a_layer_off_a_crate() -> void:
	var game := LinkGame.new(BoardRules.new(), 3)
	var p := Vector2i(2, 5)
	game.board.set_cell(p, Cell.obstacle("crate", 2))
	var result := game.smash(p)
	assert_eq(result.steps[0].hit.size(), 1)
	assert_eq(game.board.get_cell(p).layers, 1, "one layer off")
	assert_true(not result.steps[0].cleared.has(p))


func test_the_hammer_sets_off_a_special() -> void:
	var game := LinkGame.new(BoardRules.new(), 3)
	var p := Vector2i(3, 4)
	game.board.get_cell(p).special = Cell.Special.LIGHTNING
	var result := game.smash(p)
	assert_true(result.steps[0].triggered.has(p))
	assert_true(result.steps[0].cleared.size() >= game.board.columns + game.board.rows - 1, "its row and column go")


func test_shuffling_keeps_specials_and_crates() -> void:
	var game := LinkGame.new(BoardRules.new(), 5)
	var bomb := game.board.get_cell(Vector2i(1, 1))
	bomb.special = Cell.Special.BOMB
	var crate := Cell.obstacle("crate", 2)
	game.board.set_cell(Vector2i(4, 6), crate)
	game.deal(true)
	assert_true(game.board.get_cell(Vector2i(1, 1)) == bomb, "the bomb stays")
	assert_true(game.board.get_cell(Vector2i(4, 6)) == crate, "the crate stays")
	assert_true(game.has_move())


func test_opening_bombs_land_inside_the_board() -> void:
	var game := LinkGame.new(BoardRules.new(), 7)
	var placed := game.place_opening_specials()
	assert_eq(placed.size(), 2)
	assert_eq(game.board.get_cell(placed[0]).special, Cell.Special.BOMB)
	assert_eq(game.board.get_cell(placed[1]).special, Cell.Special.LIGHTNING)
	for p in placed:
		assert_true(p.x > 0 and p.y > 0 and p.x < game.board.columns - 1 and p.y < game.board.rows - 1, "away from the edge: %s" % p)


func test_a_free_blow_hurts_without_costing_a_move() -> void:
	var state := BattleState.new(BattleRules.new(), _orc())
	var result := MoveResult.new()
	var step := ClearStep.new()
	step.chain = 1
	step.cleared.append(Vector2i.ZERO)
	step.cleared_cells.append(Cell.new(R))
	result.steps.append(step)
	var report := state.apply_move(result, true)
	assert_true(report.damage > 0)
	assert_eq(state.countdown, 3, "the monster's countdown didn't tick")
	assert_eq(state.moves, 0)
	state.apply_move(result)
	assert_eq(state.countdown, 2, "a real move does tick")


func test_the_potion_heals_up_to_full() -> void:
	var state := BattleState.new(BattleRules.new(), _orc())
	state.hero_hp = state.rules.hero_max_hp - 10
	var report := state.drink_potion(Boosters.POTION_HEAL)
	assert_eq(report.heal, 10)
	assert_eq(report.booster, "potion")
	assert_eq(state.hero_hp, state.rules.hero_max_hp)


func test_boosters_are_bought_kept_and_saved() -> void:
	var campaign := Campaign.from_map()
	campaign.gold = 100
	assert_true(campaign.buy_booster("hammer"))
	assert_eq(campaign.gold, 100 - int(Boosters.ITEMS["hammer"]["price"]))
	assert_true(not campaign.buy_booster("nonsense"))
	campaign.gold = 0
	assert_true(not campaign.buy_booster("potion"), "too poor")
	for i in Boosters.MAX_CARRIED:
		campaign.add_booster("shuffle")
	assert_true(not campaign.add_booster("shuffle"), "the bag is full")
	var copy := Campaign.from_map()
	copy.apply_dict(JSON.parse_string(JSON.stringify(campaign.to_dict())))
	assert_eq(copy.booster_count("hammer"), 1)
	assert_eq(copy.booster_count("shuffle"), Boosters.MAX_CARRIED)
	assert_true(copy.use_booster("hammer"))
	assert_true(not copy.use_booster("hammer"), "none left")


func test_bosses_drop_a_booster_the_first_time() -> void:
	var rng := RandomNumberGenerator.new()
	for i in 20:
		rng.seed = i
		assert_true(Boosters.reward(true, true, 1, rng) in Boosters.ORDER)
		assert_eq(Boosters.reward(true, false, 1, rng), "", "a plain first clear drops nothing")
		assert_eq(Boosters.reward(false, true, 2, rng), "", "a replay under three stars drops nothing")


func test_the_hammer_has_nothing_to_break_on_an_item() -> void:
	var game := LinkGame.new(BoardRules.new(), 3)
	game.board.set_cell(Vector2i(2, 2), Cell.obstacle("orc_flag"))
	assert_true(game.smash(Vector2i(2, 2)) == null)
