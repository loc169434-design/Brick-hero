class_name ForgeView
extends Node2D
## The blacksmith's forge, told with pictures instead of words. The next piece of every gear
## slot hangs from a wooden rack in the middle of the room, swaying, over a plaque with its name
## and price; what can't be bought yet hangs dimmed with a padlock. The smith works at his anvil
## by the fire.
##
## Tapping a piece the hero can afford takes it to the anvil: the camera leans in and the
## player strikes it three times (each tap a hammer blow, sparks and a clang, the metal
## glowing hotter); on the third it flashes, and flies down to its row on the gear board at
## the bottom, where the hero stands beside what he wears and what each piece does. Tapping one that can't be bought shows why on a small tag.
## Above the hero, two buttons pick the skill he takes into fights; a locked one says which
## fight teaches it. `closed` asks to go back to the map.

signal closed
## Something was bought: the campaign changed and should be saved.
signal bought(id: String)
## Another skill was picked: the campaign changed and should be saved.
signal skill_picked(id: String)

const SCREEN := Vector2(1080, 1920)
const BACKGROUND := "res://assets/bg/forge.png"
const ITEM_ICONS := "res://assets/ui/items/%s.png"
const COMIC_FONT := "res://assets/fonts/Bangers-Regular.ttf"

## Where things are on the painted room.
const ANVIL_TOP := Vector2(650, 735)
## The anvil's outline on the painted room, ink and all. It is drawn again over the smith, so he
## stands behind it to strike rather than in front of it.
const ANVIL_OUTLINE := [
	Vector2(606, 737), Vector2(720, 738), Vector2(722, 750), Vector2(715, 760), Vector2(692, 771),
	Vector2(688, 782), Vector2(690, 795), Vector2(700, 807), Vector2(712, 812), Vector2(712, 853),
	Vector2(589, 854), Vector2(587, 816), Vector2(594, 809), Vector2(604, 805), Vector2(615, 787),
	Vector2(612, 777), Vector2(600, 771), Vector2(580, 760), Vector2(571, 750), Vector2(575, 742),
]
## Where the centre of the hammer's head comes down: on the metal lying on the anvil's face.
const HAMMER_REST := ANVIL_TOP + Vector2(0, -28)
## The piece on the anvil, against its size hanging on the rack.
const ON_ANVIL_SCALE := 0.7
const FIRE := Vector2(860, 700)
const TORCH := Vector2(60, 470)
const SMITH_FEET := Vector2(790, 880)
## About 300 px tall on screen: a grown man beside the painted bench and anvil.
const SMITH_SCALE := 1.05
const ZOOM_ON_ANVIL := 1.55

## The rack: two posts on the floor and a beam, one hook per slot.
const RACK_BAR_Y := 930.0
const RACK_POSTS := Vector2(36, 1044)
const RACK_FLOOR := 1330.0
const ICON_SIZE := 150.0
const HANG := 112.0
const TAG_Y := 1218.0
const TAG_SIZE := Vector2(180, 86)
const TAP_REACH := 95.0

## The gear board on the dark floor at the bottom: a wooden frame round a parchment, the hero
## standing on the left, one row per slot on the right.
const BOARD := Rect2(24, 1374, 1032, 518)
const HERO_FEET := Vector2(190, 1850)
const HERO_SCALE := 0.74
const ROW_ICON := 78.0
const ROW_X := 370.0
const ROW_Y0 := 1462.0
const ROW_STEP := 86.0
## The skill buttons over the hero, one under the other.
const SKILL_PILL := Rect2(66, 1500, 270, 60)
const SKILL_STEP := 70.0
## What the smith says about each skill when it's picked.
const SKILL_LINES := {
	"armor_breaker": "Phá Giáp: bóc khiên rồi chém mạnh!",
	"second_wind": "Hồi Quang: hồi máu giữa trận!",
}

const STRIKES := 3
## The smith's clips (assets/characters/blacksmith/anim/): the last blow has its own when there is
## one, and the grin when a piece reaches the hero has its tooth glint drawn in. Without them he
## swings the plain hammer and cheers, and the glint is drawn here.
const LAST_STRIKE_CLIP := &"hammer_final"
const GRIN_CLIP := &"grin"
## Sweat flies off the smith's brow on every blow, more as he tires.
const SWEAT := Color(0.62, 0.85, 1.0)
## A strike lands by itself if the player doesn't tap for this long.
const STRIKE_PATIENCE := 1.3

const INK := MapView.INK
const PAPER := MapView.PAPER
const GOLD := MapView.GOLD
const WOOD := Color(0.55, 0.36, 0.2)
const WOOD_DARK := Color(0.36, 0.22, 0.12)
const WOOD_LIGHT := Color(0.72, 0.5, 0.3)
const IRON := Color(0.3, 0.3, 0.33)
const PARCHMENT := Color(0.96, 0.89, 0.74)
const RIBBON := Color(0.62, 0.16, 0.12)
## Pieces that can't be bought yet hang in this shade, with a padlock.
const LOCKED_TINT := Color(0.42, 0.36, 0.33)

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
## Drawn over the smith: the anvil, the piece on it, sparks, sweat and his words.
var _front: Node2D
var _hero: CharacterRig
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
## No new tap can restart a swing before its recovery has played.
var _striking := false
var _strike_landed := false
var _strike_timer := 0.0
var _flash := 0.0
var _shake := 0.0
## Slot whose strip icon just landed, and how fresh that is (1 → 0).
var _landed := ""
var _landed_t := 0.0
## How fresh the last skill pick is (1 → 0), for its button's pop.
var _picked_t := 0.0
var _sparks: Array[Dictionary] = []
## Drops of sweat in flight: {"at", "v", "life"}.
var _drops: Array[Dictionary] = []
## Glint off the grinning smith, 1 → 0.
var _glint := 0.0
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
	_smith.procedural_motion = false
	add_child(_smith)
	_smith.setup("blacksmith", -1)
	_smith.clip_impact.connect(_on_smith_impact)
	_front = Node2D.new()
	_front.draw.connect(_draw_front)
	add_child(_front)
	# The gear board, the purse and the way out stay still while the camera leans on the anvil.
	_hud_layer = CanvasLayer.new()
	add_child(_hud_layer)
	_hud = Node2D.new()
	_hud.draw.connect(_draw_hud)
	_hud_layer.add_child(_hud)
	_hero = CharacterRig.new()
	_hero.position = HERO_FEET
	_hero.scale = Vector2.ONE * HERO_SCALE
	_hud_layer.add_child(_hero)
	_hero.setup("hero_rookie", 1)
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
	for id: String in Gear.SKILL_AFTER:
		if _skill_pill(id).has_point(event.position):
			_on_skill_tapped(id)
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


## A learned skill is picked (and explained); a locked one says which fight teaches it.
func _on_skill_tapped(id: String) -> void:
	var title: String = BattleState.SKILLS[id]
	if not campaign.pick_skill(id):
		Sfx.play(&"untick")
		_say("Qua màn %s để học %s!" % [Gear.SKILL_AFTER[id], title])
		return
	if _picked_t <= 0.0 or campaign.skill != id:
		Sfx.play(&"charge")
		_hero.react(&"cheer", 1.0)
	_picked_t = 1.0
	skill_picked.emit(id)
	_say(SKILL_LINES.get(id, title))


func _skill_pill(id: String) -> Rect2:
	var i := Gear.SKILL_AFTER.keys().find(id)
	return Rect2(SKILL_PILL.position + Vector2(0, i * SKILL_STEP), SKILL_PILL.size)


func _locked_reason(id: String) -> String:
	var ladder := Gear.ladder(Gear.ITEMS[id]["slot"])
	var below: String = ladder[ladder.find(id) - 1] if ladder.find(id) > 0 else ""
	if below and not campaign.owned.has(below):
		return "Cần %s" % String(Gear.ITEMS[below]["name"]).to_lower()
	var after: String = Gear.ITEMS[id]["after"]
	return "Qua màn %s" % after if Campaign.has_level(after) else "Vùng sau"


func _show_note(slot: String, text: String) -> void:
	_note = {"slot": slot, "text": text, "until": _time + 1.8}


# --- forging -------------------------------------------------------------------

func _start_forging(slot: String, id: String) -> void:
	campaign.buy(id)
	bought.emit(id)
	_forging = id
	_forge_slot = slot
	_strikes = 0
	_striking = false
	_waiting_strike = false
	_heat = 0.3
	_note = {}
	_hanging[slot] = ""
	Sfx.play(&"coin")
	var from := _hang_point(slot)
	_piece_at = from
	_piece_scale = 1.0
	_piece_spin = 0.0
	_smith.react(&"idle", 0.0)
	# The greeting would hang over the close-up.
	if _line_tween:
		_line_tween.kill()
	_line_alpha = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_method(func(t: float) -> void:
		_piece_at = from.lerp(ANVIL_TOP, t) + Vector2(0, -sin(t * PI) * 160.0), 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_method(_lean, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Step beside the anvil while the metal arrives; keep this foot position through each blow.
	if _smith.has_clip(&"hammer"):
		var strike_feet := _smith.position + HAMMER_REST - to_local(_smith.point("hammer", &"hammer"))
		tween.tween_property(_smith, "position", strike_feet, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
	if not _waiting_strike or _striking:
		return
	_waiting_strike = false
	_striking = true
	_strike_landed = false
	_strikes += 1
	_heat = minf(_heat + 0.25, 1.0)
	var clip := LAST_STRIKE_CLIP if _strikes >= STRIKES and _smith.has_clip(LAST_STRIKE_CLIP) else &"hammer"
	# This view owns the transition; react's old 0.32-second timer cut the wind-up short.
	_smith.react(clip, 0.0)
	if _smith.has_clip(clip):
		_smith.position += HAMMER_REST - to_local(_smith.point("hammer"))
	var duration := _smith.clip_seconds(clip, 0.32)
	var tween := create_tween()
	if not _smith.has_clip(clip):
		# A still-art fallback has no clip_impact signal.
		tween.tween_interval(duration * 0.5)
		tween.tween_callback(_land_strike)
		tween.tween_interval(duration * 0.5)
	else:
		tween.tween_interval(duration)
	tween.tween_callback(func() -> void:
		_striking = false
		if _strikes >= STRIKES:
			_finish_forging()
		else:
			_smith.react(&"idle", 0.0)
			_waiting_strike = true
			_strike_timer = STRIKE_PATIENCE)


func _on_smith_impact(clip: StringName) -> void:
	if clip == &"hammer" or clip == LAST_STRIKE_CLIP:
		_land_strike()


## Called by the actual drawn contact frame, once per swing.
func _land_strike() -> void:
	if not _striking or _strike_landed:
		return
	_strike_landed = true
	Sfx.play(&"clang", 0.85 + _strikes * 0.15)
	_shake = 1.0
	# The drawn swings sweat by themselves; the still pose gets drops from here.
	if not _smith.has_clip(&"hammer"):
		_sweat(2 + _strikes * 2)
	for i in 18:
		_sparks.append({"at": ANVIL_TOP, "v": Vector2.from_angle(randf_range(-PI * 0.95, -PI * 0.05)) * randf_range(250, 900), "life": randf_range(0.25, 0.6)})


func _finish_forging() -> void:
	var slot := _forge_slot
	var tween := create_tween()
	tween.tween_callback(func() -> void:
		_flash = 1.0
		Sfx.play(&"special")
		_smith.react(&"cheer", _smith.clip_seconds(&"cheer", 1.4))
		_say(FORGED[randi() % FORGED.size()]))
	# It leaps off the anvil, spinning and shining…
	tween.tween_method(func(t: float) -> void:
		_piece_scale = 1.0 + 0.7 * sin(t * PI * 0.5)
		_piece_spin = t * TAU
		_piece_at = ANVIL_TOP + Vector2(0, -140 * sin(t * PI * 0.5)), 0.0, 1.0, 0.5)
	tween.tween_interval(0.35)
	tween.tween_method(_lean, 1.0, 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_smith, "position", SMITH_FEET, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# …then drops into its row on the gear board.
	var start := ANVIL_TOP + Vector2(0, -140)
	tween.tween_method(func(t: float) -> void:
		_piece_at = start.lerp(_slot_center(slot), t) + Vector2(0, -sin(t * PI) * 120.0)
		_piece_scale = lerpf(1.7, ROW_ICON / ICON_SIZE, t), 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		Sfx.play(&"coin", 1.3)
		_hero.react(&"cheer", 1.2)
		if _smith.has_clip(GRIN_CLIP):
			_smith.react(GRIN_CLIP, _smith.clip_seconds(GRIN_CLIP))
		else:
			_smith.react(&"cheer", 1.4)
			_glint = 1.0
		_landed = slot
		_landed_t = 1.0
		_forging = ""
		_restock())


## Drops fly off the smith's brow, up and away from the anvil, and fall.
func _sweat(count: int) -> void:
	var brow := to_local(_smith.point("head")) + Vector2(0, -20)
	for i in count:
		_drops.append({"at": brow + Vector2(randf_range(-25, 25), randf_range(-10, 10)), "v": Vector2(randf_range(40, 260), randf_range(-420, -220)), "life": randf_range(0.5, 0.8)})


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
	_picked_t = maxf(_picked_t - delta * 2.0, 0.0)
	_glint = maxf(_glint - delta * 1.4, 0.0)
	for drop in _drops:
		drop["v"] += Vector2(0, 1400) * delta
		drop["at"] += drop["v"] * delta
		drop["life"] -= delta
	_drops = _drops.filter(func(d: Dictionary) -> bool: return d["life"] > 0.0)
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
	_front.queue_redraw()
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


## Over the smith: the anvil again, cut from the room, so he stands behind it; then the piece
## being forged, sparks, sweat, the glint off his grin and what he says.
func _draw_front() -> void:
	if campaign == null:
		return
	if _background:
		var outline := PackedVector2Array(ANVIL_OUTLINE)
		var uvs := PackedVector2Array()
		for p in outline:
			uvs.append(p / SCREEN)
		_front.draw_colored_polygon(outline, Color.WHITE, uvs, _background)
	if not _forging.is_empty() and _camera.zoom.x > 1.001:
		_draw_glow(ANVIL_TOP, 120.0, Color(1, 0.5, 0.1), 0.25 + 0.45 * _heat, _front)
		var tint := Color(1, 1 - _heat * 0.45, 1 - _heat * 0.8).lerp(Color.WHITE, _flash)
		if _piece_at.is_equal_approx(ANVIL_TOP):
			# On the anvil it lies low and flat (blades on their side) so the hammer is seen coming down on it.
			var flat: bool = Gear.ITEMS[_forging]["slot"] in ["weapon", "refine"]
			var size := ICON_SIZE * ON_ANVIL_SCALE
			_draw_item(_front, _forging, ANVIL_TOP + Vector2(0, -10.0 if flat else -size * 0.3), size, -PI / 2 if flat else 0.0, tint)
		else:
			_draw_item(_front, _forging, _piece_at, ICON_SIZE * _piece_scale, _piece_spin, tint)
		if _waiting_strike:
			_draw_strike_prompt()
	for spark in _sparks:
		var tail: Vector2 = spark["v"] * 0.02
		_front.draw_line(spark["at"], spark["at"] - tail, Color(1, 0.85, 0.4, clampf(spark["life"] * 2.5, 0.0, 1.0)), 4.0)
	for drop in _drops:
		_draw_drop(drop["at"], drop["v"], clampf(drop["life"] * 3.0, 0.0, 1.0))
	if _glint > 0.0:
		_draw_glint(to_local(_smith.point("mouth")) + Vector2(-6, -2), _glint)
	if _line_alpha > 0.0:
		_draw_bubble(_line, _line_alpha)


## A drop of sweat pointing back along its flight, inked like the rest of the art.
func _draw_drop(at: Vector2, velocity: Vector2, alpha: float) -> void:
	var back := -velocity.normalized() * 16.0
	var side := back.orthogonal().normalized() * 7.0
	_front.draw_colored_polygon(PackedVector2Array([at + back * 1.2, at + side * 1.25, at - side * 1.25]), Color(INK, alpha))
	_front.draw_circle(at, 9.5, Color(INK, alpha))
	_front.draw_colored_polygon(PackedVector2Array([at + back, at + side, at - side]), Color(SWEAT, alpha))
	_front.draw_circle(at, 7, Color(SWEAT, alpha))
	_front.draw_circle(at + Vector2(-2.5, -2.5), 2.2, Color(1, 1, 1, alpha))


## A four-pointed glint off the smith's grin: it pops, turns a little and fades.
func _draw_glint(at: Vector2, t: float) -> void:
	var k := 1.0 - t
	var size := 46.0 * sin(minf(k * 3.0, 1.0) * PI * 0.5) * (0.6 + 0.4 * t)
	_draw_glow(at, size * 1.2, Color(1, 0.95, 0.7), 0.5 * t, _front)
	var turn := k * 0.8
	var points := PackedVector2Array()
	for i in 8:
		points.append(at + Vector2.from_angle(turn + i * PI / 4) * (size if i % 2 == 0 else size * 0.18))
	_front.draw_colored_polygon(points, Color(1, 1, 1, t))


## Soft light: rings of `color` on `canvas`, the room's own layer unless another is given.
func _draw_glow(at: Vector2, radius: float, color: Color, alpha: float, canvas: CanvasItem = null) -> void:
	var on := canvas if canvas else self
	for i in 6:
		on.draw_circle(at, radius * (1.0 - i * 0.14), Color(color, alpha * 0.18))


## A sturdy rack standing on the floor: two posts on feet, a beam with iron brackets and an iron
## hook per slot, shaded from the top left like the painted room. Each piece hangs on a cord.
func _draw_rack() -> void:
	var top := RACK_BAR_Y
	for x: float in [RACK_POSTS.x, RACK_POSTS.y]:
		_draw_floor_shadow(Vector2(x + 14, RACK_FLOOR), 60.0)
		_draw_plank(Rect2(x - 15, top, 30, RACK_FLOOR - top), true)
		_draw_plank(Rect2(x - 32, RACK_FLOOR - 20, 64, 24), false)
	var beam := Rect2(RACK_POSTS.x - 42, top - 30, RACK_POSTS.y - RACK_POSTS.x + 84, 38)
	draw_rect(Rect2(beam.position + Vector2(8, beam.size.y), Vector2(beam.size.x - 16, 10)), Color(0, 0, 0, 0.22))
	_draw_plank(beam, false)
	for x: float in [RACK_POSTS.x, RACK_POSTS.y]:
		_draw_bracket(Vector2(x, top + 8))
	for slot: String in Gear.SLOTS:
		var peg := _peg(slot)
		var id: String = _hanging.get(slot, "")
		var at := _hang_point(slot)
		if not id.is_empty():
			var knot := at - Vector2(0, ICON_SIZE * 0.42)
			draw_line(peg + Vector2(0, 14), knot, INK, 5.0, true)
			draw_line(peg + Vector2(0, 14), knot, Color(0.62, 0.48, 0.3), 2.5, true)
		_draw_hook(peg + Vector2(0, -2))
		if id.is_empty():
			continue
		var offer := _offer(slot)
		var pulse := 1.0
		if offer == Gear.Offer.BUY:
			pulse += 0.04 * sin(_time * 5.0)
			_draw_glow(at, ICON_SIZE * 0.62, GOLD, 0.35 + 0.15 * sin(_time * 5.0))
		var locked := offer == Gear.Offer.LOCKED
		_draw_item(self, id, at, ICON_SIZE * pulse, _sway(slot), LOCKED_TINT if locked else Color.WHITE)
		if locked:
			_draw_lock_badge(at + Vector2(ICON_SIZE * 0.3, ICON_SIZE * 0.3))
		# While the camera leans on the anvil the plaques would only clutter the edge of the shot.
		if _forging.is_empty():
			_draw_tag(slot, id, offer, Vector2(at.x, TAG_Y))


## A wooden plank with an ink outline, a lit face on its top (or left) side and a few grain lines.
func _draw_plank(rect: Rect2, upright: bool) -> void:
	_box(self, rect.grow(3), INK, 8)
	_box(self, rect, WOOD_DARK, 6)
	var lit := Rect2(rect.position, Vector2(rect.size.x * 0.55, rect.size.y) if upright else Vector2(rect.size.x, rect.size.y * 0.55))
	_box(self, lit, WOOD, 6)
	var shine := Rect2(rect.position + Vector2(4, 4), Vector2(5, rect.size.y - 8) if upright else Vector2(rect.size.x - 8, 4))
	draw_rect(shine, Color(WOOD_LIGHT, 0.8))
	var grain := Color(WOOD_DARK, 0.55)
	for i in 3:
		var k := (i + 1) / 4.0
		if upright:
			draw_line(rect.position + Vector2(rect.size.x * k, 14), rect.position + Vector2(rect.size.x * k, rect.size.y - 14), grain, 1.5)
		else:
			var y := rect.position.y + rect.size.y * k
			draw_line(Vector2(rect.position.x + 20 + i * 90, y), Vector2(rect.end.x - 40 - i * 70, y), grain, 1.5)


## An iron corner bracket where the beam meets a post, with two rivets.
func _draw_bracket(at: Vector2) -> void:
	var plate := Rect2(at - Vector2(24, 20), Vector2(48, 40))
	_box(self, plate.grow(3), INK, 6)
	_box(self, plate, IRON, 5)
	draw_rect(Rect2(plate.position + Vector2(4, 4), Vector2(plate.size.x - 8, 5)), Color(1, 1, 1, 0.18))
	for x: float in [-12.0, 12.0]:
		draw_circle(at + Vector2(x, 2), 5, INK)
		draw_circle(at + Vector2(x - 1, 1), 2.5, Color(0.7, 0.7, 0.72))


## An iron hook screwed into the underside of the beam.
func _draw_hook(at: Vector2) -> void:
	draw_circle(at, 10, INK)
	draw_circle(at, 6.5, IRON)
	draw_arc(at + Vector2(0, 18), 9, -PI * 0.5, PI * 1.1, 14, INK, 7.0, true)
	draw_arc(at + Vector2(0, 18), 9, -PI * 0.5, PI * 1.1, 14, Color(0.55, 0.55, 0.58), 3.0, true)


## A soft oval shadow on the floor.
func _draw_floor_shadow(at: Vector2, width: float) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, 0.28))
	for i in 4:
		draw_circle(Vector2.ZERO, width * (1.0 - i * 0.2), Color(0, 0, 0, 0.09))
	draw_set_transform(Vector2.ZERO)


## A padlock on a dark round badge, on the corner of a piece that can't be bought yet.
func _draw_lock_badge(at: Vector2) -> void:
	draw_circle(at, 25, INK)
	draw_circle(at, 21, WOOD_DARK)
	_draw_padlock(at + Vector2(0, 2), GOLD)


func _draw_strike_prompt() -> void:
	var ring := 90.0 + 18.0 * sin(_time * 10.0)
	_front.draw_arc(ANVIL_TOP, ring, 0, TAU, 48, Color(GOLD, 0.8), 6.0, true)
	var word := "GÕ!" if _strikes == 0 else "%d/%d" % [_strikes, STRIKES]
	var size := 64
	var width := _comic_font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := ANVIL_TOP + Vector2(-width / 2, -150)
	_front.draw_string_outline(_comic_font, at, word, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 12, INK)
	_front.draw_string(_comic_font, at, word, HORIZONTAL_ALIGNMENT_LEFT, -1, size, GOLD)


## The wooden plaque under a peg: the piece's name over its price, a padlock and the price when it
## can't be bought yet, or the reason after a tap that couldn't buy.
func _draw_tag(slot: String, id: String, offer: Gear.Offer, center: Vector2) -> void:
	var note: bool = _note.get("slot", "") == slot and _time < float(_note.get("until", 0.0))
	var note_text: String = _note.get("text", "") if note else ""
	var width := maxf(TAG_SIZE.x, _font.get_string_size(note_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 32)
	var box := Rect2(center - Vector2(width, TAG_SIZE.y) / 2, Vector2(width, TAG_SIZE.y))
	_draw_floor_shadow(center + Vector2(6, TAG_SIZE.y / 2 + 6), width * 0.45)
	_box(self, box.grow(4), INK, 18)
	_box(self, box, PAPER if note else WOOD, 14)
	if not note:
		_box(self, Rect2(box.position + Vector2(6, 5), Vector2(box.size.x - 12, 8)), Color(WOOD_LIGHT, 0.7), 4)
	var title: String = Gear.ITEMS[id]["name"]
	_text(self, title, Vector2(center.x, box.position.y + 34), 26, INK if note else PAPER)
	var bottom := box.position.y + 72
	if note:
		_text(self, note_text, Vector2(center.x, bottom), 26, RIBBON)
		return
	match offer:
		Gear.Offer.TOP:
			_text(self, "TỐT NHẤT", Vector2(center.x, bottom), 28, GOLD)
		_:
			var price := str(int(Gear.ITEMS[id]["price"]))
			var price_width := _font.get_string_size(price, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
			var x := center.x - (price_width + 40) / 2
			var color := GOLD
			if offer == Gear.Offer.TOO_POOR:
				color = Color(1, 0.55, 0.5)
			if offer == Gear.Offer.LOCKED:
				_draw_padlock(Vector2(x + 15, bottom - 11), Color(PAPER, 0.75))
				color = Color(PAPER, 0.6)
			elif _coin:
				draw_texture_rect(_coin, Rect2(Vector2(x, bottom - 30), Vector2(32, 32)), false)
			draw_string(_font, Vector2(x + 40, bottom), price, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, color)


func _draw_padlock(at: Vector2, color := PAPER) -> void:
	_draw_padlock_on(self, at, color)


func _draw_padlock_on(canvas: CanvasItem, at: Vector2, color: Color) -> void:
	canvas.draw_arc(at + Vector2(0, -8), 9, PI, TAU, 16, color, 5.0, true)
	canvas.draw_rect(Rect2(at + Vector2(-13, -8), Vector2(26, 20)), color)
	canvas.draw_circle(at + Vector2(0, 2), 3.5, WOOD_DARK)


## A rounded box filled with `color` on `canvas`.
func _box(canvas: CanvasItem, rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	canvas.draw_style_box(style, rect)


## `text` centred on `center.x`, with its baseline at `center.y`.
func _text(canvas: CanvasItem, text: String, center: Vector2, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	canvas.draw_string(_font, center - Vector2(width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


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
	_front.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-24, -34), tip + Vector2(20, -34)]), Color(INK, alpha))
	_front.draw_style_box(style, box)
	_front.draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -10), tip + Vector2(-16, -30), tip + Vector2(14, -30)]), Color(PAPER, alpha))
	_front.draw_string(_font, box.position + Vector2(28, 49), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(INK, alpha))


# --- drawing: the gear board and the purse ---------------------------------------

## Where `slot`'s piece sits on the gear board.
func _slot_center(slot: String) -> Vector2:
	return Vector2(ROW_X + ROW_ICON / 2 + 6, ROW_Y0 + Gear.SLOTS.find(slot) * ROW_STEP)


func _draw_hud() -> void:
	if campaign == null:
		return
	_draw_board()
	var flying := not _forging.is_empty()
	for slot: String in Gear.SLOTS:
		var best := Gear.best(campaign.owned, slot)
		# The new piece is in the air until it lands; show the old one meanwhile.
		if flying and slot == _forge_slot:
			var ladder := Gear.ladder(slot)
			best = ladder[ladder.find(_forging) - 1] if ladder.find(_forging) > 0 else ""
		_draw_row(slot, best)
	_draw_skills()
	if flying and _camera.zoom.x <= 1.001:
		_draw_item(_hud, _forging, _piece_at, ICON_SIZE * _piece_scale, 0.0, Color.WHITE)
	if _flash > 0.0:
		_hud.draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(1, 0.95, 0.8, _flash * 0.45))
	_draw_purse()


## A wooden frame round a sheet of parchment, a red ribbon with its title across the top, and a
## patch of shade for the hero to stand on.
func _draw_board() -> void:
	_box(_hud, Rect2(BOARD.position + Vector2(0, 10), BOARD.size), Color(0, 0, 0, 0.35), 36)
	_box(_hud, BOARD.grow(5), INK, 40)
	_box(_hud, BOARD, WOOD_DARK, 36)
	_box(_hud, Rect2(BOARD.position, Vector2(BOARD.size.x, BOARD.size.y * 0.5)), WOOD, 36)
	var sheet := BOARD.grow(-18)
	_box(_hud, sheet.grow(3), Color(INK, 0.8), 26)
	_box(_hud, sheet, PARCHMENT, 24)
	_box(_hud, Rect2(sheet.position + Vector2(10, 10), Vector2(sheet.size.x - 20, 10)), Color(1, 1, 1, 0.35), 5)
	# The hero's corner, shaded, with an oval of shadow at his feet.
	_box(_hud, Rect2(sheet.position + Vector2(14, 60), Vector2(ROW_X - sheet.position.x - 38, sheet.size.y - 76)), Color(WOOD, 0.14), 20)
	_hud.draw_set_transform(HERO_FEET + Vector2(0, -4), 0.0, Vector2(1.0, 0.22))
	for i in 3:
		_hud.draw_circle(Vector2.ZERO, 110.0 * (1.0 - i * 0.25), Color(0, 0, 0, 0.1))
	_hud.draw_set_transform(Vector2.ZERO)
	# The ribbon: tails tucked behind, a band in front.
	var center := Vector2(SCREEN.x / 2, BOARD.position.y + 2)
	for side: float in [-1.0, 1.0]:
		var tail := PackedVector2Array([center + Vector2(side * 150, -18), center + Vector2(side * 230, -18), center + Vector2(side * 205, 12), center + Vector2(side * 230, 42), center + Vector2(side * 150, 42)])
		_hud.draw_colored_polygon(tail, RIBBON.darkened(0.35))
		tail.append(tail[0])
		_hud.draw_polyline(tail, INK, 4.0, true)
	var band := Rect2(center - Vector2(175, 34), Vector2(350, 64))
	_box(_hud, band.grow(4), INK, 12)
	_box(_hud, band, RIBBON, 10)
	_box(_hud, Rect2(band.position + Vector2(8, 6), Vector2(band.size.x - 16, 8)), Color(1, 1, 1, 0.22), 4)
	_text(_hud, "TRANG BỊ", center + Vector2(0, 14), 40, PAPER)


## The skill buttons over the hero: the one he takes glows red and gold, a learned one is plain
## wood, a locked one is dim with a padlock.
func _draw_skills() -> void:
	_text(_hud, "TUYỆT CHIÊU", Vector2(SKILL_PILL.get_center().x, SKILL_PILL.position.y - 12), 24, WOOD_DARK)
	for id: String in Gear.SKILL_AFTER:
		var pill := _skill_pill(id)
		var picked := campaign.skill == id
		var learned := Gear.skill_unlocked(id, campaign.cleared)
		if picked:
			pill = pill.grow(4.0 * sin(_picked_t * PI))
		_box(_hud, pill.grow(4), GOLD if picked else INK, 22)
		_box(_hud, pill, RIBBON if picked else (WOOD if learned else Color(WOOD_DARK, 0.55)), 18)
		if learned:
			_box(_hud, Rect2(pill.position + Vector2(6, 5), Vector2(pill.size.x - 12, 8)), Color(1, 1, 1, 0.2), 4)
		var icon_at := Vector2(pill.position.x + 34, pill.get_center().y)
		_hud.draw_circle(icon_at, 24, INK)
		_hud.draw_circle(icon_at, 21, Color(0.32, 0.12, 0.05) if picked else WOOD_DARK)
		SkillBar.draw_icon(_hud, id, icon_at, 21, GOLD if picked else (PAPER if learned else Color(PAPER, 0.35)), Color.WHITE if learned else LOCKED_TINT)
		var title: String = BattleState.SKILLS[id]
		var color := PAPER if learned else Color(PAPER, 0.5)
		_hud.draw_string(_font, Vector2(pill.position.x + 68, pill.get_center().y + 10), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, color)
		if not learned:
			_draw_padlock_on(_hud, Vector2(pill.end.x - 26, pill.get_center().y + 2), Color(PAPER, 0.7))


## One row of the board: the piece in a round frame, its name, and what it does. An empty slot
## shows the ladder's first piece as a faint outline and says where to get one.
func _draw_row(slot: String, best: String) -> void:
	var center := _slot_center(slot)
	var i := Gear.SLOTS.find(slot)
	var bounce := 1.0 + 0.25 * sin(_landed_t * PI) if slot == _landed else 1.0
	var row := Rect2(Vector2(ROW_X - 12, center.y - ROW_STEP / 2 + 4), Vector2(BOARD.end.x - 30 - ROW_X, ROW_STEP - 8))
	if slot == _landed and _landed_t > 0.0:
		_box(_hud, row, Color(GOLD, 0.45 * _landed_t), 18)
	if i > 0:
		_hud.draw_line(Vector2(row.position.x + 10, row.position.y - 4), Vector2(row.end.x - 10, row.position.y - 4), Color(WOOD, 0.3), 2.0)
	var radius := ROW_ICON / 2 * bounce
	_hud.draw_circle(center, radius + 4, Color(INK, 0.85) if best else Color(WOOD, 0.45))
	_hud.draw_circle(center, radius, Color(1, 1, 1, 0.75) if best else Color(PARCHMENT.darkened(0.08)))
	var text_x := center.x + ROW_ICON / 2 + 22
	if best:
		_draw_item(_hud, best, center, ROW_ICON * 0.92 * bounce, 0.0, Color.WHITE)
		_hud.draw_string(_font, Vector2(text_x, center.y - 4), Gear.ITEMS[best]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 32, INK)
		_hud.draw_string(_font, Vector2(text_x, center.y + 28), Gear.describe(best), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, WOOD_DARK)
	else:
		_draw_item(_hud, Gear.ladder(slot)[0], center, ROW_ICON * 0.8, 0.0, Color(WOOD_DARK, 0.25))
		_hud.draw_string(_font, Vector2(text_x, center.y - 4), "%s: chưa có" % Gear.SLOT_NAMES[slot], HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(INK, 0.45))
		_hud.draw_string(_font, Vector2(text_x, center.y + 28), "Rèn ở giá treo phía trên", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(WOOD_DARK, 0.5))


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


## A plain helmet for when the icon is missing: a dome, a brim and rivets.
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
