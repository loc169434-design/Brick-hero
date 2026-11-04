class_name MapView
extends Node2D
## The world map between fights: the painted road from the castle to the dragon's cave, a
## marker on every stop (cleared, open, locked), the monster's name under it, the hero
## standing at the next stop and the gold in the purse. Tapping an open or cleared stop asks
## for that fight (stop_chosen); after a first win the hero walks up the road to the next stop.

signal stop_chosen(id: String)

const SIZE := Vector2(1080, 1920)
const BACKGROUND := "res://assets/bg/world_map.png"
const NODE_ICONS := {
	Campaign.Stop.LOCKED: "res://assets/ui/map_node_locked.png",
	Campaign.Stop.OPEN: "res://assets/ui/map_node_open.png",
	Campaign.Stop.DONE: "res://assets/ui/map_node_done.png",
	Campaign.Stop.SOON: "res://assets/ui/map_node_locked.png",
}
const COIN := "res://assets/fx/props/coin.png"
const FONT := "res://assets/fonts/baloo_2_extra_bold.ttf"
const NODE_SIZE := 128.0
## Taps this close to a stop's centre pick it.
const TAP_REACH := 90.0
## The hero stands beside the marker, feet just below its rim.
const HERO_OFFSET := Vector2(-96, 52)
const HERO_SCALE := 0.42
const WALK_SECONDS := 1.1
const LABEL_SIZE := 34
const INK := Color(0.16, 0.1, 0.06)
const PAPER := Color(1, 0.97, 0.88)
const GOLD := Color(1, 0.8, 0.25)

var campaign: Campaign

var _background: Texture2D
var _icons := {}
var _coin: Texture2D
var _font: Font
var _hero: CharacterRig
var _camera: Camera2D
var _names := {}
var _time := 0.0
var _walking := false
var _toast := ""
var _toast_alpha := 0.0
var _toast_tween: Tween


func _ready() -> void:
	_background = load(BACKGROUND) if ResourceLoader.exists(BACKGROUND) else null
	for state in NODE_ICONS:
		var path: String = NODE_ICONS[state]
		_icons[state] = load(path) if ResourceLoader.exists(path) else null
	_coin = load(COIN) if ResourceLoader.exists(COIN) else null
	_font = load(FONT) if ResourceLoader.exists(FONT) else ThemeDB.fallback_font
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_hero = CharacterRig.new()
	_hero.scale = Vector2.ONE * HERO_SCALE
	add_child(_hero)
	_hero.setup("hero_rookie", 1)


## Shows `p_campaign`. With `walk_from` set to a stop index, the hero starts there and walks
## to the next stop.
func show_campaign(p_campaign: Campaign, walk_from := -1) -> void:
	campaign = p_campaign
	_camera.make_current()
	_names.clear()
	for stop in campaign.stops:
		var data := Campaign.monster(stop["id"])
		_names[stop["id"]] = data.display_name if data else ""
	var target := campaign.hero_index()
	if walk_from >= 0 and walk_from != target:
		_walk(walk_from, target)
	else:
		_hero.position = _stand_point(target)
	if campaign.next_index() == 0 and campaign.cleared.is_empty():
		show_toast("Chạm vào điểm sáng để vào trận")
	queue_redraw()


func show_toast(text: String, seconds := 2.2) -> void:
	_toast = text
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_method(func(a: float) -> void:
		_toast_alpha = a
		queue_redraw(), 0.0, 1.0, 0.15)
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_method(func(a: float) -> void:
		_toast_alpha = a
		queue_redraw(), 1.0, 0.0, 0.4)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _walking or campaign == null:
		return
	if event is InputEventScreenTouch and event.pressed:
		_tap(event.position)


func _tap(at: Vector2) -> void:
	var picked := -1
	var best := TAP_REACH
	for i in campaign.stops.size():
		var d: float = at.distance_to(campaign.stops[i]["position"])
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


func _stand_point(index: int) -> Vector2:
	return campaign.stops[index]["position"] + HERO_OFFSET


## Hops the hero from stop `from` up the road to stop `to`.
func _walk(from: int, to: int) -> void:
	_walking = true
	_hero.position = _stand_point(from)
	var start := _stand_point(from)
	var end := _stand_point(to)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		_hero.position = start.lerp(end, t) + Vector2(0, -absf(sin(t * PI * 5.0)) * 26.0), 0.0, 1.0, WALK_SECONDS).set_delay(0.35)
	tween.tween_callback(func() -> void:
		_walking = false
		Sfx.play(&"land")
		_hero.react(&"cheer", 0.8))


func _draw() -> void:
	if _background:
		draw_texture_rect(_background, Rect2(Vector2.ZERO, SIZE), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.3, 0.5, 0.3))
	if campaign == null:
		return
	for stop in campaign.stops:
		_draw_stop(stop)
	_draw_purse()
	if _toast_alpha > 0.0:
		_draw_pill(_toast, Vector2(SIZE.x / 2, 1800), 38, _toast_alpha)


func _draw_stop(stop: Dictionary) -> void:
	var id: String = stop["id"]
	var at: Vector2 = stop["position"]
	var state := campaign.state_of(id)
	var size := NODE_SIZE
	if state == Campaign.Stop.OPEN:
		size *= 1.0 + 0.07 * sin(_time * 4.0)
		# A soft halo so the stop to play next stands out on the busy map.
		draw_circle(at, size * 0.62, Color(1, 0.92, 0.5, 0.28 + 0.12 * sin(_time * 4.0)))
	var icon: Texture2D = _icons.get(state)
	if icon:
		var tint := Color(1, 1, 1, 0.75) if state == Campaign.Stop.SOON else Color.WHITE
		draw_texture_rect(icon, Rect2(at - Vector2.ONE * size / 2, Vector2.ONE * size), false, tint)
	# Locked stops keep their monster a secret: just the padlock, no label.
	var label := ""
	match state:
		Campaign.Stop.SOON:
			label = "Sắp có"
		Campaign.Stop.OPEN, Campaign.Stop.DONE:
			label = _names.get(id, "")
	if label:
		_draw_pill(label, at + Vector2(0, NODE_SIZE / 2 + 30), LABEL_SIZE)


## Text on a rounded paper label, centred on `center`.
func _draw_pill(text: String, center: Vector2, font_size: int, alpha := 1.0) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var box := Rect2(center - Vector2(width / 2 + 22, font_size * 0.75), Vector2(width + 44, font_size * 1.5))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PAPER, 0.92 * alpha)
	style.border_color = Color(INK, alpha)
	style.set_border_width_all(4)
	style.set_corner_radius_all(int(box.size.y / 2))
	draw_style_box(style, box)
	var baseline := Vector2(center.x - width / 2, center.y + font_size * 0.36)
	draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK, alpha))


func _draw_purse() -> void:
	var text := str(campaign.gold)
	var font_size := 48
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var box := Rect2(Vector2(SIZE.x - width - 150, 36), Vector2(width + 116, 78))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.82)
	style.border_color = GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(39)
	draw_style_box(style, box)
	if _coin:
		draw_texture_rect(_coin, Rect2(box.position + Vector2(14, 11), Vector2(56, 56)), false)
	draw_string_outline(_font, box.position + Vector2(80, 57), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, INK)
	draw_string(_font, box.position + Vector2(80, 57), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, GOLD)
