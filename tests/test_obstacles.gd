extends "res://tests/test_case.gd"

const R := Cell.BlockColor.RED
const G := Cell.BlockColor.GREEN


func _board(columns: int, lines: Array) -> BoardModel:
	var board := BoardModel.new(columns, lines.size())
	board.fill_from_pattern(lines)
	return board


func _link(board: BoardModel, cells: Array, refill := Callable()) -> Array[ClearStep]:
	var path: Array[Vector2i] = []
	path.assign(cells)
	return Resolver.resolve_link(board, BoardRules.new(), path, refill)


## New squares cycle through the colors so no line forms and the chain ends.
func _refill() -> Callable:
	var next := [0]
	return func() -> Cell:
		next[0] += 1
		return Cell.new(next[0] % Cell.COLOR_COUNT)


func test_a_crate_loses_a_layer_when_a_square_beside_it_clears() -> void:
	var board := _board(4, [
		"G P Y G",
		"R R R 2",
	])
	var steps := _link(board, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], _refill())
	assert_eq(steps[0].hit.size(), 1)
	assert_eq(steps[0].hit[0]["layers"], 1)
	assert_eq(board.get_cell(Vector2i(3, 1)).layers, 1, "one layer left, still standing")
	assert_true(steps[0].broken.is_empty())


func test_the_last_layer_breaks_the_crate_once_per_round() -> void:
	var board := _board(4, [
		"G P 1 G",
		"R R R G",
	])
	# Two cleared squares touch the crate (below and left); it still only loses one layer.
	var steps := _link(board, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], _refill())
	assert_eq(steps[0].broken.size(), 1)
	assert_eq(steps[0].broken[0]["kind"], "crate")
	assert_true(steps[0].cleared.has(Vector2i(2, 0)), "a broken crate clears with the round")
	assert_eq(steps[0].count_by_color().get(R, 0), 3, "the crate adds no color")


func test_obstacles_cannot_be_linked() -> void:
	var game := LinkGame.new(BoardRules.new(), 3)
	game.board.set_cell(Vector2i(0, 0), Cell.obstacle("crate", 1))
	var empty: Array[Vector2i] = []
	assert_true(not game.can_extend(empty, Vector2i(0, 0)), "can't start on a crate")
	game.board.set_cell(Vector2i(1, 0), Cell.new(R))
	game.board.set_cell(Vector2i(2, 0), Cell.obstacle("rock", 2))
	var path: Array[Vector2i] = [Vector2i(1, 0)]
	assert_true(not game.can_extend(path, Vector2i(2, 0)), "can't go through a rock")


func test_a_blast_takes_a_layer_too() -> void:
	var board := _board(3, [
		"G 3 G",
		"R R R",
	])
	board.set_cell(Vector2i(1, 1), Cell.new(R, Cell.Special.BOMB))
	var steps := _link(board, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], _refill())
	assert_eq(steps[0].hit.size(), 1, "the bomb's blast and the squares beside count as one hit")
	# The squares under it cleared, so the crate fell to the bottom row.
	assert_eq(board.get_cell(Vector2i(1, 1)).blocker, "crate")
	assert_eq(board.get_cell(Vector2i(1, 1)).layers, 2)


func test_an_item_reaching_the_bottom_is_rescued() -> void:
	var board := _board(3, [
		"F G G",
		"R R R",
	])
	var steps := _link(board, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], _refill())
	assert_eq(steps.size(), 2, "the link, then the rescue")
	assert_eq(steps[1].rescued.size(), 1)
	assert_eq(steps[1].rescued[0]["kind"], "orc_flag")
	assert_eq(steps[1].chain, steps[0].chain, "a rescue doesn't add to the chain")
	for x in 3:
		for y in 2:
			assert_true(not board.get_cell(Vector2i(x, y)).is_blocker(), "the flag left the board")


func test_blasts_pass_over_items() -> void:
	var board := _board(3, [
		"G F G",
		"R R R",
	])
	board.set_cell(Vector2i(1, 1), Cell.new(R, Cell.Special.BOMB))
	var steps := _link(board, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)])
	assert_true(not steps[0].cleared.has(Vector2i(1, 0)), "the flag isn't destroyed")


func test_placing_obstacles_keeps_a_move_and_survives_a_reshuffle() -> void:
	var game := LinkGame.new(BoardRules.new(), 11)
	var spots := game.place("crate", 6, 2, 4)
	assert_eq(spots.size(), 6)
	for p in spots:
		assert_true(p.y >= 4)
		assert_eq(game.board.get_cell(p).blocker, "crate")
	assert_true(game.has_move())
	game.deal()
	for p in spots:
		assert_eq(game.board.get_cell(p).blocker, "crate", "a reshuffle leaves crates in place")
