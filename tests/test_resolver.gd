extends "res://tests/test_case.gd"

const R := Cell.BlockColor.RED
const G := Cell.BlockColor.GREEN
const Y := Cell.BlockColor.YELLOW
const P := Cell.BlockColor.PURPLE
const EMPTY := -2


func _board(lines: Array) -> BoardModel:
	var board := BoardModel.new(8, 12)
	board.fill_from_pattern(lines)
	return board


func _resolve(board: BoardModel, focus: Array = []) -> Array[ClearStep]:
	var moved: Array[Vector2i] = []
	moved.assign(focus)
	return Resolver.resolve(board, BoardRules.new(), moved)


func _color(board: BoardModel, x: int, y: int) -> int:
	var cell := board.get_cell(Vector2i(x, y))
	return cell.color if cell else EMPTY


func _special(board: BoardModel, x: int, y: int) -> int:
	var cell := board.get_cell(Vector2i(x, y))
	return cell.special if cell else EMPTY


func test_full_row_clears() -> void:
	var board := _board([
		"G . . . . . . .",
		"R G Y P R G Y P",
	])
	var steps := _resolve(board)
	assert_eq(steps.size(), 1)
	assert_eq(steps[0].full_rows.size(), 1)
	assert_eq(steps[0].full_rows[0], 11)
	assert_eq(_color(board, 0, 11), G, "loose square falls into the cleared row")
	assert_eq(board.count(), 1)


func test_four_of_a_color_clear_but_three_do_not() -> void:
	var board := _board(["R R R . G G G G"])
	var steps := _resolve(board)
	assert_eq(steps.size(), 1)
	assert_eq(board.count(), 3)
	assert_eq(_color(board, 2, 11), R)
	assert_eq(_color(board, 4, 11), EMPTY)


func test_squares_fall_one_by_one() -> void:
	var board := _board([
		"Y . . . . . . .",
		"G P . . . . . .",
		"R R R R . . . .",
	])
	_resolve(board)
	assert_eq(_color(board, 0, 11), G)
	assert_eq(_color(board, 0, 10), Y)
	assert_eq(_color(board, 1, 11), P)


func test_falling_squares_set_off_a_chain() -> void:
	var board := _board([
		"R R . . . . . .",
		"G G G G . . . .",
		"R R Y P . . . .",
	])
	var steps := _resolve(board, [Vector2i(3, 10)])
	assert_eq(steps.size(), 2, "green clears, then the reds fall together and clear")
	assert_eq(steps[1].chain, 2)
	assert_eq(steps[1].count_by_color().get(R, 0), 4)
	assert_eq(board.count(), 2)
	assert_eq(_color(board, 2, 11), Y)


func test_cluster_of_five_leaves_lightning_where_the_piece_landed() -> void:
	var board := _board(["R R R R R . . ."])
	var steps := _resolve(board, [Vector2i(4, 11)])
	assert_eq(steps[0].spawned.size(), 1)
	assert_eq(board.count(), 1)
	assert_eq(_special(board, 4, 11), Cell.Special.LIGHTNING)
	assert_eq(_color(board, 4, 11), R)


func test_cluster_of_six_leaves_a_bomb_at_the_lowest_square() -> void:
	var board := _board([
		"R R R . . . . .",
		"R R R . . . . .",
	])
	_resolve(board)
	assert_eq(board.count(), 1)
	assert_eq(_special(board, 0, 11), Cell.Special.BOMB)


func test_lightning_clears_its_row_and_column() -> void:
	var board := _board([
		"Y . . . . . . .",
		"G . . . . . . G",
		"R R R R . . P .",
	])
	board.set_cell(Vector2i(0, 11), Cell.new(R, Cell.Special.LIGHTNING))
	var steps := _resolve(board)
	assert_true(steps[0].triggered.has(Vector2i(0, 11)))
	assert_eq(board.count(), 1)
	assert_eq(_color(board, 7, 11), G)


func test_bomb_clears_three_by_three() -> void:
	var board := _board([
		". . P . . . . .",
		". . . G G G G .",
		". R Y . . . . .",
	])
	board.set_cell(Vector2i(3, 10), Cell.new(G, Cell.Special.BOMB))
	_resolve(board)
	assert_eq(board.count(), 1)
	assert_eq(_color(board, 1, 11), R)


func test_rainbow_is_wild_and_clears_its_cluster_color() -> void:
	var board := _board(["R R * R . . . G"])
	board.set_cell(Vector2i(7, 5), Cell.new(R))
	var steps := _resolve(board)
	assert_true(steps[0].triggered.has(Vector2i(2, 11)))
	assert_eq(board.count(), 1, "the far red is gone too")
	assert_eq(_color(board, 7, 11), G)


func test_two_full_rows_leave_a_rainbow() -> void:
	var board := _board([
		"G Y P R G Y P R",
		"R G Y P R G Y P",
	])
	_resolve(board, [Vector2i(5, 10)])
	assert_eq(board.count(), 1)
	assert_eq(_special(board, 5, 11), Cell.Special.RAINBOW)


func test_lightning_next_to_bomb_fuses_into_a_wide_cross() -> void:
	var board := _board([". R R R R . . ."])
	board.set_cell(Vector2i(2, 11), Cell.new(R, Cell.Special.LIGHTNING))
	board.set_cell(Vector2i(3, 11), Cell.new(R, Cell.Special.BOMB))
	board.set_cell(Vector2i(0, 10), Cell.new(Y))
	board.set_cell(Vector2i(2, 5), Cell.new(G))
	board.set_cell(Vector2i(7, 8), Cell.new(P))
	var steps := _resolve(board)
	assert_eq(steps[0].fusions.size(), 1)
	assert_eq(board.count(), 1, "row 10 and column 2 go too; only the far purple is left")
	assert_eq(_color(board, 7, 11), P)


func test_two_bombs_fuse_into_five_by_five() -> void:
	var board := _board([
		"Y . . . . . . .",
		". . . . . . . Y",
		". . R R R R . .",
	])
	board.set_cell(Vector2i(3, 11), Cell.new(R, Cell.Special.BOMB))
	board.set_cell(Vector2i(4, 11), Cell.new(R, Cell.Special.BOMB))
	var steps := _resolve(board)
	assert_eq(steps[0].fusions.size(), 1)
	assert_eq(board.count(), 2, "only squares more than two away survive")


func test_rainbow_next_to_lightning_strikes_every_square_of_that_color() -> void:
	var board := _board([
		". . . . . . P .",
		". . . . . . Y .",
		"G G * G . . . .",
	])
	board.set_cell(Vector2i(3, 11), Cell.new(G, Cell.Special.LIGHTNING))
	board.set_cell(Vector2i(6, 3), Cell.new(G))
	var steps := _resolve(board)
	assert_eq(steps[0].fusions.size(), 1)
	assert_eq(board.count(), 0, "the far green strikes column 6, taking the purple and yellow")
