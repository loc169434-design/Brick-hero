class_name BattleSim
extends RefCounted
## A bot that plays whole fights on the real rules (LinkGame + BattleState), with no nodes,
## so thousands of fights run headless and the balance numbers can be judged by measurement.
## Run it with tests/sim_balance.gd.

enum Strategy {
	## Picks any link, of any length: a player who doesn't plan.
	RANDOM,
	## Always the longest link on the board, whatever its color.
	LONGEST,
	## Long links of the color the fight needs: purple while there's shield, green when hurt,
	## red otherwise, and links that run through specials.
	SMART,
}

const STRATEGY_NAMES := ["ngẫu nhiên", "nối dài nhất", "chơi khôn"]
## A fight still going after this many moves is called off and counted as neither.
const MAX_MOVES := 80
## Squares tried per move when searching for links; keeps a move to a few milliseconds.
const SEARCH_BUDGET := 6000
## Longer links than this aren't searched for.
const MAX_LINK := 12

var board_rules: BoardRules
var battle_rules: BattleRules
var strategy: Strategy

var _rng := RandomNumberGenerator.new()
var _budget := 0


func _init(p_board_rules: BoardRules, p_battle_rules: BattleRules, p_strategy: Strategy) -> void:
	board_rules = p_board_rules
	battle_rules = p_battle_rules
	strategy = p_strategy


## Plays one fight to the end and returns what happened:
## { outcome, moves, hero_hp, gold, rounds, auto_moves, max_chain, damage, auto_damage,
##   first_hit, specials_made, specials_fired, reshuffles, link_squares, auto_squares }
## `auto` means the rounds after the link itself: lines that cleared on their own.
func play_fight(monster: MonsterData, seed_value: int) -> Dictionary:
	_rng.seed = seed_value
	var game := LinkGame.new(board_rules, seed_value)
	var state := BattleState.new(battle_rules, monster)
	var stats := {
		"outcome": BattleState.Outcome.ONGOING, "moves": 0, "hero_hp": 0, "gold": 0,
		"rounds": 0, "auto_moves": 0, "max_chain": 0, "damage": 0, "auto_damage": 0.0,
		"first_hit": 0, "specials_made": 0, "specials_fired": 0, "reshuffles": 0,
		"link_squares": 0, "auto_squares": 0,
	}
	while state.outcome == BattleState.Outcome.ONGOING and state.moves < MAX_MOVES:
		var path := choose(game, state)
		if path.is_empty():
			break
		var result := game.play(path)
		var report := state.apply_move(result)
		_count(stats, result, report)
	stats["outcome"] = state.outcome
	stats["moves"] = state.moves
	stats["hero_hp"] = state.hero_hp
	stats["gold"] = state.gold
	return stats


## The link this bot plays next, or an empty path if it can't find one.
func choose(game: LinkGame, state: BattleState) -> Array[Vector2i]:
	if strategy == Strategy.RANDOM:
		return _random_link(game)
	_budget = SEARCH_BUDGET
	var best: Array[Vector2i] = []
	var best_score := -INF
	# Start from every square in random order, so ties don't always favor the top-left.
	var starts: Array[Vector2i] = []
	for y in game.board.rows:
		for x in game.board.columns:
			starts.append(Vector2i(x, y))
	_shuffle(starts)
	for start in starts:
		var path: Array[Vector2i] = [start]
		var found := _search(game, state, path)
		if found["score"] > best_score:
			best_score = found["score"]
			best = found["path"]
		if _budget <= 0:
			break
	return best


## How much this bot wants to play `path`.
func score(game: LinkGame, state: BattleState, path: Array[Vector2i]) -> float:
	if strategy == Strategy.LONGEST:
		return path.size()
	var color := Resolver.link_color(game.board, path)
	var weight := 0.3
	match color:
		Cell.BlockColor.PURPLE:
			weight = 1.6 if state.shield > 0 else 0.3
		Cell.BlockColor.RED:
			weight = 1.5 if state.shield == 0 else 0.9
		Cell.BlockColor.GREEN:
			weight = 1.4 if state.hero_health() < 0.5 else 0.3
		Cell.NO_COLOR:
			weight = 1.0
	var specials := 0
	for p in path:
		if game.board.get_cell(p).is_special():
			specials += 1
	return path.size() * weight + specials * 3.0


## Depth-first over the links starting with `path`; returns the best { "path", "score" }.
func _search(game: LinkGame, state: BattleState, path: Array[Vector2i]) -> Dictionary:
	var best := {"path": [] as Array[Vector2i], "score": -INF}
	if path.size() >= game.rules.min_link:
		best = {"path": path.duplicate(), "score": score(game, state, path)}
	if path.size() >= MAX_LINK:
		return best
	for d in Resolver.NEIGHBORS:
		if _budget <= 0:
			break
		var next: Vector2i = path[-1] + d
		if not game.can_extend(path, next):
			continue
		_budget -= 1
		path.append(next)
		var found := _search(game, state, path)
		path.pop_back()
		if found["score"] > best["score"]:
			best = found
	return best


## A random walk from a random square, stopping at a random length of min_link or more.
func _random_link(game: LinkGame) -> Array[Vector2i]:
	for attempt in 200:
		var path: Array[Vector2i] = [Vector2i(_rng.randi_range(0, game.board.columns - 1), _rng.randi_range(0, game.board.rows - 1))]
		while path.size() < MAX_LINK:
			if path.size() >= game.rules.min_link and _rng.randf() < 0.4:
				break
			var options: Array[Vector2i] = []
			for d in Resolver.NEIGHBORS:
				if game.can_extend(path, path[-1] + d):
					options.append(path[-1] + d)
			if options.is_empty():
				break
			path.append(options[_rng.randi_range(0, options.size() - 1)])
		if path.size() >= game.rules.min_link:
			return path
	return []


func _count(stats: Dictionary, result: MoveResult, report: TurnReport) -> void:
	stats["rounds"] += result.chain_length()
	stats["max_chain"] = maxi(stats["max_chain"], result.chain_length())
	if result.chain_length() >= 2:
		stats["auto_moves"] += 1
	if result.reshuffled:
		stats["reshuffles"] += 1
	stats["damage"] += report.damage
	if stats["moves"] == 0:
		stats["first_hit"] = report.damage
	stats["moves"] += 1
	# Red damage before the shield factor, split into the link's round and the rounds after.
	var red_link := 0.0
	var red_auto := 0.0
	for step in result.steps:
		var red: float = step.count_by_color().get(Cell.BlockColor.RED, 0) * battle_rules.red_damage * (1.0 + battle_rules.chain_step * (step.chain - 1))
		if step.chain == 1:
			red_link += red
			stats["link_squares"] += step.cleared.size()
		else:
			red_auto += red
			stats["auto_squares"] += step.cleared.size()
		stats["specials_made"] += step.spawned.size()
		stats["specials_fired"] += step.triggered.size()
	if red_link + red_auto > 0.0:
		stats["auto_damage"] += report.damage * red_auto / (red_link + red_auto)


func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp
