class_name CharacterRig
extends Node2D
## One fighter on screen. Shows the pose for how beaten up it is (wear, from health) and what
## it's feeling right now (mood, a short reaction), moves it with small tweens, and adds FX.
## The node's origin is the character's feet.
##
## Art contract (issue #5): assets/characters/<id>/<wear>_<mood>.png, victory.png, defeat.png,
## shield_<layers>.png and rig.json with feet/head/mouth/shield points on a 512 px canvas.
## FX images come from assets/fx/battle/. Anything missing is drawn as a placeholder.
##
## Fight moves (issue #18): extra moods such as throw, leap, bash, kick, drink, dizzy, knocked
## (hero) or throw, charge, dodge, windup and the wearless bald (Orc) are just poses; the
## battle view moves the body with dash_to(), hop_to(), squash() and knockback(). A blow to
## the head spins stars around it (daze).
##
## Frame-by-frame clips: when assets/characters/<id>/anim/anim.json lists a clip named after
## the current mood or end pose (idle, attack, hurt, throw, victory...), that clip plays
## instead of the still pose: <wear>_<clip>.png (or fresh_<clip>.png, or <clip>.png), a grid
## of `columns` frames of `frame_size`, feet at the usual point. Looping clips repeat; others
## hold their last frame. A clip's "impact" frame is when the blow lands (clip_impact), and an
## optional per-frame "shield" track moves the Orc's shield with its hand.

enum Wear { FRESH, BRUISED, BATTERED }

const WEAR_NAMES := ["fresh", "bruised", "battered"]
const CANVAS := 512.0
const DISPLAY_SIZE := 360.0
const DEFAULT_FEET := Vector2(256, 500)
const DEFAULT_HEAD := Vector2(256, 150)
const DEFAULT_MOUTH := Vector2(256, 190)
const FX_DIR := "res://assets/fx/battle/"
## Mixes the body toward white by `flash`, keeping its outline.
const FLASH_SHADER := """
shader_type canvas_item;
uniform float flash = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a);
}
"""
## Burst played when the character is hit, by character id.
const HURT_FX := {"scarecrow": "straw"}
## Burst played when the character first looks battered: the rookie's wooden sword snaps.
const BREAK_FX := {"hero_rookie": "splinters"}

## Faces right for 1 (the hero), left for -1 (monsters). Attacks lunge this way.
## The current clip reached its impact frame.
signal clip_impact(clip: StringName)

const ANIM_FILE := "anim/anim.json"

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
var _flash_material: ShaderMaterial
var _flash_tween: Tween
## Bumped by every new mood so an older mood's timer doesn't cut a newer one short.
var _mood_serial := 0
var _time := 0.0
## Squash and stretch on top of breathing, for slams and landings.
var squash_scale := Vector2.ONE
## anim.json, or empty without clips.
var _anim := {}
## Loaded clip sheets by path; null for a missing one.
var _sheets := {}
## The clip playing: its name, sheet, settings, and seconds since it started. Empty name: none.
var _clip := &""
var _clip_sheet: Texture2D
var _clip_info := {}
var _clip_time := 0.0
var _clip_impacted := false
## What the clip was chosen for, so a new mood (or the same one again) restarts it.
var _clip_key := ""


func _ready() -> void:
	_body = Node2D.new()
	add_child(_body)
	_body.draw.connect(_draw_body)
	var shader := Shader.new()
	shader.code = FLASH_SHADER
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = shader
	_body.material = _flash_material


## The body goes solid white for an instant and fades back: the blow landed.
func flash(seconds := 0.16) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_material.set_shader_parameter("flash", 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_method(func(v: float) -> void: _flash_material.set_shader_parameter("flash", v), 1.0, 0.0, seconds).set_ease(Tween.EASE_IN)


func setup(id: String, p_facing: int, layers := -1) -> void:
	character_id = id
	facing = p_facing
	shield_layers = layers
	wear = Wear.FRESH
	mood = &"idle"
	end_pose = &""
	squash_scale = Vector2.ONE
	_mood_serial += 1
	_textures.clear()
	_sheets.clear()
	_clip = &""
	_clip_key = ""
	_rig = {}
	var rig_path := "res://assets/characters/%s/rig.json" % id
	if ResourceLoader.exists(rig_path):
		var json: JSON = load(rig_path)
		if json.data is Dictionary:
			_rig = json.data
	_anim = {}
	var anim_path := "res://assets/characters/%s/%s" % [id, ANIM_FILE]
	if ResourceLoader.exists(anim_path):
		var anim_json: JSON = load(anim_path)
		if anim_json.data is Dictionary:
			_anim = anim_json.data
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
	# Clips of the old wear are no longer drawn; free their sheets.
	_sheets.clear()
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
	# With an attack clip, arrive just as its impact frame comes up.
	var reach := maxf(impact_seconds(&"attack"), 0.16)
	_motion = create_tween()
	_motion.tween_property(_body, "position", Vector2(facing * 220, -20), reach).set_ease(Tween.EASE_IN)
	await _motion.finished
	reach_impact()
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
	_time += delta
	_update_clip(delta)
	# Breathing: a slow squash that keeps still art from looking frozen. An idle clip breathes
	# by itself.
	var breath := 0.0 if _clip == &"idle" or end_pose else sin(_time * 2.4)
	_body.scale = Vector2(1.0 - 0.01 * breath, 1.0 + 0.015 * breath) * squash_scale


## Whether there's a frame-by-frame clip called `clip` for this character.
func has_clip(clip: StringName) -> bool:
	return _anim.get("clips", {}).has(String(clip)) and _clip_sheet_for(clip) != null


## Seconds from the start of `clip` to its impact frame; 0 without one.
func impact_seconds(clip: StringName) -> float:
	if not has_clip(clip):
		return 0.0
	var info: Dictionary = _anim["clips"][String(clip)]
	return float(info.get("impact", 0)) / float(info.get("fps", 24))


## How long a move's wind-up takes: up to the clip's impact frame, or `fallback` seconds when
## the character has no clip for it.
func strike_time(clip: StringName, fallback: float) -> float:
	var seconds := impact_seconds(clip)
	return seconds if seconds > 0.0 else fallback


func _update_clip(delta: float) -> void:
	var wanted := end_pose if end_pose else mood
	if not has_clip(wanted) and not end_pose and has_clip(&"idle") and not _has_still(wanted):
		wanted = &"idle"
	var key := "%s/%d/%d" % [wanted, wear, _mood_serial if wanted != &"idle" else 0]
	if key != _clip_key:
		_clip_key = key
		_start_clip(wanted if has_clip(wanted) else &"")
	if _clip == &"":
		return
	_clip_time += delta
	var fps := float(_clip_info.get("fps", 24))
	if not _clip_impacted and _clip_info.has("impact") and _clip_time * fps >= float(_clip_info["impact"]):
		_clip_impacted = true
		clip_impact.emit(_clip)
	_body.queue_redraw()


## Jumps the playing clip forward to its impact frame if it hasn't got there yet, so the
## hit-stop that follows a landed blow freezes on the blow, not on the swing before it.
## Call it the moment a blow lands.
func reach_impact() -> void:
	if _clip == &"" or not _clip_info.has("impact"):
		return
	_clip_time = maxf(_clip_time, float(_clip_info["impact"]) / float(_clip_info.get("fps", 24)))
	_body.queue_redraw()


func _start_clip(clip: StringName) -> void:
	_clip = clip
	_clip_time = 0.0
	_clip_impacted = false
	if clip == &"":
		_clip_sheet = null
		_clip_info = {}
	else:
		_clip_sheet = _clip_sheet_for(clip)
		_clip_info = _anim["clips"][String(clip)]
	_body.queue_redraw()


## Whether there's a still pose for `pose_mood`: then a missing clip falls back to that pose
## rather than to the idle clip.
func _has_still(pose_mood: StringName) -> bool:
	return pose_mood != &"idle" and (_texture("%s_%s" % [WEAR_NAMES[wear], pose_mood]) != null or _texture(String(pose_mood)) != null)


func _clip_sheet_for(clip: StringName) -> Texture2D:
	for stem in ["%s_%s" % [WEAR_NAMES[wear], clip], "fresh_%s" % clip, String(clip)]:
		var path := "res://assets/characters/%s/anim/%s.png" % [character_id, stem]
		if not _sheets.has(path):
			_sheets[path] = load(path) if ResourceLoader.exists(path) else null
		if _sheets[path]:
			return _sheets[path]
	return null


## The frame showing now: looping clips wrap, others hold their last frame.
func _clip_frame() -> int:
	var frames := int(_clip_info.get("frames", 1))
	var frame := int(_clip_time * float(_clip_info.get("fps", 24)))
	return frame % frames if _clip_info.get("loop", false) else mini(frame, frames - 1)


## Global position of a point on the current pose: "head", "mouth", "crown" or "hand".
func point(key: String) -> Vector2:
	return _body.to_global(_anchor(key))


## Stars spin around the head: knocked silly for `seconds`.
func daze(seconds := 0.8) -> void:
	_spin_stars(seconds)


## Moves the body to `offset` from the feet over `seconds`. Returns when it gets there.
func dash_to(offset: Vector2, seconds: float, ease_type := Tween.EASE_IN) -> void:
	if _motion:
		_motion.kill()
	_motion = create_tween()
	_motion.tween_property(_body, "position", offset, seconds).set_ease(ease_type).set_trans(Tween.TRANS_QUAD)
	await _motion.finished


## Jumps to `offset` along an arc `height` pixels high. Returns on landing.
func hop_to(offset: Vector2, height: float, seconds: float) -> void:
	if _motion:
		_motion.kill()
	var from := _body.position
	_motion = create_tween()
	_motion.tween_method(func(t: float) -> void:
		_body.position = from.lerp(offset, t) + Vector2(0, -height * 4.0 * t * (1.0 - t)), 0.0, 1.0, seconds)
	await _motion.finished


## Back to standing on its own feet.
func home(seconds := 0.25) -> void:
	await dash_to(Vector2.ZERO, seconds, Tween.EASE_OUT)


## Flattened by `amount` (0.5 = half height), springing back with a wobble.
func squash(amount: float, seconds := 0.6) -> void:
	squash_scale = Vector2(1.0 + amount * 0.8, 1.0 - amount)
	var tween := create_tween()
	tween.tween_property(self, "squash_scale", Vector2.ONE, seconds).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Knocked back `distance` pixels, sliding home again after a moment.
func knockback(distance: float, hold := 0.35) -> void:
	_move([[Vector2(-facing * distance, 0), 0.1], [Vector2(-facing * distance, 0), hold], [Vector2.ZERO, 0.3]])


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
	var stem := _pose_stem()
	if not anchors.has(stem) and anchors.has(String(mood)):
		stem = String(mood)
	var pose: Dictionary = anchors.get(stem, anchors.get("fresh_idle", {}))
	var fallback := DEFAULT_HEAD
	match key:
		"mouth":
			fallback = DEFAULT_MOUTH
		"crown":
			fallback = _vec(pose.get("head"), DEFAULT_HEAD) + Vector2(0, -70)
		"hand":
			fallback = _vec(pose.get("head"), DEFAULT_HEAD) + Vector2(110, 120)
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
	if not end_pose:
		# Poses with no wear stages, like the Orc's bald.png.
		candidates.append(String(mood))
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
	if _clip != &"":
		_draw_clip_frame()
		if shield_layers >= 0 and end_pose != &"defeat" and mood != &"bald":
			_draw_shield(false, _clip_shield_offset())
		return
	var texture := _pose_texture()
	if texture:
		var size := Vector2(CANVAS, CANVAS) * _scale()
		_body.draw_texture_rect(texture, Rect2(-_feet() * _scale(), size), false)
	else:
		_draw_placeholder()
	if shield_layers >= 0 and end_pose != &"defeat" and mood != &"bald":
		_draw_shield(texture == null)


func _draw_clip_frame() -> void:
	var cell: Array = _anim.get("frame_size", [CANVAS, CANVAS])
	var cell_size := Vector2(cell[0], cell[1])
	var columns := int(_anim.get("columns", 4))
	var frame := _clip_frame()
	var source := Rect2(Vector2(frame % columns, frame / columns) * cell_size, cell_size)
	_body.draw_texture_rect_region(_clip_sheet, Rect2(-_feet() * _scale(), cell_size * _scale()), source)


## How far this frame's shield has moved from the rig's shield point, in canvas pixels.
func _clip_shield_offset() -> Vector2:
	var track: Array = _clip_info.get("shield", [])
	if track.is_empty():
		return Vector2.ZERO
	var point: Array = track[mini(_clip_frame(), track.size() - 1)]
	return Vector2(point[0], point[1]) - _vec(_rig.get("shield"), Vector2(140, 330))


## `placeholder_body`: the stand-in plate only goes next to stand-in shapes. A drawn character
## without shield art (the scarecrow) shows its shield in the health panel only.
func _draw_shield(placeholder_body: bool, offset := Vector2.ZERO) -> void:
	var texture := _texture("shield_%d" % shield_layers)
	if texture:
		_body.draw_texture_rect(texture, Rect2((offset - _feet()) * _scale(), Vector2(CANVAS, CANVAS) * _scale()), false)
		return
	if shield_layers == 0 or not placeholder_body:
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
