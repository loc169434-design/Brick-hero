class_name BattleState
extends RefCounted
## One fight, the hero against one monster. Pure rules with no nodes, so tests run headless.
## Each move, the cleared squares act by color and fill the hero's rage, then the monster's
## countdown ticks. A full rage bar lets the hero use a skill between moves.

enum Outcome { ONGOING, WON, LOST }

## The hero skills, by BattleRules.skill, and what their button says.
const SKILLS := {
	"armor_breaker": "PHÁ GIÁP",
	"second_wind": "HỒI QUANG",
}

var rules: BattleRules
var monster: MonsterData
var hero_hp: int
var monster_hp: int
## Shield points; every rules.shield_layer_size points is one layer.
var shield: int
## Moves left until the monster attacks.
var countdown: int
## Moves the war drum has taken off the monster's countdown (MonsterData.special "drum").
var tempo := 0
var gold := 0
## Fills from cleared squares; at rules.rage_max the hero skill is ready. Starts empty each fight.
var rage := 0
var outcome := Outcome.ONGOING
## Moves played this fight.
var moves := 0
## Attacks the monster has made this fight, for its critical every crit_every attacks.
var attacks_made := 0
## For lucky critical hits. Fixed seed by default so tests and the balance bot repeat;
## the game randomizes it.
var rng := RandomNumberGenerator.new()


func _init(p_rules: BattleRules, p_monster: MonsterData) -> void:
	rules = p_rules
	monster = p_monster
	hero_hp = rules.hero_max_hp
	monster_hp = monster.max_hp
	shield = monster.shield_layers * rules.shield_layer_size
	countdown = monster.countdown
	rng.seed = 0


func shield_layers() -> int:
	return ceili(float(shield) / rules.shield_layer_size)


## Shown above the monster one move ahead, so the player can react.
func attacks_next_move() -> bool:
	return monster.counterattacks and outcome == Outcome.ONGOING and countdown == 1


## Whether the monster's next attack is its critical one. Announced along with the attack.
func next_attack_is_critical() -> bool:
	return monster.counterattacks and monster.crit_every > 0 and (attacks_made + 1) % monster.crit_every == 0


func apply_move(result: MoveResult) -> TurnReport:
	var report := TurnReport.new()
	if outcome != Outcome.ONGOING:
		report.outcome = outcome
		return report
	report.chain = result.chain_length()
	report.link_length = result.path.size()
	if not result.steps.is_empty() and not result.steps[0].clusters.is_empty():
		report.link_color = result.steps[0].clusters[0]["color"]

	var red := 0.0
	var green := 0.0
	var yellow := 0.0
	var purple := 0.0
	var smashes := 0
	for step in result.steps:
		var mult := 1.0 + rules.chain_step * (step.chain - 1)
		var counts := step.count_by_color()
		red += counts.get(Cell.BlockColor.RED, 0) * rules.red_damage * mult
		green += counts.get(Cell.BlockColor.GREEN, 0) * rules.green_heal * mult
		yellow += counts.get(Cell.BlockColor.YELLOW, 0) * rules.yellow_gold * mult
		purple += counts.get(Cell.BlockColor.PURPLE, 0) * rules.purple_shield * mult
		if step.chain >= rules.layer_break_chain:
			smashes += 1
		for cell in step.cleared_cells:
			if cell.critical:
				report.critical = true
	if red > 0.0 and not report.critical and rng.randf() < rules.crit_chance:
		report.critical = true
	if report.critical and red > 0.0:
		red *= rules.crit_multiplier
	else:
		report.critical = false

	_strike(red, purple, smashes, report)
	report.heal = mini(roundi(green), rules.hero_max_hp - hero_hp)
	hero_hp += report.heal
	report.gold = roundi(yellow)
	gold += report.gold

	if monster_hp <= 0:
		outcome = Outcome.WON
	elif monster.counterattacks:
		countdown -= 1
		if countdown <= 0:
			report.monster_critical = next_attack_is_critical()
			report.monster_attack = monster_hit(report.monster_critical)
			hero_hp = maxi(hero_hp - report.monster_attack, 0)
			attacks_made += 1
			match monster.special:
				"rock":
					report.rock_thrown = true
				"drum":
					tempo += 1
					report.drummed = true
			countdown = attack_every()
			if hero_hp == 0:
				outcome = Outcome.LOST
	report.rage_gained = _gain_rage(result)
	report.outcome = outcome
	moves += 1
	return report


## Whether the hero skill can be used now: the bar is full, the fight is on, and the skill would
## do something (Hồi Quang needs the hero hurt).
func skill_ready() -> bool:
	if outcome != Outcome.ONGOING or rage < rules.rage_max or not SKILLS.has(rules.skill):
		return false
	return rules.skill != "second_wind" or hero_hp < rules.hero_max_hp


## Spends the full bar on the hero skill. It isn't a move: the monster's countdown doesn't tick.
## Its amounts are fixed: no critical hit, no chain.
func use_skill() -> TurnReport:
	var report := TurnReport.new()
	report.outcome = outcome
	if not skill_ready():
		return report
	rage = 0
	report.skill = rules.skill
	match rules.skill:
		"armor_breaker":
			_strike(rules.armor_breaker_squares * rules.red_damage, rules.armor_breaker_shield, 0, report)
		"second_wind":
			report.heal = mini(rules.second_wind_heal, rules.hero_max_hp - hero_hp)
			hero_hp += report.heal
	if monster_hp <= 0:
		outcome = Outcome.WON
	report.outcome = outcome
	return report


## Shield points come off first, then whole layers for each smash, so purple and long chains open
## the way for the red in the same blow. Red is halved while any shield is left.
func _strike(red: float, shield_points: float, smashes: int, report: TurnReport) -> void:
	var shield_before := shield
	var layers_before := shield_layers()
	shield = maxi(shield - roundi(shield_points), 0)
	for i in smashes:
		shield = maxi((shield_layers() - 1) * rules.shield_layer_size, 0)
	report.shield_damage = shield_before - shield
	report.layers_broken = layers_before - shield_layers()
	var damage := red * (rules.shielded_damage_factor if shield > 0 else 1.0)
	report.damage = mini(roundi(damage), monster_hp)
	monster_hp -= report.damage


## Plain squares cleared and fusions set off fill the bar, up to rules.rage_per_move a move.
func _gain_rage(result: MoveResult) -> int:
	var squares := 0
	var fusions := 0
	for step in result.steps:
		fusions += step.fusions.size()
		for cell in step.cleared_cells:
			if not cell.is_special():
				squares += 1
	var gain := mini(roundi(squares * rules.rage_per_square + fusions * rules.rage_per_fusion), rules.rage_per_move)
	gain = mini(gain, rules.rage_max - rage)
	rage += gain
	return gain


## What a monster attack takes off the hero after the helmet and armor.
func monster_hit(critical: bool) -> int:
	var crit_bonus := (rules.monster_crit_multiplier - 1.0) * (1.0 - rules.crit_guard) if critical else 0.0
	return maxi(roundi(monster.attack * (1.0 + crit_bonus)) - rules.armor, 1)


## Moves between the monster's attacks, sped up by the war drum, but never under 2.
func attack_every() -> int:
	return maxi(monster.countdown - tempo, mini(2, monster.countdown))


func hero_health() -> float:
	return clampf(float(hero_hp) / rules.hero_max_hp, 0.0, 1.0)


func monster_health() -> float:
	return clampf(float(monster_hp) / monster.max_hp, 0.0, 1.0)


## The board filled up: the fight is lost whatever the health bars say.
func lose() -> void:
	if outcome == Outcome.ONGOING:
		outcome = Outcome.LOST
