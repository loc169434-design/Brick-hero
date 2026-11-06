extends "res://tests/test_case.gd"

const R := Cell.BlockColor.RED
const G := Cell.BlockColor.GREEN


func _board(columns: int, lines: Array) -> BoardModel:
	var board := BoardModel.new(columns, lines.size())
	board.fill_from_pattern(lines)
	return board


func _link(board: BoardModel, cells: Array) -> Array[ClearStep]:
	var path: Array[Vector2i] = []
	path.assign(cells)
	var next := [0]
	var refill := func() -> Cell:
		next[0] += 1
		return Cell.new(next[0] % Cell.COLOR_COUNT)
	return Resolver.resolve_link(board, BoardRules.new(), path, refill)


func _row() -> Array:
	return [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]


func test_ice_melts_a_layer_and_the_tile_stays() -> void:
	var board := _board(3, ["G P Y", "R R R"])
	board.get_cell(Vector2i(1, 1)).ice = 2
	var steps := _link(board, _row())
	assert_eq(steps[0].thawed.size(), 1)
	assert_eq(steps[0].count_by_color().get(R, 0), 2, "the iced tile gives nothing")
	assert_eq(board.get_cell(Vector2i(1, 1)).ice, 1)
	assert_eq(board.get_cell(Vector2i(1, 1)).color, R, "still the same red tile")


func test_the_last_ice_layer_counts_as_broken() -> void:
	var board := _board(3, ["G P Y", "R R R"])
	board.get_cell(Vector2i(0, 1)).ice = 1
	var steps := _link(board, _row())
	assert_eq(steps[0].broken.size(), 1)
	assert_eq(steps[0].broken[0]["kind"], "ice")


func test_a_web_blocks_links_and_tears_when_a_neighbor_clears() -> void:
	var game := LinkGame.new(BoardRules.new(), 5)
	var cell := game.board.get_cell(Vector2i(0, 0))
	cell.web = true
	var empty: Array[Vector2i] = []
	assert_true(not game.can_extend(empty, Vector2i(0, 0)), "can't start on a web")
	var board := _board(3, ["G G Y", "R R R"])
	board.get_cell(Vector2i(1, 0)).web = true
	var steps := _link(board, _row())
	var torn := steps[0].broken.filter(func(b: Dictionary) -> bool: return b["kind"] == "web")
	assert_eq(torn.size(), 1)


func test_time_bombs_count_down_and_go_off() -> void:
	var game := LinkGame.new(BoardRules.new(), 7)
	var spots := game.place("time_bomb", 1, 1)
	game.board.get_cell(spots[0]).timer = 2
	assert_true(game.end_turn(true)["bombs"].is_empty())
	var events := game.end_turn(true)
	assert_eq(events["bombs"], [spots[0]])
	assert_true(not game.board.get_cell(spots[0]).is_blocker(), "it leaves the board")


func test_mud_creeps_unless_it_was_hit() -> void:
	var game := LinkGame.new(BoardRules.new(), 9)
	game.place("mud", 1, 1, 3, 5)
	assert_eq(game.end_turn(true)["mud"], null, "mud hit this move stays put")
	var events := game.end_turn(false)
	assert_true(events["mud"] != null)
	assert_eq(game.count(func(c: Cell) -> bool: return c.blocker == "mud"), 2)


func test_poison_bites_each_move_and_greens_wash_it_out() -> void:
	var rules: BattleRules = load("res://data/balance.tres")
	var state := BattleState.new(rules, load("res://data/monsters/scarecrow.tres"))
	state.poison_hero(2)
	state.poison_hero(2)
	var plain := MoveResult.new()
	plain.steps.append(ClearStep.new())
	var report := state.apply_move(plain)
	assert_eq(report.poison_damage, 4, "poison stacks")
	assert_eq(state.hero_hp, rules.hero_max_hp - 4)
	var greens := MoveResult.new()
	var step := ClearStep.new()
	for i in 3:
		step.cleared_cells.append(Cell.new(G))
		step.cleared.append(Vector2i.ZERO)
	greens.steps.append(step)
	report = state.apply_move(greens)
	assert_true(report.cured)
	assert_eq(state.poison, 0)


func test_as_a_toad_each_red_does_one_point_and_the_skill_waits() -> void:
	var rules: BattleRules = load("res://data/balance.tres")
	var state := BattleState.new(rules, load("res://data/monsters/scarecrow.tres"))
	state.shield = 0
	state.toad_turns = 2
	state.rage = rules.rage_max
	assert_true(not state.skill_ready())
	var move := MoveResult.new()
	var step := ClearStep.new()
	for i in 4:
		step.cleared_cells.append(Cell.new(R))
		step.cleared.append(Vector2i.ZERO)
	step.chain = 1
	move.steps.append(step)
	var report := state.apply_move(move)
	assert_eq(report.damage, 4)
	state.apply_move(move)
	assert_eq(state.toad_turns, 0)


func test_a_long_link_breaks_the_broom() -> void:
	var rules: BattleRules = load("res://data/balance.tres")
	var state := BattleState.new(rules, load("res://data/monsters/scarecrow.tres"))
	state.broom_turns = 2
	var move := MoveResult.new()
	for i in 6:
		move.path.append(Vector2i(i, 0))
	move.steps.append(ClearStep.new())
	assert_true(state.apply_move(move).broom_broken)
	assert_eq(state.broom_turns, 0)


func test_spells_take_turns() -> void:
	var rules: BattleRules = load("res://data/balance.tres")
	var witch := MonsterData.new()
	witch.special = "toads, broom, potion"
	witch.countdown = 1
	witch.attack = 1
	witch.max_hp = 99
	var state := BattleState.new(rules, witch)
	var spells: Array[String] = []
	for i in 4:
		var move := MoveResult.new()
		move.steps.append(ClearStep.new())
		spells.append(state.apply_move(move).board_spell)
	assert_eq(spells, ["toads", "broom", "potion", "toads"])
