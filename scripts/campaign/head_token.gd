class_name HeadToken
extends Node2D
## A character's head on a round badge, like a game piece on the world map. The head is cut
## from the character's idle clip, so it breathes and blinks with it; without a clip it uses
## the still idle pose. Drawn centred on the node's position.

const RADIUS := 64.0
## Square cut from the 512 px canvas around the head anchor, in canvas pixels.
const CROP := 236.0
const RING := 7.0
const INK := Color(0.16, 0.1, 0.06)
const PAPER := Color(1, 0.97, 0.88)

var character_id := ""

var _sheet: Texture2D
var _frames := 1
var _fps := 12.0
var _columns := 4
var _cell := Vector2(512, 512)
var _center := Vector2(256, 165)
var _time := 0.0
var _mask: Polygon2D
var _head: Sprite2D


func setup(id: String) -> void:
	character_id = id
	var dir := "res://assets/characters/%s/" % id
	var head: Variant = null
	if ResourceLoader.exists(dir + "rig.json"):
		var rig: JSON = load(dir + "rig.json")
		if rig.data is Dictionary:
			head = rig.data.get("anchors", {}).get("fresh_idle", {}).get("head")
	if head is Array:
		_center = Vector2(head[0], head[1]) + Vector2(0, 6)
	_sheet = null
	if ResourceLoader.exists(dir + "anim/anim.json") and ResourceLoader.exists(dir + "anim/fresh_idle.png"):
		var anim: JSON = load(dir + "anim/anim.json")
		var clip: Dictionary = anim.data.get("clips", {}).get("idle", {})
		_sheet = load(dir + "anim/fresh_idle.png")
		_frames = int(clip.get("frames", 1))
		_fps = float(clip.get("fps", 12))
		_columns = int(anim.data.get("columns", 4))
		var size: Array = anim.data.get("frame_size", [512, 512])
		_cell = Vector2(size[0], size[1])
	elif ResourceLoader.exists(dir + "fresh_idle.png"):
		_sheet = load(dir + "fresh_idle.png")
		_frames = 1
		_cell = Vector2(_sheet.get_size())
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	_mask = Polygon2D.new()
	var points := PackedVector2Array()
	for i in 48:
		points.append(Vector2.from_angle(TAU * i / 48.0) * RADIUS)
	_mask.polygon = points
	_mask.color = PAPER
	_mask.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(_mask)
	_head = Sprite2D.new()
	_head.texture = _sheet
	_head.region_enabled = true
	_head.scale = Vector2.ONE * (RADIUS * 2.0 / CROP)
	_head.position = Vector2(0, 8)
	_mask.add_child(_head)
	var ring := Node2D.new()
	ring.draw.connect(func() -> void: ring.draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 64, INK, RING, true))
	add_child(ring)
	_update_frame()


func _process(delta: float) -> void:
	_time += delta
	_update_frame()


func _update_frame() -> void:
	if _head == null or _sheet == null:
		return
	var frame := int(_time * _fps) % maxi(_frames, 1)
	var origin := Vector2(frame % _columns, frame / _columns) * _cell
	_head.region_rect = Rect2(origin + _center - Vector2.ONE * CROP / 2, Vector2.ONE * CROP)


func _draw() -> void:
	# A soft drop shadow so the badge sits on the map.
	draw_circle(Vector2(5, 9), RADIUS + RING / 2, Color(0, 0, 0, 0.3))
