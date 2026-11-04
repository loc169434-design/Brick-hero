class_name ForgeView
extends Node2D
## The blacksmith's forge, told with pictures instead of words. The next piece of every gear
## slot hangs from a rack in the middle of the room, swaying, with a wooden price tag; what
## can't be bought yet hangs dark with a padlock. The smith works at his anvil by the fire.
##
## Tapping a piece the hero can afford takes it to the anvil: the camera leans in and the
## player strikes it three times (each tap a hammer blow, sparks and a clang, the metal
## glowing hotter); on the third it flashes, and flies down to its slot on the hero's gear
## strip at the bottom. Tapping one that can't be bought shows why on a small tag.
## `closed` asks to go back to the map.

signal closed
## Something was bought: the campaign changed and should be saved.
signal bought(id: String)

const SCREEN := Vector2(1080, 1920)
const BACKGROUND := "res://assets/bg/forge.png"
const ITEM_ICONS := "res://assets/ui/items/%s.png"
const COMIC_FONT := "res://assets/fonts/Bangers-Regular.ttf"

## Where things are on the painted room.
const ANVIL_TOP := Vector2(650, 735)
const FIRE := Vector2(860, 700)
const TORCH := Vector2(60, 470)
const SMITH_FEET := Vector2(790, 880)
const SMITH_SCALE := 0.82
const ZOOM_ON_ANVIL := 1.55

## The rack: two posts and a bar, one peg per slot.
const RACK_BAR_Y := 930.0
const RACK_POSTS := Vector2(36, 1044)
const ICON_SIZE := 150.0
const HANG := 112.0
const TAG_Y := 1218.0
const TAP_REACH := 95.0

## The hero's gear strip on the dark floor at the bottom.
const STRIP_Y := 1560.0
const HERO_BADGE := Vector2(140, 1560)
const SLOT_SIZE := 128.0
const SLOT_X0 := 320.0
const SLOT_STEP := 166.0

const STRIKES := 3
## A strike lands by itself if the player doesn't tap for this long.
const STRIKE_PATIENCE := 1.3

const INK := MapView.INK
const PAPER := MapView.PAPER
const GOLD := MapView.GOLD
const WOOD := Color(0.55, 0.36, 0.2)
const WOOD_DARK := Color(0.36, 0.22, 0.12)

## Short lines; the pictures do the talking.
const HELLO_FIRST := "Kiếm gỗ à? Ta sửa được… thành củi!"
const HELLO := "Lò đang nóng, rèn gì nào?"
const FORGED := ["Ngon lành!", "Chắc như đá!", "Hàng thượng hạng!"]

var campaign: Campaign

var _background: Texture2D
var _coin: Texture2D
var _font: Font
var _comic_font: Font
var _camera: Camera2D
var _smith: CharacterRig
var _hero: HeadToken
var _hud_layer: CanvasLayer
var _hud: Node2D
var _icons := {}
var _time := 0.0

## What hangs on each peg, by slot: the next rung, or the best owned when the ladder is done.
var _hanging := {}
## The tag shown under one peg after a tap that couldn't buy: {"slot", "text", "until"}.
var _note := {}
var _line := ""
var _line_alpha := 0.0
var _line_tween: Tween

## Forging: the piece on the anvil and how many strikes it has taken.
var _forging := ""
var _forge_slot := ""
var _strikes := 0
var _heat := 0.0
var _piece_at := Vector2.ZERO
var _piece_scale := 1.0
var _piece_spin := 0.0
var _waiting_strike := false
var _strike_timer := 0.0
var _flash := 0.0
var _shake := 0.0
## Slot whose strip icon just landed, and how fresh that is (1 → 0).
var _landed := ""
var _landed_t := 0.0
var _sparks: Array[Dictionary] = []
var _embers: Array[Dictionary] = []


func _ready() -> void:
	_background = load(BACKGROUND) if ResourceLoader.exists(BACKGROUND) else null
	_coin = load(MapView.COIN) if ResourceLoader.exists(MapView.COIN) else null
	_font = load(MapView.FONT) if ResourceLoader.exists(MapView.FONT) else ThemeDB.fallback_font
	_comic_font = load(COMIC_FONT) if ResourceLoader.exists(COMIC_FONT) else _font
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_smith = CharacterRig.new()
	_smith.position = SMITH_FEET
	_smith.scale = Vector2.ONE * SMITH_SCALE
	add_child(_smith)
	_smith.setup("blacksmith", -1)
	# The strip, the purse and the way out stay still while the camera leans on the anvil.
	_hud_layer = CanvasLayer.new()
	add_child(_hud_layer)
	_hud = Node2D.new()
	_hud.draw.connect(_draw_hud)
	_hud_layer.add_child(_hud)
	_hero = HeadToken.new()
	_hero.position = HERO_BADGE
	_hud_layer.add_child(_hero)
	_hero.setup("hero_rookie")
	var back := Button.new()
	back.text = "◀"
	back.position = Vector2(36, 36)
	back.size = Vector2(96, 96)
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override("font_size", 48)
	back.add_theme_color_override("font_color", PAPER)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(INK, 1.0 if state == "pressed" else 0.85)
		style.border_color = GOLD
		style.set_border_width_all(4)
		style.set_corner_radius_all(48)
		back.add_theme_stylebox_override(state, style)
	back.pressed.connect(func() -> void:
		if _forging.is_empty():
			closed.emit())
	_hud_layer.add_child(back)


func show_campaign(p_campaign: Campaign) -> void:
	campaign = p_campaign
	_camera.make_current()
	_restock()
	var first := Gear.best(campaign.owned, "weapon") == "wood_sword" and Gear.best(campaign.owned, "armor") == ""
	_say(HELLO_FIRST if first else HELLO)
	_smith.react(&"talk", 1.4)


func _restock() -> void:
	for slot: String in Gear.SLOTS:
		var next := Gear.next(campaign.owned, slot)
		_hanging[slot] = next if next else Gear.best(campaign.owned, slot)


func _peg(slot: String) -> Vector2:
	var span := RACK_POSTS.y - RACK_POSTS.x
	return Vector2(RACK_POSTS.x + span * (Gear.SLOTS.find(slot) + 0.5) / Gear.SLOTS.size(), RACK_BAR_Y)


func _sway(slot: String) -> float:
	return sin(_time * 1.6 + Gear.SLOTS.find(slot) * 1.3) * 0.06


## Where the piece on `slot`'s peg hangs right now, swaying a little.
func _hang_point(slot: String) -> Vector2:
	return _peg(slot) + Vector2(0, HANG).rotated(_sway(slot))


func _offer(slot: String) -> Gear.Offer:
	return Gear.offer(Gear.next(campaign.owned, slot), campaign.owned, campaign.cleared, campaign.gold)


# --- input ---------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if campaign == null or not (event is InputEventScreenTouch and event.pressed):
		return
	if _waiting_strike:
		_strike()
		return
	if not _forging.is_empty():
		return
	for slot: String in Gear.SLOTS:
		var at := _hang_point(slot)
		if event.position.distance_to(at) < TAP_REACH or event.position.distance_to(Vector2(at.x, TAG_Y)) < 60:
			_on_piece_tapped(slot)
			return


func _on_piece_tapped(slot: String) -> void:
	var id := Gear.next(campaign.owned, slot)
	match _offer(slot):
		Gear.Offer.BUY:
			_start_forging(slot, id)
		Gear.Offer.TOO_POOR:
			Sfx.play(&"untick")
			_show_note(slot, "Thiếu %d" % (int(Gear.ITEMS[id]["price"]) - campaign.gold))
		Gear.Offer.LOCKED:
			Sfx.play(&"untick")
			_show_note(slot, _locked_reason(id))
		Gear.Offer.TOP:
			_show_note(slot, "Tốt nhất rồi!")


func _locked_reason(id: String) -> String:
	var ladder := Gear.ladder(Gear.ITEMS[id]["slot"])
	var below: String = ladder[ladder.find(id) - 1] if ladder.find(id) > 0 else ""
	if below and not campaign.owned.has(below):
		return "Cần %s" % String(Gear.ITEMS[below]["name"]).to_lower()
	var monster := Campaign.monster(Gear.ITEMS[id]["after"])
	return "Thắng %s" % monster.display_name if monster else "Vùng sau"


func _show_note(slot: String, text: String) -> void:
	_note = {"slot": slot, "text": text, "until": _time + 1.8}


# --- forging -------------------------------------------------------------------

func _start_forging(slot: String, id: String) -> void:
	campaign.buy(id)
	bought.emit(id)
	_forging = id
	_forge_slot = slot
	_strikes = 0
	_heat = 0.3
	_note = {}
	_hanging[slot] = ""
	Sfx.play(&"coin")
	var from := _hang_point(slot)
	_piece_at = from
	_piece_scale = 1.0
	_piece_spin = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_method(func(t: float) -> void:
		_piece_at = from.lerp(ANVIL_TOP, t) + Vector2(0, -sin(t * PI) * 160.0), 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_method(_lean, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(func() -> void:
		Sfx.play(&"land")
		_waiting_strike = true
		_strike_timer = STRIKE_PATIENCE)


## 0 = the whole room, 1 = leaning in on the anvil.
func _lean(t: float) -> void:
	var zoom := lerpf(1.0, ZOOM_ON_ANVIL, t)
	_camera.zoom = Vector2.ONE * zoom
	var view := SCREEN / zoom
	var focus := ANVIL_TOP + Vector2(40, 40)
	_camera.position = (focus - view / 2).clamp(Vector2.ZERO, SCREEN - view)


func _strike() -> void:
	if not _waiting_strike:
		return
	_strikes += 1
	_heat = minf(_heat + 0.25, 1.0)
	_strike_timer = STRIKE_PATIENCE
	_smith.react(&"hammer", 0.22)
	Sfx.play(&"clang", 0.85 + _strikes * 0.15)
	_shake = 1.0
	for i in 18:
		_sparks.append({"at": ANVIL_TOP, "v": Vector2.from_angle(randf_range(-PI * 0.95, -PI * 0.05)) * randf_range(250, 900), "life": randf_range(0.25, 0.6)})
	if _strikes >= STRIKES:
		_waiting_strike = false
		_finish_forging()


func _finish_forging() -> void:
	var slot := _forge_slot
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_callback(func() -> void:
		_flash = 1.0
		Sfx.play(&"special")
		_smith.react(&"cheer", 1.4)
		_say(FORGED[randi() % FORGED.size()]))
	# It leaps off the anvil, spinning and shining…
	tween.tween_method(func(t: float) -> void:
		_piece_scale = 1.0 + 0.7 * sin(t * PI * 0.5)
		_piece_spin = t * TAU
		_piece_at = ANVIL_TOP + Vector2(0, -140 * sin(t * PI * 0.5)), 0.0, 1.0, 0.5)
	tween.tween_interval(0.35)
	tween.tween_method(_lean, 1.0, 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	# …then drops into its slot on the strip.
	var start := ANVIL_TOP + Vector2(0, -140)
	tween.tween_method(func(t: float) -> void:
		_piece_at = start.lerp(_slot_center(slot), t) + Vector2(0, -sin(t * PI) * 120.0)
		_piece_scale = lerpf(1.7, SLOT_SIZE * 0.9 / ICON_SIZE, t), 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		Sfx.play(&"coin", 1.3)
		_landed = slot
		_landed_t = 1.0
		_forging = ""
		_restock())


func _say(line: String) -> void:
	_line = line
	if _line_tween:
		_line_tween.kill()
	_line_tween = create_tween()
	_line_tween.tween_method(func(a: float) -> void: _line_alpha = a, _line_alpha, 1.0, 0.15)
	_line_tween.tween_interval(2.2)
	_line_tween.tween_method(func(a: float) -> void: _line_alpha = a, 1.0, 0.0, 0.4)


func _process(delta: float) -> void:
	_time += delta
	if _waiting_strike:
		_strike_timer -= delta
		if _strike_timer <= 0.0:
			_strike()
	_flash = maxf(_flash - delta * 2.5, 0.0)
	_shake = maxf(_shake - delta * 6.0, 0.0)
	_landed_t = maxf(_landed_t - delta * 1.5, 0.0)
	_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10.0 * _shake
	for spark in _sparks:
		spark["v"] += Vector2(0, 1500) * delta
		spark["at"] += spark["v"] * delta
		spark["life"] -= delta
	_sparks = _sparks.filter(func(s: Dictionary) -> bool: return s["life"] > 0.0)
	# Embers drift up the chimney all the time.
	if randf() < delta * 9.0:
		_embers.append({"at": FIRE + Vector2(randf_range(-50, 50), -10), "v": Vector2(randf_range(-20, 20), randf_range(-140, -70)), "life": randf_range(0.8, 1.6)})
	for ember in _embers:
		ember["at"] += ember["v"] * delta
		ember["life"] -= delta
	_embers = _embers.filter(func(e: Dictionary) -> bool: return e["life"] > 0.0)
	queue_redraw()
	_hud.queue_redraw()


# --- drawing: the room -----------------------------------------------------------

func _draw() -> void:
	if _background:
		draw_texture_rect(_background, Rect2(Vector2.ZERO, SCREEN), false)
	if campaign == null:
		return
	_draw_glow(FIRE, 190.0, Color(1, 0.55, 0.15), 0.32 + 0.08 * sin(_time * 7.0) + 0.05 * sin(_time * 13.0))
	_draw_glow(TORCH, 110.0, Color(1, 0.6, 0.2), 0.25 + 0.07 * sin(_time * 9.0 + 1.0))
	for ember in _embers:
		draw_circle(ember["at"], 3.5, Color(1, 0.7, 0.25, clampf(ember["life"], 0.0, 1.0)))
	_draw_rack()
	if not _forging.is_empty() and _camera.zoom.x > 1.001:
		_draw_glow(ANVIL_TOP, 120.0, Color(1, 0.5, 0.1), 0.25 + 0.45 * _heat)
		_draw_item(self, _forging, _piece_at, ICON_SIZE * _piece_scale, _piece_spin, Color(1, 1 - _heat * 0.45, 1 - _heat * 0.8).lerp(Color.WHITE, _flash))
		if _waiting_strike:
			_draw_strike_prompt()
	for spark in _sparks:
		var tail: Vector2 = spark["v"] * 0.02
		draw_line(spark["at"], spark["at"] - tail, Color(1, 0.85, 0.4, clampf(spark["life"] * 2.5, 0.0, 1.0)), 4.0)
	if _line_alpha > 0.0:
		_draw_bubble(_line, _line_alpha)


func _draw_glow(at: Vector2, radius: float, color: Color, alpha: float) -> void:
	for i in 6:
		draw_circle(at, radius * (1.0 - i * 0.14), Color(color, alpha * 0.18))


func _draw_rack() -> void:
	var top := RACK_BAR_Y
	var bottom := 1330.0
	for x: float in [RACK_POSTS.x, RACK_POSTS.y]:
		draw_rect(Rect2(x - 14, top - 20, 28, bottom - top + 20), WOOD_DARK)
		draw_rect(Rect2(x - 9, top - 20, 10, bottom - top + 20), WOOD)
	var bar := Rect2(RACK_POSTS.x - 24, top - 22, RACK_POSTS.y - RACK_POSTS.x + 48, 30)
	draw_rect(bar, WOOD_DARK)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x, 12)), WOOD)
	for slot: String in Gear.SLOTS:
		var peg := _peg(slot)
		draw_circle(peg + Vector2(0, -6), 9, INK)
		var id: String = _hanging.get(slot, "")
		if id.is_empty():
			continue
		var at := _hang_point(slot)
		draw_line(peg, at - Vector2(0, ICON_SIZE * 0.42), Color(0.25, 0.17, 0.1), 4.0, true)
		var offer := _offer(slot)
		var pulse := 1.0
		if offer == Gear.Offer.BUY:
			pulse += 0.04 * sin(_time * 5.0)
			_draw_glow(at, ICON_SIZE * 0.62, GOLD, 0.35 + 0.15 * sin(_time * 5.0))
		var tint := Color(0.12, 0.08, 0.06, 0.92) if offer == Gear.Offer.LOCKED else Color.WHITE
		_draw_item(self, id, at, ICON_SIZE * pulse, _sway(slot), tint)
		# While the camera leans on the anvil the tags would only clutter the edge of the shot.
		if _forging.is_empty():
			_draw_tag(slot, id, offer, Vector2(at.x, TAG_Y))


func _draw_strike_prompt() -> void:
	var ring := 90.0 + 18.0 * sin(_time * 10.0)
	draw_arc(ANVIL_TOP, ring, 0, TAU, 48, Color(GOLD, 0.8), 6.0, true)
	var word := "GÕ!" if _strikes == 0 else "%d/%d" % [_strikes, STRIKES]
	var size := 64
	var width := _comic_font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := ANVIL_TOP + Vector2(-width / 2, -150)
	draw_string_outline(_comic_font, at, word, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 12, INK)
	draw_string(_comic_font, at, word, HORIZONTAL_ALIGNMENT_LEFT, -1, size, GOLD)


## The wooden tag under a peg: the price, a padlock, a tick, or the reason after a tap.
func _draw_tag(slot: String, id: String, offer: Gear.Offer, center: Vector2) -> void:
	var note: bool = _note.get("slot", "") == slot and _time < float(_note.get("until", 0.0))
	var text := ""
	match offer:
		Gear.Offer.BUY, Gear.Offer.TOO_POOR:
			text = str(int(Gear.ITEMS[id]["price"]))
		Gear.Offer.TOP:
			text = "MAX"
	if note:
		text = _note["text"]
	var size := 30 if note else 38
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var coin := offer in [Gear.Offer.BUY, Gear.Offer.TOO_POOR] and not note
	var lock := offer == Gear.Offer.LOCKED and not note
	var inner := width + (44.0 if coin else 0.0) + (34.0 if lock else 0.0)
	var box := Rect2(center - Vector2(inner / 2 + 18, 30), Vector2(inner + 36, 60))
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER if note else (WOOD_DARK if lock else WOOD)
	style.border_color = INK
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	draw_style_box(style, box)
	var x := box.position.x + 18
	if lock:
		_draw_padlock(Vector2(x + 16, center.y + 2))
	if coin and _coin:
		draw_texture_rect(_coin, Rect2(Vector2(x, center.y - 19), Vector2(38, 38)), false)
		x += 44
	var color := INK if note else (Color(1, 0.6, 0.55) if offer == Gear.Offer.TOO_POOR else PAPER)
	draw_string(_font, Vector2(x, center.y + size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_padlock(at: Vector2) -> void:
	draw_arc(at + Vector2(0, -8), 10, PI, TAU, 16, PAPER, 5.0, true)
	draw_rect(Rect2(at + Vector2(-14, -8), Vector2(28, 22)), PAPER)
	draw_circle(at + Vector2(0, 3), 3.5, WOOD_DARK)


## The smith's speech bubble, tail pointing down at him.
func _draw_bubble(text: String, alpha: float) -> void:
	var size := 36
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var tip := SMITH_FEET + Vector2(-20, -330)
	var box := Rect2(Vector2(clampf(tip.x - width / 2 - 28, 30, SCREEN.x - width - 86), tip.y - 96), Vector2(width + 56, 72))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PAPER, alpha)
	style.border_color = Color(INK, alpha)
	style.set_border_width_all(5)
	style.set_corner_radius_all(30)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-24, -34), tip + Vector2(20, -34)]), Color(INK, alpha))
	draw_style_box(style, box)
	draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -10), tip + Vector2(-16, -30), tip + Vector2(14, -30)]), Color(PAPER, alpha))
	draw_string(_font, box.position + Vector2(28, 49), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(INK, alpha))


# --- drawing: the gear strip and the purse ---------------------------------------

func _slot_center(slot: String) -> Vector2:
	return Vector2(SLOT_X0 + Gear.SLOTS.find(slot) * SLOT_STEP, STRIP_Y)


func _draw_hud() -> void:
	if campaign == null:
		return
	# The strip: the hero's badge, then what he has in each slot and what it gives.
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(INK, 0.55)
	panel.border_color = Color(GOLD, 0.5)
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(40)
	_hud.draw_style_box(panel, Rect2(Vector2(30, STRIP_Y - 120), Vector2(SCREEN.x - 60, 270)))
	var flying := not _forging.is_empty()
	for slot: String in Gear.SLOTS:
		var center := _slot_center(slot)
		var bounce := 1.0 + 0.25 * sin(_landed_t * PI) if slot == _landed else 1.0
		_hud.draw_circle(center, SLOT_SIZE / 2 * bounce, Color(PAPER, 0.1))
		_hud.draw_arc(center, SLOT_SIZE / 2 * bounce, 0, TAU, 40, Color(GOLD, 0.6), 3.0, true)
		var best := Gear.best(campaign.owned, slot)
		# The new piece is in the air until it lands; show the old one meanwhile.
		if flying and slot == _forge_slot:
			var ladder := Gear.ladder(slot)
			best = ladder[ladder.find(_forging) - 1] if ladder.find(_forging) > 0 else ""
		if best:
			_draw_item(_hud, best, center, SLOT_SIZE * 0.9 * bounce, 0.0, Color.WHITE)
		var stat := _stat(slot, best)
		var width := _font.get_string_size(stat, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
		_hud.draw_string(_font, center + Vector2(-width / 2, SLOT_SIZE / 2 + 44), stat, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, GOLD if best else Color(PAPER, 0.35))
	if flying and _camera.zoom.x <= 1.001:
		_draw_item(_hud, _forging, _piece_at, ICON_SIZE * _piece_scale, 0.0, Color.WHITE)
	if _flash > 0.0:
		_hud.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(1, 0.95, 0.8, _flash * 0.45))
	_draw_purse()


## What `best` in `slot` gives, as a few characters under its circle.
func _stat(slot: String, best: String) -> String:
	if best.is_empty():
		return "—"
	var item: Dictionary = Gear.ITEMS[best]
	match slot:
		"weapon":
			return "%s/ô" % Gear._number(item["red"])
		"refine":
			return "+%s" % Gear._number(item["refine"])
		"armor", "boots":
			return "−%d" % int(item["armor"])
		"helmet":
			return "%d%%" % roundi(float(item["crit_guard"]) * 100)
	return ""


func _draw_purse() -> void:
	var text := str(campaign.gold)
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 48).x
	var box := Rect2(Vector2(SCREEN.x - width - 150, 36), Vector2(width + 116, 78))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.82)
	style.border_color = GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(39)
	_hud.draw_style_box(style, box)
	if _coin:
		_hud.draw_texture_rect(_coin, Rect2(box.position + Vector2(14, 11), Vector2(56, 56)), false)
	_hud.draw_string(_font, box.position + Vector2(80, 57), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 48, GOLD)


# --- drawing: items ------------------------------------------------------------

func _icon(id: String) -> Texture2D:
	if not _icons.has(id):
		var path := ITEM_ICONS % id
		_icons[id] = load(path) if ResourceLoader.exists(path) else null
	return _icons[id]


## Draws item `id` centred at `at`, `size` across. Items without art yet get a drawn stand-in.
func _draw_item(canvas: CanvasItem, id: String, at: Vector2, size: float, angle: float, tint: Color) -> void:
	var slot: String = Gear.ITEMS[id]["slot"]
	var icon := _icon(id)
	if icon == null and slot == "refine":
		icon = _icon("sword_refine")
		if icon == null:
			icon = _icon(Gear.best(campaign.owned, "weapon"))
	if icon == null and id == "climbing_boots":
		icon = _icon("reinforced_boots")
	canvas.draw_set_transform(at, angle, Vector2.ONE)
	if icon:
		canvas.draw_texture_rect(icon, Rect2(-Vector2.ONE * size / 2, Vector2.ONE * size), false, tint)
	elif slot == "helmet":
		_draw_helmet(canvas, size, id == "iron_helmet", tint)
	if slot == "refine":
		var plus := "+%d" % (Gear.ladder("refine").find(id) + 1)
		var font_size := int(size * 0.3)
		canvas.draw_string_outline(_comic_font, Vector2(size * 0.08, size * 0.45), plus, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, Color(INK, tint.a))
		canvas.draw_string(_comic_font, Vector2(size * 0.08, size * 0.45), plus, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(GOLD, tint.a))
	canvas.draw_set_transform(Vector2.ZERO)


## A plain helmet until the icon is drawn (issue #30): a dome, a brim and rivets.
func _draw_helmet(canvas: CanvasItem, size: float, iron: bool, tint: Color) -> void:
	var r := size * 0.34
	var base := (Color(0.62, 0.66, 0.7) if iron else Color(0.6, 0.38, 0.2)) * tint
	var dome := PackedVector2Array()
	for i in 21:
		dome.append(Vector2.from_angle(PI + PI * i / 20.0) * r + Vector2(0, size * 0.08))
	canvas.draw_colored_polygon(dome, base)
	dome.append(dome[0])
	canvas.draw_polyline(dome, Color(INK, tint.a), 5.0, true)
	var brim := Rect2(Vector2(-r * 1.2, size * 0.06), Vector2(r * 2.4, size * 0.12))
	canvas.draw_rect(brim, base.darkened(0.2))
	canvas.draw_rect(brim, Color(INK, tint.a), false, 4.0)
	if iron:
		canvas.draw_line(Vector2(0, size * 0.08 - r), Vector2(0, size * 0.08), Color(INK, tint.a), 5.0)
		for x: float in [-0.6, 0.6]:
			canvas.draw_circle(Vector2(r * x, size * 0.12), size * 0.025, Color(INK, tint.a))
