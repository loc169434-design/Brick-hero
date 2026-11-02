extends "res://tests/test_case.gd"

const R := Cell.BlockColor.RED
const G := Cell.BlockColor.GREEN
const Y := Cell.BlockColor.YELLOW
const P := Cell.BlockColor.PURPLE


func _game() -> BoardGame:
	var game := BoardGame.new(BoardRules.new(), 42)
	game.start()
	return game


## Puts a one-square piece of `color` in hand above column `x`.
func _give_single(game: BoardGame, color: int, x: int) -> void:
	game.current = Piece.new(&"single", [Vector2i.ZERO], [color])
	game.origin = Vector2i(x, 0)


func test_piece_lands_on_the_stack() -> void:
	var game := _game()
	game.board.fill_from_pattern(["R . . . . . . ."])
	_give_single(game, G, 0)
	var result := game.drop()
	assert_eq(result.placed.size(), 1)
	assert_eq(result.placed[0], Vector2i(0, 10))


func test_combo_grows_with_each_clearing_drop_and_resets() -> void:
	var game := _game()
	game.board.fill_from_pattern(["R R R . G G G ."])
	_give_single(game, R, 3)
	assert_eq(game.drop().combo, 1)
	_give_single(game, G, 3)
	assert_eq(game.drop().combo, 2)
	_give_single(game, Y, 0)
	var result := game.drop()
	assert_true(not result.cleared_anything())
	assert_eq(game.combo, 0)


func test_hold_swaps_once_per_drop() -> void:
	var game := _game()
	var first := game.current
	assert_true(game.hold())
	assert_true(game.held == first)
	assert_true(game.current != first)
	assert_true(not game.hold(), "second hold before dropping is refused")
	game.drop()
	assert_true(game.hold())
	assert_true(game.current == first, "the held piece comes back")


func test_turning_against_the_wall_kicks_the_piece_inward() -> void:
	var game := _game()
	game.current = Piece.new(&"line", PieceBag.SHAPES[&"line"], [R, R, G, G])
	game.origin = game.spawn_origin(game.current)
	assert_true(game.rotate(), "upright")
	while game.move(-1):
		pass
	assert_eq(game.origin.x, 0)
	assert_true(game.rotate(), "flat again, pushed off the wall")
	assert_eq(game.origin.x, 2)
	assert_true(game.board.can_place(game.current, game.origin))


func test_tops_out_when_the_next_piece_has_no_room() -> void:
	var game := _game()
	# Two alternating columns in the middle: no full rows, no clusters, but no room to spawn.
	for y in game.board.rows:
		game.board.set_cell(Vector2i(3, y), Cell.new(R if y % 2 == 0 else G))
		game.board.set_cell(Vector2i(4, y), Cell.new(Y if y % 2 == 0 else P))
	var topped := [false]
	game.topped_out.connect(func() -> void: topped[0] = true)
	_give_single(game, P, 0)
	game.drop()
	assert_true(game.is_over)
	assert_true(topped[0])
	assert_eq(game.drop(), null, "no more drops after topping out")


func test_bag_deals_every_shape_once_per_round() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var bag := PieceBag.new(BoardRules.new(), rng)
	var seen := {}
	for i in PieceBag.SHAPES.size():
		seen[bag.next().shape_id] = true
	assert_eq(seen.size(), PieceBag.SHAPES.size())


func test_pieces_use_at_most_two_colors() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var bag := PieceBag.new(BoardRules.new(), rng)
	for i in 200:
		var colors := {}
		for c in bag.next().colors:
			colors[c] = true
		assert_true(colors.size() <= 2)


func test_preview_shows_the_next_pieces_in_order() -> void:
	var game := _game()
	var upcoming := game.bag.preview()
	assert_eq(upcoming.size(), 3)
	game.drop()
	assert_true(game.current == upcoming[0])
