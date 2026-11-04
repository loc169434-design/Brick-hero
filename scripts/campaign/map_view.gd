class_name MapView
extends Node2D
## The world map between fights: the painted road from the castle to the dragon's cave, and
## on it every stop as a game piece. A locked stop is a padlock; when the road reaches it the
## padlock bursts open and the monster pops up out of the ground, standing on its stop; a
## cleared stop has a flag planted in it and the stars won there. The hero is a head on a
## badge beside the next stop. Tapping an open or cleared stop asks for that fight
## (stop_chosen). A map taller than the screen scrolls with a drag.

signal stop_chosen(id: String)

const SCREEN := Vector2(1080, 1920)
const BACKGROUND := "res://assets/bg/world_map.png"
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

var _background: Texture2D
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


func _ready() -> void:
	_background = load(BACKGROUND) if ResourceLoader.exists(BACKGROUND) else null
	_lock = load(LOCK_ICON) if ResourceLoader.exists(LOCK_ICON) else null
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
	visibility_changed.connect(func() -> void: _hud_layer.visible = visible)


func map_size() -> Vector2:
	return Vector2(_background.get_size()) if _background else SCREEN


## Shows `p_campaign`. `won_at` is the stop of a fight just won (-1 for none), and
## `first_clear` whether that win opened the road: then the flag goes in, the hero walks
## to the next stop and the monster there pops up.
func show_campaign(p_campaign: Campaign, won_at := -1, first_clear := false) -> void:
	campaign = p_campaign
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
	elif campaign.cleared.is_empty() and target == 0:
		_reveal(0)
		show_toast("Chạm vào quái để vào trận")
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
	queue_redraw()
	_hud.queue_redraw()


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
	piece.setup(campaign.stops[index]["id"], -1)
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
	if _background:
		draw_texture_rect(_background, Rect2(Vector2.ZERO, map_size()), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.3, 0.5, 0.3))
	if campaign == null:
		return
	for i in campaign.stops.size():
		_draw_stop(i)


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
		_draw_pill(_toast, Vector2(SCREEN.x / 2, 1800), 38, _toast_alpha, _hud)
