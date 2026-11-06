class_name LevelProgress
extends RefCounted
## How far a level is from being won: squares gathered, crates broken, items rescued and moves
## used, counted from every move's rounds. Pure rules, no Node.

var level: LevelData
var moves := 0
var collected := 0
var broken := 0
## Overlays of the level's `cover` kind cleared (ice melted through, webs torn).
var uncovered := 0
var rescued := 0


func _init(p_level: LevelData) -> void:
	level = p_level


## `counts_move` is false for a booster's blow: its squares count toward the goals but it
## isn't one of the level's moves.
func record(result: MoveResult, counts_move := true) -> void:
	if counts_move:
		moves += 1
	for step in result.steps:
		if level.collect_color >= 0:
			collected += step.count_by_color().get(level.collect_color, 0)
		for b in step.broken:
			if b["kind"] == level.obstacle:
				broken += 1
			elif b["kind"] == level.cover:
				uncovered += 1
		rescued += step.rescued.size()


## Moves left, or -1 with no limit.
func turns_left() -> int:
	return maxi(level.turns - moves, 0) if level.turns > 0 else -1


func out_of_turns() -> bool:
	return level.turns > 0 and moves >= level.turns


## Whether every goal is met; `monsters_down` says whether the last monster has fallen.
func goals_met(monsters_down: bool) -> bool:
	if level.bonus:
		return out_of_turns()
	if level.kill and not monsters_down:
		return false
	if level.collect > 0 and collected < level.collect:
		return false
	if level.break_crates and broken < level.crates:
		return false
	if level.break_cover and uncovered < level.cover_count:
		return false
	if level.rescue > 0 and rescued < level.rescue:
		return false
	return true


## 1–3 stars for a won level: by the gold for a bonus level, by the moves to spare with a move
## limit, else by the hero's health left.
func stars(hero_health: float, gold: int) -> int:
	if level.bonus:
		var share := float(gold) / maxf(level.gold_target, 1.0)
		return 1 + int(share >= 0.6) + int(share >= 1.0)
	if level.turns > 0:
		var spare := float(turns_left()) / level.turns
		return 1 + int(spare >= 0.2) + int(spare >= 0.4)
	return Campaign.stars_for(hero_health)
