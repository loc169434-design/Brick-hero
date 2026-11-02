class_name BattleManager
extends Node
## Runs the fights in order: feeds each finished drop to the BattleState, shows the result
## above the board, makes the board's tiles react, and ends the board when a fight is decided.
## Winning moves on to the next encounter; losing retries the same one.

@export var board: BoardView
@export var battle_view: BattleView
## Fought in order: the training scarecrow, then the Shield Orc, and so on.
@export var encounters: Array[MonsterData] = []
@export var rules: BattleRules

var state: BattleState
var encounter_index := 0
var _advance_on_restart := false


func _ready() -> void:
	board.drop_finished.connect(_on_drop_finished)
	board.restarted.connect(_start)
	_start()


func monster() -> MonsterData:
	return encounters[encounter_index]


func _start() -> void:
	if _advance_on_restart:
		encounter_index = (encounter_index + 1) % encounters.size()
		_advance_on_restart = false
	state = BattleState.new(rules, monster())
	board.set_tile_theme(monster().tile_theme)
	battle_view.show_state(state)
	_show_hint()


func _on_drop_finished(result: DropResult) -> void:
	if board.game.is_over:
		state.lose()
	var report := state.apply_drop(result)
	battle_view.play_report(report)
	_show_hint()
	match state.outcome:
		BattleState.Outcome.WON:
			_advance_on_restart = true
			var last := encounter_index == encounters.size() - 1
			board.finish(true, "chạm để chơi lại từ đầu" if last else "chạm để gặp đối thủ tiếp theo")
		BattleState.Outcome.LOST:
			board.finish(false, "chạm để đánh lại")
		_:
			if report.damage > 0:
				board.play_reaction(&"hurt", 2)
			elif report.monster_attack > 0 and state.hero_health() < 0.3:
				board.play_reaction(&"gloat", 1)


func _show_hint() -> void:
	var hints := monster().hints
	var ongoing := state.outcome == BattleState.Outcome.ONGOING
	battle_view.show_hint(hints[state.drops] if ongoing and state.drops < hints.size() else "")
