class_name Sfx
extends Node
## Plays sound effects from anywhere: Sfx.play(&"tick", 1.5). The first call adds one Sfx node
## to the scene tree to hold the players, so nothing needs setting up (and scripts run with -s,
## which skip autoloads, still work).
## A recording at assets/audio/<name>.wav or .ogg wins over the made-up sound in SfxBank,
## so real sounds can drop in without code changes. M (see BoardInput) mutes.

const AUDIO_DIR := "res://assets/audio/"
## Sounds that can overlap; the oldest is cut off when more play at once.
const VOICES := 12

static var muted := false
static var _instance: Sfx

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _init() -> void:
	name = "Sfx"
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


## `pitch` 2.0 is an octave up. A touch of random detune keeps repeats from sounding canned,
## unless `exact` (the rising notes of a link must stay in tune).
static func play(sound: StringName, pitch := 1.0, volume_db := 0.0, exact := false) -> void:
	if muted:
		return
	if not is_instance_valid(_instance):
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			return
		_instance = Sfx.new()
		# Deferred: the first sound may come while the tree is still setting up its nodes.
		tree.root.add_child.call_deferred(_instance)
	_instance._play(sound, pitch if exact else pitch * randf_range(0.96, 1.04), volume_db)


## `retry`: a sound asked for before the node is in the tree waits one frame for it, once.
func _play(sound: StringName, pitch: float, volume_db: float, retry := true) -> void:
	var stream := _stream(sound)
	if stream == null:
		return
	if not is_inside_tree():
		if retry:
			_play.call_deferred(sound, pitch, volume_db, false)
		return
	var player := _players[_next]
	_next = (_next + 1) % VOICES
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func _stream(sound: StringName) -> AudioStream:
	if not _streams.has(sound):
		_streams[sound] = null
		for ext in ["wav", "ogg"]:
			var path := "%s%s.%s" % [AUDIO_DIR, sound, ext]
			if ResourceLoader.exists(path):
				_streams[sound] = load(path)
				break
		if _streams[sound] == null:
			_streams[sound] = SfxBank.build(sound)
	return _streams[sound]
