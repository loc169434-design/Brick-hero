class_name Weather
extends RefCounted
## The hour and the sky of a fight (docs/weather_plan.md). Each fight gets one hour and one
## kind of weather, drawn when it starts from what its level allows, or else from what its
## region allows. For now they only change the look of the arena; the buffs of the plan come
## once the balance bot has measured them.

const HOURS: Array[StringName] = [&"morning", &"noon", &"dusk", &"night"]
const SKIES: Array[StringName] = [&"clear", &"rain", &"storm", &"fog"]
const DEFAULT_HOUR := &"noon"
const DEFAULT_SKY := &"clear"

## What each arena backdrop can bring, by MonsterData.background (plan section 2). A kind
## listed twice is twice as likely.
const REGIONS := {
	"training_field": {"hours": ["morning", "noon"], "skies": ["clear"]},
	"orc_camp": {"hours": ["morning", "noon", "dusk"], "skies": ["clear", "clear", "clear", "rain"]},
	"goblin_camp": {"hours": ["morning", "noon", "dusk", "night"], "skies": ["clear", "clear", "rain", "fog"]},
	"swamp": {"hours": ["dusk", "night"], "skies": ["clear", "rain", "rain", "storm"]},
}

## Names on the HUD, by hour or sky.
const NAMES := {
	&"morning": "Sáng", &"noon": "Trưa", &"dusk": "Chiều", &"night": "Tối",
	&"clear": "Quang", &"rain": "Mưa", &"storm": "Giông", &"fog": "Sương mù",
}


## [hour, sky] for a fight in front of `background`. `hours` and `skies` from the level take
## the place of the region's when set; unknown names are skipped.
static func pick(background: String, rng: RandomNumberGenerator, hours := PackedStringArray(), skies := PackedStringArray()) -> Array[StringName]:
	var region: Dictionary = REGIONS.get(background, {})
	var hour := _draw(hours if not hours.is_empty() else PackedStringArray(region.get("hours", [])), HOURS, DEFAULT_HOUR, rng)
	var sky := _draw(skies if not skies.is_empty() else PackedStringArray(region.get("skies", [])), SKIES, DEFAULT_SKY, rng)
	return [hour, sky]


static func is_wet(sky: StringName) -> bool:
	return sky == &"rain" or sky == &"storm"


static func _draw(choices: PackedStringArray, known: Array[StringName], fallback: StringName, rng: RandomNumberGenerator) -> StringName:
	var valid: Array[StringName] = []
	for choice in choices:
		if StringName(choice) in known:
			valid.append(StringName(choice))
	if valid.is_empty():
		return fallback
	return valid[rng.randi_range(0, valid.size() - 1)]
