class_name HeroRig
extends Node2D
## The hero as a cut-out puppet on a skeleton, so the gear he buys shows on him and moves with
## him in every pose: a helmet rides the head bone, the sword sits in the hand, boots follow the
## shins. Being tried out beside the hand-drawn hero (scenes/rig_lab.tscn); not yet in fights.
##
## Art contract (docs/ideas/hero_rig_request.md), in assets/characters/hero_rig/:
## parts/<part>.png and gear/<item>/<part>.png are 512×512 layers of the hero standing in his
## neutral pose, feet at (256, 500), each holding only that part where it stands, so stacked
## they make the whole hero; joints.json gives the joints on that canvas and, optionally, the
## drawing order. Gear layers are drawn on the same canvas over the part they cover, so they
## can't drift from it. Swords are the forge's icons (assets/ui/items/<sword>.png), held at
## their grip. Without art every part is a plain shape, enough to judge the motion.
## The head is a whole picture per helmet and face, heads/<helmet|bare>_<mood>.png on the same
## canvas: a helmet is never laid over the bare head, whose hair would poke through it.
##
## Clips are built in code (see _build_clips): idle loops, the others play once and go back
## to idle; attack emits clip_impact at the blow. Each clip shows its face (CLIP_MOODS), and
## standing he blinks now and then.

signal clip_impact(clip: StringName)

const DIR := "res://assets/characters/hero_rig/"
const CANVAS := 512.0
const FEET := Vector2(256, 500)
## Drawn size: the canvas is shown as big as CharacterRig shows its poses.
const DRAW_SCALE := CharacterRig.DISPLAY_SIZE / CANVAS

## Each part: the bone it turns on (a joint name), its parent part, and its placeholder shape.
## The root is the pelvis.
const PARTS := {
	"pelvis": {"joint": "hip", "parent": ""},
	"torso": {"joint": "waist", "parent": "pelvis"},
	"head": {"joint": "neck", "parent": "torso"},
	"cape": {"joint": "cape", "parent": "torso"},
	"shield_arm_upper": {"joint": "shoulder_shield", "parent": "torso"},
	"shield_arm_lower": {"joint": "elbow_shield", "parent": "shield_arm_upper"},
	"shield_hand": {"joint": "wrist_shield", "parent": "shield_arm_lower"},
	"shield": {"joint": "shield", "parent": "shield_arm_lower"},
	"sword_arm_upper": {"joint": "shoulder_sword", "parent": "torso"},
	"sword_arm_lower": {"joint": "elbow_sword", "parent": "sword_arm_upper"},
	"sword_hand": {"joint": "wrist_sword", "parent": "sword_arm_lower"},
	"sword": {"joint": "grip", "parent": "sword_hand"},
	"back_leg_upper": {"joint": "hip_back", "parent": "pelvis"},
	"back_leg_lower": {"joint": "knee_back", "parent": "back_leg_upper"},
	"back_foot": {"joint": "ankle_back", "parent": "back_leg_lower"},
	"front_leg_upper": {"joint": "hip_front", "parent": "pelvis"},
	"front_leg_lower": {"joint": "knee_front", "parent": "front_leg_upper"},
	"front_foot": {"joint": "ankle_front", "parent": "front_leg_lower"},
}
## Back to front, unless joints.json says otherwise.
const ORDER := [
	"cape", "back_leg_upper", "back_leg_lower", "back_foot", "sword_arm_upper",
	"pelvis", "front_leg_upper", "front_leg_lower", "front_foot", "torso", "head",
	"sword", "sword_arm_lower", "sword_hand", "shield_arm_upper", "shield_arm_lower", "shield_hand", "shield",
]
## Joints on the 512 canvas, read from the hand-drawn hero's idle, for when there's no
## joints.json yet.
const JOINTS := {
	"hip": Vector2(262, 372), "waist": Vector2(262, 335), "neck": Vector2(262, 236), "cape": Vector2(236, 246),
	"shoulder_shield": Vector2(208, 268), "elbow_shield": Vector2(196, 316), "wrist_shield": Vector2(206, 348), "shield": Vector2(166, 352),
	"shoulder_sword": Vector2(304, 266), "elbow_sword": Vector2(330, 306), "wrist_sword": Vector2(352, 322), "grip": Vector2(354, 320),
	"hip_back": Vector2(236, 384), "knee_back": Vector2(212, 438), "ankle_back": Vector2(192, 474),
	"hip_front": Vector2(290, 384), "knee_front": Vector2(300, 438), "ankle_front": Vector2(316, 474),
}
## Where each slot's gear goes: the parts its layers may cover.
const GEAR_PARTS := {
	"armor": ["torso", "shield_arm_upper", "sword_arm_upper", "pelvis"],
	"helmet": ["head"],
	"boots": ["back_leg_lower", "back_foot", "front_leg_lower", "front_foot"],
}
## The faces drawn for every head, and the one each clip shows.
const MOODS := ["normal", "blink", "angry", "hurt", "happy", "scared"]
const CLIP_MOODS := {&"idle": "normal", &"attack": "angry", &"hurt": "hurt", &"cheer": "happy"}
## Seconds between blinks while standing, and how long the eyes stay shut.
const BLINK_EVERY := Vector2(2.2, 4.5)
const BLINK_TIME := 0.14
## A sword icon's grip on its 256 canvas, and its size held: the handle in the fist, the blade up.
const SWORD_GRIP := Vector2(128, 186)
const SWORD_SIZE := 210.0

## Placeholder colours, until there's art. Gear placeholders by item.
const SKIN := Color(0.96, 0.78, 0.6)
const SHIRT := Color(0.24, 0.36, 0.66)
const TROUSERS := Color(0.36, 0.25, 0.2)
const SHOE := Color(0.45, 0.28, 0.15)
const CAPE := Color(0.78, 0.15, 0.13)
const HAIR := Color(0.62, 0.32, 0.12)
const OUTLINE := Color(0.14, 0.08, 0.05)
const GEAR_COLORS := {
	"leather_armor": Color(0.62, 0.4, 0.2), "iron_armor": Color(0.7, 0.72, 0.78),
	"royal_armor": Color(0.18, 0.3, 0.7), "obsidian_armor": Color(0.2, 0.2, 0.24), "frost_armor": Color(0.7, 0.88, 0.95),
	"leather_helmet": Color(0.6, 0.38, 0.18), "iron_helmet": Color(0.75, 0.77, 0.83),
	"reinforced_boots": Color(0.5, 0.3, 0.14), "climbing_boots": Color(0.3, 0.32, 0.36),
}

## What he wears (Gear.outfit): weapon, armor, helmet, boots.
var outfit := {}
var clip := &""
## The face he shows (MOODS); set_mood to hold one, play() sets the clip's.
var mood := "normal"
var _joints := JOINTS.duplicate()
var _order: Array = ORDER.duplicate()
## part -> the Node2D turning on its joint.
var _bones := {}
## part -> the Node2D holding its drawing, offset so the joint is the bone's origin.
var _skins := {}
## part -> its base layer texture, or null for the placeholder.
var _art := {}
## Gear and sword textures by path (null when missing), kept so they live while drawn.
var _textures := {}
var _player: AnimationPlayer
var _root: Node2D
var _blink_in := 3.0
var _blink_left := 0.0


func _init() -> void:
	_load_joints()
	_root = Node2D.new()
	_root.scale = Vector2.ONE * DRAW_SCALE
	add_child(_root)
	_build_skeleton()
	_player = AnimationPlayer.new()
	_root.add_child(_player)
	# The blow's call goes out the moment the clip reaches it, not at the end of the frame.
	_player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	var library := AnimationLibrary.new()
	for name: StringName in CLIPS:
		library.add_animation(name, _build_clip(name))
	_player.add_animation_library(&"", library)
	_player.animation_finished.connect(func(name: StringName) -> void:
		if name != &"idle":
			play(&"idle"))


func _ready() -> void:
	play(&"idle")


func set_outfit(p_outfit: Dictionary) -> void:
	outfit = p_outfit.duplicate()
	for part: String in _skins:
		_skins[part].queue_redraw()


func set_mood(p_mood: String) -> void:
	if not p_mood in MOODS or p_mood == mood:
		return
	mood = p_mood
	_skins["head"].queue_redraw()


func play(name: StringName) -> void:
	if _player == null or not _player.has_animation(name):
		return
	clip = name
	_blink_left = 0.0
	set_mood(CLIP_MOODS.get(name, "normal"))
	_player.stop()
	_player.play(name)


func _process(delta: float) -> void:
	if clip != &"idle":
		return
	if _blink_left > 0.0:
		_blink_left -= delta
		if _blink_left <= 0.0:
			set_mood("normal")
		return
	_blink_in -= delta
	if _blink_in <= 0.0 and mood == "normal":
		_blink_in = randf_range(BLINK_EVERY.x, BLINK_EVERY.y)
		_blink_left = BLINK_TIME
		set_mood("blink")


## The picture of the whole head for the helmet worn and the face shown, or null when that
## head isn't drawn (then the bare head and a helmet layer over it, as before heads existed).
func head_texture() -> Texture2D:
	var helmet: String = outfit.get("helmet", "")
	var kind := helmet if helmet else "bare"
	var head := _texture(DIR + "heads/%s_%s.png" % [kind, mood])
	return head if head else _texture(DIR + "heads/%s_normal.png" % kind)


## Seconds into `name` at which its blow lands, or 0.
func impact_seconds(name: StringName) -> float:
	return float(CLIPS.get(name, {}).get("impact", 0.0))


## The part's bone, for tests and for effects that follow a hand or the head.
func bone(part: String) -> Node2D:
	return _bones.get(part)


## Global position of the joint a part turns on, in its current pose.
func joint_position(part: String) -> Vector2:
	var node: Node2D = _bones.get(part)
	return node.global_position if node else global_position


# --- skeleton ------------------------------------------------------------------

func _load_joints() -> void:
	var path := DIR + "joints.json"
	if not ResourceLoader.exists(path):
		return
	var json: JSON = load(path)
	if not json.data is Dictionary:
		return
	var joints: Dictionary = json.data.get("joints", {})
	for name: String in joints:
		_joints[name] = Vector2(joints[name][0], joints[name][1])
	if json.data.get("order") is Array:
		_order = json.data["order"].duplicate()
	# The sword swings back over the shoulder in the wind-up: it passes behind the head.
	if _order.has("sword") and _order.has("head") and _order.find("sword") > _order.find("head"):
		_order.erase("sword")
		_order.insert(_order.find("head"), "sword")


## Bones nest as the parts do; each sits at its joint's offset from its parent's joint, so at
## rest every layer lands where it was drawn. Draw order is set with z_index, since nesting
## alone would draw children over parents.
func _build_skeleton() -> void:
	for part: String in PARTS:
		_make_bone(part)
	for i in _order.size():
		if _skins.has(_order[i]):
			_skins[_order[i]].z_index = i


func _make_bone(part: String) -> Node2D:
	if _bones.has(part):
		return _bones[part]
	var info: Dictionary = PARTS[part]
	var here: Vector2 = _joints[info["joint"]]
	var node := Node2D.new()
	node.name = part
	if info["parent"] == "":
		node.position = here - FEET
		_root.add_child(node)
	else:
		var parent := _make_bone(info["parent"])
		node.position = here - _joints[PARTS[info["parent"]]["joint"]]
		parent.add_child(node)
	_bones[part] = node
	var skin := Node2D.new()
	skin.position = -here
	skin.draw.connect(_draw_part.bind(part, skin))
	node.add_child(skin)
	_skins[part] = skin
	var path := DIR + "parts/%s.png" % part
	_art[part] = load(path) if ResourceLoader.exists(path) else null
	return node


# --- drawing ---------------------------------------------------------------------

## A part's layer and the gear over it, in canvas coordinates (the skin is offset so the
## joint is the bone's origin). The sword is the item icon held at its grip.
func _draw_part(part: String, skin: Node2D) -> void:
	if part == "sword":
		_draw_sword(skin)
		return
	var base: Texture2D = _art[part]
	var whole_head: Texture2D = head_texture() if part == "head" else null
	if whole_head:
		base = whole_head
	if base:
		skin.draw_texture(base, Vector2.ZERO)
	else:
		_draw_placeholder(part, skin)
	for slot: String in GEAR_PARTS:
		var item: String = outfit.get(slot, "")
		if item == "" or not part in GEAR_PARTS[slot] or (whole_head and slot == "helmet"):
			continue
		var layer := _texture(DIR + "gear/%s/%s.png" % [item, part])
		if layer:
			skin.draw_texture(layer, Vector2.ZERO)
		else:
			_draw_gear_placeholder(slot, item, part, skin)


func _draw_sword(skin: Node2D) -> void:
	var item: String = outfit.get("weapon", "")
	var icon := _texture("res://assets/ui/items/%s.png" % item) if item else null
	if icon == null:
		return
	var grip: Vector2 = _joints["grip"]
	var size := SWORD_SIZE / 256.0
	skin.draw_set_transform(grip, 0.0, Vector2.ONE * size)
	skin.draw_texture(icon, -SWORD_GRIP)
	skin.draw_set_transform(Vector2.ZERO)


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


## A capsule from one joint toward the next, the way a limb would be drawn.
func _limb(skin: Node2D, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	skin.draw_line(from, to, OUTLINE, width + 8.0)
	skin.draw_circle(from, (width + 8.0) / 2, OUTLINE)
	skin.draw_circle(to, (width + 8.0) / 2, OUTLINE)
	skin.draw_line(from, to, color, width)
	skin.draw_circle(from, width / 2, color)
	skin.draw_circle(to, width / 2, color)


func _draw_placeholder(part: String, skin: Node2D) -> void:
	var j := _joints
	match part:
		"pelvis":
			_limb(skin, j["hip_back"], j["hip_front"], 44, TROUSERS)
		"torso":
			_limb(skin, j["waist"], j["neck"] + Vector2(0, 26), 86, SHIRT)
			skin.draw_rect(Rect2(j["waist"] + Vector2(-42, -8), Vector2(84, 14)), Color(0.4, 0.25, 0.12))
		"head":
			var center: Vector2 = j["neck"] + Vector2(6, -62)
			skin.draw_circle(center, 62, OUTLINE)
			skin.draw_circle(center, 56, SKIN)
			skin.draw_circle(center + Vector2(-10, -26), 50, HAIR)
			skin.draw_circle(center + Vector2(14, -6), 7, OUTLINE)
			skin.draw_circle(center + Vector2(36, -6), 7, OUTLINE)
			skin.draw_arc(center + Vector2(26, 18), 14, 0.2, PI - 0.2, 10, OUTLINE, 4.0)
		"cape":
			skin.draw_colored_polygon(PackedVector2Array([j["cape"], j["cape"] + Vector2(40, -6), j["cape"] + Vector2(-50, 120), j["cape"] + Vector2(-110, 90)]), CAPE)
		"shield_arm_upper":
			_limb(skin, j["shoulder_shield"], j["elbow_shield"], 30, SHIRT)
		"shield_arm_lower":
			_limb(skin, j["elbow_shield"], j["wrist_shield"], 26, SKIN)
		"shield_hand":
			skin.draw_circle(j["wrist_shield"], 18, OUTLINE)
			skin.draw_circle(j["wrist_shield"], 14, SKIN)
		"shield":
			skin.draw_circle(j["shield"], 64, OUTLINE)
			skin.draw_circle(j["shield"], 58, Color(0.72, 0.72, 0.75))
			skin.draw_circle(j["shield"], 46, Color(0.55, 0.33, 0.16))
			skin.draw_circle(j["shield"], 14, Color(0.95, 0.75, 0.2))
		"sword_arm_upper":
			_limb(skin, j["shoulder_sword"], j["elbow_sword"], 30, SHIRT)
		"sword_arm_lower":
			_limb(skin, j["elbow_sword"], j["wrist_sword"], 26, SKIN)
		"sword_hand":
			skin.draw_circle(j["wrist_sword"] + Vector2(4, 0), 20, OUTLINE)
			skin.draw_circle(j["wrist_sword"] + Vector2(4, 0), 16, SKIN)
		"back_leg_upper":
			_limb(skin, j["hip_back"], j["knee_back"], 34, TROUSERS)
		"back_leg_lower":
			_limb(skin, j["knee_back"], j["ankle_back"], 30, TROUSERS)
		"back_foot":
			_limb(skin, j["ankle_back"], j["ankle_back"] + Vector2(-26, 20), 30, SHOE)
		"front_leg_upper":
			_limb(skin, j["hip_front"], j["knee_front"], 34, TROUSERS)
		"front_leg_lower":
			_limb(skin, j["knee_front"], j["ankle_front"], 30, TROUSERS)
		"front_foot":
			_limb(skin, j["ankle_front"], j["ankle_front"] + Vector2(26, 20), 30, SHOE)


func _draw_gear_placeholder(slot: String, item: String, part: String, skin: Node2D) -> void:
	var j := _joints
	var color: Color = GEAR_COLORS.get(item, Color.GRAY)
	match part:
		"torso":
			_limb(skin, j["waist"] + Vector2(0, -4), j["neck"] + Vector2(0, 34), 92, color)
			if item == "iron_armor":
				skin.draw_line(j["waist"] + Vector2(0, -10), j["neck"] + Vector2(0, 40), color.darkened(0.3), 6)
		"shield_arm_upper", "sword_arm_upper":
			var shoulder: Vector2 = j["shoulder_shield" if part == "shield_arm_upper" else "shoulder_sword"]
			skin.draw_circle(shoulder, 26, OUTLINE)
			skin.draw_circle(shoulder, 22, color)
		"head":
			var center: Vector2 = j["neck"] + Vector2(6, -62)
			skin.draw_arc(center, 58, PI * 1.02, PI * 1.98, 24, OUTLINE, 34)
			skin.draw_arc(center, 58, PI * 1.05, PI * 1.95, 24, color, 26)
			if item == "iron_helmet":
				skin.draw_line(center + Vector2(0, -88), center + Vector2(0, -60), OUTLINE, 10)
		"back_leg_lower", "front_leg_lower":
			var knee: Vector2 = j["knee_back" if part == "back_leg_lower" else "knee_front"]
			var ankle: Vector2 = j["ankle_back" if part == "back_leg_lower" else "ankle_front"]
			_limb(skin, knee.lerp(ankle, 0.35), ankle, 36, color)
		"back_foot", "front_foot":
			var ankle: Vector2 = j["ankle_back" if part == "back_foot" else "ankle_front"]
			var toe := Vector2(-30, 20) if part == "back_foot" else Vector2(30, 20)
			_limb(skin, ankle, ankle + toe, 36, color)


# --- clips -----------------------------------------------------------------------

## Each clip: length, loop, the blow's time, and keys {time: {part: degrees}} for the bones
## that move, plus "lift" (the pelvis's offset, in canvas pixels). Bones not keyed stay at
## rest. Times are seconds. The shield arm barely moves until the torso is painted under it:
## turned further, it opens holes beside the shield.
const CLIPS := {
	&"idle": {
		"length": 2.4, "loop": true,
		"keys": {
			0.0: {"lift": Vector2(0, 0), "torso": 0.0, "head": 0.0, "sword_arm_upper": 0.0, "shield_arm_upper": 0.0, "cape": 0.0},
			1.2: {"lift": Vector2(0, 5), "torso": -2.0, "head": 2.5, "sword_arm_upper": 4.0, "shield_arm_upper": -0.8, "cape": -6.0},
			2.4: {"lift": Vector2(0, 0), "torso": 0.0, "head": 0.0, "sword_arm_upper": 0.0, "shield_arm_upper": 0.0, "cape": 0.0},
		},
	},
	&"attack": {
		"length": 0.85, "loop": false, "impact": 0.34,
		"keys": {
			0.0: {"lift": Vector2(0, 0), "torso": 0.0, "head": 0.0, "sword_arm_upper": 0.0, "sword_arm_lower": 0.0, "sword_hand": 0.0, "shield_arm_upper": 0.0, "front_leg_upper": 0.0, "front_leg_lower": 0.0, "back_leg_upper": 0.0, "cape": 0.0},
			# Wind-up: leans back, the fist comes up to the chest in front (a chibi's short arm
			# can't clear the big head, and higher it hides the face) and the wrist cocks the
			# blade back over the head. (At rest the blade stands up from a hanging arm, about 153° off
			# the forearm's line, so the wrist turns a long way through a cut.)
			0.24: {"lift": Vector2(-10, 4), "torso": -12.0, "head": -6.0, "sword_arm_upper": -60.0, "sword_arm_lower": -25.0, "sword_hand": 45.0, "shield_arm_upper": 4.5, "front_leg_upper": -10.0, "front_leg_lower": 8.0, "back_leg_upper": 6.0, "cape": 10.0},
			# The cut: steps in, the arm comes down in front and the blade lands level.
			0.34: {"lift": Vector2(24, 10), "torso": 16.0, "head": 8.0, "sword_arm_upper": -35.0, "sword_arm_lower": -5.0, "sword_hand": 125.0, "shield_arm_upper": -5.0, "front_leg_upper": -28.0, "front_leg_lower": 18.0, "back_leg_upper": 22.0, "cape": -18.0},
			# Follow-through, the blade carrying on down.
			0.5: {"lift": Vector2(20, 8), "torso": 12.0, "head": 6.0, "sword_arm_upper": 10.0, "sword_arm_lower": 5.0, "sword_hand": 140.0, "shield_arm_upper": -3.5, "front_leg_upper": -24.0, "front_leg_lower": 16.0, "back_leg_upper": 18.0, "cape": -10.0},
			0.85: {"lift": Vector2(0, 0), "torso": 0.0, "head": 0.0, "sword_arm_upper": 0.0, "sword_arm_lower": 0.0, "sword_hand": 0.0, "shield_arm_upper": 0.0, "front_leg_upper": 0.0, "front_leg_lower": 0.0, "back_leg_upper": 0.0, "cape": 0.0},
		},
	},
	# Struck: knocked back a step, head thrown back, then steadies.
	&"hurt": {
		"length": 0.55, "loop": false,
		"keys": {
			0.0: {"lift": Vector2(0, 0), "torso": 0.0, "head": 0.0, "sword_arm_upper": 0.0, "shield_arm_upper": 0.0, "front_leg_upper": 0.0, "back_leg_upper": 0.0, "cape": 0.0},
			0.08: {"lift": Vector2(-22, 4), "torso": -14.0, "head": -12.0, "sword_arm_upper": 18.0, "shield_arm_upper": 4.0, "front_leg_upper": 10.0, "back_leg_upper": -8.0, "cape": 14.0},
			0.25: {"lift": Vector2(-14, 3), "torso": -8.0, "head": -6.0, "sword_arm_upper": 10.0, "shield_arm_upper": 2.0, "front_leg_upper": 6.0, "back_leg_upper": -5.0, "cape": 8.0},
			0.55: {"lift": Vector2(0, 0), "torso": 0.0, "head": 0.0, "sword_arm_upper": 0.0, "shield_arm_upper": 0.0, "front_leg_upper": 0.0, "back_leg_upper": 0.0, "cape": 0.0},
		},
	},
	# A win: two hops, the sword raised.
	&"cheer": {
		"length": 1.1, "loop": false,
		"keys": {
			0.0: {"lift": Vector2(0, 0), "torso": 0.0, "head": 0.0, "sword_arm_upper": 0.0, "sword_arm_lower": 0.0, "sword_hand": 0.0, "shield_arm_upper": 0.0, "front_leg_upper": 0.0, "front_leg_lower": 0.0, "back_leg_upper": 0.0, "back_leg_lower": 0.0, "cape": 0.0},
			0.22: {"lift": Vector2(0, -42), "torso": -4.0, "head": -5.0, "sword_arm_upper": -100.0, "sword_arm_lower": -40.0, "sword_hand": 150.0, "shield_arm_upper": 2.5, "front_leg_upper": -18.0, "front_leg_lower": 26.0, "back_leg_upper": 14.0, "back_leg_lower": 18.0, "cape": 14.0},
			0.42: {"lift": Vector2(0, 0), "torso": 2.0, "head": 0.0, "sword_arm_upper": -100.0, "sword_arm_lower": -40.0, "sword_hand": 150.0, "shield_arm_upper": 1.0, "front_leg_upper": 0.0, "front_leg_lower": 0.0, "back_leg_upper": 0.0, "back_leg_lower": 0.0, "cape": 0.0},
			0.64: {"lift": Vector2(0, -28), "torso": -4.0, "head": -5.0, "sword_arm_upper": -106.0, "sword_arm_lower": -40.0, "sword_hand": 146.0, "shield_arm_upper": 2.5, "front_leg_upper": -14.0, "front_leg_lower": 20.0, "back_leg_upper": 10.0, "back_leg_lower": 14.0, "cape": 10.0},
			0.84: {"lift": Vector2(0, 0), "torso": 2.0, "head": 0.0, "sword_arm_upper": -100.0, "sword_arm_lower": -40.0, "sword_hand": 150.0, "shield_arm_upper": 1.0, "front_leg_upper": 0.0, "front_leg_lower": 0.0, "back_leg_upper": 0.0, "back_leg_lower": 0.0, "cape": 0.0},
			1.1: {"lift": Vector2(0, 0), "torso": 0.0, "head": 0.0, "sword_arm_upper": 0.0, "sword_arm_lower": 0.0, "sword_hand": 0.0, "shield_arm_upper": 0.0, "front_leg_upper": 0.0, "front_leg_lower": 0.0, "back_leg_upper": 0.0, "back_leg_lower": 0.0, "cape": 0.0},
		},
	},
}


func _build_clip(name: StringName) -> Animation:
	var info: Dictionary = CLIPS[name]
	var animation := Animation.new()
	animation.length = info["length"]
	animation.loop_mode = Animation.LOOP_LINEAR if info["loop"] else Animation.LOOP_NONE
	var tracks := {}
	var times: Array = info["keys"].keys()
	times.sort()
	for t: float in times:
		var keys: Dictionary = info["keys"][t]
		for what: String in keys:
			var path := ""
			var value: Variant
			if what == "lift":
				path = "pelvis:position"
				value = _bones["pelvis"].position + Vector2(keys[what])
			else:
				path = "%s:rotation" % _path_to(what)
				value = deg_to_rad(float(keys[what]))
			if not tracks.has(path):
				var track := animation.add_track(Animation.TYPE_VALUE)
				animation.track_set_path(track, NodePath(path))
				animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
				tracks[path] = track
			animation.track_insert_key(tracks[path], t, value)
	if info.has("impact"):
		var calls := animation.add_track(Animation.TYPE_METHOD)
		animation.track_set_path(calls, NodePath(".."))
		animation.track_insert_key(calls, float(info["impact"]), {"method": "_on_impact", "args": [name]})
	return animation


## The bone's path from the AnimationPlayer's root (_root).
func _path_to(part: String) -> String:
	var chain: Array[String] = [part]
	var parent: String = PARTS[part]["parent"]
	while parent != "":
		chain.push_front(parent)
		parent = PARTS[parent]["parent"]
	return "/".join(chain)


func _on_impact(name: StringName) -> void:
	clip_impact.emit(name)
