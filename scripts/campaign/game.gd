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
var forge: ForgeView
var battle: Node
var manager: BattleManager

var _fighting := ""
var _back_layer: CanvasLayer


func _ready() -> void:
	campaign = Campaign.from_map()
	campaign.load_progress(save_path)
	map = MapView.new()
	add_child(map)
	map.stop_chosen.connect(show_card)
	map.forge_requested.connect(open_forge)
	map.show_campaign(campaign)
	_back_layer = CanvasLayer.new()
	add_child(_back_layer)
	_back_layer.add_child(_back_button())
	_back_layer.hide()


## The level card for stop `id`: who's there, what to do, the stars so far, and a button to fight.
func show_card(id: String) -> void:
	var level := Campaign.level(id)
	if level == null or battle or has_node("Card"):
		return
	var card := LevelCard.new()
	card.name = "Card"
	add_child(card)
	card.show_level(id, level, campaign.stars_at(id))
	card.play.connect(func(level_id: String) -> void:
		card.queue_free()
		start_fight(level_id))


## Plays level `id` (its number).
func start_fight(id: String) -> void:
	var level := Campaign.level(id)
	if level == null or battle:
		return
	_fighting = id
	battle = load(BATTLE_SCENE).instantiate()
	manager = battle.get_node("BattleManager")
	var encounters: Array[MonsterData] = []
	for monster_id in level.monsters:
		encounters.append(Campaign.monster_data(monster_id))
	manager.encounters = encounters
	manager.level = level
	manager.rules = Gear.apply(manager.rules, campaign.owned)
	manager.rules.skill = campaign.skill
	manager.rules.yellow_gold *= level.gold_multiplier
	manager.return_to_map = true
	manager.starting_gold = campaign.gold
	manager.fight_over.connect(end_fight)
	map.hide()
	add_child(battle)
	# The map's camera may be scrolled up the map: the fight is seen through its own.
	(battle.get_node("Feel") as Camera2D).make_current()
	_back_layer.show()


func open_forge() -> void:
	if forge or battle:
		return
	forge = ForgeView.new()
	add_child(forge)
	forge.closed.connect(close_forge)
	forge.bought.connect(func(_id: String) -> void: campaign.save(save_path))
	forge.skill_picked.connect(func(_id: String) -> void: campaign.save(save_path))
	map.hide()
	forge.show_campaign(campaign)


func close_forge() -> void:
	if forge == null:
		return
	campaign.save(save_path)
	forge.queue_free()
	forge = null
	map.show()
	map.show_campaign(campaign)


## Leaves the fight for the map. A fight left before it was won counts as lost.
func end_fight(won: bool, gold: int) -> void:
	if battle == null:
		return
	var stars := manager.progress.stars(manager.state.hero_health(), gold - campaign.gold) if won else 0
	var won_at := campaign.index_of(_fighting) if won else -1
	var first_clear := campaign.finish_fight(_fighting, won, gold, stars)
	var level := Campaign.level(_fighting)
	campaign.save(save_path)
	battle.queue_free()
	battle = null
	manager = null
	_fighting = ""
	_back_layer.hide()
	var chapter := level.chapter if level else 0
	if first_clear and StoryView.has_chapter(chapter):
		await read_story(chapter)
	map.show()
	map.show_campaign(campaign, won_at, first_clear)


## Shows story chapter `number` over everything until it's read or skipped.
func read_story(number: int) -> void:
	var story := StoryView.new()
	add_child(story)
	story.show_chapter(number)
	map.hide()
	await story.finished
	story.queue_free()


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
