extends "res://tests/test_case.gd"

const R := Cell.BlockColor.RED
const G := Cell.BlockColor.GREEN
const Y := Cell.BlockColor.YELLOW
const P := Cell.BlockColor.PURPLE
const EMPTY := -2


func _board(columns: int, lines: Array) -> BoardModel:
	var board := BoardModel.new(columns, lines.size())
	board.fill_from_pattern(lines)
	return board


func _link(board: BoardModel, cells: Array, refill := Callable()) -> Array[ClearStep]:
	var path: Array[Vector2i] = []
	path.assign(cells)
	return Resolver.resolve_link(board, BoardRules.new(), path, refill)


## Hands out new squares in a fixed order, so refills are predictable.
func _refill_from(colors: Array) -> Callable:
	var queue := colors.duplicate()
	return func() -> Cell: return Cell.new(queue.pop_front())


func _color(board: BoardModel, x: int, y: int) -> int:
	var cell := board.get_cell(Vector2i(x, y))
	return cell.color if cell else EMPTY


func _special(board: BoardModel, x: int, y: int) -> int:
	var cell := board.get_cell(Vector2i(x, y))
	return cell.special if cell else EMPTY


func test_link_clears_and_squares_above_fall() -> void:
	var board := _board(4, [
		"Y G P Y",
		"G P Y G",
		"R R R P",
	])
	var steps := _link(board, [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)])
	assert_eq(steps.size(), 1)
	assert_eq(steps[0].count_by_color().get(R, 0), 3)
	assert_eq(_color(board, 0, 2), G, "column 0 dropped one row")
	assert_eq(_color(board, 0, 1), Y)
	assert_eq(_color(board, 0, 0), EMPTY, "no refill given")


func test_refill_drops_new_squares_from_above() -> void:
	var board := _board(4, [
		"Y G P Y",
		"G P Y G",
		"R R R P",
	])
	var steps := _link(board, [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)], _refill_from([P, Y, G]))
	assert_eq(board.count(), 12, "the board is full again")
	var dropped_in := steps[0].falls.filter(func(f: Dictionary) -> bool: return f.has("cell"))
	assert_eq(dropped_in.size(), 3)
	assert_eq(dropped_in[0]["from"].y, -1, "new squares start above the board")
	assert_eq(_color(board, 0, 0), P)


func test_falling_squares_that_line_up_clear_as_a_chain() -> void:
	var board := _board(4, [
		"G Y P Y",
		"R R R P",
		"G P Y G",
		"G Y P Y",
		"G P Y G",
	])
	var steps := _link(board, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)])
	assert_eq(steps.size(), 2, "the G falls onto three Gs and makes a column of four")
	assert_eq(steps[1].chain, 2)
	assert_eq(steps[1].count_by_color().get(G, 0), 4)


func test_three_in_a_row_is_not_a_line() -> void:
	var board := _board(4, [
		"Y G Y G",
		"G R R R",
	])
	assert_true(Resolver.find_lines(board, BoardRules.new()).is_empty())


func test_bent_links_work() -> void:
	var board := _board(3, [
		"R R Y",
		"G R Y",
		"G R R",
	])
	var steps := _link(board, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)])
	assert_eq(steps[0].count_by_color().get(R, 0), 5)


func test_long_links_leave_a_special_where_the_finger_let_go() -> void:
	var cases := {5: Cell.Special.LIGHTNING, 6: Cell.Special.BOMB, 7: Cell.Special.RAINBOW}
	for length: int in cases:
		# The rest of the row alternates, so nothing lines up with the new special afterwards.
		var row := "R".repeat(length) + "GY".repeat(4)
		var board := _board(8, [row.substr(0, 8)])
		var path := []
		for x in length:
			path.append(Vector2i(x, 0))
		_link(board, path)
		assert_eq(_special(board, length - 1, 0), cases[length], "link of %d" % length)


func test_star_takes_no_color_but_lightning_keeps_the_link_color() -> void:
	var board := _board(8, ["P P P P P G Y G"])
	_link(board, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)])
	assert_eq(_color(board, 4, 0), P)
	board = _board(8, ["P P P P P P P G"])
	_link(board, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0)])
	assert_eq(_color(board, 6, 0), Cell.NO_COLOR)


func test_link_through_lightning_clears_its_row_and_column() -> void:
	var board := _board(4, [
		"Y G Y G",
		"P Y P Y",
		"R R R G",
	])
	board.set_cell(Vector2i(1, 2), Cell.new(R, Cell.Special.LIGHTNING))
	var steps := _link(board, [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)])
	assert_true(steps[0].triggered.has(Vector2i(1, 2)))
	assert_eq(steps[0].cleared.size(), 3 + 1 + 2, "the link, the rest of row 2, and column 1")


func test_stars_wait_for_the_player_instead_of_completing_lines() -> void:
	var board := _board(5, [
		"Y G Y G Y",
		"G R R * R",
	])
	assert_true(Resolver.find_lines(board, BoardRules.new()).is_empty(), "R R * R is not a line")
	board = _board(4, ["* * * *"])
	assert_true(Resolver.find_lines(board, BoardRules.new()).is_empty())


## Specials are wild and keep their color hidden, so like stars they wait for the player.
func test_falling_lightning_does_not_complete_a_line() -> void:
	var board := _board(5, [
		"Y G Y G Y",
		"G R R R R",
	])
	board.set_cell(Vector2i(2, 1), Cell.new(R, Cell.Special.LIGHTNING))
	var step := Resolver.find_lines(board, BoardRules.new())
	assert_true(step.cleared.is_empty())


func test_bomb_and_lightning_join_a_link_of_any_color() -> void:
	var board := _board(4, [
		"Y G Y G",
		"G R P R",
	])
	board.set_cell(Vector2i(1, 1), Cell.new(P, Cell.Special.BOMB))
	board.set_cell(Vector2i(2, 1), Cell.new(G, Cell.Special.LIGHTNING))
	var game := LinkGame.new(BoardRules.new(), 1)
	game.board = board
	var path: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
	assert_true(game.is_valid(path), "green, a purple bomb, a green lightning")
	path = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
	assert_true(game.is_valid(path), "two specials of different colors, then red")
	assert_eq(Resolver.link_color(board, path), R)


func test_lightning_next_to_bomb_fuses_into_a_wide_cross() -> void:
	var board := _board(5, [
		"Y G Y G Y",
		"G Y G Y G",
		"Y R R R P",
		"G Y G Y G",
		"Y G Y G Y",
	])
	board.set_cell(Vector2i(1, 2), Cell.new(R, Cell.Special.LIGHTNING))
	board.set_cell(Vector2i(2, 2), Cell.new(R, Cell.Special.BOMB))
	var steps := _link(board, [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)])
	assert_eq(steps[0].fusions.size(), 1)
	assert_eq(steps[0].cleared.size(), 5 * 3 + 2 * 3, "rows 1-3 and columns 0-2 (or 1-3)")
