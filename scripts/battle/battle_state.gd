class_name BattleState
extends RefCounted
## One fight, the hero against one monster. Pure rules with no nodes, so tests run headless.
## Each move, the cleared squares act by color, then the monster's countdown ticks.

enum Outcome { ONGOING, WON, LOST }

var rules: BattleRules
var monster: MonsterData
var hero_hp: int
var monster_hp: int
## Shield points; every rules.shield_layer_size points is one layer.
var shield: int
## Moves left until the monster attacks.
var countdown: int
var gold := 0
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

	# The shield goes first, so purple and long chains open the way for the red in the same move.
	var shield_before := shield
	var layers_before := shield_layers()
	shield = maxi(shield - roundi(purple), 0)
	for i in smashes:
		shield = maxi((shield_layers() - 1) * rules.shield_layer_size, 0)
	report.shield_damage = shield_before - shield
	report.layers_broken = layers_before - shield_layers()

	var damage := red * (rules.shielded_damage_factor if shield > 0 else 1.0)
	report.damage = mini(roundi(damage), monster_hp)
	monster_hp -= report.damage
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
			report.monster_attack = roundi(monster.attack * (rules.monster_crit_multiplier if report.monster_critical else 1.0))
			hero_hp = maxi(hero_hp - report.monster_attack, 0)
			attacks_made += 1
			countdown = monster.countdown
			if hero_hp == 0:
				outcome = Outcome.LOST
	report.outcome = outcome
	moves += 1
	return report


func hero_health() -> float:
	return clampf(float(hero_hp) / rules.hero_max_hp, 0.0, 1.0)


func monster_health() -> float:
	return clampf(float(monster_hp) / monster.max_hp, 0.0, 1.0)


## The board filled up: the fight is lost whatever the health bars say.
func lose() -> void:
	if outcome == Outcome.ONGOING:
		outcome = Outcome.LOST
