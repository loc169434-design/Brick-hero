class_name BattleManager
extends Node

## The fight is won and the player tapped on: back to the map with `gold` in the purse.
signal fight_over(won: bool, gold: int)
## Runs the fights in order: feeds each finished move to the BattleState, shows the result
## above the board, makes the board's tiles react, and ends the board when a fight is decided.
## The skill bar's button spends a full rage bar on the hero skill, between moves.
## Winning moves on to the next encounter; losing retries the same one.
##
## On the campaign map (`return_to_map`), a won fight ends with fight_over instead of moving
## on, and the hero starts with `starting_gold` in the purse.

## Below this much health after a hit, the monster's tiles sweat out a close call (near_miss).
const NEAR_MISS_HEALTH := 0.15
## Below this much health, the hero is close enough to losing for the tiles to gloat.
const GLOAT_HEALTH := 0.3
## Seconds after the move until the thrown rock lands on the board.
const ROCK_LANDS := 1.0

@export var board: BoardView
@export var battle_view: BattleView
## Shakes the screen when the board or the fight reports an impact. Optional.
@export var feel: ScreenFeel
## The rage bar and skill button. Optional.
@export var skill_bar: SkillBar
## Fought in order: the training scarecrow, then the Shield Orc, and so on.
@export var encounters: Array[MonsterData] = []
@export var rules: BattleRules
## Tapping after a win sends fight_over instead of starting the next encounter.
@export var return_to_map := false
## Gold in the hero's purse when a fight starts.
@export var starting_gold := 0
## The level being played, if any: its goals, move limit, board and waves (see LevelData).
## `encounters` then holds its monsters.
@export var level: LevelData

var progress: LevelProgress
## The monster fell but the level goes on with the next one (or its next form).
var _next_up := false

var state: BattleState
var encounter_index := 0
var _advance_on_restart := false


func _ready() -> void:
	board.move_finished.connect(_on_move_finished)
	board.restarted.connect(_on_restarted)
	if feel:
		board.impact.connect(feel.impact)
		battle_view.impact.connect(feel.impact)
		battle_view.slow_motion.connect(feel.slow_motion)
	board.orb_targets = battle_view.orb_targets()
	if skill_bar:
		skill_bar.pressed.connect(_on_skill_pressed)
	_start()


func monster() -> MonsterData:
	return encounters[encounter_index]


## How the monster's faces on the board answer a move that left the fight going, as
## [clip, how many tiles], or [&"", 0] for none. Themes without the clip just skip it.
static func board_reaction(report: TurnReport, state: BattleState) -> Array:
	if report.monster_attack > 0 and state.hero_health() < GLOAT_HEALTH:
		return [&"gloat", 1]
	if report.damage > 0:
		if state.monster_health() <= NEAR_MISS_HEALTH:
			return [&"near_miss", 2]
		return [&"hurt", 2]
	if report.shield_damage == 0 and state.monster.counterattacks and not report.skill:
		# Only green and yellow: nothing that hurts it, so it laughs.
		return [&"taunt", 2]
	return [&"", 0]


func _on_restarted() -> void:
	if return_to_map and _advance_on_restart:
		fight_over.emit(true, state.gold)
		return
	_start()


func _start() -> void:
	if _advance_on_restart:
		encounter_index = (encounter_index + 1) % encounters.size()
		_advance_on_restart = false
	if level:
		encounter_index = 0
	state = BattleState.new(rules, monster())
	state.rng.randomize()
	state.gold = starting_gold
	board.set_tile_theme(monster().tile_theme)
	board.locked = false
	_next_up = false
	if level:
		progress = LevelProgress.new(level)
		if level.hero_hp > 0:
			state.hero_hp = level.hero_hp
		board.prepare(level.board_seed, _set_up_board)
		battle_view.show_goal(progress)
	battle_view.show_state(state)
	if skill_bar:
		skill_bar.show_state(state)
	_show_hint()


func _on_move_finished(result: MoveResult) -> void:
	var report := state.apply_move(result)
	if level:
		progress.record(result)
		_judge(report)
	battle_view.play_report(report)
	if report.rock_thrown:
		_throw_rock()
	if skill_bar:
		skill_bar.refresh()
	_settle(report)


## The skill goes off only between moves, with the bar full. It waits for the last move to finish
## playing out above the board, and the board waits for the skill.
func _on_skill_pressed() -> void:
	if not state.skill_ready() or not board.can_act() or not board.path.is_empty():
		skill_bar.refuse()
		return
	var fight := state
	board.locked = true
	while battle_view.is_playing():
		await get_tree().process_frame
	if fight != state or not state.skill_ready():
		board.locked = false
		return
	var report := state.use_skill()
	if level:
		_judge(report)
	skill_bar.refresh()
	_settle(report)
	await battle_view.play_report(report)
	if fight == state:
		board.locked = false


## The Orc's rock lands on the board as it hits: a two-layer obstacle on a random tile.
func _throw_rock() -> void:
	var fight := state
	await get_tree().create_timer(ROCK_LANDS).timeout
	if fight == state:
		board.drop_obstacle("rock", 2)


func _set_up_board(game: LinkGame) -> void:
	if level.crates > 0:
		game.place("crate", level.crates, level.crate_layers, level.crate_rows.x, level.crate_rows.y)
	if level.rescue > 0:
		game.place(level.rescue_item, level.rescue, 0, 0, 1)


## Weighs a move against the level: a monster that falls with more to come makes way for the
## next, goals met win, the moves running out lose. Monsters of a level that isn't about
## beating them can't fall.
func _judge(report: TurnReport) -> void:
	var down := state.outcome == BattleState.Outcome.WON
	if down and not level.kill:
		state.monster_hp = maxi(state.monster_hp, 1)
		state.outcome = BattleState.Outcome.ONGOING
		down = false
	var more := state.monster.next_phase != "" or encounter_index < encounters.size() - 1
	if down and more:
		_next_up = true
		# A boss changing form isn't knocked out.
		if state.monster.next_phase:
			report.outcome = BattleState.Outcome.ONGOING
	elif state.outcome != BattleState.Outcome.LOST and progress.goals_met(down):
		state.outcome = BattleState.Outcome.WON
	elif state.outcome == BattleState.Outcome.ONGOING and progress.out_of_turns():
		state.outcome = BattleState.Outcome.LOST
	report.outcome = state.outcome if not _next_up else report.outcome
	battle_view.show_goal(progress)


## The next monster of the level steps in once the last blow has played out. The hero keeps
## their health, gold and rage.
func _bring_on_next() -> void:
	var fight := state
	board.locked = true
	while battle_view.is_playing():
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	if fight != state:
		return
	var next: MonsterData
	if state.monster.next_phase:
		next = load("res://data/monsters/%s.tres" % state.monster.next_phase)
	else:
		encounter_index += 1
		next = monster()
	var carried := state
	state = BattleState.new(rules, next)
	state.rng.randomize()
	state.hero_hp = carried.hero_hp
	state.gold = carried.gold
	state.rage = carried.rage
	# The drum keeps beating for whoever steps in next.
	state.tempo = carried.tempo
	state.countdown = state.attack_every()
	_next_up = false
	battle_view.show_state(state)
	battle_view.show_goal(progress)
	if skill_bar:
		skill_bar.show_state(state)
	Sfx.play(&"warn")
	board.locked = false


## After a move or a skill: the next hint, and the end of the fight or the tiles' reaction.
func _settle(report: TurnReport) -> void:
	_show_hint()
	if _next_up:
		_bring_on_next()
		return
	match state.outcome:
		BattleState.Outcome.WON:
			_advance_on_restart = true
			var last := encounter_index == encounters.size() - 1
			if return_to_map:
				board.finish(true, "chạm để về bản đồ")
			else:
				board.finish(true, "chạm để chơi lại từ đầu" if last else "chạm để gặp đối thủ tiếp theo")
		BattleState.Outcome.LOST:
			board.finish(false, "chạm để đánh lại")
		_:
			var reaction := board_reaction(report, state)
			if reaction[1] > 0:
				board.play_reaction(reaction[0], reaction[1])


func _show_hint() -> void:
	# The tutorial lines belong to the very first level, not to every fight with a dummy.
	var hints := monster().hints if level == null or level.number == 1 else PackedStringArray()
	var ongoing := state.outcome == BattleState.Outcome.ONGOING
	battle_view.show_hint(hints[state.moves] if ongoing and state.moves < hints.size() else "")
