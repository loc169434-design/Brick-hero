class_name CharacterRig
extends Node2D
## One fighter on screen. Shows the pose for how beaten up it is (wear, from health) and what
## it's feeling right now (mood, a short reaction), moves it with small tweens, and adds FX.
## The node's origin is the character's feet.
##
## Art contract (issue #5): assets/characters/<id>/<wear>_<mood>.png, victory.png, defeat.png,
## shield_<layers>.png and rig.json with feet/head/mouth/shield points on a 512 px canvas.
## FX images come from assets/fx/battle/. Anything missing is drawn as a placeholder.

enum Wear { FRESH, BRUISED, BATTERED }

const WEAR_NAMES := ["fresh", "bruised", "battered"]
const CANVAS := 512.0
const DISPLAY_SIZE := 360.0
const DEFAULT_FEET := Vector2(256, 500)
const DEFAULT_HEAD := Vector2(256, 150)
const DEFAULT_MOUTH := Vector2(256, 190)
const FX_DIR := "res://assets/fx/battle/"
## Burst played when the character is hit, by character id.
const HURT_FX := {"scarecrow": "straw"}
## Burst played when the character first looks battered: the rookie's wooden sword snaps.
const BREAK_FX := {"hero_rookie": "splinters"}

## Faces right for 1 (the hero), left for -1 (monsters). Attacks lunge this way.
var facing := 1
var character_id := ""
var wear := Wear.FRESH
var mood := &"idle"
## &"victory" or &"defeat" once the fight is over; moods are ignored after that.
var end_pose := &""
## Shield layers left, or -1 for a character without a shield.
var shield_layers := -1

var _rig := {}
var _textures := {}
## Holds the pose drawing so lunges and shakes don't move the FX already in the air.
var _body: Node2D
var _motion: Tween
## Bumped by every new mood so an older mood's timer doesn't cut a newer one short.
var _mood_serial := 0
var _time := 0.0


func _ready() -> void:
	_body = Node2D.new()
	add_child(_body)
	_body.draw.connect(_draw_body)


func setup(id: String, p_facing: int, layers := -1) -> void:
	character_id = id
	facing = p_facing
	shield_layers = layers
	wear = Wear.FRESH
	mood = &"idle"
	end_pose = &""
	_mood_serial += 1
	_textures.clear()
	_rig = {}
	var rig_path := "res://assets/characters/%s/rig.json" % id
	if ResourceLoader.exists(rig_path):
		var json: JSON = load(rig_path)
		if json.data is Dictionary:
			_rig = json.data
	if _motion:
		_motion.kill()
	_body.position = Vector2.ZERO
	_body.rotation = 0.0
	_body.scale = Vector2.ONE
	for child in get_children():
		if child != _body:
			child.queue_free()
	modulate = Color.WHITE
	_body.queue_redraw()


func set_health(fraction: float) -> void:
	var new_wear := Wear.FRESH
	if fraction <= 0.3:
		new_wear = Wear.BATTERED
	elif fraction <= 0.6:
		new_wear = Wear.BRUISED
	if new_wear == wear:
		return
	if new_wear == Wear.BATTERED and BREAK_FX.has(character_id):
		_burst(BREAK_FX[character_id], _anchor("head") + Vector2(facing * 70, 120))
	wear = new_wear
	_body.queue_redraw()


func set_shield_layers(layers: int) -> void:
	if shield_layers >= 0 and layers < shield_layers:
		_burst("splinters", _shield_point())
	shield_layers = layers
	_body.queue_redraw()


## Shows `new_mood` for `seconds`, then goes back to idle. 0 holds it until the next mood.
func react(new_mood: StringName, seconds := 0.8) -> void:
	if end_pose:
		return
	mood = new_mood
	_mood_serial += 1
	var serial := _mood_serial
	_body.queue_redraw()
	match new_mood:
		&"hurt":
			_move([[Vector2(-facing * 30, 0), 0.06], [Vector2(-facing * 10, 0), 0.08], [Vector2.ZERO, 0.1]])
			if wear == Wear.BATTERED:
				_spin_stars(seconds)
			if HURT_FX.has(character_id):
				_burst(HURT_FX[character_id], _anchor("head") + Vector2(0, 120))
		&"scared":
			_tremble(seconds if seconds > 0.0 else 1.2)
			_drip_sweat()
		&"cheer":
			_move([[Vector2(0, -40), 0.12], [Vector2.ZERO, 0.12], [Vector2(0, -25), 0.1], [Vector2.ZERO, 0.1]])
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
		if serial == _mood_serial and not end_pose:
			mood = &"idle"
			_body.queue_redraw()


## Leaps at the opponent. Returns at the moment of impact so the caller can land the hit.
func attack() -> void:
	if end_pose:
		return
	mood = &"attack"
	_mood_serial += 1
	var serial := _mood_serial
	_body.queue_redraw()
	if _motion:
		_motion.kill()
	_motion = create_tween()
	_motion.tween_property(_body, "position", Vector2(facing * 220, -20), 0.16).set_ease(Tween.EASE_IN)
	await _motion.finished
	_motion = create_tween()
	_motion.tween_property(_body, "position", Vector2.ZERO, 0.25).set_ease(Tween.EASE_OUT).set_delay(0.08)
	_motion.tween_callback(func() -> void:
		if serial == _mood_serial and not end_pose:
			mood = &"idle"
			_body.queue_redraw())


func finish(won: bool) -> void:
	end_pose = &"victory" if won else &"defeat"
	_mood_serial += 1
	if _motion:
		_motion.kill()
	_body.position = Vector2.ZERO
	_body.queue_redraw()
	if won:
		_move([[Vector2(0, -60), 0.18], [Vector2.ZERO, 0.15], [Vector2(0, -30), 0.12], [Vector2.ZERO, 0.12]])
		_flash_teeth()
	else:
		_motion = create_tween()
		_motion.tween_property(_body, "position", Vector2(0, 20), 0.4).set_ease(Tween.EASE_OUT)
		_spin_stars(2.5)


func _process(delta: float) -> void:
	# Breathing: a slow squash that keeps still art from looking frozen.
	_time += delta
	if not end_pose:
		_body.scale = Vector2(1.0 - 0.01 * sin(_time * 2.4), 1.0 + 0.015 * sin(_time * 2.4))


func _move(steps: Array) -> void:
	if _motion:
		_motion.kill()
	_motion = create_tween()
	for step in steps:
		_motion.tween_property(_body, "position", step[0], step[1])


func _tremble(seconds: float) -> void:
	if _motion:
		_motion.kill()
	_motion = create_tween()
	for i in int(seconds / 0.08):
		_motion.tween_property(_body, "position", Vector2(6 if i % 2 == 0 else -6, 0), 0.04)
	_motion.tween_property(_body, "position", Vector2.ZERO, 0.04)


# --- art lookup ------------------------------------------------------------

func _scale() -> float:
	return DISPLAY_SIZE / CANVAS


func _feet() -> Vector2:
	return _vec(_rig.get("feet"), DEFAULT_FEET)


## Canvas point -> position relative to the feet, in screen pixels.
func _to_local(canvas_point: Vector2) -> Vector2:
	return (canvas_point - _feet()) * _scale()


func _anchor(key: String) -> Vector2:
	var anchors: Dictionary = _rig.get("anchors", {})
	var pose: Dictionary = anchors.get(_pose_stem(), anchors.get("fresh_idle", {}))
	var fallback := DEFAULT_MOUTH if key == "mouth" else DEFAULT_HEAD
	return _to_local(_vec(pose.get(key), fallback))


func _shield_point() -> Vector2:
	return _to_local(_vec(_rig.get("shield"), Vector2(140, 330)))


func _pose_stem() -> String:
	if end_pose:
		return end_pose
	return "%s_%s" % [WEAR_NAMES[wear], mood]


## The best image on hand for the current pose, or null for placeholder art.
func _pose_texture() -> Texture2D:
	var wear_name: String = WEAR_NAMES[wear]
	var candidates := [_pose_stem()]
	if end_pose == &"victory":
		candidates.append("%s_cheer" % wear_name)
	elif end_pose == &"defeat":
		candidates.append("%s_hurt" % wear_name)
	else:
		candidates.append_array(["%s_idle" % wear_name, "fresh_%s" % mood])
	candidates.append("fresh_idle")
	for stem in candidates:
		var texture := _texture(stem)
		if texture:
			return texture
	return null


func _texture(stem: String) -> Texture2D:
	if not _textures.has(stem):
		var path := "res://assets/characters/%s/%s.png" % [character_id, stem]
		_textures[stem] = load(path) if ResourceLoader.exists(path) else null
	return _textures[stem]


static func _vec(value: Variant, fallback: Vector2) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(value[0], value[1])
	return fallback


# --- drawing ---------------------------------------------------------------

func _draw_body() -> void:
	var texture := _pose_texture()
	if texture:
		var size := Vector2(CANVAS, CANVAS) * _scale()
		_body.draw_texture_rect(texture, Rect2(-_feet() * _scale(), size), false)
	else:
		_draw_placeholder()
	if shield_layers >= 0 and end_pose != &"defeat":
		_draw_shield()


func _draw_shield() -> void:
	var texture := _texture("shield_%d" % shield_layers)
	if texture:
		_body.draw_texture_rect(texture, Rect2(-_feet() * _scale(), Vector2(CANVAS, CANVAS) * _scale()), false)
		return
	if shield_layers == 0:
		return
	var center := _shield_point()
	var plate := Rect2(center - Vector2(35, 80), Vector2(70, 160))
	_body.draw_rect(plate, Color(0.45, 0.3, 0.18))
	_body.draw_rect(plate, Color(0.62, 0.42, 0.85), false, 6)
	# One crack per lost layer, out of three.
	for i in 3 - shield_layers:
		var y := plate.position.y + 30 + i * 45
		_body.draw_line(Vector2(plate.position.x + 8, y), Vector2(plate.end.x - 8, y + 25), Color(0.15, 0.1, 0.05), 5)


## Stand-in shapes so every pose and wear stage is visible before the art arrives.
func _draw_placeholder() -> void:
	var skin := Color(0.95, 0.8, 0.65)
	var cloth := Color(0.25, 0.4, 0.75)
	var head_r := 42.0
	var body := Rect2(Vector2(-45, -150), Vector2(90, 150))
	match character_id:
		"orc_shield":
			skin = Color(0.48, 0.68, 0.35)
			cloth = Color(0.4, 0.6, 0.3)
			head_r = 62.0
			body = Rect2(Vector2(-80, -170), Vector2(160, 170))
		"scarecrow":
			_draw_scarecrow()
			return

	if end_pose == &"defeat":
		# Slumped on the ground.
		_body.draw_rect(Rect2(body.position.x - 20, -70, body.size.x + 40, 70), cloth)
		_draw_face(Vector2(0, -110), head_r, skin)
		return
	_body.draw_rect(body, cloth)
	var head := Vector2(0, body.position.y - head_r + 4)
	_draw_face(head, head_r, skin)
	if character_id == "hero_rookie":
		var tip := Vector2(facing * 130, -230)
		if wear == Wear.BATTERED:
			tip = Vector2(facing * 85, -150)
		elif mood == &"attack":
			tip = Vector2(facing * 170, -120)
		_body.draw_line(Vector2(facing * 55, -90), tip, Color(0.75, 0.55, 0.3), 12)
		_body.draw_circle(Vector2(-facing * 55, -85), 38, Color(0.55, 0.35, 0.2))
	else:
		var tusk := head + Vector2(0, head_r * 0.4)
		for side in [-1, 1]:
			_body.draw_colored_polygon(PackedVector2Array([tusk + Vector2(side * 30, 0), tusk + Vector2(side * 22, 28), tusk + Vector2(side * 14, 0)]), Color.WHITE)


func _draw_face(head: Vector2, r: float, skin: Color) -> void:
	_body.draw_circle(head, r, skin)
	var ink := Color(0.15, 0.1, 0.08)
	var look := Vector2(facing * r * 0.2, 0) if end_pose != &"victory" else Vector2.ZERO
	var eye_y := head.y - r * 0.15
	for side in [-1, 1]:
		var eye := Vector2(head.x + side * r * 0.35, eye_y) + look
		match mood if not end_pose else end_pose:
			&"hurt", &"defeat":
				_body.draw_line(eye - Vector2(8, 8), eye + Vector2(8, 8), ink, 4)
				_body.draw_line(eye + Vector2(-8, 8), eye + Vector2(8, -8), ink, 4)
			&"scared":
				_body.draw_circle(eye, 10, Color.WHITE)
				_body.draw_circle(eye, 4, ink)
			_:
				_body.draw_circle(eye, 6, ink)
	var mouth := head + Vector2(0, r * 0.45) + look
	match mood if not end_pose else end_pose:
		&"cheer", &"victory", &"attack":
			_body.draw_rect(Rect2(mouth - Vector2(r * 0.45, 6), Vector2(r * 0.9, 16)), Color.WHITE)
			_body.draw_rect(Rect2(mouth - Vector2(r * 0.45, 6), Vector2(r * 0.9, 16)), ink, false, 3)
		&"scared", &"hurt":
			_body.draw_circle(mouth, 9, ink)
		&"defeat":
			_body.draw_arc(mouth + Vector2(0, 10), 14, PI * 1.15, PI * 1.85, 8, ink, 4)
		_:
			_body.draw_line(mouth - Vector2(14, 0), mouth + Vector2(14, 0), ink, 4)
	if wear >= Wear.BRUISED:
		_body.draw_line(head + Vector2(-r, -r * 0.55), head + Vector2(r, -r * 0.35), Color(0.95, 0.95, 0.9), 12)
	if wear == Wear.BATTERED:
		_body.draw_circle(head + Vector2(-r * 0.35, -r * 0.15) + look, 13, Color(0.35, 0.2, 0.45, 0.6))


func _draw_scarecrow() -> void:
	var straw := Color(0.9, 0.78, 0.4)
	var sack := Color(0.85, 0.75, 0.55)
	if end_pose == &"defeat":
		_body.draw_colored_polygon(PackedVector2Array([Vector2(-90, 0), Vector2(-40, -45), Vector2(30, -55), Vector2(90, 0)]), straw)
		_body.draw_circle(Vector2(110, -25), 30, sack)
		return
	var lean := 0.25 if mood == &"hurt" else 0.0
	var top := Vector2(-facing * 60 * lean, -300)
	_body.draw_line(Vector2.ZERO, top, Color(0.45, 0.3, 0.15), 12)
	var arm_y := top.y + 90
	var left_arm := wear != Wear.BATTERED
	_body.draw_line(Vector2(-110 if left_arm else 0, arm_y), Vector2(110, arm_y), Color(0.45, 0.3, 0.15), 10)
	_body.draw_rect(Rect2(top + Vector2(-55, 60), Vector2(110, 120)), Color(0.55, 0.4, 0.6))
	_body.draw_circle(top + Vector2(0, 20), 48, sack)
	_body.draw_colored_polygon(PackedVector2Array([top + Vector2(-70, -15), top + Vector2(0, -75), top + Vector2(70, -15)]), straw.darkened(0.2))
	var ink := Color(0.2, 0.15, 0.1)
	for side in [-1, 1]:
		var eye := top + Vector2(side * 16, 12)
		_body.draw_line(eye - Vector2(7, 7), eye + Vector2(7, 7), ink, 4)
		_body.draw_line(eye + Vector2(-7, 7), eye + Vector2(7, -7), ink, 4)
	_body.draw_line(top + Vector2(-18, 42), top + Vector2(18, 38), ink, 4)
	if wear >= Wear.BRUISED:
		_body.draw_circle(top + Vector2(25, 120), 14, Color(0.2, 0.15, 0.1))
		_body.draw_line(top + Vector2(25, 120), top + Vector2(45, 150), straw, 5)


# --- FX ----------------------------------------------------------------------

func _fx_texture(fx: String) -> Texture2D:
	var path := "%s%s.png" % [FX_DIR, fx]
	return load(path) if ResourceLoader.exists(path) else null


## A one-off FX node at `at` (relative to the feet). Uses the image if present, else `fallback`.
func _spawn_fx(fx: String, at: Vector2, fallback: Callable) -> Node2D:
	var node: Node2D
	var texture := _fx_texture(fx)
	if texture:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2.ONE * 0.7
		node = sprite
	else:
		node = Node2D.new()
		node.draw.connect(fallback.bind(node))
	node.position = at
	add_child(node)
	return node


func _burst(fx: String, at: Vector2) -> void:
	var node := _spawn_fx(fx, at, func(n: Node2D) -> void:
		var color := Color(0.9, 0.78, 0.4) if fx == "straw" else Color(0.6, 0.42, 0.22)
		for i in 8:
			var dir := Vector2.from_angle(i * TAU / 8)
			n.draw_line(dir * 20, dir * 60, color, 6))
	node.scale *= 0.4
	var tween := create_tween().set_parallel()
	tween.tween_property(node, "scale", node.scale * 3.0, 0.45).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 0.0, 0.45).set_delay(0.15)
	tween.chain().tween_callback(node.queue_free)


func _drip_sweat() -> void:
	var node := _spawn_fx("sweat", _anchor("head") + Vector2(facing * 50, -30), func(n: Node2D) -> void:
		for drop in [Vector2(0, 0), Vector2(18, 22), Vector2(-10, 30)]:
			n.draw_circle(drop, 9, Color(0.6, 0.85, 1.0)))
	var tween := create_tween().set_parallel()
	tween.tween_property(node, "position:y", node.position.y + 40, 0.9)
	tween.tween_property(node, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(node.queue_free)


func _spin_stars(seconds: float) -> void:
	var node := _spawn_fx("stars", _anchor("head") + Vector2(0, -60), func(n: Node2D) -> void:
		for i in 3:
			var at := Vector2.from_angle(i * TAU / 3) * Vector2(50, 16)
			n.draw_circle(at, 9, Color(1, 0.9, 0.3)))
	var tween := create_tween()
	tween.tween_property(node, "rotation", TAU * seconds, seconds)
	tween.tween_property(node, "modulate:a", 0.0, 0.2)
	tween.tween_callback(node.queue_free)


## The winning grin: a sparkle pops on the teeth a few times.
func _flash_teeth() -> void:
	var node := _spawn_fx("sparkle", _anchor("mouth") + Vector2(18, -8), func(n: Node2D) -> void:
		var c := Color(1, 1, 0.85)
		n.draw_colored_polygon(PackedVector2Array([Vector2(0, -30), Vector2(7, -7), Vector2(30, 0), Vector2(7, 7), Vector2(0, 30), Vector2(-7, 7), Vector2(-30, 0), Vector2(-7, -7)]), c))
	var base := node.scale
	node.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_interval(0.35)
	for i in 3:
		tween.tween_property(node, "scale", base * 1.2, 0.12).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "scale", Vector2.ZERO, 0.18)
		tween.tween_interval(0.5)
