extends "res://tests/test_case.gd"

const R := Cell.BlockColor.RED
const G := Cell.BlockColor.GREEN
const Y := Cell.BlockColor.YELLOW
const P := Cell.BlockColor.PURPLE


func _game(seed_value := 42) -> LinkGame:
	return LinkGame.new(BoardRules.new(), seed_value)


func _path(cells: Array) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	path.assign(cells)
	return path


## Puts a known board in place: `lines` fill it from the top, row by row.
func _set_board(game: LinkGame, lines: Array) -> void:
	game.board.fill_from_pattern(lines)


func test_fresh_board_is_full_with_no_lines_and_a_move() -> void:
	for seed_value in [1, 2, 3, 42]:
		var game := _game(seed_value)
		assert_eq(game.board.count(), 7 * 8)
		assert_true(Resolver.find_lines(game.board, game.rules).is_empty(), "seed %d" % seed_value)
		assert_true(game.has_move())


func test_links_go_sideways_and_up_down_but_not_diagonally() -> void:
	var game := _game()
	_set_board(game, [
		"R R G Y P G Y",
		"G R R P Y P G",
		"Y G Y G P Y P",
		"P Y P Y G P Y",
		"G P G P Y G P",
		"Y G Y G P Y G",
		"P Y P Y G P Y",
		"G P G P Y G P",
	])
	assert_true(game.can_extend(_path([Vector2i(0, 0)]), Vector2i(1, 0)))
	assert_true(game.can_extend(_path([Vector2i(1, 0)]), Vector2i(1, 1)), "down")
	assert_true(not game.can_extend(_path([Vector2i(0, 0)]), Vector2i(1, 1)), "diagonal")
	assert_true(not game.can_extend(_path([Vector2i(0, 0)]), Vector2i(0, 1)), "other color")
	assert_true(not game.can_extend(_path([Vector2i(0, 0), Vector2i(1, 0)]), Vector2i(0, 0)), "already in the link")
	assert_true(game.is_valid(_path([Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)])))


func test_star_joins_any_color_and_the_first_real_square_sets_it() -> void:
	var game := _game()
	_set_board(game, ["* G G Y R P Y"])
	var row := game.board.rows - 1
	assert_true(game.can_extend(_path([Vector2i(0, row)]), Vector2i(1, row)))
	assert_true(game.can_extend(_path([Vector2i(1, row)]), Vector2i(0, row)), "a star joins a green link")
	assert_true(game.is_valid(_path([Vector2i(0, row), Vector2i(1, row), Vector2i(2, row)])))
	assert_true(not game.can_extend(_path([Vector2i(0, row), Vector2i(1, row), Vector2i(2, row)]), Vector2i(3, row)))


func test_short_links_are_refused_and_change_nothing() -> void:
	var game := _game()
	var before := game.board.get_cell(Vector2i(0, 0))
	var second := Vector2i(1, 0) if game.can_extend(_path([Vector2i(0, 0)]), Vector2i(1, 0)) else Vector2i(0, 1)
	assert_eq(game.play(_path([Vector2i(0, 0), second])), null)
	assert_true(game.board.get_cell(Vector2i(0, 0)) == before)


func test_a_move_keeps_the_board_full() -> void:
	var game := _game()
	_set_board(game, [
		"R R R Y P G Y",
		"G Y G P Y P G",
		"Y G Y G P Y P",
		"P Y P Y G P Y",
		"G P G P Y G P",
		"Y G Y G P Y G",
		"P Y P Y G P Y",
		"G P G P Y G P",
	])
	var result := game.play(_path([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]))
	assert_true(result != null)
	assert_eq(result.path.size(), 3)
	assert_true(result.chain_length() >= 1)
	assert_eq(game.board.count(), 7 * 8)


func test_board_is_dealt_again_when_no_link_is_left() -> void:
	var game := _game()
	# Diagonal stripes: no two neighbors share a color, so nothing can be linked.
	for y in game.board.rows:
		for x in game.board.columns:
			game.board.set_cell(Vector2i(x, y), Cell.new((x + 2 * y) % Cell.COLOR_COUNT))
	assert_true(not game.has_move())
	game.deal()
	assert_true(game.has_move())
	assert_eq(game.board.count(), 7 * 8)


func test_critical_tiles_are_red_and_rare_on_the_board() -> void:
	var game := _game()
	game.rules.crit_tile_chance = 1.0
	game.rules.max_crit_tiles = 1
	var made := 0
	for i in 40:
		var cell := game._random_cell()
		if cell.critical:
			assert_eq(cell.color, R)
			made += 1
			game.board.set_cell(Vector2i(0, 0), cell)
	assert_eq(made, 1, "no second critical tile while one is on the board")
	assert_eq(game.critical_tiles(), 1)
