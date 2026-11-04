class_name Campaign
extends RefCounted
## The journey from the castle to the dragon's cave: the stops on the world map in order,
## which ones are cleared, and the gold the hero carries between fights. Pure rules, no Node.
##
## Stops come from assets/bg/world_map.json, bottom to top. Each stop is a fight against the
## monster with the same id; a stop whose monster has no data in data/monsters/ yet is shown
## as coming soon. The next stop opens when every stop before it is cleared, and cleared
## stops can be fought again for gold.

enum Stop { LOCKED, OPEN, DONE, SOON }

const MAP_FILE := "res://assets/bg/world_map.json"
const MONSTER_DIR := "res://data/monsters/"
const SAVE_FILE := "user://campaign.json"

## [{id, position}], bottom to top, position on the 1080×1920 map.
var stops: Array[Dictionary] = []
var cleared: Array[String] = []
var gold := 0


static func from_map(path := MAP_FILE) -> Campaign:
	var campaign := Campaign.new()
	if ResourceLoader.exists(path):
		var json: JSON = load(path)
		if json.data is Array:
			for stop: Dictionary in json.data:
				campaign.stops.append({"id": String(stop["id"]), "position": Vector2(stop["x"], stop["y"])})
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
	return Stop.OPEN if has_monster(id) else Stop.SOON


## Where the hero stands on the map: the next stop, or the last one when all are cleared.
func hero_index() -> int:
	var i := next_index()
	return i if i >= 0 else stops.size() - 1


static func has_monster(id: String) -> bool:
	return ResourceLoader.exists(MONSTER_DIR + id + ".tres")


static func monster(id: String) -> MonsterData:
	return load(MONSTER_DIR + id + ".tres") if has_monster(id) else null


## A fight at `id` ended. Winning clears the stop and the hero keeps `gold_after`, the purse
## at the end of the fight; losing keeps the purse from before it. Returns whether this win
## cleared the stop for the first time.
func finish_fight(id: String, won: bool, gold_after: int) -> bool:
	if not won:
		return false
	gold = maxi(gold_after, 0)
	if is_cleared(id):
		return false
	cleared.append(id)
	return true


func to_dict() -> Dictionary:
	return {"cleared": cleared.duplicate(), "gold": gold}


func apply_dict(data: Dictionary) -> void:
	cleared.clear()
	for id in data.get("cleared", []):
		if index_of(String(id)) >= 0 and not cleared.has(String(id)):
			cleared.append(String(id))
	gold = maxi(int(data.get("gold", 0)), 0)


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
