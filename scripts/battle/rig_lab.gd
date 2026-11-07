extends Node2D
## A bench to judge the hero rig (HeroRig) against the hand-drawn hero (CharacterRig): both
## stand side by side and play the same clip. Buttons (or keys 1, 2, O): stand, strike, and
## change into the next outfit. Run scenes/rig_lab.tscn.

const OUTFITS := [
	{"name": "Tân binh", "gear": ["wood_sword"]},
	{"name": "Đồ da", "gear": ["iron_sword", "leather_armor", "leather_helmet", "reinforced_boots"]},
	{"name": "Đồ sắt", "gear": ["tempered_sword", "iron_armor", "iron_helmet", "climbing_boots"]},
]
const GROUND := 1180.0

var rig: HeroRig
var drawn: CharacterRig
var _outfit := 0
var _label: Label


func _ready() -> void:
	var sky := ColorRect.new()
	sky.color = Color(0.55, 0.75, 0.9)
	sky.size = Vector2(1080, GROUND)
	add_child(sky)
	var ground := ColorRect.new()
	ground.color = Color(0.55, 0.45, 0.3)
	ground.position = Vector2(0, GROUND)
	ground.size = Vector2(1080, 1920 - GROUND)
	add_child(ground)
	rig = HeroRig.new()
	rig.position = Vector2(290, GROUND)
	add_child(rig)
	drawn = CharacterRig.new()
	drawn.position = Vector2(800, GROUND)
	add_child(drawn)
	drawn.setup("hero_rookie", 1)
	for i in 2:
		var title := Label.new()
		title.text = ["RIG XƯƠNG (mới)", "VẼ TAY (hiện tại)"][i]
		title.position = Vector2(80 + i * 560, 600)
		title.add_theme_font_size_override("font_size", 40)
		title.add_theme_color_override("font_color", Color(0.1, 0.07, 0.05))
		add_child(title)
	_label = Label.new()
	_label.position = Vector2(80, 1250)
	_label.add_theme_font_size_override("font_size", 44)
	add_child(_label)
	var actions := [["ĐỨNG", _stand], ["CHÉM", _strike], ["ĐỔI ĐỒ", _next_outfit]]
	for i in actions.size():
		var button := Button.new()
		button.text = actions[i][0]
		button.position = Vector2(60 + i * 330, 1700)
		button.size = Vector2(300, 120)
		button.add_theme_font_size_override("font_size", 44)
		button.pressed.connect(actions[i][1])
		add_child(button)
	_wear(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_stand()
			KEY_2:
				_strike()
			KEY_O:
				_next_outfit()


func _stand() -> void:
	rig.play(&"idle")
	drawn.react(&"idle")


func _strike() -> void:
	rig.play(&"attack")
	drawn.attack()


func _next_outfit() -> void:
	_wear((_outfit + 1) % OUTFITS.size())


func _wear(index: int) -> void:
	_outfit = index
	rig.set_outfit(Gear.outfit(OUTFITS[index]["gear"]))
	_label.text = "Bộ đồ: %s" % OUTFITS[index]["name"]
