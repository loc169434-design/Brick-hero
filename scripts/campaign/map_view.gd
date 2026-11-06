class_name MapView
extends Node2D
## The world map between fights: the painted road from the castle to the dragon's cave, and
## on it every stop as a game piece. A locked stop is a padlock; when the road reaches it the
## padlock bursts open and the monster pops up out of the ground, standing on its stop; a
## cleared stop has a flag planted in it and the stars won there. The hero is a head on a
## badge beside the next stop. Tapping an open or cleared stop asks for that fight
## (stop_chosen). A map taller than the screen scrolls with a drag.
##
## The painted map lives on through assets/bg/campaign/ambience.json (art issue #49): smoke
## curling from chimneys, glints on the water, flags flapping on the Orc camp's poles,
## waterfalls, gold twinkling in the dragon's hoard, and soft clouds drifting over it all with
## their shadows on the land. Its `profiles` name the file laid out for each number of
## segments, since every position is on the whole map.

signal stop_chosen(id: String)
## The forge button was pressed.
signal forge_requested

const SCREEN := Vector2(1080, 1920)
## Map segments, segment 1 at the bottom: assets/bg/campaign/segment_01.png and up.
const SEGMENT := "res://assets/bg/campaign/segment_%02d.png"
const AMBIENCE := "res://assets/bg/campaign/ambience.json"
## Cloud drift when the ambience doesn't say: opacity, shadow, its offset, speeds, wrap.
const CLOUD_MOTION := {"opacity": 0.55, "shadow_opacity": 0.16, "shadow_offset": [90, 260], "speed_px_per_second": [14, 30], "wrap_x": [-500, 1280]}
## Clouds on the map for each segment, counting those the ambience places.
const CLOUDS_PER_SEGMENT := 2
const LOCK_ICON := "res://assets/ui/map_node_locked.png"
const COIN := "res://assets/fx/props/coin.png"
const FONT := "res://assets/fonts/baloo_2_extra_bold.ttf"
const NODE_SIZE := 128.0
## Taps this close to a stop's centre pick it.
const TAP_REACH := 96.0
## A press that moves further than this is a drag, not a tap.
const DRAG_SLOP := 24.0
## The hero's badge floats beside the next stop.
const HERO_OFFSET := Vector2(-124, -60)
## Monsters stand on their stop at this size, feet a little below its centre.
const MONSTER_SCALE := 0.5
const MONSTER_FEET := Vector2(0, 40)
const WALK_SECONDS := 1.1
const LABEL_SIZE := 32
const INK := Color(0.16, 0.1, 0.06)
const PAPER := Color(1, 0.97, 0.88)
const GOLD := Color(1, 0.8, 0.25)
const FLAG := Color(0.86, 0.2, 0.18)
const MOUND := Color(0.45, 0.3, 0.16)

var campaign: Campaign

## Sky over the map (see _move_sky): drifting clouds, birds, the swamp's fireflies.
const CLOUDS := 9
const CLOUD_ART := ["res://assets/bg/orc_camp/cloud_1.png", "res://assets/bg/orc_camp/cloud_2.png", "res://assets/bg/orc_camp/cloud_3.png"]
const BIRD_ART := "res://assets/bg/orc_camp/bird.png"
const FIREFLY_ART := "res://assets/bg/swamp/firefly.png"
## Segments (counted from 1 at the bottom) where fireflies come out.
const FIREFLY_SEGMENTS := [3]
const FIREFLIES := 26
var _cloud_art: Array[Texture2D] = []
var _clouds: Array[Dictionary] = []
var _bird_art: Texture2D
var _birds: Array[Dictionary] = []
var _next_bird := 2.0
var _firefly_art: Texture2D
var _fireflies: Array[Vector2] = []
## The map's segments, bottom one first.
var _segments: Array[Texture2D] = []
## Marks on special stops: hard, boss, bonus, petal.
var _badges := {}
## The map's moving touches, as read from AMBIENCE, and their textures by name.
var _ambience := {}
var _ambience_art := {}
var _ambience_path := ""
## How clouds drift: CLOUD_MOTION, or the ambience's cloud_motion.
var _cloud_motion := CLOUD_MOTION
var _lock: Texture2D
var _coin: Texture2D
var _font: Font
var _camera: Camera2D
var _hero: HeadToken
var _hud_layer: CanvasLayer
var _hud: Node2D
## Monster pieces standing on open stops, by stop index.
var _monsters := {}
var _names := {}
var _time := 0.0
var _busy := false
## 0..1 progress of the padlock bursting at `_opening`, and of the flag going in at `_planting`.
var _opening := -1
var _open_t := 0.0
var _planting := -1
var _plant_t := 0.0
## Stars shown so far at `_planting` while they pop in one by one.
var _stars_shown := 3
var _toast := ""
var _toast_alpha := 0.0
var _toast_tween: Tween
var _press_at := Vector2.ZERO
var _press_camera := Vector2.ZERO
var _pressed := false
var _dragged := false
## The first stop pops up only the first time the map is shown.
var _intro_done := false


func _ready() -> void:
	for kind in ["hard", "boss", "bonus", "petal"]:
		var path := "res://assets/ui/campaign/node_%s.png" % kind
		_badges[kind] = load(path) if ResourceLoader.exists(path) else null
	_lock = load(LOCK_ICON) if ResourceLoader.exists(LOCK_ICON) else null
	for path in CLOUD_ART:
		if ResourceLoader.exists(path):
			_cloud_art.append(load(path))
	_bird_art = load(BIRD_ART) if ResourceLoader.exists(BIRD_ART) else null
	_firefly_art = load(FIREFLY_ART) if ResourceLoader.exists(FIREFLY_ART) else null
	_load_ambience(AMBIENCE)
	_coin = load(COIN) if ResourceLoader.exists(COIN) else null
	_font = load(FONT) if ResourceLoader.exists(FONT) else ThemeDB.fallback_font
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_hero = HeadToken.new()
	_hero.z_index = 2
	add_child(_hero)
	_hero.setup("hero_rookie")
	_hud_layer = CanvasLayer.new()
	add_child(_hud_layer)
	_hud = Node2D.new()
	_hud.draw.connect(_draw_hud)
	_hud_layer.add_child(_hud)
	var forge := Button.new()
	forge.text = "⚒ LÒ RÈN"
	forge.position = Vector2(36, 1790)
	forge.size = Vector2(300, 96)
	forge.focus_mode = Control.FOCUS_NONE
	forge.add_theme_font_size_override("font_size", 40)
	forge.add_theme_color_override("font_color", PAPER)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(INK, 1.0 if state == "pressed" else 0.85)
		style.border_color = GOLD
		style.set_border_width_all(4)
		style.set_corner_radius_all(48)
		forge.add_theme_stylebox_override(state, style)
	forge.pressed.connect(func() -> void:
		if not _busy:
			forge_requested.emit())
	_hud_layer.add_child(forge)
	visibility_changed.connect(func() -> void: _hud_layer.visible = visible)


func _load_ambience(path: String) -> void:
	if path == _ambience_path or not ResourceLoader.exists(path):
		return
	var json: JSON = load(path)
	if not json.data is Dictionary:
		return
	_ambience_path = path
	_ambience = json.data
	_ambience_art.clear()
	var dir := path.get_base_dir() + "/"
	for name: String in _ambience.get("textures", {}):
		var info: Dictionary = _ambience["textures"][name]
		var file: String = dir + String(info.get("file", ""))
		if ResourceLoader.exists(file):
			_ambience_art[name] = {"texture": load(file), "info": info}
	# The map's own clouds take over from the ones borrowed from the Orc camp.
	var clouds: Array[Texture2D] = []
	for name: String in _ambience_art:
		if name.begins_with("cloud_"):
			clouds.append(_ambience_art[name]["texture"])
	if not clouds.is_empty():
		_cloud_art = clouds
	_cloud_motion = CLOUD_MOTION.merged(_ambience.get("cloud_motion", {}), true)
	_clouds.clear()


## The ambience laid out for a map of `count` segments.
func _ambience_for(count: int) -> void:
	var base: Variant = load(AMBIENCE).data if ResourceLoader.exists(AMBIENCE) else null
	var profiles: Dictionary = base.get("profiles", {}) if base is Dictionary else {}
	var file: String = profiles.get(str(count), AMBIENCE.get_file())
	_load_ambience(AMBIENCE.get_base_dir() + "/" + file)


func map_size() -> Vector2:
	return Vector2(SCREEN.x, SCREEN.y * maxi(_segments.size(), 1))


func _load_segments(count: int) -> void:
	_segments.clear()
	for i in count:
		var path := SEGMENT % (i + 1)
		_segments.append(load(path) if ResourceLoader.exists(path) else null)


## Shows `p_campaign`. `won_at` is the stop of a fight just won (-1 for none), and
## `first_clear` whether that win opened the road: then the flag goes in, the hero walks
## to the next stop and the monster there pops up.
func show_campaign(p_campaign: Campaign, won_at := -1, first_clear := false) -> void:
	campaign = p_campaign
	if _segments.size() != campaign.segments:
		_load_segments(campaign.segments)
		_ambience_for(campaign.segments)
	_camera.make_current()
	_names.clear()
	for stop in campaign.stops:
		var data := Campaign.monster(stop["id"])
		_names[stop["id"]] = data.display_name if data else ""
	var target := campaign.hero_index()
	_build_monsters()
	_hero.position = _hero_point(target)
	_look_at(_hero.position)
	if first_clear and won_at >= 0:
		# The next stop stays padlocked, its monster underground, until the hero gets there.
		_hide_monster(target)
		_celebrate(won_at, target)
	elif won_at >= 0:
		_pop_stars(won_at)
	elif campaign.cleared.is_empty() and target == 0 and not _intro_done:
		_reveal(0)
		show_toast("Chạm vào quái để vào trận")
	_intro_done = true
	queue_redraw()


func show_toast(text: String, seconds := 2.2) -> void:
	_toast = text
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_method(_set_toast_alpha, 0.0, 1.0, 0.15)
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_method(_set_toast_alpha, 1.0, 0.0, 0.4)


func _set_toast_alpha(a: float) -> void:
	_toast_alpha = a
	_hud.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_move_sky(delta)
	queue_redraw()
	_hud.queue_redraw()


## The painted map never sits still: clouds drift over it and their shadows slide across the
## land, birds cross now and then, and fireflies wink over the swamp.
func _move_sky(delta: float) -> void:
	if _clouds.is_empty() and not _cloud_art.is_empty():
		_spread_clouds()
	var wrap: Array = _cloud_motion["wrap_x"]
	for cloud in _clouds:
		cloud["at"].x += cloud["speed"] * delta
		if cloud["at"].x > float(wrap[1]):
			cloud["at"] = Vector2(float(wrap[0]), randf_range(0, map_size().y))
	_next_bird -= delta
	if _next_bird <= 0.0 and _bird_art:
		_next_bird = randf_range(4.0, 9.0)
		var view_top := _camera.position.y
		var left := randf() < 0.5
		_birds.append({"at": Vector2(-60.0 if left else SCREEN.x + 60.0, view_top + randf_range(150, SCREEN.y * 0.6)), "speed": randf_range(130, 190) * (1.0 if left else -1.0), "count": randi_range(1, 3)})
	for bird in _birds:
		bird["at"].x += bird["speed"] * delta
	_birds = _birds.filter(func(b: Dictionary) -> bool: return b["at"].x > -200 and b["at"].x < SCREEN.x + 200)


# --- pieces on the stops -----------------------------------------------------

func _build_monsters() -> void:
	for piece in _monsters.values():
		piece.queue_free()
	_monsters.clear()
	for i in campaign.stops.size():
		var id: String = campaign.stops[i]["id"]
		if campaign.state_of(id) == Campaign.Stop.OPEN:
			_monsters[i] = _monster_piece(i)


func _monster_piece(index: int) -> CharacterRig:
	var piece := CharacterRig.new()
	piece.scale = Vector2.ONE * MONSTER_SCALE
	piece.position = campaign.stops[index]["position"] + MONSTER_FEET
	piece.z_index = 1
	add_child(piece)
	var monster := Campaign.monster(campaign.stops[index]["id"])
	piece.setup(monster.id if monster else "", -1)
	return piece


func _hide_monster(index: int) -> void:
	var piece: CharacterRig = _monsters.get(index)
	if piece == null:
		return
	_opening = index
	_open_t = 0.0
	piece.scale = Vector2(MONSTER_SCALE, 0.0)


## The padlock at `index` shakes and bursts, then its monster rises out of the ground.
func _reveal(index: int, delay := 0.4) -> void:
	var piece: CharacterRig = _monsters.get(index)
	if piece == null:
		return
	_busy = true
	_hide_monster(index)
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_method(func(t: float) -> void: _open_t = t, 0.0, 1.0, 0.6)
	tween.tween_callback(func() -> void: Sfx.play(&"special"))
	tween.tween_property(piece, "scale", Vector2.ONE * MONSTER_SCALE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_opening = -1
		_busy = false
		piece.react(&"cheer", 0.6))


## The flag goes into the stop just won and its stars pop in; then the hero walks on and
## the next stop opens.
func _celebrate(won_at: int, next: int) -> void:
	_busy = true
	_hero.position = _hero_point(won_at)
	_look_at(_hero.position)
	var tween := create_tween()
	tween.tween_callback(func() -> void: _pop_stars(won_at))
	tween.tween_interval(1.0)
	tween.tween_callback(func() -> void: _walk(won_at, next))


func _pop_stars(index: int) -> void:
	_planting = index
	_plant_t = 0.0
	_stars_shown = 0
	var stars := campaign.stars_at(campaign.stops[index]["id"])
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void: _plant_t = t, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: Sfx.play(&"land"))
	for i in stars:
		tween.tween_interval(0.16)
		tween.tween_callback(func() -> void:
			_stars_shown = i + 1
			Sfx.play(&"coin", 1.0 + i * 0.15))
	tween.tween_callback(func() -> void: _planting = -1)


## Hops the hero's badge up the road from stop `from` to stop `to`, then opens `to`.
func _walk(from: int, to: int) -> void:
	_busy = true
	var start := _hero_point(from)
	var end := _hero_point(to)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		_hero.position = start.lerp(end, t) + Vector2(0, -absf(sin(t * PI * 4.0)) * 30.0)
		_look_at(_hero.position), 0.0, 1.0, WALK_SECONDS)
	tween.tween_callback(func() -> void:
		Sfx.play(&"land")
		_reveal(to, 0.1))


func _hero_point(index: int) -> Vector2:
	return campaign.stops[index]["position"] + HERO_OFFSET


# --- scrolling and taps ------------------------------------------------------

## Scrolls so `point` sits a little below the middle of the screen.
func _look_at(point: Vector2) -> void:
	var top := point.y - SCREEN.y * 0.58
	_camera.position = Vector2(0, clampf(top, 0.0, maxf(map_size().y - SCREEN.y, 0.0)))


func _unhandled_input(event: InputEvent) -> void:
	if not visible or campaign == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_pressed = true
			_dragged = false
			_press_at = event.position
			_press_camera = _camera.position
		elif _pressed:
			_pressed = false
			if not _dragged and not _busy:
				_tap(event.position + _camera.position)
	elif event is InputEventScreenDrag and _pressed:
		var moved: Vector2 = event.position - _press_at
		if moved.length() > DRAG_SLOP:
			_dragged = true
		if _dragged and not _busy:
			var top := clampf(_press_camera.y - moved.y, 0.0, maxf(map_size().y - SCREEN.y, 0.0))
			_camera.position = Vector2(0, top)


func _tap(at: Vector2) -> void:
	var picked := -1
	var best := TAP_REACH
	for i in campaign.stops.size():
		var stop_at: Vector2 = campaign.stops[i]["position"]
		# Monsters stand above their stop: count a tap on the body too.
		var d := minf(at.distance_to(stop_at), at.distance_to(stop_at + Vector2(0, -60)))
		if d < best:
			best = d
			picked = i
	if picked < 0:
		return
	var id: String = campaign.stops[picked]["id"]
	match campaign.state_of(id):
		Campaign.Stop.OPEN, Campaign.Stop.DONE:
			Sfx.play(&"tick")
			stop_chosen.emit(id)
		Campaign.Stop.SOON:
			show_toast("Vùng đất này đang được xây, sắp có!")
		Campaign.Stop.LOCKED:
			Sfx.play(&"untick")
			show_toast("Thắng các trận trước để mở đường")


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, map_size()), Color(0.3, 0.5, 0.3))
	for i in _segments.size():
		if _segments[i]:
			draw_texture_rect(_segments[i], Rect2(Vector2(0, (_segments.size() - 1 - i) * SCREEN.y), SCREEN), false)
	_draw_ambience()
	_draw_cloud_shadows()
	_draw_fireflies()
	if campaign == null:
		return
	for i in campaign.stops.size():
		_draw_stop(i)
	_draw_sky()


## The ambience's own clouds where it puts them, then more scattered about until every segment
## has its share. A cloud's `at` is its top-left corner.
func _spread_clouds() -> void:
	var speeds: Array = _cloud_motion["speed_px_per_second"]
	var own := _cloud_art.size() == 3 and _ambience_art.has("cloud_1")
	if own:
		for cloud: Dictionary in _ambience.get("clouds", []):
			var art := maxi(int(String(cloud.get("texture", "cloud_1")).trim_prefix("cloud_")) - 1, 0) % _cloud_art.size()
			var size := Vector2(_cloud_art[art].get_size()) * float(cloud.get("scale", 1.0))
			var centre := Vector2(cloud["position"][0], cloud["position"][1])
			_clouds.append({"at": centre - size / 2, "speed": float(cloud.get("speed", speeds[0])), "art": art, "scale": float(cloud.get("scale", 1.0))})
	var wanted := maxi(CLOUDS_PER_SEGMENT * maxi(_segments.size(), 1), CLOUDS if not own else 0)
	var i := 0
	while _clouds.size() < wanted:
		var grow := randf_range(0.6, 0.95) if own else randf_range(1.6, 2.6)
		_clouds.append({"at": Vector2(randf_range(-200, SCREEN.x), randf_range(0, map_size().y)), "speed": randf_range(float(speeds[0]), float(speeds[1])), "art": i % _cloud_art.size(), "scale": grow})
		i += 1


func _draw_cloud_shadows() -> void:
	var offset: Array = _cloud_motion["shadow_offset"]
	for cloud in _clouds:
		var art: Texture2D = _cloud_art[cloud["art"]]
		var size := Vector2(art.get_size()) * float(cloud["scale"])
		draw_texture_rect(art, Rect2(cloud["at"] + Vector2(offset[0], offset[1]), size), false, Color(0.05, 0.1, 0.05, float(_cloud_motion["shadow_opacity"])))


## Clouds and birds pass over everything on the map, stops included.
func _draw_sky() -> void:
	for cloud in _clouds:
		var art: Texture2D = _cloud_art[cloud["art"]]
		var size := Vector2(art.get_size()) * float(cloud["scale"])
		draw_texture_rect(art, Rect2(cloud["at"], size), false, Color(1, 1, 1, float(_cloud_motion["opacity"])))
	if _bird_art:
		var frame_width := _bird_art.get_width() / 4.0
		for bird in _birds:
			for k in int(bird["count"]):
				var frame := int(_time * 10.0 + k * 1.7) % 4
				var at: Vector2 = bird["at"] + Vector2(-signf(bird["speed"]) * k * 46, k * 22 + sin(_time * 3.0 + k) * 8)
				var flip := -1.0 if bird["speed"] < 0 else 1.0
				draw_set_transform(at, 0.0, Vector2(0.9 * flip, 0.9))
				draw_texture_rect_region(_bird_art, Rect2(Vector2(-frame_width / 2, -32), Vector2(frame_width, 64)), Rect2(frame * frame_width, 0, frame_width, 64))
				draw_set_transform(Vector2.ZERO)


func _draw_fireflies() -> void:
	if _firefly_art == null or campaign == null:
		return
	if _fireflies.is_empty():
		for segment: int in FIREFLY_SEGMENTS:
			if segment > campaign.segments:
				continue
			var top := (campaign.segments - segment) * SCREEN.y
			for i in FIREFLIES:
				_fireflies.append(Vector2(randf_range(40, SCREEN.x - 40), top + randf_range(60, SCREEN.y - 60)))
	for i in _fireflies.size():
		var wink := pow(maxf(sin(_time * 1.7 + i * 2.3), 0.0), 2.0)
		if wink <= 0.02:
			continue
		var at := _fireflies[i] + Vector2(sin(_time * 0.8 + i) * 22, cos(_time * 0.6 + i * 1.3) * 16)
		var frame := int(_time * 8.0 + i) % 4
		draw_texture_rect_region(_firefly_art, Rect2(at - Vector2(28, 28), Vector2(56, 56)), Rect2(frame * 256, 0, 256, 256), Color(1, 1, 0.8, wink))


func _draw_ambience() -> void:
	if _ambience.is_empty():
		return
	var loop := float(_ambience.get("loop_seconds", 4.0))
	# Smoke puffs rise, drift and fade, one after another from each chimney.
	var smoke: Dictionary = _ambience.get("smoke_motion", {})
	for puff: Dictionary in _ambience.get("smoke", []):
		var t := fposmod(_time / loop + float(puff.get("phase", 0.0)), 1.0)
		var base := Vector2(puff["position"][0], puff["position"][1])
		var at := base + Vector2(sin(t * TAU) * float(smoke.get("drift_px", 12)), -t * float(smoke.get("rise_px", 60)))
		var tint := _tint(smoke.get("tint"), float(smoke.get("opacity", 0.8)) * sin(t * PI))
		_draw_fx_frame("smoke", at, float(smoke.get("size_px", 96)) * lerpf(0.7, 1.3, t), t, tint)
	# Glints slide a little down the water and wink out.
	var water: Dictionary = _ambience.get("water_motion", {})
	var water_sizes: Array = water.get("size_px", [8, 18])
	var water_period := float(water.get("period_seconds", 2.0))
	var glints: Array = _ambience.get("water_glints", [])
	for i in glints.size():
		var t := fposmod(_time / water_period + i * 0.37, 1.0)
		var at := Vector2(glints[i][0], glints[i][1] + t * float(water.get("travel_y_px", 12)))
		var size := lerpf(float(water_sizes[0]), float(water_sizes[1]), sin(t * PI))
		_draw_fx_frame("sparkle", at, size * 2.0, 0.0, _tint(water.get("tint"), float(water.get("opacity", 0.45)) * sin(t * PI)))
	# Flags flap on their poles and waterfalls tumble, each a looping strip of frames.
	for kind: String in ["flags", "waterfalls"]:
		var name := "flag" if kind == "flags" else "waterfall"
		for piece: Dictionary in _ambience.get(kind, []):
			var size: Array = piece.get("size_px", [64, 96])
			var origin: Variant = piece.get("origin")
			_draw_fx_strip(name, Vector2(piece["position"][0], piece["position"][1]), Vector2(size[0], size[1]), origin, float(piece.get("phase", 0.0)))
	# Gold in the hoard twinkles now and then.
	var gold: Dictionary = _ambience.get("gold_motion", {})
	var gold_sizes: Array = gold.get("size_px", [20, 34])
	var gold_period := float(gold.get("period_seconds", 4.0))
	var hoard: Array = _ambience.get("gold_glints", [])
	for i in hoard.size():
		var wink := pow(maxf(sin(TAU * (_time / gold_period + i * 0.21)), 0.0), 3.0)
		var at := Vector2(hoard[i][0], hoard[i][1])
		_draw_fx_frame("glow", at, lerpf(float(gold_sizes[0]), float(gold_sizes[1]), wink) * 2.0, 0.0, Color(1, 0.9, 0.5, float(gold.get("opacity", 0.8)) * wink))
		_draw_fx_frame("sparkle", at, lerpf(float(gold_sizes[0]), float(gold_sizes[1]), wink), 0.0, Color(1, 1, 0.85, float(gold.get("opacity", 0.8)) * wink))


static func _tint(rgb: Variant, alpha: float) -> Color:
	if rgb is Array and rgb.size() >= 3:
		return Color8(int(rgb[0]), int(rgb[1]), int(rgb[2]), int(clampf(alpha, 0.0, 1.0) * 255))
	return Color(1, 1, 1, clampf(alpha, 0.0, 1.0))


## One frame of an ambience texture, `size` across, centred on `at`; `t` 0..1 picks the frame.
func _draw_fx_frame(name: String, at: Vector2, size: float, t: float, tint: Color) -> void:
	if not _ambience_art.has(name) or tint.a <= 0.0:
		return
	var art: Dictionary = _ambience_art[name]
	var info: Dictionary = art["info"]
	var frames := int(info.get("frames", 1))
	var columns := int(info.get("columns", 1))
	var cell := Vector2(info["frame_size"][0], info["frame_size"][1])
	var frame := mini(int(t * frames), frames - 1)
	var source := Rect2(Vector2(frame % columns, frame / columns) * cell, cell)
	draw_texture_rect_region(art["texture"], Rect2(at - Vector2.ONE * size / 2, Vector2.ONE * size), source, tint)


## The looping frame for now of an ambience strip, `size` across and tall, its `origin`
## (in the art's frame, by default its middle) at `at`. `phase` 0..1 staggers pieces.
func _draw_fx_strip(name: String, at: Vector2, size: Vector2, origin: Variant, phase: float) -> void:
	if not _ambience_art.has(name):
		return
	var art: Dictionary = _ambience_art[name]
	var info: Dictionary = art["info"]
	var frames := int(info.get("frames", 1))
	var columns := int(info.get("columns", 1))
	var cell := Vector2(info["frame_size"][0], info["frame_size"][1])
	if not origin is Array:
		origin = info.get("origin", [cell.x / 2, cell.y / 2])
	var pivot := Vector2(origin[0], origin[1]) * size / cell
	var frame := int(_time * float(info.get("fps", 12)) + phase * frames) % frames
	var source := Rect2(Vector2(frame % columns, frame / columns) * cell, cell)
	draw_texture_rect_region(art["texture"], Rect2(at - pivot, size), source)


func _draw_stop(index: int) -> void:
	var id: String = campaign.stops[index]["id"]
	var at: Vector2 = campaign.stops[index]["position"]
	var state := campaign.state_of(id)
	match state:
		Campaign.Stop.LOCKED, Campaign.Stop.SOON:
			_draw_lock(at, 0.0, 0.75 if state == Campaign.Stop.SOON else 1.0)
			if state == Campaign.Stop.SOON:
				_draw_pill("Sắp có", at + Vector2(0, NODE_SIZE / 2 + 28), LABEL_SIZE)
		Campaign.Stop.OPEN:
			# A glowing mound for the monster to stand on.
			var pulse := 0.5 + 0.5 * sin(_time * 4.0)
			draw_circle(at + Vector2(0, 30), 70 + 6 * pulse, Color(1, 0.9, 0.45, 0.22 + 0.12 * pulse))
			_draw_mound(at + Vector2(0, 38))
			if index == _opening:
				_draw_lock(at, _open_t)
			_draw_pill(_names.get(id, ""), at + Vector2(0, NODE_SIZE / 2 + 30), LABEL_SIZE)
		Campaign.Stop.DONE:
			var rise := _plant_t if index == _planting else 1.0
			_draw_mound(at + Vector2(0, 38))
			_draw_flag(at + Vector2(0, 38), rise)
			var shown := _stars_shown if index == _planting else campaign.stars_at(id)
			_draw_stars(at + Vector2(0, NODE_SIZE / 2 + 26), shown)
	_draw_number(index, at)


## The level's number on a small medal by the stop, and its mark (hard, boss, bonus, a petal).
func _draw_number(index: int, at: Vector2) -> void:
	var stop: Dictionary = campaign.stops[index]
	var medal := at + Vector2(-58, -50)
	draw_circle(medal, 26, INK)
	draw_circle(medal, 21, PAPER)
	var text := str(stop.get("level", index + 1))
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_string(_font, medal + Vector2(-width / 2, 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
	for kind in ["boss", "hard", "bonus", "petal"]:
		if stop.get(kind, false) and _badges.get(kind):
			draw_texture_rect(_badges[kind], Rect2(at + Vector2(30, -92), Vector2(64, 64)), false)
			break


## The padlock badge; `burst` 0..1 shakes it, then blows it up and away.
func _draw_lock(at: Vector2, burst := 0.0, alpha := 1.0) -> void:
	if _lock == null:
		return
	var size := NODE_SIZE
	var offset := Vector2.ZERO
	if burst > 0.0:
		if burst < 0.6:
			offset.x = sin(burst * 70.0) * 9.0 * (burst / 0.6)
		else:
			var t := (burst - 0.6) / 0.4
			size *= 1.0 + t * 0.6
			alpha *= 1.0 - t
	draw_texture_rect(_lock, Rect2(at + offset - Vector2.ONE * size / 2, Vector2.ONE * size), false, Color(1, 1, 1, alpha))


func _draw_mound(at: Vector2) -> void:
	draw_set_transform(at, 0.0, Vector2(1, 0.38))
	draw_circle(Vector2(0, 6), 58, Color(0, 0, 0, 0.25))
	draw_circle(Vector2.ZERO, 54, MOUND)
	draw_circle(Vector2(-10, -8), 40, MOUND.lightened(0.15))
	draw_set_transform(Vector2.ZERO)


## A flag stuck in the ground at `foot`; `rise` 0..1 drives it in.
func _draw_flag(foot: Vector2, rise: float) -> void:
	var height := 112.0 * rise
	var top := foot - Vector2(0, height)
	draw_line(foot, top, INK, 8.0, true)
	draw_line(foot + Vector2(-1, 0), top + Vector2(-1, 0), Color(0.6, 0.42, 0.22), 4.0, true)
	if rise < 0.5:
		return
	var wave := sin(_time * 5.0) * 7.0
	var cloth := PackedVector2Array([
		top + Vector2(3, 4),
		top + Vector2(66, 20 + wave * 0.5),
		top + Vector2(60, 30 + wave),
		top + Vector2(3, 50),
	])
	draw_colored_polygon(cloth, FLAG)
	cloth.append(cloth[0])
	draw_polyline(cloth, INK, 4.0, true)
	draw_circle(top, 7, GOLD)


func _draw_stars(center: Vector2, count: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.78)
	style.set_corner_radius_all(22)
	draw_style_box(style, Rect2(center - Vector2(68, 30), Vector2(136, 50)))
	for i in 3:
		var at := center + Vector2((i - 1) * 40, -8 if i == 1 else 0)
		_draw_star(at, 19.0, count > i)


func _draw_star(at: Vector2, radius: float, filled: bool) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		points.append(at + Vector2.from_angle(-PI / 2 + i * PI / 5) * r)
	draw_colored_polygon(points, GOLD if filled else Color(PAPER, 0.25))
	points.append(points[0])
	draw_polyline(points, INK, 3.5, true)


## Text on a rounded paper label, centred on `center`.
func _draw_pill(text: String, center: Vector2, font_size: int, alpha := 1.0, canvas: CanvasItem = self) -> void:
	if text.is_empty():
		return
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var box := Rect2(center - Vector2(width / 2 + 22, font_size * 0.75), Vector2(width + 44, font_size * 1.5))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PAPER, 0.92 * alpha)
	style.border_color = Color(INK, alpha)
	style.set_border_width_all(4)
	style.set_corner_radius_all(int(box.size.y / 2))
	canvas.draw_style_box(style, box)
	var baseline := Vector2(center.x - width / 2, center.y + font_size * 0.36)
	canvas.draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK, alpha))


## The purse and messages stay put on the screen while the map scrolls.
func _draw_hud() -> void:
	if campaign == null:
		return
	var text := str(campaign.gold)
	var font_size := 48
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var box := Rect2(Vector2(SCREEN.x - width - 150, 36), Vector2(width + 116, 78))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.82)
	style.border_color = GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(39)
	_hud.draw_style_box(style, box)
	if _coin:
		_hud.draw_texture_rect(_coin, Rect2(box.position + Vector2(14, 11), Vector2(56, 56)), false)
	_hud.draw_string_outline(_font, box.position + Vector2(80, 57), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, INK)
	_hud.draw_string(_font, box.position + Vector2(80, 57), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, GOLD)
	if _toast_alpha > 0.0:
		_draw_pill(_toast, Vector2(SCREEN.x / 2, 1690), 38, _toast_alpha, _hud)
