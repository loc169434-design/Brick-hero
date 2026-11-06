class_name Resolver
extends RefCounted
## Clears a link, then lets the board settle: specials go off, squares fall, new ones drop in
## from the top, and any straight line that forms clears too. Each clear is one round of the chain.

const NEIGHBORS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


## Plays `path` (already checked by LinkGame) and every round it sets off.
## `refill` returns a new Cell for each square emptied at the top; without it the gaps stay empty.
static func resolve_link(board: BoardModel, rules: BoardRules, path: Array[Vector2i], refill := Callable()) -> Array[ClearStep]:
	var steps: Array[ClearStep] = []
	var chain := 0
	var step := link_step(board, rules, path)
	while not step.is_empty():
		if step.rescued.is_empty():
			chain += 1
		step.chain = maxi(chain, 1)
		for h in step.hit:
			board.get_cell(h["at"]).layers = h["layers"]
		for t in step.thawed:
			board.get_cell(t["at"]).ice = t["ice"]
		for b in step.broken:
			if b["kind"] == "web":
				board.get_cell(b["at"]).web = false
		for p in step.cleared:
			board.set_cell(p, null)
		for s in step.spawned:
			board.set_cell(s["at"], Cell.new(s["color"], s["special"]))
		step.falls = apply_gravity(board, refill)
		steps.append(step)
		step = rescue_step(board)
		if step.is_empty():
			step = find_lines(board, rules)
	return steps


## Items resting on the bottom row are rescued: taken off the board as a round of their own.
static func rescue_step(board: BoardModel) -> ClearStep:
	var step := ClearStep.new()
	for x in board.columns:
		var p := Vector2i(x, board.rows - 1)
		var cell := board.get_cell(p)
		if cell and cell.is_item():
			step.cleared.append(p)
			step.cleared_cells.append(cell)
			step.rescued.append({"at": p, "kind": cell.blocker})
	return step


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
	_hit_blockers(board, step, marked)
	_collect(board, step, marked)
	return step


## The color of the first plain square, or NO_COLOR for a link of specials only.
static func link_color(board: BoardModel, path: Array[Vector2i]) -> int:
	for p in path:
		var cell := board.get_cell(p)
		if cell and not cell.is_special():
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
	_hit_blockers(board, step, marked)
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


## Runs per color along rows and columns. Specials don't count here: they're the player's to
## link, so one never goes off just because squares fell next to it.
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
					if cell and not cell.is_special() and cell.color == color:
						run.append(p)
						continue
					if run.size() >= min_length:
						runs.append({"color": color, "cells": run.duplicate()})
					run.clear()
	return runs


## Crates and rocks take one layer off per round when a square beside them clears, or when a
## blast covers them; at none left they break and clear with the round. Blasts pass over items.
static func _hit_blockers(board: BoardModel, step: ClearStep, marked: Dictionary) -> void:
	var hits := {}
	var webs := {}
	for p: Vector2i in marked.keys():
		var cell := board.get_cell(p)
		if cell and cell.is_blocker():
			marked.erase(p)
			if not cell.is_item():
				hits[p] = true
		elif cell and cell.web:
			# A blast tears the web away; the tile under it stays.
			marked.erase(p)
			webs[p] = true
		elif cell and cell.ice > 0:
			# Ice takes the blow: one layer melts and the tile stays.
			marked.erase(p)
			step.thawed.append({"at": p, "ice": cell.ice - 1})
			if cell.ice == 1:
				step.broken.append({"at": p, "kind": "ice"})
	for p: Vector2i in marked:
		for d in NEIGHBORS:
			var q: Vector2i = p + d
			var other := board.get_cell(q)
			if other and other.is_blocker() and not other.is_item():
				hits[q] = true
			elif other and other.web and not marked.has(q):
				webs[q] = true
	for q: Vector2i in webs:
		step.broken.append({"at": q, "kind": "web"})
	for q: Vector2i in hits:
		var cell := board.get_cell(q)
		if cell.layers > 1:
			step.hit.append({"at": q, "layers": cell.layers - 1})
		else:
			marked[q] = true
			step.broken.append({"at": q, "kind": cell.blocker})


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
		# Every square of the star's color goes off as the partner would. The color is one the
		# player can see (see _rainbow_target), never the partner's own: specials show none.
		var partner_kind := b if a == Cell.Special.RAINBOW else a
		var area: Array[Vector2i] = []
		for target in _all_of_color(board, _rainbow_target(board, step, [p, q])):
			area.append_array(_area(board, step, target, partner_kind))
		return area
	if a == Cell.Special.BOMB and b == Cell.Special.BOMB:
		return _square(board, p, 2)
	if a == Cell.Special.LIGHTNING and b == Cell.Special.LIGHTNING:
		# Eight ways: the row, the column and both diagonals.
		var area := _cross(board, p, 0)
		area.append_array(_diagonals(board, p))
		return area
	# Lightning + bomb: a cross three squares wide.
	return _cross(board, p, 1)


static func _area(board: BoardModel, step: ClearStep, p: Vector2i, kind: Cell.Special) -> Array[Vector2i]:
	match kind:
		Cell.Special.LIGHTNING:
			return _cross(board, p, 0)
		Cell.Special.BOMB:
			return _square(board, p, 1)
		Cell.Special.RAINBOW:
			return _all_of_color(board, _rainbow_target(board, step, [p]))
	return []


## The color a star goes after, one the player can see: that of the longest colored link or
## line through any of `squares` (the star, and its partner in a fusion), else the board's most
## common plain color, ties to the first in Cell.BlockColor order. NO_COLOR on a board of
## specials only.
static func _rainbow_target(board: BoardModel, step: ClearStep, squares: Array[Vector2i]) -> int:
	var best_size := 0
	var target := Cell.NO_COLOR
	for cluster in step.clusters:
		var cells: Array[Vector2i] = cluster["cells"]
		if cluster["color"] == Cell.NO_COLOR or cells.size() <= best_size:
			continue
		if squares.any(func(s: Vector2i) -> bool: return cells.has(s)):
			best_size = cells.size()
			target = cluster["color"]
	if target != Cell.NO_COLOR:
		return target
	var counts := {}
	for q in _everything(board):
		var cell := board.get_cell(q)
		if not cell.is_special():
			counts[cell.color] = counts.get(cell.color, 0) + 1
	for c in Cell.COLOR_COUNT:
		if counts.get(c, 0) > best_size:
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


## Both diagonals through `center`, edge to edge.
static func _diagonals(board: BoardModel, center: Vector2i) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	var reach := maxi(board.columns, board.rows)
	for i in range(-reach, reach + 1):
		area.append(center + Vector2i(i, i))
		area.append(center + Vector2i(i, -i))
	return area


static func _square(board: BoardModel, center: Vector2i, radius: int) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			area.append(Vector2i(x, y))
	return area


## The plain squares of `color`: specials keep a color but don't show it, so a star passes them by.
static func _all_of_color(board: BoardModel, color: int) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for p in _everything(board):
		var cell := board.get_cell(p)
		if cell.color == color and not cell.is_special() and not cell.is_blocker():
			area.append(p)
	return area


static func _everything(board: BoardModel) -> Array[Vector2i]:
	var area: Array[Vector2i] = []
	for y in board.rows:
		for x in board.columns:
			if board.get_cell(Vector2i(x, y)) != null:
				area.append(Vector2i(x, y))
	return area
