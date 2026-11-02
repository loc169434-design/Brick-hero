class_name Resolver
extends RefCounted
## After a piece locks: find clears, set off specials, drop what's left, and repeat
## until nothing clears. Each repeat is one link of the chain.

const NEIGHBORS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const NO_POS := Vector2i(-1, -1)


## `focus` holds the squares that just moved (the dropped piece, then whatever fell);
## new specials appear there when they can, so they land where the player was looking.
static func resolve(board: BoardModel, rules: BoardRules, focus: Array[Vector2i]) -> Array[ClearStep]:
	var steps: Array[ClearStep] = []
	var moved: Array[Vector2i] = focus.duplicate()
	while true:
		var step := find_clears(board, rules, moved)
		if step.is_empty():
			break
		step.chain = steps.size() + 1
		for p in step.cleared:
			board.set_cell(p, null)
		for s in step.spawned:
			board.set_cell(s["at"], Cell.new(s["color"], s["special"]))
		step.falls = apply_gravity(board)
		steps.append(step)
		moved.clear()
		for fall in step.falls:
			moved.append(fall["to"])
	return steps


## Works out one round without touching the board.
static func find_clears(board: BoardModel, rules: BoardRules, focus: Array[Vector2i]) -> ClearStep:
	var step := ClearStep.new()
	var marked := {}

	for y in board.rows:
		if _row_full(board, y):
			step.full_rows.append(y)
			for x in board.columns:
				marked[Vector2i(x, y)] = true

	for cluster in _find_clusters(board, rules.min_cluster):
		step.clusters.append(cluster)
		for p in cluster["cells"]:
			marked[p] = true

	if marked.is_empty():
		return step

	_plan_spawns(board, rules, step, focus)
	_trigger_specials(board, step, marked)
	for p in marked:
		step.cleared.append(p)
		step.cleared_cells.append(board.get_cell(p))
	return step


## Every square falls on its own, so a cleared gap can pull loose squares into new clusters.
static func apply_gravity(board: BoardModel) -> Array[Dictionary]:
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
	return falls


static func _row_full(board: BoardModel, y: int) -> bool:
	for x in board.columns:
		if board.get_cell(Vector2i(x, y)) == null:
			return false
	return true


static func _find_clusters(board: BoardModel, min_size: int) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for color in Cell.COLOR_COUNT:
		# Per color, because a rainbow can belong to clusters of several colors at once.
		var seen := {}
		for y in board.rows:
			for x in board.columns:
				var start := Vector2i(x, y)
				var cell := board.get_cell(start)
				if cell == null or cell.color != color or seen.has(start):
					continue
				var cells := _flood(board, start, color, seen)
				if cells.size() >= min_size:
					found.append({"color": color, "cells": cells})
	return found


static func _flood(board: BoardModel, start: Vector2i, color: int, seen: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var stack: Array[Vector2i] = [start]
	seen[start] = true
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		cells.append(p)
		for d in NEIGHBORS:
			var q: Vector2i = p + d
			var cell := board.get_cell(q)
			if cell != null and not seen.has(q) and cell.matches(color):
				seen[q] = true
				stack.append(q)
	return cells


static func _plan_spawns(board: BoardModel, rules: BoardRules, step: ClearStep, focus: Array[Vector2i]) -> void:
	var used := {}
	for cluster in step.clusters:
		var cells: Array[Vector2i] = cluster["cells"]
		var kind := Cell.Special.NONE
		if cells.size() >= rules.bomb_cluster:
			kind = Cell.Special.BOMB
		elif cells.size() >= rules.lightning_cluster:
			kind = Cell.Special.LIGHTNING
		else:
			continue
		var at := _pick_spawn(board, cells, focus, used)
		if at != NO_POS:
			used[at] = true
			step.spawned.append({"at": at, "special": kind, "color": cluster["color"]})

	if step.full_rows.size() >= rules.rainbow_rows:
		var y: int = step.full_rows.max()
		var x := focus[0].x if not focus.is_empty() else floori(board.columns / 2.0)
		while used.has(Vector2i(x, y)):
			x = (x + 1) % board.columns
		step.spawned.append({"at": Vector2i(x, y), "special": Cell.Special.RAINBOW, "color": Cell.NO_COLOR})


## Prefers a square that just moved, then the lowest, leftmost one. Skips squares that already
## hold a special, since those are about to go off.
static func _pick_spawn(board: BoardModel, cells: Array[Vector2i], focus: Array[Vector2i], used: Dictionary) -> Vector2i:
	var best := NO_POS
	for p in cells:
		if used.has(p) or board.get_cell(p).is_special():
			continue
		if focus.has(p):
			return p
		if best == NO_POS or p.y > best.y or (p.y == best.y and p.x < best.x):
			best = p
	return best


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


## The color of the biggest cluster the rainbow joined, or the board's most common color
## if a full row took it instead.
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
