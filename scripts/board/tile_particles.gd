class_name TileParticles
extends Node2D
## Light particles over the board, drawn by hand from the white masks in assets/fx/particles/
## (issue #17) and tinted per tile color. Two of these sit over the board: one blends
## normally for solid shards, one adds light for sparks, glows and the orbs that fly from a
## cleared tile to the part of the fight it feeds (red to the sword, green to the health bar...).
## Without the masks, particles are drawn as plain circles.

## An orb reached its target, at `at` in this node's coordinates.
signal orb_landed(color: Color, at: Vector2)

const DIR := "res://assets/fx/particles/"
const GRAVITY := 1800.0
const ORB_TIME := Vector2(0.45, 0.65)

@export var additive := false

var _textures := {}
## {"tex", "pos", "vel", "t", "life", "color", "size", "spin", "rot", "grow", "fade", "gravity"}
var _particles := []
## {"from", "to", "bend", "t", "life", "color", "delay"}
var _orbs := []
var _time := 0.0


func _ready() -> void:
	if additive:
		var blend := CanvasItemMaterial.new()
		blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = blend
	for key in ["spark", "glow", "star", "shard", "ring"]:
		if ResourceLoader.exists(DIR + key + ".png"):
			_textures[key] = load(DIR + key + ".png")


func clear() -> void:
	_particles.clear()
	_orbs.clear()
	queue_redraw()


## Tile pieces thrown out of a cleared square: falls under gravity and spins.
func shatter(center: Vector2, color: Color, count := 5) -> void:
	for i in count:
		var direction := Vector2.from_angle(randf_range(-PI * 0.95, -PI * 0.05))
		_add("shard", center + direction * 20, direction * randf_range(350, 750), randf_range(0.5, 0.8), color, randf_range(26, 44), {"spin": randf_range(-12, 12), "gravity": GRAVITY})


## Light bursting out of a cleared square: sparks fly out, a glow flashes and a ring spreads.
func flare(center: Vector2, color: Color, strength := 1.0) -> void:
	for i in roundi(5 * strength):
		var direction := Vector2.from_angle(randf() * TAU)
		_add("spark", center, direction * randf_range(250, 600) * strength, randf_range(0.25, 0.45), color.lightened(0.4), randf_range(28, 48), {"spin": randf_range(-6, 6)})
	_add("glow", center, Vector2.ZERO, 0.3, color, 120 * strength, {"grow": 1.8})
	_add("ring", center, Vector2.ZERO, 0.35, color.lightened(0.3), 70 * strength, {"grow": 2.6})


## A glowing ball flying from `from` to `to` on a curve, trailing sparks. Lands with a ring.
func orb(from: Vector2, to: Vector2, color: Color, delay := 0.0) -> void:
	var side := 1.0 if randf() < 0.5 else -1.0
	var bend := (to - from).orthogonal().normalized() * randf_range(120, 260) * side
	_orbs.append({"from": from, "to": to, "bend": bend, "t": 0.0, "life": randf_range(ORB_TIME.x, ORB_TIME.y), "color": color, "delay": delay})


func is_busy() -> bool:
	return not _particles.is_empty() or not _orbs.is_empty()


func _process(delta: float) -> void:
	_time += delta
	for p in _particles:
		p["t"] += delta
		p["vel"].y += p.get("gravity", 0.0) * delta
		p["vel"] *= 1.0 - 2.5 * delta if p.get("gravity", 0.0) == 0.0 else 1.0
		p["pos"] += p["vel"] * delta
		p["rot"] += p.get("spin", 0.0) * delta
	_particles = _particles.filter(func(p: Dictionary) -> bool: return p["t"] < p["life"])
	for o in _orbs:
		if o["delay"] > 0.0:
			o["delay"] -= delta
			continue
		o["t"] += delta
		var at := _orb_position(o)
		if randf() < 0.7:
			_add("spark", at, Vector2.from_angle(randf() * TAU) * 60, 0.25, o["color"].lightened(0.3), 22)
		if o["t"] >= o["life"]:
			flare(o["to"], o["color"], 0.6)
			orb_landed.emit(o["color"], o["to"])
	_orbs = _orbs.filter(func(o: Dictionary) -> bool: return o["t"] < o["life"])
	queue_redraw()


func _draw() -> void:
	for p in _particles:
		var k: float = p["t"] / p["life"]
		var size: float = p["size"] * lerpf(1.0, p.get("grow", 1.0), k)
		var color: Color = p["color"]
		color.a *= 1.0 - k * k
		_draw_mask(p["tex"], p["pos"], size, p["rot"], color)
	for o in _orbs:
		if o["delay"] > 0.0:
			continue
		var at := _orb_position(o)
		_draw_mask("glow", at, 90, 0.0, o["color"])
		_draw_mask("spark", at, 56, _time * 8.0, Color(1, 1, 1, 0.9))


func _orb_position(o: Dictionary) -> Vector2:
	var k := ease(clampf(o["t"] / o["life"], 0.0, 1.0), 2.2)
	var from: Vector2 = o["from"]
	var to: Vector2 = o["to"]
	var control: Vector2 = (from + to) / 2 + o["bend"]
	return from.lerp(control, k).lerp(control.lerp(to, k), k)


func _add(tex: String, pos: Vector2, vel: Vector2, life: float, color: Color, size: float, extra := {}) -> void:
	var p := {"tex": tex, "pos": pos, "vel": vel, "t": 0.0, "life": life, "color": color, "size": size, "rot": randf() * TAU}
	p.merge(extra)
	_particles.append(p)


func _draw_mask(tex: String, at: Vector2, size: float, rot: float, color: Color) -> void:
	if not _textures.has(tex):
		draw_circle(at, size * 0.3, color)
		return
	draw_set_transform(at, rot, Vector2.ONE)
	draw_texture_rect(_textures[tex], Rect2(Vector2(-size, -size) / 2, Vector2(size, size)), false, color)
	draw_set_transform(Vector2.ZERO)
