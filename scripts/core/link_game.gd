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


## Fills the board with no ready-made lines and at least one possible link. Crates, rocks
## and items stay where they are; only the tiles around them are dealt again.
func deal() -> void:
	for attempt in 200:
		for y in board.rows:
			for x in board.columns:
				var p := Vector2i(x, y)
				var cell := board.get_cell(p)
				if cell == null or not (cell.is_blocker() or cell.web or cell.ice > 0 or cell.marked):
					board.set_cell(p, Cell.new(_color_without_line(p)))
		if has_move():
			return


## Lays an overlay on `count` random plain tiles between rows `from_row` and `to_row`:
## "ice" (`layers` thick), "web", or "mark" (gold tiles only). Keeps a link possible.
## Returns where they went.
func cover(kind: String, count: int, layers := 1, from_row := 0, to_row := -1) -> Array[Vector2i]:
	var last := board.rows - 1 if to_row < 0 else mini(to_row, board.rows - 1)
	var spots: Array[Vector2i] = []
	for y in range(from_row, last + 1):
		for x in board.columns:
			var cell := board.get_cell(Vector2i(x, y))
			if cell == null or cell.is_blocker() or cell.is_special() or cell.web or cell.ice > 0 or cell.marked:
				continue
			if kind == "mark" and cell.color != Cell.BlockColor.YELLOW:
				continue
			spots.append(Vector2i(x, y))
	var covered: Array[Vector2i] = []
	while covered.size() < count and not spots.is_empty():
		var p: Vector2i = spots.pop_at(_rng.randi_range(0, spots.size() - 1))
		var cell := board.get_cell(p)
		match kind:
			"ice":
				cell.ice = layers
			"web":
				cell.web = true
				if not has_move():
					cell.web = false
					continue
			"mark":
				cell.marked = true
		covered.append(p)
	return covered


## Counts the cells for which `test` is true.
func count(test: Callable) -> int:
	var total := 0
	for y in board.rows:
		for x in board.columns:
			var cell := board.get_cell(Vector2i(x, y))
			if cell and test.call(cell):
				total += 1
	return total


## What the board does on its own once a move has played out, before the monster's turn:
## time bombs and potion bottles tick down and go off at zero (they leave the board), and mud
## that wasn't hit this move creeps onto a tile beside it. Returns
## {"bombs": [Vector2i…], "potions": [Vector2i…], "mud": Vector2i or null, "toads": int}.
func end_turn(mud_hit: bool) -> Dictionary:
	var events := {"bombs": [], "potions": [], "mud": null, "toads": 0}
	var muds: Array[Vector2i] = []
	for y in board.rows:
		for x in board.columns:
			var p := Vector2i(x, y)
			var cell := board.get_cell(p)
			if cell == null or not cell.is_blocker():
				continue
			match cell.blocker:
				"time_bomb", "potion_bottle":
					cell.timer -= 1
					if cell.timer <= 0:
						events["bombs" if cell.blocker == "time_bomb" else "potions"].append(p)
						board.set_cell(p, Cell.new(_rng.randi_range(0, Cell.COLOR_COUNT - 1)))
				"mud":
					muds.append(p)
				"poison_toad":
					events["toads"] += 1
	if not mud_hit and not muds.is_empty():
		muds.shuffle()
		for p in muds:
			var spots: Array[Vector2i] = []
			for d in Resolver.NEIGHBORS:
				var q: Vector2i = p + d
				var cell := board.get_cell(q)
				if cell and not cell.is_blocker() and not cell.is_special():
					spots.append(q)
			if not spots.is_empty():
				var q: Vector2i = spots[_rng.randi_range(0, spots.size() - 1)]
				board.set_cell(q, Cell.obstacle("mud", 1))
				if has_move():
					events["mud"] = q
					break
				board.set_cell(q, Cell.new(_rng.randi_range(0, Cell.COLOR_COUNT - 1)))
	if not has_move():
		deal()
	return events


## Puts `count` obstacles of `kind` (`layers` thick; 0 for items) on random tiles between rows
## `from_row` and `to_row`, keeping at least one link possible. Returns where they went.
func place(kind: String, count: int, layers := 0, from_row := 0, to_row := -1) -> Array[Vector2i]:
	var last := board.rows - 1 if to_row < 0 else mini(to_row, board.rows - 1)
	var spots: Array[Vector2i] = []
	for y in range(from_row, last + 1):
		for x in board.columns:
			var cell := board.get_cell(Vector2i(x, y))
			if cell and not cell.is_blocker() and not cell.is_special():
				spots.append(Vector2i(x, y))
	var placed: Array[Vector2i] = []
	while placed.size() < count and not spots.is_empty():
		var p: Vector2i = spots.pop_at(_rng.randi_range(0, spots.size() - 1))
		var before := board.get_cell(p)
		board.set_cell(p, Cell.obstacle(kind, layers))
		if has_move():
			placed.append(p)
		else:
			board.set_cell(p, before)
	return placed


## Whether `p` can be added to the end of `path` (or start it, if `path` is empty).
func can_extend(path: Array[Vector2i], p: Vector2i) -> bool:
	var cell := board.get_cell(p)
	if cell == null or cell.is_blocker() or cell.web or path.has(p):
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


## A new square dropping in. Now and then a red one is a critical tile.
func _random_cell() -> Cell:
	var cell := Cell.new(_rng.randi_range(0, Cell.COLOR_COUNT - 1))
	if cell.color == Cell.BlockColor.RED and _rng.randf() < rules.crit_tile_chance and critical_tiles() < rules.max_crit_tiles:
		cell.critical = true
	return cell


func critical_tiles() -> int:
	var count := 0
	for y in board.rows:
		for x in board.columns:
			var cell := board.get_cell(Vector2i(x, y))
			if cell and cell.critical:
				count += 1
	return count


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
