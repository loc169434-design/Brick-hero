class_name Gear
extends RefCounted
## What the blacksmith sells and what it does in a fight. Pure rules, no Node.
##
## Five slots, each a ladder: the hero always uses the best rung owned, and a rung can only
## be bought once the one below it is owned and the road has reached its region (its
## `after` stop is cleared). The hero starts with the wooden sword. Prices and effects are
## proposals from docs/world_plan.md, to be checked with the balance bot.

enum Offer { OWNED, BUY, TOO_POOR, LOCKED, TOP }

const SLOTS := ["weapon", "refine", "armor", "helmet", "boots"]
const SLOT_NAMES := {
	"weapon": "Vũ khí",
	"refine": "Rèn kiếm",
	"armor": "Giáp",
	"helmet": "Nón",
	"boots": "Ủng",
}
const STARTING := ["wood_sword"]

## Each item: slot, name, price, `after` (the stop that must be cleared first, "" for none)
## and its effect: `red` damage per red square, `refine` extra red damage, `armor` taken off
## every monster attack, `crit_guard` of the monster's critical bonus stopped.
const ITEMS := {
	"wood_sword": {"slot": "weapon", "name": "Kiếm gỗ", "price": 0, "after": "", "red": 2.0},
	"iron_sword": {"slot": "weapon", "name": "Kiếm sắt", "price": 45, "after": "orc_shield", "red": 2.5},
	"tempered_sword": {"slot": "weapon", "name": "Kiếm thép", "price": 70, "after": "goblin_boss", "red": 3.0},
	"sword_plus_1": {"slot": "refine", "name": "Rèn kiếm +1", "price": 60, "after": "toad_witch", "refine": 0.25},
	"sword_plus_2": {"slot": "refine", "name": "Rèn kiếm +2", "price": 90, "after": "toad_witch", "refine": 0.5},
	"sword_plus_3": {"slot": "refine", "name": "Rèn kiếm +3", "price": 120, "after": "toad_witch", "refine": 0.75},
	"leather_armor": {"slot": "armor", "name": "Giáp da", "price": 30, "after": "scarecrow", "armor": 2},
	"iron_armor": {"slot": "armor", "name": "Giáp sắt", "price": 65, "after": "orc_chief", "armor": 4},
	"leather_helmet": {"slot": "helmet", "name": "Nón da", "price": 35, "after": "orc_chief", "crit_guard": 0.5},
	"iron_helmet": {"slot": "helmet", "name": "Nón sắt", "price": 60, "after": "goblin_boss", "crit_guard": 1.0},
	"reinforced_boots": {"slot": "boots", "name": "Ủng gia cố", "price": 35, "after": "orc_shield", "armor": 1},
	"climbing_boots": {"slot": "boots", "name": "Ủng leo núi", "price": 55, "after": "witch_house", "armor": 2},
}


## The items of `slot`, cheapest rung first.
static func ladder(slot: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in ITEMS:
		if ITEMS[id]["slot"] == slot:
			ids.append(id)
	return ids


## The best item owned in `slot`, or "" for none.
static func best(owned: Array, slot: String) -> String:
	var found := ""
	for id in ladder(slot):
		if owned.has(id):
			found = id
	return found


## The next rung to buy in `slot`, or "" when the ladder is climbed.
static func next(owned: Array, slot: String) -> String:
	for id in ladder(slot):
		if not owned.has(id):
			return id
	return ""


## Whether `id` can be bought now, and if not, why.
static func offer(id: String, owned: Array, cleared: Array, gold: int) -> Offer:
	if id.is_empty():
		return Offer.TOP
	if owned.has(id):
		return Offer.OWNED
	var item: Dictionary = ITEMS[id]
	if next(owned, item["slot"]) != id:
		return Offer.LOCKED
	if item["after"] != "" and not cleared.has(item["after"]):
		return Offer.LOCKED
	if gold < int(item["price"]):
		return Offer.TOO_POOR
	return Offer.BUY


## A copy of `base` with the gear in `owned` applied.
static func apply(base: BattleRules, owned: Array) -> BattleRules:
	var rules: BattleRules = base.duplicate()
	var weapon := best(owned, "weapon")
	if weapon:
		rules.red_damage = float(ITEMS[weapon]["red"])
	var refine := best(owned, "refine")
	if refine:
		rules.red_damage += float(ITEMS[refine]["refine"])
	rules.armor = 0
	for slot in ["armor", "boots"]:
		var id := best(owned, slot)
		if id:
			rules.armor += int(ITEMS[id]["armor"])
	var helmet := best(owned, "helmet")
	rules.crit_guard = float(ITEMS[helmet]["crit_guard"]) if helmet else 0.0
	return rules


## One line on what `id` does, for the shop.
static func describe(id: String) -> String:
	var item: Dictionary = ITEMS[id]
	match item["slot"]:
		"weapon":
			return "Mỗi ô đỏ gây %s sát thương" % _number(item["red"])
		"refine":
			return "Thêm %s sát thương mỗi ô đỏ" % _number(item["refine"])
		"armor", "boots":
			return "Mỗi đòn quái nhẹ đi %d máu" % int(item["armor"])
		"helmet":
			return "Đòn chí mạng của quái đỡ được %d%%" % roundi(float(item["crit_guard"]) * 100)
	return ""


static func _number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else str(value).replace(".", ",")
