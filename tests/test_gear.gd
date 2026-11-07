extends "res://tests/test_case.gd"


func _campaign(gold: int, cleared: Array) -> Campaign:
	var campaign := Campaign.from_map()
	campaign.gold = gold
	for id in cleared:
		campaign.cleared.append(id)
	return campaign


func test_the_hero_starts_with_the_wooden_sword() -> void:
	var campaign := Campaign.new()
	assert_eq(Gear.best(campaign.owned, "weapon"), "wood_sword")
	assert_eq(Gear.next(campaign.owned, "weapon"), "iron_sword")
	assert_eq(Gear.best(campaign.owned, "armor"), "")


func test_an_item_waits_for_its_region_its_lower_rung_and_the_gold() -> void:
	var campaign := _campaign(100, [])
	assert_eq(Gear.offer("leather_armor", campaign.owned, campaign.cleared, campaign.gold), Gear.Offer.LOCKED, "road not there yet")
	campaign.cleared.append("5")
	assert_eq(Gear.offer("leather_armor", campaign.owned, campaign.cleared, campaign.gold), Gear.Offer.BUY)
	assert_eq(Gear.offer("iron_armor", campaign.owned, campaign.cleared, campaign.gold), Gear.Offer.LOCKED, "leather first")
	campaign.gold = 10
	assert_eq(Gear.offer("leather_armor", campaign.owned, campaign.cleared, campaign.gold), Gear.Offer.TOO_POOR)
	assert_eq(Gear.offer("", campaign.owned, campaign.cleared, campaign.gold), Gear.Offer.TOP)


func test_buying_takes_the_gold_once() -> void:
	var campaign := _campaign(50, ["5", "7"])
	assert_true(campaign.buy("iron_sword"))
	assert_eq(campaign.gold, 5)
	assert_eq(Gear.best(campaign.owned, "weapon"), "iron_sword")
	assert_true(not campaign.buy("iron_sword"), "already owned")
	assert_true(not campaign.buy("leather_armor"), "too poor")
	assert_eq(campaign.gold, 5)


func test_gear_changes_the_fight_numbers() -> void:
	var base: BattleRules = load("res://data/balance.tres")
	var rules := Gear.apply(base, ["wood_sword", "iron_sword", "sword_plus_1", "leather_armor"])
	assert_eq(rules.red_damage, 2.75)
	assert_eq(rules.armor, 3, "the leather outfit: armour and boots together")
	assert_eq(rules.crit_guard, 0.25, "and its helmet")
	assert_eq(base.armor, 0, "the shared balance file is untouched")
	var orc: MonsterData = load("res://data/monsters/orc_shield.tres")
	var state := BattleState.new(rules, orc)
	assert_eq(state.monster_hit(false), orc.attack - 3)
	# Critical: 12 × (1 + 0.5 × 0.75) = 16.5, rounded to 17, minus 3 armor.
	assert_eq(state.monster_hit(true), 14)
	var bare := BattleState.new(base, orc)
	assert_eq(bare.monster_hit(true), 18)


func test_an_attack_always_hurts_a_little() -> void:
	var base: BattleRules = load("res://data/balance.tres")
	var rules := Gear.apply(base, ["leather_armor", "iron_armor"])
	rules.armor = 50
	var orc: MonsterData = load("res://data/monsters/orc_shield.tres")
	assert_eq(BattleState.new(rules, orc).monster_hit(false), 1)


func test_owned_gear_is_saved() -> void:
	var campaign := _campaign(55, ["5"])
	campaign.buy("leather_armor")
	var again := Campaign.from_map()
	again.apply_dict(campaign.to_dict())
	assert_eq(again.owned, ["wood_sword", "leather_armor"])
	assert_eq(again.gold, 10)
	again.apply_dict({"owned": ["nonsense"], "cleared": []})
	assert_eq(again.owned, ["wood_sword"], "unknown items are dropped, the wooden sword stays")


func test_armor_breaker_comes_first_and_second_wind_after_the_orc() -> void:
	var campaign := _campaign(0, ["5"])
	assert_eq(campaign.skill, "armor_breaker")
	assert_true(not campaign.pick_skill("second_wind"), "locked until the Shield Orc falls")
	assert_eq(campaign.skill, "armor_breaker")
	campaign.cleared.append("7")
	assert_true(campaign.pick_skill("second_wind"))
	assert_true(not campaign.pick_skill("nonsense"))
	assert_eq(campaign.skill, "second_wind")


func test_the_picked_skill_is_saved_and_a_locked_one_is_not_restored() -> void:
	var campaign := _campaign(0, ["1", "2", "3", "4", "5", "6", "7"])
	campaign.pick_skill("second_wind")
	var again := Campaign.from_map()
	again.apply_dict(campaign.to_dict())
	assert_eq(again.skill, "second_wind")
	again.apply_dict({"cleared": ["1"], "skill": "second_wind"})
	assert_eq(again.skill, "armor_breaker", "a save can't skip the fight that teaches it")


## Every game script compiles, including scenes no other test opens (the map, the forge).
func test_every_script_compiles() -> void:
	var folders := ["res://scripts/"]
	var checked := 0
	while not folders.is_empty():
		var folder: String = folders.pop_back()
		for sub in DirAccess.get_directories_at(folder):
			folders.append(folder + sub + "/")
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".gd"):
				var script: GDScript = load(folder + file)
				assert_true(script != null and script.can_instantiate(), folder + file)
				checked += 1
	assert_true(checked > 20, "found the scripts")


func test_an_old_save_gets_its_helmets_and_boots_back_as_gold() -> void:
	var campaign := Campaign.from_map()
	campaign.apply_dict({"gold": 7, "cleared": [], "owned": ["wood_sword", "leather_armor", "leather_helmet", "reinforced_boots"]})
	assert_eq(campaign.owned, ["wood_sword", "leather_armor"], "helmets and boots are part of the armour now")
	assert_eq(campaign.gold, 7 + 35 + 35, "their price comes back")


func test_an_armour_is_a_whole_outfit() -> void:
	assert_eq(Gear.SLOTS, ["weapon", "refine", "armor"])
	var outfit := Gear.outfit(["wood_sword", "frost_armor"])
	assert_eq(outfit.keys(), ["weapon", "armor", "refine"])
	for id in Gear.ladder("armor"):
		assert_true(Gear.ITEMS[id].has("crit_guard"), "%s guards against critical blows" % id)
	assert_eq(Gear.describe("iron_armor"), "Mỗi đòn quái nhẹ đi 5 máu, đỡ 75% chí mạng")
