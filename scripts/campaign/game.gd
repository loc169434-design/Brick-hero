class_name Game
extends Node
## The whole game: the world map, and a fight scene laid over it while a fight is on.
## Loads the saved journey at start and saves it after every fight.

const BATTLE_SCENE := "res://scenes/main.tscn"
const BACK_BUTTON_RECT := Rect2(36, 1790, 300, 96)

## Where progress is kept. Tests point it elsewhere.
@export var save_path := Campaign.SAVE_FILE

var campaign: Campaign
var map: MapView
var battle: Node
var manager: BattleManager

var _fighting := ""
var _back_layer: CanvasLayer


func _ready() -> void:
	campaign = Campaign.from_map()
	campaign.load_progress(save_path)
	map = MapView.new()
	add_child(map)
	map.stop_chosen.connect(start_fight)
	map.show_campaign(campaign)
	_back_layer = CanvasLayer.new()
	add_child(_back_layer)
	_back_layer.add_child(_back_button())
	_back_layer.hide()


func start_fight(id: String) -> void:
	var data := Campaign.monster(id)
	if data == null or battle:
		return
	_fighting = id
	battle = load(BATTLE_SCENE).instantiate()
	manager = battle.get_node("BattleManager")
	var encounters: Array[MonsterData] = [data]
	manager.encounters = encounters
	manager.return_to_map = true
	manager.starting_gold = campaign.gold
	manager.fight_over.connect(end_fight)
	map.hide()
	add_child(battle)
	_back_layer.show()


## Leaves the fight for the map. A fight left before it was won counts as lost.
func end_fight(won: bool, gold: int) -> void:
	if battle == null:
		return
	var from := campaign.hero_index()
	var first_clear := campaign.finish_fight(_fighting, won, gold)
	campaign.save(save_path)
	battle.queue_free()
	battle = null
	manager = null
	_fighting = ""
	_back_layer.hide()
	map.show()
	map.show_campaign(campaign, from if first_clear else -1)


func _leave_fight() -> void:
	if manager == null:
		return
	var won := manager.state.outcome == BattleState.Outcome.WON
	end_fight(won, manager.state.gold)


func _back_button() -> Button:
	var button := Button.new()
	button.text = "◀ BẢN ĐỒ"
	button.position = BACK_BUTTON_RECT.position
	button.size = BACK_BUTTON_RECT.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 40)
	button.add_theme_color_override("font_color", MapView.PAPER)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(MapView.INK, 0.85 if state != "pressed" else 1.0)
		style.border_color = MapView.GOLD
		style.set_border_width_all(4)
		style.set_corner_radius_all(48)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(_leave_fight)
	return button
