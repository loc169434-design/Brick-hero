class_name ForgeView
extends Node2D
## The blacksmith's forge: the hero and the smith face each other, and under them one row per
## gear slot offers the next rung of its ladder (Gear). Buying takes the gold, the smith
## hammers and cheers, and the hero is stronger in every fight after. `closed` asks to go
## back to the map.

signal closed
## Something was bought: the campaign changed and should be saved.
signal bought(id: String)

const SCREEN := Vector2(1080, 1920)
const BACKGROUND := "res://assets/bg/forge.png"
const ITEM_ICONS := "res://assets/ui/items/%s.png"
const HERO_FEET := Vector2(270, 1250)
const SMITH_FEET := Vector2(810, 1250)
const ROWS_TOP := 1372.0
const ROW_HEIGHT := 102.0
const ROW_GAP := 4.0
const BUTTON_SIZE := Vector2(236, 78)
const ICON_SIZE := 84.0
const BUBBLE_POINT := Vector2(700, 900)
## What the smith says as he hands over each kind of gear.
const BOUGHT_LINES := {
	"weapon": "Cầm lấy! Tiếng Orc cười thì để giáp đỡ nhé.",
	"refine": "Mài lại lưỡi rồi, chém ngọt hơn hẳn!",
	"armor": "Giáp này đỡ được cả chùy Orc!",
	"helmet": "Đội vào. Đá có bay tới cũng chỉ nghe cái cốc.",
	"boots": "Ủng này đi mòn cả núi chưa rách.",
}

var campaign: Campaign

var _background: Texture2D
var _coin: Texture2D
var _font: Font
var _camera: Camera2D
var _hero: CharacterRig
var _smith: CharacterRig
## Per slot: {"button": Button, "id": String}.
var _rows := {}
var _icons := {}
var _line := ""
var _line_alpha := 0.0
var _line_tween: Tween
var _sparks: Array[Dictionary] = []


func _ready() -> void:
	_background = load(BACKGROUND) if ResourceLoader.exists(BACKGROUND) else null
	_coin = load(MapView.COIN) if ResourceLoader.exists(MapView.COIN) else null
	_font = load(MapView.FONT) if ResourceLoader.exists(MapView.FONT) else ThemeDB.fallback_font
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_hero = CharacterRig.new()
	_hero.position = HERO_FEET
	add_child(_hero)
	_hero.setup("hero_rookie", 1)
	_smith = CharacterRig.new()
	_smith.position = SMITH_FEET
	add_child(_smith)
	_smith.setup("blacksmith", -1)
	for slot: String in Gear.SLOTS:
		var button := _make_button(Vector2(SCREEN.x - 30 - BUTTON_SIZE.x, _row_top(slot) + (ROW_HEIGHT - BUTTON_SIZE.y) / 2), BUTTON_SIZE)
		button.pressed.connect(_on_row_pressed.bind(slot))
		add_child(button)
		_rows[slot] = {"button": button, "id": ""}
	var back := _make_button(Vector2(36, 36), Vector2(300, 90))
	back.text = "◀ BẢN ĐỒ"
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)


func show_campaign(p_campaign: Campaign) -> void:
	campaign = p_campaign
	_camera.make_current()
	_refresh()
	var only_wood := Gear.best(campaign.owned, "weapon") == "wood_sword" and Gear.best(campaign.owned, "armor") == ""
	_say("Kiếm gỗ à? Ta sửa được… thành củi." if only_wood else "Lại cần gì nữa đây, hiệp sĩ?")
	_smith.react(&"talk", 1.6)


func _row_top(slot: String) -> float:
	return ROWS_TOP + Gear.SLOTS.find(slot) * (ROW_HEIGHT + ROW_GAP)


func _refresh() -> void:
	for slot: String in Gear.SLOTS:
		var row: Dictionary = _rows[slot]
		var id := Gear.next(campaign.owned, slot)
		row["id"] = id
		var button: Button = row["button"]
		match Gear.offer(id, campaign.owned, campaign.cleared, campaign.gold):
			Gear.Offer.TOP:
				button.text = "TỐI ĐA"
				button.disabled = true
			Gear.Offer.LOCKED:
				button.text = "CHƯA MỞ"
				button.disabled = false
			Gear.Offer.TOO_POOR, Gear.Offer.BUY:
				button.text = "%d VÀNG" % int(Gear.ITEMS[id]["price"])
				button.disabled = false
		button.modulate = Color(1, 1, 1, 1.0 if Gear.offer(id, campaign.owned, campaign.cleared, campaign.gold) == Gear.Offer.BUY else 0.6)
	queue_redraw()


func _on_row_pressed(slot: String) -> void:
	var id: String = _rows[slot]["id"]
	match Gear.offer(id, campaign.owned, campaign.cleared, campaign.gold):
		Gear.Offer.BUY:
			campaign.buy(id)
			bought.emit(id)
			_celebrate(slot)
			_refresh()
		Gear.Offer.TOO_POOR:
			Sfx.play(&"untick")
			_smith.react(&"talk", 1.2)
			_say("Thiếu %d vàng. Đánh thêm vài trận rồi quay lại!" % (int(Gear.ITEMS[id]["price"]) - campaign.gold))
		Gear.Offer.LOCKED:
			Sfx.play(&"untick")
			_smith.react(&"talk", 1.2)
			_say(_locked_line(id))


func _locked_line(id: String) -> String:
	var lower := Gear.ladder(Gear.ITEMS[id]["slot"])
	var below := lower[lower.find(id) - 1] if lower.find(id) > 0 else ""
	if below and not campaign.owned.has(below):
		return "Mua %s trước đã." % Gear.ITEMS[below]["name"]
	var after: String = Gear.ITEMS[id]["after"]
	var monster := Campaign.monster(after)
	if monster:
		return "Thắng %s rồi ta mới có quặng làm món này." % monster.display_name
	return "Món này cần quặng ở vùng xa hơn. Đi tiếp rồi quay lại!"


func _celebrate(slot: String) -> void:
	Sfx.play(&"clang")
	Sfx.play(&"coin", 1.2)
	_smith.react(&"hammer", 0.5)
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func() -> void:
		_smith.react(&"cheer", 1.2)
		_hero.react(&"cheer", 1.2)
		Sfx.play(&"special"))
	_say(BOUGHT_LINES.get(slot, "Xong!"))
	# Sparks fly off the anvil side of the smith.
	for i in 14:
		_sparks.append({"at": SMITH_FEET + Vector2(-110, -150), "v": Vector2.from_angle(randf_range(-PI, 0)) * randf_range(250, 650), "life": randf_range(0.35, 0.7)})


func _say(line: String) -> void:
	_line = line
	if _line_tween:
		_line_tween.kill()
	_line_tween = create_tween()
	_line_tween.tween_method(func(a: float) -> void:
		_line_alpha = a
		queue_redraw(), _line_alpha, 1.0, 0.15)
	_line_tween.tween_interval(3.0)
	_line_tween.tween_method(func(a: float) -> void:
		_line_alpha = a
		queue_redraw(), 1.0, 0.0, 0.5)


func _process(delta: float) -> void:
	for spark in _sparks:
		spark["v"] += Vector2(0, 1400) * delta
		spark["at"] += spark["v"] * delta
		spark["life"] -= delta
	_sparks = _sparks.filter(func(s: Dictionary) -> bool: return s["life"] > 0.0)
	queue_redraw()


func _make_button(at: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.position = at
	button.size = size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 36)
	button.add_theme_color_override("font_color", MapView.PAPER)
	button.add_theme_color_override("font_disabled_color", Color(MapView.PAPER, 0.6))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(MapView.INK, 1.0 if state == "pressed" else 0.88)
		style.border_color = MapView.GOLD
		style.set_border_width_all(4)
		style.set_corner_radius_all(int(size.y / 2))
		button.add_theme_stylebox_override(state, style)
	return button


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	if _background:
		draw_texture_rect(_background, Rect2(Vector2.ZERO, SCREEN), false)
	if campaign == null:
		return
	for slot: String in Gear.SLOTS:
		_draw_row(slot)
	for spark in _sparks:
		draw_circle(spark["at"], 5.0, Color(1, 0.75, 0.3, clampf(spark["life"] * 2.0, 0.0, 1.0)))
	_draw_purse()
	if _line_alpha > 0.0:
		_draw_bubble(_line, _line_alpha)


func _draw_row(slot: String) -> void:
	var top := _row_top(slot)
	var box := Rect2(Vector2(30, top), Vector2(SCREEN.x - 60, ROW_HEIGHT))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MapView.PAPER, 0.08)
	style.border_color = Color(MapView.GOLD, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	draw_style_box(style, box)
	var next: String = _rows[slot]["id"]
	var shown := next if next else Gear.best(campaign.owned, slot)
	_draw_icon(shown, box.position + Vector2(14, (ROW_HEIGHT - ICON_SIZE) / 2))
	var text_x := box.position.x + 14 + ICON_SIZE + 18
	var title: String = Gear.SLOT_NAMES[slot].to_upper()
	draw_string(_font, Vector2(text_x, top + 30), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(MapView.GOLD, 0.9))
	var label: String = "Đã tốt nhất: %s" % Gear.ITEMS[shown]["name"] if next.is_empty() and shown else (Gear.ITEMS[next]["name"] if next else "")
	draw_string(_font, Vector2(text_x, top + 62), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, MapView.PAPER)
	var effect := Gear.describe(shown) if shown else ""
	draw_string(_font, Vector2(text_x, top + 90), effect, HORIZONTAL_ALIGNMENT_LEFT, SCREEN.x - text_x - BUTTON_SIZE.x - 60, 22, Color(MapView.PAPER, 0.7))
	if next and Gear.offer(next, campaign.owned, campaign.cleared, campaign.gold) in [Gear.Offer.BUY, Gear.Offer.TOO_POOR] and _coin:
		var button: Button = _rows[slot]["button"]
		draw_texture_rect(_coin, Rect2(button.position + Vector2(-46, (BUTTON_SIZE.y - 40) / 2), Vector2(40, 40)), false)


func _draw_icon(id: String, at: Vector2) -> void:
	var rect := Rect2(at, Vector2.ONE * ICON_SIZE)
	draw_circle(rect.get_center(), ICON_SIZE / 2, Color(MapView.PAPER, 0.12))
	if id.is_empty():
		return
	var icon := _icon(id)
	if icon == null and Gear.ITEMS[id]["slot"] == "refine":
		icon = _icon(Gear.best(campaign.owned, "weapon"))
	if icon:
		draw_texture_rect(icon, rect, false)
	else:
		# Until the art comes: the slot's first letter on a plate.
		draw_circle(rect.get_center(), ICON_SIZE * 0.4, Color(MapView.GOLD, 0.5))
		var letter: String = Gear.SLOT_NAMES[Gear.ITEMS[id]["slot"]].left(1)
		draw_string(_font, rect.get_center() + Vector2(-12, 14), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, MapView.INK)
	if Gear.ITEMS[id]["slot"] == "refine":
		var plus := "+%d" % (Gear.ladder("refine").find(id) + 1)
		draw_string_outline(_font, rect.end - Vector2(40, 6), plus, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, MapView.INK)
		draw_string(_font, rect.end - Vector2(40, 6), plus, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, MapView.GOLD)


func _icon(id: String) -> Texture2D:
	if not _icons.has(id):
		var path := ITEM_ICONS % id
		_icons[id] = load(path) if ResourceLoader.exists(path) else null
	return _icons[id]


func _draw_purse() -> void:
	var text := str(campaign.gold)
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 48).x
	var box := Rect2(Vector2(SCREEN.x - width - 150, 36), Vector2(width + 116, 78))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MapView.INK, 0.82)
	style.border_color = MapView.GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(39)
	draw_style_box(style, box)
	if _coin:
		draw_texture_rect(_coin, Rect2(box.position + Vector2(14, 11), Vector2(56, 56)), false)
	draw_string(_font, box.position + Vector2(80, 57), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 48, MapView.GOLD)


## The smith's speech bubble, its tail pointing at his head.
func _draw_bubble(text: String, alpha: float) -> void:
	var size := 34
	var width := minf(_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x, 820.0)
	var lines := ceili(_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 820.0)
	var box_size := Vector2(width + 56, lines * 46 + 36)
	var box := Rect2(Vector2(clampf(BUBBLE_POINT.x - box_size.x / 2, 30, SCREEN.x - 30 - box_size.x), BUBBLE_POINT.y - box_size.y - 30), box_size)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MapView.PAPER, alpha)
	style.border_color = Color(MapView.INK, alpha)
	style.set_border_width_all(5)
	style.set_corner_radius_all(30)
	draw_colored_polygon(PackedVector2Array([BUBBLE_POINT + Vector2(10, 0), BUBBLE_POINT + Vector2(-26, -38), BUBBLE_POINT + Vector2(26, -38)]), Color(MapView.INK, alpha))
	draw_style_box(style, box)
	draw_colored_polygon(PackedVector2Array([BUBBLE_POINT + Vector2(6, -10), BUBBLE_POINT + Vector2(-18, -36), BUBBLE_POINT + Vector2(18, -36)]), Color(MapView.PAPER, alpha))
	draw_multiline_string(_font, box.position + Vector2(28, 50), text, HORIZONTAL_ALIGNMENT_LEFT, 820.0, size, -1, Color(MapView.INK, alpha))
