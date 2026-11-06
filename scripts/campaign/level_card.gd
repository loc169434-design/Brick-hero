class_name LevelCard
extends CanvasLayer
## The card that pops up over the map when a level is picked, told in pictures: the level's
## number and mark, the heads of the monsters waiting there in order, the goals as icons with
## numbers, the stars won so far, and a big button to fight. `play` starts the level;
## tapping outside the card or ✕ closes it.

signal play(id: String)
signal closed

const SCREEN := Vector2(1080, 1920)
const CARD := Rect2(90, 470, 900, 940)
const INK := MapView.INK
const PAPER := MapView.PAPER
const GOLD := MapView.GOLD
const DIM := Color(0, 0, 0, 0.55)
const HEAD_SPACING := 190.0

var id := ""
var level: LevelData

var _stars := 0
var _canvas: Node2D
var _font: Font
var _number_font: Font
var _art := ObstacleArt.new()
var _badges := {}
var _sword: Texture2D
var _pop := 0.0


func _ready() -> void:
	layer = 5
	_font = load(MapView.FONT) if ResourceLoader.exists(MapView.FONT) else ThemeDB.fallback_font
	_number_font = load(BattleView.NUMBER_FONT) if ResourceLoader.exists(BattleView.NUMBER_FONT) else _font
	for kind in ["hard", "boss", "bonus", "petal"]:
		var path := "res://assets/ui/campaign/node_%s.png" % kind
		_badges[kind] = load(path) if ResourceLoader.exists(path) else null
	var sword := "res://assets/ui/items/iron_sword.png"
	_sword = load(sword) if ResourceLoader.exists(sword) else null
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_card)
	add_child(_canvas)
	var fight := _button("ĐÁNH!", Vector2(CARD.position.x + (CARD.size.x - 420) / 2, CARD.end.y - 150), Vector2(420, 116), 60)
	fight.pressed.connect(func() -> void:
		Sfx.play(&"charge")
		play.emit(id))
	add_child(fight)
	var close := _button("✕", Vector2(CARD.end.x - 92, CARD.position.y + 18), Vector2(72, 72), 40)
	close.pressed.connect(_close)
	add_child(close)


func show_level(p_id: String, p_level: LevelData, stars: int) -> void:
	id = p_id
	level = p_level
	_stars = stars
	for i in level.monsters.size():
		var head := HeadToken.new()
		head.position = _head_at(i, level.monsters.size())
		head.scale = Vector2.ONE * (0.9 if level.monsters.size() > 2 else 1.05)
		add_child(head)
		head.setup(level.monsters[i])
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		_pop = t
		_canvas.queue_redraw(), 0.0, 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _head_at(i: int, count: int) -> Vector2:
	return Vector2(SCREEN.x / 2 + (i - (count - 1) / 2.0) * HEAD_SPACING, CARD.position.y + 300)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		if not CARD.has_point(event.position):
			_close()


func _close() -> void:
	Sfx.play(&"untick")
	closed.emit()
	queue_free()


func _draw_card() -> void:
	_canvas.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(DIM, DIM.a * _pop))
	if level == null:
		return
	var scale := lerpf(0.85, 1.0, _pop)
	_canvas.draw_set_transform(CARD.get_center() * (1.0 - scale), 0.0, Vector2.ONE * scale)
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = INK
	style.set_border_width_all(8)
	style.set_corner_radius_all(48)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 18
	_canvas.draw_style_box(style, CARD)
	_draw_medal(Vector2(SCREEN.x / 2, CARD.position.y + 4))
	for i in level.monsters.size() - 1:
		# An arrow between monsters met one after another.
		var a := _head_at(i, level.monsters.size()) + Vector2(70, 0)
		_canvas.draw_string(_number_font, a + Vector2(4, 16), "›", HORIZONTAL_ALIGNMENT_LEFT, -1, 60, INK)
	_draw_goals(Vector2(SCREEN.x / 2, CARD.position.y + 500))
	_draw_stars(Vector2(SCREEN.x / 2, CARD.position.y + 640))
	_canvas.draw_set_transform(Vector2.ZERO)


## The level's number on a big medal at the top of the card, its mark beside it.
func _draw_medal(center: Vector2) -> void:
	_canvas.draw_circle(center, 84, INK)
	_canvas.draw_circle(center, 74, GOLD)
	var text := str(level.number)
	var width := _number_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 84).x
	_canvas.draw_string(_number_font, center + Vector2(-width / 2, 30), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 84, INK)
	for kind in ["boss", "hard", "bonus", "petal"]:
		if level.get(kind) and _badges.get(kind):
			_canvas.draw_texture_rect(_badges[kind], Rect2(center + Vector2(70, -10), Vector2(96, 96)), false)
			break


## The goals as icon + number chips in one row.
func _draw_goals(center: Vector2) -> void:
	var chips: Array = []
	if level.collect > 0:
		chips.append(["collect", str(level.collect)])
	if level.break_crates:
		chips.append(["crate", str(level.crates)])
	if level.break_cover:
		chips.append(["cover", str(level.cover_count)])
	if level.rescue > 0:
		chips.append(["rescue", str(level.rescue)])
	if level.bonus:
		chips.append(["bonus", "x%d" % roundi(level.gold_multiplier)])
	if level.turns > 0:
		chips.append(["turns", str(level.turns)])
	if chips.is_empty():
		chips.append(["kill", ""])
	const ICON := 72.0
	const GAP := 34.0
	var widths: Array[float] = []
	var total := -GAP
	for chip in chips:
		var w := ICON + (12.0 + _number_font.get_string_size(chip[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 60).x if chip[1] else 0.0)
		widths.append(w)
		total += w + GAP
	var x := center.x - total / 2
	for i in chips.size():
		var icon := Rect2(Vector2(x, center.y - ICON / 2), Vector2(ICON, ICON))
		match chips[i][0]:
			"collect":
				var box := StyleBoxFlat.new()
				box.bg_color = BoardView.BLOCK_COLORS.get(level.collect_color, GOLD)
				box.border_color = INK
				box.set_border_width_all(4)
				box.set_corner_radius_all(16)
				_canvas.draw_style_box(box, icon.grow(-4))
			"crate":
				_draw_texture(_art.texture(Cell.obstacle(level.obstacle, maxi(level.crate_layers, 1))), icon)
			"cover":
				_draw_texture(_art.overlay(level.cover, level.cover_layers), icon)
			"rescue":
				_draw_texture(_art.texture(Cell.obstacle(level.rescue_item)), icon)
			"bonus":
				_draw_texture(_badges.get("bonus"), icon)
			"turns":
				var c := icon.get_center()
				var s := ICON * 0.36
				_canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-s, -s), c + Vector2(s, -s), c]), INK)
				_canvas.draw_colored_polygon(PackedVector2Array([c, c + Vector2(s, s), c + Vector2(-s, s)]), INK)
			"kill":
				# A sword: beat them all.
				_draw_texture(_sword, icon.grow(14))
		if chips[i][1]:
			_canvas.draw_string(_number_font, Vector2(icon.end.x + 12, center.y + 22), chips[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 60, INK)
		x += widths[i] + GAP


func _draw_texture(texture: Texture2D, rect: Rect2) -> void:
	if texture:
		_canvas.draw_texture_rect(texture, rect, false)


func _draw_stars(center: Vector2) -> void:
	for i in 3:
		var at := center + Vector2((i - 1) * 96, -14 if i == 1 else 0)
		var points := PackedVector2Array()
		for k in 10:
			var r := 40.0 if k % 2 == 0 else 18.0
			points.append(at + Vector2.from_angle(-PI / 2 + k * PI / 5) * r)
		_canvas.draw_colored_polygon(points, GOLD if _stars > i else Color(INK, 0.15))
		points.append(points[0])
		_canvas.draw_polyline(points, INK, 5.0, true)


func _button(text: String, at: Vector2, size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", PAPER)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.75, 0.2, 0.15) if state != "pressed" else Color(0.55, 0.12, 0.1)
		style.border_color = INK
		style.set_border_width_all(6)
		style.set_corner_radius_all(int(size.y / 2))
		button.add_theme_stylebox_override(state, style)
	return button
