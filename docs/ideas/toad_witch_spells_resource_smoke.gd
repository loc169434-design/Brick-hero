extends SceneTree
## Resource validation only; curse state machine and combat rules belong to Claude.
var failures: Array[String] = []
var actor_clips := 0
var broom_variants := 0
var effects := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for id in ["toad_witch","toad_witch_giant","hero_toad"]:
		var rig := CharacterRig.new()
		root.add_child(rig)
		rig.setup(id,1 if id=="hero_toad" else -1)
		var meta: JSON = load("res://assets/characters/%s/anim/anim.json" % id)
		if meta == null:
			failures.append(id+" metadata")
			rig.free()
			continue
		for clip: String in meta.data.clips:
			var m: Dictionary = meta.data.clips[clip]
			for wear in 3:
				rig.wear=wear
				if not rig.has_clip(StringName(clip)):failures.append(id+"/"+clip+" fallback")
				rig._start_clip(StringName(clip))
				if rig._clip_sheet == null:failures.append(id+"/"+clip+" texture")
				if absf(rig.clip_seconds(StringName(clip))-float(m.frames)/float(m.fps))>.001:failures.append(id+"/"+clip+" timing")
			actor_clips+=1
		rig.free()
	var broom: JSON = load("res://assets/characters/hero_rookie/anim/broom/anim.json")
	if broom == null:
		failures.append("broom metadata")
	else:
		for clip: String in broom.data.clips:
			var m: Dictionary = broom.data.clips[clip]
			var wears: Array = ["fresh"] if clip in broom.data.fresh_only else broom.data.wears
			for wear: String in wears:
				var path := "res://assets/characters/hero_rookie/anim/broom/%s_%s.png" % [wear,clip]
				var texture: Texture2D = load(path)
				if texture == null or texture.get_width()!=2048 or texture.get_height()!=512*ceili(float(m.frames)/4):failures.append(path)
				broom_variants+=1
	var fx: JSON = load("res://assets/fx/curse/anim.json")
	for name: String in fx.data:
		if load("res://assets/fx/curse/"+name+".png")==null:failures.append(name)
		effects+=1
	for name in ["potion_bottle","potion_bottle_idle","potion_break","potion_burst"]:
		if load("res://assets/board/obstacles/"+name+".png")==null:failures.append(name)
	for name in ["toad","broom","poison"]:
		var texture: Texture2D = load("res://assets/ui/status/"+name+".png")
		if texture==null or texture.get_width()!=128:failures.append(name+" status icon")
	print("Toad witch spells smoke: %d actor clips with 3 wear fallbacks, %d broom variants, %d FX atlases, 4 potion textures, 3 status icons; %d failures" % [actor_clips,broom_variants,effects,failures.size()])
	for failure in failures:printerr(failure)
	quit(0 if failures.is_empty() else 1)
