class_name Resolver
extends RefCounted
## Clears a link, then lets the board settle: specials go off, squares fall, new ones drop in
## from the top, and any straight line that forms clears too. Each clear is one round of the chain.

const NEIGHBORS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


## Plays `path` (already checked by LinkGame) and every round it sets off.
## `refill` returns a new Cell for each square emptied at the top; without it the gaps stay empty.
static func resolve_link(board: BoardModel, rules: BoardRules, path: Array[Vector2i], refill := Callable()) -> Array[ClearStep]:
	var steps: Array[ClearStep] = []
	var step := link_step(board, rules, path)
	while not step.is_empty():
		step.chain = steps.size() + 1
		for p in step.cleared:
			board.set_cell(p, null)
		for s in step.spawned:
			board.set_cell(s["at"], Cell.new(s["color"], s["special"]))
		step.falls = apply_gravity(board, refill)
		steps.append(step)
		step = find_lines(board, rules)
	return steps


## The link's own round, worked out without touching the board. A long link leaves a special
## where the finger let go.
static func link_step(board: BoardModel, rules: BoardRules, path: Array[Vector2i]) -> ClearStep:
	var step := ClearStep.new()
	if path.is_empty():
		return step
	var color := link_color(board, path)
	step.clusters.append({"color": color, "cells": path.duplicate()})
	var kind := special_for_link(rules, path.size())
	if kind != Cell.Special.NONE:
		var spawn_color := Cell.NO_COLOR if kind == Cell.Special.RAINBOW else color
		step.spawned.append({"at": path[-1], "special": kind, "color": spawn_color})
	var marked := {}
	for p in path:
		marked[p] = true
	_trigger_specials(board, step, marked)
	_collect(board, step, marked)
	return step


## The color of the first non-star square, or NO_COLOR for a link of stars only.
static func link_color(board: BoardModel, path: Array[Vector2i]) -> int:
	for p in path:
		var cell := board.get_cell(p)
		if cell and cell.special != Cell.Special.RAINBOW:
			return cell.color
	return Cell.NO_COLOR


static func special_for_link(rules: BoardRules, length: int) -> Cell.Special:
	if length >= rules.star_link:
		return Cell.Special.RAINBOW
	if length >= rules.bomb_link:
		return Cell.Special.BOMB
	if length >= rules.lightning_link:
		return Cell.Special.LIGHTNING
	return Cell.Special.NONE


## Straight lines of rules.min_line or more, worked out without touching the board.
static func find_lines(board: BoardModel, rules: BoardRules) -> ClearStep:
	var step := ClearStep.new()
	var marked := {}
	for run in _runs(board, rules.min_line):
		step.clusters.append(run)
		for p in run["cells"]:
			marked[p] = true
	if marked.is_empty():
		return step
	_trigger_specials(board, step, marked)
	_collect(board, step, marked)
	return step


## Every square falls on its own to the lowest free spot. With `refill`, new squares then drop
## in from above; their falls start above the board (negative y) and carry the new "cell".
static func apply_gravity(board: BoardModel, refill := Callable()) -> Array[Dictionary]:
	var falls: Array[Dictionary] = []
	for x in board.columns:
		var write := board.rows - 1
		for y in range(board.rows - 1, -1, -1):
			var from := Vector2i(x, y)
			var cell := board.get_cell(from)
			if cell == null:
				continue
			if y != write:
				var to := Vector2i(x, write)
				board.set_cell(to, cell)
				board.set_cell(from, null)
				falls.append({"from": from, "to": to})
			write -= 1
		if refill.is_valid():
			var missing := write + 1
			for y in range(write, -1, -1):
				var fresh: Cell = refill.call()
				board.set_cell(Vector2i(x, y), fresh)
				falls.append({"from": Vector2i(x, y - missing), "to": Vector2i(x, y), "cell": fresh})
	return falls


## Runs per color along rows and columns. Stars don't count here: a star is the player's to
## link, so it never clears just because squares fell next to it.
static func _runs(board: BoardModel, min_length: int) -> Array[Dictionary]:
	var runs: Array[Dictionary] = []
	for color in Cell.COLOR_COUNT:
		for horizontal in [true, false]:
			var lanes: int = board.rows if horizontal else board.columns
			var length: int = board.columns if horizontal else board.rows
			for lane in lanes:
				var run: Array[Vector2i] = []
				for i in length + 1:
					var p := Vector2i(i, lane) if horizontal else Vector2i(lane, i)
					var cell := board.get_cell(p) if i < length else null
					if cell and cell.color == color:
						run.append(p)
						continue
					if run.size() >= min_length:
						runs.append({"color": color, "cells": run.duplicate()})
					run.clear()
	return runs


static func _collect(board: BoardModel, step: ClearStep, marked: Dictionary) -> void:
	for p in marked:
		step.cleared.append(p)
		step.cleared_cells.append(board.get_cell(p))


static func _trigger_specials(board: BoardModel, step: ClearStep, marked: Dictionary) -> void:
	var queue: Array[Vector2i] = []
	for p in marked:
		if board.get_cell(p).is_special():
			queue.append(p)
	var done := {}
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		if done.has(p):
			continue
		done[p] = true
		step.triggered.append(p)
		var area := _try_fusion(board, step, p, done, marked)
		if area.is_empty():
			area = _area(board, step, p, board.get_cell(p).special)
		for q in area:
			if marked.has(q) or board.get_cell(q) == null:
				continue
			marked[q] = true
			if board.get_cell(q).is_special():
				queue.append(q)


## Two specials side by side go off as one bigger blast. Returns [] if `p` has no partner.
static func _try_fusion(board: BoardModel, step: ClearStep, p: Vector2i, done: Dictionary, marked: Dictionary) -> Array[Vector2i]:
	var kind: Cell.Special = board.get_cell(p).special
	for d in NEIGHBORS:
		var q: Vector2i = p + d
		var other := board.get_cell(q)
		if other == null or not other.is_special() or done.has(q):
			continue
		# Two lightnings already make two full crosses; fusing them would add nothing.
		if kind == Cell.Special.LIGHTNING and other.special == Cell.Special.LIGHTNING:
			continue
		done[q] = true
		marked[q] = true
		step.triggered.append(q)
		step.fusions.append({"at": p, "with": q, "kinds": [kind, other.special]})
		return _fusion_area(board, step, p, q)
	return []


static func _fusion_area(board: BoardModel, step: ClearStep, p: Vector2i, q: Vector2i) -> Array[Vector2i]:
	var a: Cell.Special = board.get_cell(p).special
	var b: Cell.Special = board.get_cell(q).special
	if a == Cell.Special.RAINBOW and b == Cell.Special.RAINBOW:
		return _everything(board)
	if a == Cell.Special.RAINBOW or b == Cell.Special.RAINBOW:
		# Every square of the partner's color goes off as the partner would.
		var partner := q if a == Cell.Special.RAINBOW else p
		var partner_cell := board.get_cell(partner)
		var area: Array[Vector2i] = []
		for target in _all_of_color(board, partner_cell.color):
			area.append_array(_area(board, step, target, partner_cell.special))
		return area
	if a == Cell.Special.BOMB and b == Cell.Special.BOMB:
		return _square(board, p, 2)
	# Lightning + bomb: a cross three squares wide.
	return _cross(board, p, 1)


static func _area(board: BoardModel, step: ClearStep, p: Vector2i, kind: Cell.Special) -> Array[Vector2i]:
	match kind:
		Cell.Special.LIGHTNING:
			return _cross(board, p, 0)
		Cell.Special.BOMB:
			return _square(board, p, 1)
		Cell.Special.RAINBOW:
			return _all_of_color(board, _rainbow_target(board, step, p))
	return []


## The color of the longest link or line the star was part of, or the board's most common color
## if something else set it off (a blast, or a link of stars only).
static func _rainbow_target(board: BoardModel, step: ClearStep, p: Vector2i) -> int:
	var best_size := 0
	var target := Cell.NO_COLOR
	for cluster in step.clusters:
		var cells: Array[Vector2i] = cluster["cells"]
		if cells.has(p) and cells.size() > best_size:
			best_size = cells.size()
			target = cluster["color"]
	if target != Cell.NO_COLOR:
		return target
	var counts := {}
	for q in _everything(board):
		var c := board.get_cell(q).color
		if c != Cell.NO_COLOR:
			counts[c] = counts.get(c, 0) + 1
	for c in counts:
		if counts[c] > best_size:
			best_size = counts[c]
			target = c
	return target


## Off-board squares are left in; callers skip them since they hold no cell.
static func _cross(board: BoardModel, center: Vector2i, half_width: int) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for y in range(center.y - half_width, center.y + half_width + 1):
		for x in board.columns:
			area.append(Vector2i(x, y))
	for x in range(center.x - half_width, center.x + half_width + 1):
		for y in board.rows:
			area.append(Vector2i(x, y))
	return area


static func _square(board: BoardModel, center: Vector2i, radius: int) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			area.append(Vector2i(x, y))
	return area


static func _all_of_color(board: BoardModel, color: int) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for p in _everything(board):
		if board.get_cell(p).color == color:
			area.append(p)
	return area


static func _everything(board: BoardModel) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for y in board.rows:
		for x in board.columns:
			if board.get_cell(Vector2i(x, y)) != null:
				area.append(Vector2i(x, y))
	return area
