class_name Gear
extends RefCounted
## What the blacksmith sells and what it does in a fight. Pure rules, no Node.
##
## Two slots, each a ladder: the hero always uses the best rung owned, and a rung can only
## be bought once the one below it is owned and the road has reached its region (its
## `after` stop is cleared). Prices and effects are proposals (docs/sprite_plan.md), to be
## checked by playing.
##
## An outfit is the whole kit, sword, helmet, armour, shield and boots, drawn into the hero's
## frames as one (assets/characters/hero_rookie/anim/<outfit>/): buying the next rung upgrades
## all of it. Any outfit owned can be worn for its look (Campaign.look); the numbers always
## come from the best one. Refining adds damage on top, whatever is worn.

enum Offer { OWNED, BUY, TOO_POOR, LOCKED, TOP }

const SLOTS := ["outfit", "refine"]
const SLOT_NAMES := {
	"outfit": "Trang bị",
	"refine": "Rèn kiếm",
}
const STARTING := ["rookie"]
## Swords and armours sold apart before outfits: an armour becomes the outfit of its rank.
const RENAMED := {
	"wood_sword": "rookie", "leather_armor": "leather", "iron_armor": "iron",
	"royal_armor": "royal", "obsidian_armor": "obsidian", "frost_armor": "frost",
}
## Items no longer sold: an old save that owns them gets their price back.
const RETIRED := {
	"iron_sword": 45, "tempered_sword": 70,
	"leather_helmet": 35, "iron_helmet": 60, "reinforced_boots": 35, "climbing_boots": 55,
}
## The hero skills the forge lets the player pick (BattleState.SKILLS), each with the level
## that must be won before it can be picked ("" for none). The hero takes one into every fight.
const SKILL_AFTER := {
	"armor_breaker": "",
	"second_wind": "7",
	"thunder_slash": "12",
	"iron_guard": "18",
	"blade_vortex": "24",
	"starfall_strike": "30",
}
const STARTING_SKILL := "armor_breaker"

## Each item: slot, name, price, `after` (the level that must be won first, "" for none),
## its shop `icon` (assets/ui/items/) and its effect: an outfit's `red` damage per red square,
## `armor` taken off every monster attack and `crit_guard` of the monster's critical bonus
## stopped; a refine's `refine` extra red damage.
const ITEMS := {
	"rookie": {"slot": "outfit", "name": "Tân binh", "price": 0, "after": "", "icon": "wood_sword", "red": 2.0, "armor": 0, "crit_guard": 0.0},
	"leather": {"slot": "outfit", "name": "Bộ da", "price": 70, "after": "5", "icon": "leather_armor", "red": 2.25, "armor": 3, "crit_guard": 0.25},
	"iron": {"slot": "outfit", "name": "Bộ sắt", "price": 140, "after": "18", "icon": "iron_armor", "red": 2.5, "armor": 5, "crit_guard": 0.75},
	"royal": {"slot": "outfit", "name": "Hoàng Gia", "price": 190, "after": "45", "icon": "royal_armor", "red": 3.0, "armor": 7, "crit_guard": 1.0},
	"obsidian": {"slot": "outfit", "name": "Hắc Thép", "price": 210, "after": "65", "icon": "obsidian_armor", "red": 3.0, "armor": 8, "crit_guard": 1.0},
	"frost": {"slot": "outfit", "name": "Bộ Băng", "price": 240, "after": "85", "icon": "frost_armor", "red": 3.0, "armor": 9, "crit_guard": 1.0},
	"sword_plus_1": {"slot": "refine", "name": "Rèn kiếm +1", "price": 60, "after": "36", "icon": "sword_refine", "refine": 0.25},
	"sword_plus_2": {"slot": "refine", "name": "Rèn kiếm +2", "price": 90, "after": "36", "icon": "sword_refine", "refine": 0.5},
	"sword_plus_3": {"slot": "refine", "name": "Rèn kiếm +3", "price": 120, "after": "36", "icon": "sword_refine", "refine": 0.75},
}


## Whether skill `id` can be picked once the stops in `cleared` are behind the hero.
static func skill_unlocked(id: String, cleared: Array) -> bool:
	if not SKILL_AFTER.has(id):
		return false
	var after: String = SKILL_AFTER[id]
	return after.is_empty() or cleared.has(after)


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


## What the hero wears, for drawing (CharacterRig.set_outfit): `outfit`, the one he has on
## (`look` if he owns it, else his best), and the sword's refining level 0–3.
static func outfit(owned: Array, look := "") -> Dictionary:
	var refine := best(owned, "refine")
	var worn := look if owned.has(look) and ITEMS.get(look, {}).get("slot") == "outfit" else best(owned, "outfit")
	return {
		"outfit": worn,
		"refine": ladder("refine").find(refine) + 1 if refine else 0,
	}


## Old item ids in `ids` moved to today's: renamed ones swapped, retired ones dropped. Returns
## the gold the retired ones paid back.
static func migrate(ids: Array) -> int:
	var refund := 0
	for i in range(ids.size() - 1, -1, -1):
		var id := String(ids[i])
		if RENAMED.has(id):
			ids[i] = RENAMED[id]
		elif RETIRED.has(id):
			refund += int(RETIRED[id])
			ids.remove_at(i)
	return refund


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


## A copy of `base` with the gear in `owned` applied; the hero wears `look` if he owns it.
static func apply(base: BattleRules, owned: Array, look := "") -> BattleRules:
	var rules: BattleRules = base.duplicate()
	var kit := best(owned, "outfit")
	if kit:
		rules.red_damage = float(ITEMS[kit]["red"])
	var refine := best(owned, "refine")
	if refine:
		rules.red_damage += float(ITEMS[refine]["refine"])
	rules.armor = int(ITEMS[kit]["armor"]) if kit else 0
	rules.crit_guard = float(ITEMS[kit]["crit_guard"]) if kit else 0.0
	rules.outfit = outfit(owned, look)
	return rules


## One line on what `id` does, for the shop.
static func describe(id: String) -> String:
	var item: Dictionary = ITEMS[id]
	match item["slot"]:
		"outfit":
			var text := "Ô đỏ %s sát thương" % _number(item["red"])
			if int(item["armor"]) > 0:
				text = "Ô đỏ %s · đỡ %d máu/đòn · %d%% chí mạng" % [_number(item["red"]), int(item["armor"]), roundi(float(item["crit_guard"]) * 100)]
			return text
		"refine":
			return "Thêm %s sát thương mỗi ô đỏ" % _number(item["refine"])
	return ""


static func _number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else str(value).replace(".", ",")
