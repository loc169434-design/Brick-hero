class_name BoardJuice
extends Node2D
## The extra show over the board when tiles go: a praise word slammed in for a big move
## (TUYỆT! … THẦN SẦU!) with rays turning behind it and a shower of stars, a "+N" rising from
## each round, a shockwave ring from every special that goes off, a white flash for fusions,
## and the board's frame glowing hotter round by round through a chain. Drawn in board
## coordinates, above the tiles and their particles.

## Praise words, from the smallest big move up. See praise_for().
const PRAISES := ["TỐT LẮM!", "TUYỆT!", "XUẤT SẮC!", "SIÊU ĐẲNG!", "THẦN SẦU!"]
const PRAISE_TIME := 1.25
const PRAISE_SIZE := 92
const RING_TIME := 0.45
const FLOAT_TIME := 0.85
const FLOAT_RISE := 80.0
const FLASH_TIME := 0.3
const STAR_COUNT := 26
const OUTLINE := Color(0.12, 0.06, 0.04)

var cell_size := 100.0
var board_size := Vector2(700, 800)
var font: Font

var _praise := ""
var _praise_t := -1.0
var _praise_level := 0
## {"at", "t", "color", "reach"}
var _rings: Array[Dictionary] = []
## {"text", "at", "t", "color", "size"}
var _floats: Array[Dictionary] = []
## {"at", "vel", "t", "life", "color", "spin"}
var _stars: Array[Dictionary] = []
var _flash := 0.0
## 0..1 heat of the frame's glow through a chain, cooling between moves.
var _heat := 0.0
var _heat_color := Color.WHITE
var _time := 0.0


func _ready() -> void:
	if font == null:
		font = ThemeDB.fallback_font


## Which praise a move earns, as an index into PRAISES, or -1 for none. Counts the tiles it
## cleared, specials set off (worth 4) and fusions (8), and how long its chain ran.
static func praise_for(result: MoveResult) -> int:
	var score := 0
	for step in result.steps:
		score += step.cleared.size() + 4 * step.triggered.size() + 8 * step.fusions.size()
	var chain := result.chain_length()
	if score >= 40 or chain >= 5:
		return 4
	if score >= 28 or chain >= 4:
		return 3
	if score >= 18 or chain >= 3:
		return 2
	if score >= 11 or chain >= 2:
		return 1
	if result.path.size() >= 5:
		return 0
	return -1


func clear() -> void:
	_praise_t = -1.0
	_rings.clear()
	_floats.clear()
	_stars.clear()
	_flash = 0.0
	_heat = 0.0
	queue_redraw()


## One round of a move going off: its "+N" in the color it cleared most of, rings for its
## specials and a flash for fusions, and the frame warming with the chain.
func play_round(step: ClearStep, colors: Dictionary) -> void:
	var tiles: Array[Vector2] = []
	var counts := {}
	for i in step.cleared.size():
		var cell: Cell = step.cleared_cells[i]
		if cell.is_blocker():
			continue
		tiles.append(_center(step.cleared[i]))
		counts[cell.color] = int(counts.get(cell.color, 0)) + 1
	if not tiles.is_empty():
		var middle := Vector2.ZERO
		for at in tiles:
			middle += at
		middle /= tiles.size()
		var main := -1
		for color: int in counts:
			if main < 0 or counts[color] > counts[main]:
				main = color
		var tint: Color = colors.get(main, Color(1, 0.95, 0.6))
		_floats.append({"text": "+%d" % tiles.size(), "at": middle, "t": 0.0, "color": tint.lightened(0.25), "size": 40 + mini(tiles.size(), 20) * 2})
	for p: Vector2i in step.triggered:
		_rings.append({"at": _center(p), "t": 0.0, "color": Color(1, 0.9, 0.55), "reach": cell_size * 2.6})
	for fusion: Dictionary in step.fusions:
		_rings.append({"at": _center(fusion["at"]), "t": 0.0, "color": Color(1, 1, 1), "reach": cell_size * 5.0})
		_flash = 1.0
	if step.chain >= 2:
		_heat = minf(1.0, 0.25 + 0.2 * step.chain)
		_heat_color = Color.from_hsv(fmod(0.12 + 0.13 * step.chain, 1.0), 0.8, 1.0)


## The move has played out: the praise it earned, if any.
func praise(result: MoveResult) -> void:
	var level := praise_for(result)
	if level < 0:
		return
	_praise = PRAISES[level]
	_praise_level = level
	_praise_t = 0.0
	Sfx.play(&"praise", 1.0 + 0.06 * level)
	for i in STAR_COUNT * (level + 1) / 3:
		var at := Vector2(randf_range(0.1, 0.9) * board_size.x, board_size.y * 0.5)
		var vel := Vector2(randf_range(-260, 260), randf_range(-900, -450))
		_stars.append({"at": at, "vel": vel, "t": 0.0, "life": randf_range(0.9, 1.4), "color": Color.from_hsv(randf(), 0.55, 1.0), "spin": randf_range(-8, 8)})


func _center(p: Vector2i) -> Vector2:
	return (Vector2(p) + Vector2(0.5, 0.5)) * cell_size


func _process(delta: float) -> void:
	_time += delta
	if _praise_t >= 0.0:
		_praise_t += delta / PRAISE_TIME
		if _praise_t >= 1.0:
			_praise_t = -1.0
	for ring in _rings:
		ring["t"] += delta / RING_TIME
	_rings = _rings.filter(func(r: Dictionary) -> bool: return r["t"] < 1.0)
	for f in _floats:
		f["t"] += delta / FLOAT_TIME
	_floats = _floats.filter(func(f: Dictionary) -> bool: return f["t"] < 1.0)
	for s in _stars:
		s["t"] += delta
		s["vel"].y += 1400.0 * delta
		s["at"] += s["vel"] * delta
	_stars = _stars.filter(func(s: Dictionary) -> bool: return s["t"] < s["life"])
	_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
	_heat = maxf(_heat - delta * 0.35, 0.0)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, board_size)
	if _heat > 0.01:
		var pulse := 0.6 + 0.4 * sin(_time * 10.0)
		for k in 3:
			draw_rect(rect.grow(4 + k * 6), Color(_heat_color, _heat * pulse * (0.5 - k * 0.14)), false, 8.0)
	if _flash > 0.0:
		draw_rect(rect, Color(1, 1, 1, 0.45 * _flash))
	for ring in _rings:
		var t: float = ring["t"]
		var radius: float = ring["reach"] * ease(t, 0.4)
		draw_arc(ring["at"], radius, 0, TAU, 48, Color(ring["color"], 1.0 - t), 14.0 * (1.0 - t) + 2.0, true)
	for f in _floats:
		var t: float = f["t"]
		var at: Vector2 = f["at"] + Vector2(0, -FLOAT_RISE * ease(t, 0.5))
		var size: int = f["size"]
		var pop := 1.0 + 0.4 * maxf(0.0, 1.0 - t * 6.0)
		_text(f["text"], at, roundi(size * pop), Color(f["color"], 1.0 - maxf(t - 0.6, 0.0) / 0.4))
	for s in _stars:
		var alpha := 1.0 - float(s["t"]) / float(s["life"])
		_star(s["at"], 14.0, s["t"] * s["spin"], Color(s["color"], alpha))
	if _praise_t >= 0.0:
		_draw_praise()


## The praise word: slams in from big with an overshoot, wobbles, rays turning behind it, each
## letter its own color for the best ones, then lifts away and fades.
func _draw_praise() -> void:
	var t := _praise_t
	var center := Vector2(board_size.x / 2, board_size.y * 0.58)
	var grow := 2.2 - 1.2 * ease(minf(t / 0.18, 1.0), -2.6) if t < 0.18 else 1.0 + 0.06 * sin((t - 0.18) * 20.0) * (1.0 - t)
	var alpha := 1.0 if t < 0.75 else 1.0 - (t - 0.75) / 0.25
	var lift := -40.0 * maxf(t - 0.75, 0.0) / 0.25
	center.y += lift
	# Rays.
	var rays := 12
	for i in rays:
		var angle := _time * 0.8 + i * TAU / rays
		var a := center + Vector2.from_angle(angle - 0.12) * 40.0
		var b := center + Vector2.from_angle(angle) * (260.0 + 40.0 * _praise_level) * grow
		var c := center + Vector2.from_angle(angle + 0.12) * 40.0
		draw_colored_polygon(PackedVector2Array([a, b, c]), Color(1, 0.9, 0.5, 0.18 * alpha))
	var size := roundi((PRAISE_SIZE + 10 * _praise_level) * grow)
	var width := font.get_string_size(_praise, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_set_transform(center, 0.05 * sin(_time * 7.0) * (1.0 - t), Vector2.ONE)
	var x := -width / 2
	var baseline := size * 0.35
	for i in _praise.length():
		var letter := _praise[i]
		var color := Color(1, 0.88, 0.25)
		if _praise_level >= 2:
			color = Color.from_hsv(fmod(i * 0.09 + _time * 0.6, 1.0), 0.65, 1.0)
		var bob := sin(_time * 12.0 + i * 0.7) * 6.0 * (1.0 if _praise_level >= 3 else 0.0)
		draw_string_outline(font, Vector2(x, baseline + bob), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(size / 6, 6), Color(OUTLINE, alpha))
		draw_string(font, Vector2(x, baseline + bob), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(color, alpha))
		x += font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_set_transform(Vector2.ZERO)


func _text(text: String, at: Vector2, size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := at + Vector2(-width / 2, size * 0.35)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(size / 7, 4), Color(OUTLINE, color.a))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _star(at: Vector2, radius: float, angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	for k in 10:
		var r := radius if k % 2 == 0 else radius * 0.45
		points.append(at + Vector2(0, -r).rotated(angle + k * TAU / 10))
	draw_colored_polygon(points, color)
