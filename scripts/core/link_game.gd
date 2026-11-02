class_name LinkGame
extends RefCounted
## One board in play. It is always full; a move is a link of rules.min_link or more same-colored
## squares, each beside the last (no diagonals). Stars join any color.

var rules: BoardRules
var board: BoardModel

var _rng := RandomNumberGenerator.new()


## A negative seed picks a random one.
func _init(p_rules: BoardRules = null, seed_value: int = -1) -> void:
	rules = p_rules if p_rules else BoardRules.new()
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	board = BoardModel.new(rules.columns, rules.rows)
	deal()


## Fills the board with no ready-made lines and at least one possible link.
func deal() -> void:
	while true:
		for y in board.rows:
			for x in board.columns:
				board.set_cell(Vector2i(x, y), Cell.new(_color_without_line(Vector2i(x, y))))
		if has_move():
			return


## Whether `p` can be added to the end of `path` (or start it, if `path` is empty).
func can_extend(path: Array[Vector2i], p: Vector2i) -> bool:
	var cell := board.get_cell(p)
	if cell == null or path.has(p):
		return false
	if path.is_empty():
		return true
	var step := p - path[-1]
	if absi(step.x) + absi(step.y) != 1:
		return false
	var color := Resolver.link_color(board, path)
	return color == Cell.NO_COLOR or cell.matches(color)


func is_valid(path: Array[Vector2i]) -> bool:
	if path.size() < rules.min_link:
		return false
	var traced: Array[Vector2i] = []
	for p in path:
		if not can_extend(traced, p):
			return false
		traced.append(p)
	return true


## Plays `path`. Returns null and changes nothing if it isn't a valid link.
func play(path: Array[Vector2i]) -> MoveResult:
	if not is_valid(path):
		return null
	var result := MoveResult.new()
	result.path = path.duplicate()
	result.steps = Resolver.resolve_link(board, rules, result.path, _random_cell)
	if not has_move():
		deal()
		result.reshuffled = true
	return result


func has_move() -> bool:
	for y in board.rows:
		for x in board.columns:
			var start: Array[Vector2i] = [Vector2i(x, y)]
			if _can_grow(start):
				return true
	return false


## Depth-first: can `path` be extended to rules.min_link squares?
func _can_grow(path: Array[Vector2i]) -> bool:
	if path.size() >= rules.min_link:
		return true
	for d in Resolver.NEIGHBORS:
		var next: Vector2i = path[-1] + d
		if can_extend(path, next):
			path.append(next)
			var found := _can_grow(path)
			path.pop_back()
			if found:
				return true
	return false


func _random_cell() -> Cell:
	return Cell.new(_rng.randi_range(0, Cell.COLOR_COUNT - 1))


## A random color that doesn't complete a line with the squares already dealt to the left or above.
func _color_without_line(p: Vector2i) -> int:
	var banned := {}
	var reach := rules.min_line - 1
	for d in [Vector2i.LEFT, Vector2i.UP]:
		var first := board.get_cell(p + d)
		if first == null:
			continue
		var same := true
		for i in range(2, reach + 1):
			var other := board.get_cell(p + d * i)
			same = same and other != null and other.color == first.color
		if same:
			banned[first.color] = true
	var choices: Array[int] = []
	for c in Cell.COLOR_COUNT:
		if not banned.has(c):
			choices.append(c)
	return choices[_rng.randi_range(0, choices.size() - 1)]
