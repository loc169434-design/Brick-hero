class_name Campaign
extends RefCounted
## The journey from the castle to the dragon's cave: the levels on the world map in order,
## which ones are won, and the gold the hero carries between fights. Pure rules, no Node.
##
## Stops are the levels of docs/campaign_100.md, laid out on the map segments of
## assets/bg/campaign/ (nodes_g*.json; segment 1 at the bottom). A stop's id is its level
## number; a level without data in data/levels/ yet is shown as coming soon. The next level
## opens when every one before it is won, and won levels can be played again for gold and
## for more stars (LevelProgress.stars).

enum Stop { LOCKED, OPEN, DONE, SOON }

const MAP_DIR := "res://assets/bg/campaign/"
const SEGMENT_HEIGHT := 1920.0
const MONSTER_DIR := "res://data/monsters/"
const LEVEL_FILE := "res://data/levels/level_%03d.tres"
const SAVE_FILE := "user://campaign.json"
## Hero health left for 2 and 3 stars; any win earns 1.
const STAR_HEALTH := [0.4, 0.7]

## [{id, position, level, hard, boss, bonus, petal}], bottom to top; position on the whole
## map, its segments stacked with segment 1 at the bottom.
var stops: Array[Dictionary] = []
## How many map segments the stops are laid out on.
var segments := 1
var cleared: Array[String] = []
var gold := 0
## Best stars won at each cleared stop, by id.
var stars := {}
## Gear bought at the forge (Gear.ITEMS ids); the hero uses the best of each slot.
var owned: Array[String] = []
## The hero skill taken into every fight, picked at the forge.
var skill := Gear.STARTING_SKILL
## Boosters in the bag, by Boosters id: how many of each.
var boosters := {}


func _init() -> void:
	owned.assign(Gear.STARTING)


## Reads every nodes_g*.json in `dir` (one per batch of levels).
static func from_map(dir := MAP_DIR) -> Campaign:
	var campaign := Campaign.new()
	var nodes: Array[Dictionary] = []
	for file in DirAccess.get_files_at(dir):
		if file.begins_with("nodes_") and file.ends_with(".json"):
			var json := JSON.new()
			if json.parse(FileAccess.get_file_as_string(dir + file)) == OK and json.data is Array:
				for node: Dictionary in json.data:
					nodes.append(node)
	nodes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["level"]) < int(b["level"]))
	for node in nodes:
		campaign.segments = maxi(campaign.segments, int(node.get("segment", 1)))
	for node in nodes:
		var lift := (campaign.segments - int(node.get("segment", 1))) * SEGMENT_HEIGHT
		campaign.stops.append({
			"id": str(int(node["level"])),
			"level": int(node["level"]),
			"position": Vector2(node["x"], float(node["y"]) + lift),
			"hard": bool(node.get("hard", false)),
			"boss": bool(node.get("boss", false)),
			"bonus": bool(node.get("bonus", false)),
			"petal": bool(node.get("petal", false)),
		})
	return campaign


func index_of(id: String) -> int:
	for i in stops.size():
		if stops[i]["id"] == id:
			return i
	return -1


func is_cleared(id: String) -> bool:
	return cleared.has(id)


## The furthest stop the hero may fight now: the first one not cleared. -1 once all are.
func next_index() -> int:
	for i in stops.size():
		if not is_cleared(stops[i]["id"]):
			return i
	return -1


func state_of(id: String) -> Stop:
	if is_cleared(id):
		return Stop.DONE
	var i := index_of(id)
	if i < 0 or i != next_index():
		return Stop.LOCKED
	return Stop.OPEN if has_level(id) else Stop.SOON


## Where the hero stands on the map: the next stop, or the last one when all are cleared.
func hero_index() -> int:
	var i := next_index()
	return i if i >= 0 else stops.size() - 1


static func has_level(id: String) -> bool:
	return id.is_valid_int() and ResourceLoader.exists(LEVEL_FILE % int(id))


static func level(id: String) -> LevelData:
	return load(LEVEL_FILE % int(id)) if has_level(id) else null


## The first monster met at stop `id`: who stands on it on the map.
static func monster(id: String) -> MonsterData:
	var data := level(id)
	if data == null or data.monsters.is_empty():
		return null
	return monster_data(data.monsters[0])


static func monster_data(monster_id: String) -> MonsterData:
	var path := MONSTER_DIR + monster_id + ".tres"
	return load(path) if ResourceLoader.exists(path) else null


## Stars for a win with `hero_health` (0..1) left.
static func stars_for(hero_health: float) -> int:
	var count := 1
	for need: float in STAR_HEALTH:
		if hero_health >= need:
			count += 1
	return count


func stars_at(id: String) -> int:
	return int(stars.get(id, 0))


## A fight at `id` ended. Winning clears the stop, keeps the best `star_count` and the hero
## keeps `gold_after`, the purse at the end of the fight; losing keeps the purse from before
## it. Returns whether this win cleared the stop for the first time.
func finish_fight(id: String, won: bool, gold_after: int, star_count := 1) -> bool:
	if not won:
		return false
	gold = maxi(gold_after, 0)
	stars[id] = clampi(maxi(star_count, stars_at(id)), 1, 3)
	if is_cleared(id):
		return false
	cleared.append(id)
	return true


## Buys `id` at the forge if Gear.offer allows it. Returns whether it was bought.
func buy(id: String) -> bool:
	if Gear.offer(id, owned, cleared, gold) != Gear.Offer.BUY:
		return false
	gold -= int(Gear.ITEMS[id]["price"])
	owned.append(id)
	return true


func booster_count(id: String) -> int:
	return int(boosters.get(id, 0))


## Buys one booster `id` at the forge. Returns whether it was bought.
func buy_booster(id: String) -> bool:
	if not Boosters.is_known(id) or booster_count(id) >= Boosters.MAX_CARRIED:
		return false
	var price := int(Boosters.ITEMS[id]["price"])
	if gold < price:
		return false
	gold -= price
	boosters[id] = booster_count(id) + 1
	return true


## Adds a booster won in a fight, if the bag has room for it. Returns whether it went in.
func add_booster(id: String) -> bool:
	if not Boosters.is_known(id) or booster_count(id) >= Boosters.MAX_CARRIED:
		return false
	boosters[id] = booster_count(id) + 1
	return true


## Takes one booster `id` out of the bag. Returns whether there was one.
func use_booster(id: String) -> bool:
	if booster_count(id) <= 0:
		return false
	boosters[id] = booster_count(id) - 1
	return true


## Takes skill `id` into the next fights if it's been learned. Returns whether it was picked.
func pick_skill(id: String) -> bool:
	if not Gear.skill_unlocked(id, cleared):
		return false
	skill = id
	return true


func to_dict() -> Dictionary:
	return {"cleared": cleared.duplicate(), "gold": gold, "stars": stars.duplicate(), "owned": owned.duplicate(), "skill": skill, "boosters": boosters.duplicate()}


func apply_dict(data: Dictionary) -> void:
	cleared.clear()
	for id in data.get("cleared", []):
		if index_of(String(id)) >= 0 and not cleared.has(String(id)):
			cleared.append(String(id))
	gold = maxi(int(data.get("gold", 0)), 0)
	owned.assign(Gear.STARTING)
	for id in data.get("owned", []):
		if Gear.ITEMS.has(String(id)) and not owned.has(String(id)):
			owned.append(String(id))
	skill = Gear.STARTING_SKILL
	pick_skill(String(data.get("skill", "")))
	boosters.clear()
	var bag: Variant = data.get("boosters", {})
	if bag is Dictionary:
		for id in bag:
			if Boosters.is_known(String(id)):
				boosters[String(id)] = clampi(int(bag[id]), 0, Boosters.MAX_CARRIED)
	stars.clear()
	var saved: Variant = data.get("stars", {})
	if saved is Dictionary:
		for id in saved:
			if cleared.has(String(id)):
				stars[String(id)] = clampi(int(saved[id]), 1, 3)


func save(path := SAVE_FILE) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(to_dict()))


## Loads progress saved at `path`, if any. A missing or broken file starts a new journey.
func load_progress(path := SAVE_FILE) -> void:
	if not FileAccess.file_exists(path):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
		apply_dict(json.data)
