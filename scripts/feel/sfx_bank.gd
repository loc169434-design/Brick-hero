class_name SfxBank
extends RefCounted
## Sound effects made in code, so the game has sound before real recordings arrive.
## Each recipe is a few layers mixed into one 16-bit mono AudioStreamWAV: tones that glide
## from one pitch to another, and noise bursts. A file at assets/audio/<name>.wav or .ogg
## takes the place of the recipe with the same name (see Sfx).

const MIX_RATE := 22050
## Fade-in at the start of every layer, so nothing clicks.
const ATTACK := 0.004

## name -> layers. A layer is { "wave": sine|square|triangle|noise, "from", "to" (Hz, glides
## between them), "start" and "length" (seconds), "volume" (0..1) }. Noise ignores pitch and
## takes "smooth" (0..1) instead: higher is duller.
const RECIPES := {
	# Each square added to the link; played higher as the link grows.
	"tick": [{"wave": "sine", "from": 660.0, "to": 720.0, "length": 0.07, "volume": 0.5}],
	"untick": [{"wave": "sine", "from": 520.0, "to": 400.0, "length": 0.07, "volume": 0.35}],
	# The link just got long enough to leave a special.
	"charge": [
		{"wave": "triangle", "from": 1320.0, "to": 1320.0, "length": 0.12, "volume": 0.35},
		{"wave": "triangle", "from": 1760.0, "to": 1760.0, "start": 0.06, "length": 0.18, "volume": 0.35},
	],
	# A round of squares bursting.
	"pop": [
		{"wave": "noise", "length": 0.05, "volume": 0.35, "smooth": 0.4},
		{"wave": "sine", "from": 620.0, "to": 260.0, "length": 0.12, "volume": 0.55},
	],
	"land": [{"wave": "sine", "from": 170.0, "to": 110.0, "length": 0.06, "volume": 0.3}],
	# A lightning or bomb going off.
	"boom": [
		{"wave": "noise", "length": 0.4, "volume": 0.7, "smooth": 0.8},
		{"wave": "sine", "from": 140.0, "to": 38.0, "length": 0.35, "volume": 0.7},
	],
	# A praise word slamming in over the board (BoardJuice): a bright rising arpeggio.
	"praise": [
		{"wave": "triangle", "from": 784.0, "to": 784.0, "length": 0.09, "volume": 0.35},
		{"wave": "triangle", "from": 988.0, "to": 988.0, "start": 0.07, "length": 0.09, "volume": 0.35},
		{"wave": "triangle", "from": 1175.0, "to": 1175.0, "start": 0.14, "length": 0.09, "volume": 0.35},
		{"wave": "sine", "from": 1568.0, "to": 1568.0, "start": 0.21, "length": 0.3, "volume": 0.4},
	],
	# A storm's thunder rolling after the flash (ArenaWeather).
	"thunder": [
		{"wave": "noise", "length": 0.25, "volume": 0.6, "smooth": 0.5},
		{"wave": "noise", "start": 0.1, "length": 1.4, "volume": 0.55, "smooth": 0.93},
		{"wave": "sine", "from": 70.0, "to": 34.0, "start": 0.05, "length": 1.1, "volume": 0.45},
	],
	"special": [
		{"wave": "triangle", "from": 880.0, "to": 880.0, "length": 0.1, "volume": 0.3},
		{"wave": "triangle", "from": 1108.0, "to": 1108.0, "start": 0.05, "length": 0.1, "volume": 0.3},
		{"wave": "triangle", "from": 1320.0, "to": 1320.0, "start": 0.1, "length": 0.22, "volume": 0.3},
	],
	"shuffle": [{"wave": "noise", "length": 0.3, "volume": 0.3, "smooth": 0.6}],
	# The hero's blow landing.
	"hit": [
		{"wave": "noise", "length": 0.08, "volume": 0.6, "smooth": 0.3},
		{"wave": "square", "from": 220.0, "to": 70.0, "length": 0.14, "volume": 0.35},
	],
	# Purple chipping the shield, and a whole layer giving way.
	"clang": [
		{"wave": "triangle", "from": 1250.0, "to": 1180.0, "length": 0.28, "volume": 0.3},
		{"wave": "triangle", "from": 1870.0, "to": 1800.0, "length": 0.22, "volume": 0.2},
		{"wave": "noise", "length": 0.03, "volume": 0.3, "smooth": 0.1},
	],
	"shatter": [
		{"wave": "noise", "length": 0.3, "volume": 0.6, "smooth": 0.15},
		{"wave": "square", "from": 320.0, "to": 60.0, "length": 0.25, "volume": 0.3},
	],
	"heal": [
		{"wave": "sine", "from": 660.0, "to": 660.0, "length": 0.15, "volume": 0.3},
		{"wave": "sine", "from": 880.0, "to": 880.0, "start": 0.06, "length": 0.15, "volume": 0.3},
		{"wave": "sine", "from": 1100.0, "to": 1100.0, "start": 0.12, "length": 0.2, "volume": 0.3},
	],
	"coin": [
		{"wave": "square", "from": 988.0, "to": 988.0, "length": 0.06, "volume": 0.2},
		{"wave": "square", "from": 1318.0, "to": 1318.0, "start": 0.06, "length": 0.18, "volume": 0.2},
	],
	# The monster's blow landing on the hero.
	"thud": [
		{"wave": "sine", "from": 110.0, "to": 40.0, "length": 0.3, "volume": 0.8},
		{"wave": "noise", "length": 0.1, "volume": 0.45, "smooth": 0.7},
	],
	# The monster attacks next move.
	"warn": [
		{"wave": "square", "from": 440.0, "to": 440.0, "length": 0.08, "volume": 0.2},
		{"wave": "square", "from": 440.0, "to": 440.0, "start": 0.14, "length": 0.08, "volume": 0.2},
	],
	"win": [
		{"wave": "triangle", "from": 523.0, "to": 523.0, "length": 0.18, "volume": 0.35},
		{"wave": "triangle", "from": 659.0, "to": 659.0, "start": 0.12, "length": 0.18, "volume": 0.35},
		{"wave": "triangle", "from": 784.0, "to": 784.0, "start": 0.24, "length": 0.18, "volume": 0.35},
		{"wave": "triangle", "from": 1047.0, "to": 1047.0, "start": 0.36, "length": 0.5, "volume": 0.4},
	],
	"lose": [
		{"wave": "triangle", "from": 392.0, "to": 380.0, "length": 0.3, "volume": 0.35},
		{"wave": "triangle", "from": 311.0, "to": 300.0, "start": 0.28, "length": 0.3, "volume": 0.35},
		{"wave": "triangle", "from": 262.0, "to": 196.0, "start": 0.56, "length": 0.7, "volume": 0.35},
	],
	# Something thrown or swung through the air: a sword, a rock, a dodge.
	"whoosh": [
		{"wave": "noise", "length": 0.22, "volume": 0.4, "smooth": 0.55},
		{"wave": "sine", "from": 300.0, "to": 520.0, "length": 0.2, "volume": 0.15},
	],
	# A critical hit winding up, then landing.
	"crit_charge": [
		{"wave": "triangle", "from": 220.0, "to": 880.0, "length": 0.4, "volume": 0.3},
		{"wave": "noise", "length": 0.4, "volume": 0.15, "smooth": 0.3},
	],
	"crit": [
		{"wave": "noise", "length": 0.12, "volume": 0.8, "smooth": 0.1},
		{"wave": "square", "from": 900.0, "to": 90.0, "length": 0.4, "volume": 0.35},
		{"wave": "sine", "from": 120.0, "to": 35.0, "length": 0.5, "volume": 0.8},
	],
	# The monster dodges and laughs at you.
	"taunt": [
		{"wave": "square", "from": 300.0, "to": 380.0, "length": 0.08, "volume": 0.25},
		{"wave": "square", "from": 300.0, "to": 380.0, "start": 0.12, "length": 0.08, "volume": 0.25},
	],
}


static func names() -> Array:
	return RECIPES.keys()


## The recipe mixed down, or null if there's no recipe called `name`.
static func build(name: String) -> AudioStreamWAV:
	if not RECIPES.has(name):
		return null
	var layers: Array = RECIPES[name]
	var seconds := 0.0
	for layer: Dictionary in layers:
		seconds = maxf(seconds, layer.get("start", 0.0) + layer["length"])
	var mix := PackedFloat32Array()
	mix.resize(ceili(seconds * MIX_RATE))
	# Fixed seed: the same sound every time, and the same bytes on every run.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	for layer: Dictionary in layers:
		_add_layer(mix, layer, rng)

	var data := PackedByteArray()
	data.resize(mix.size() * 2)
	for i in mix.size():
		data.encode_s16(i * 2, roundi(clampf(mix[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


static func _add_layer(mix: PackedFloat32Array, layer: Dictionary, rng: RandomNumberGenerator) -> void:
	var wave: String = layer["wave"]
	var length: float = layer["length"]
	var volume: float = layer.get("volume", 0.5)
	var from: float = layer.get("from", 440.0)
	var to: float = layer.get("to", from)
	var smooth: float = layer.get("smooth", 0.0)
	var first := roundi(layer.get("start", 0.0) * MIX_RATE)
	var count := mini(roundi(length * MIX_RATE), mix.size() - first)
	var phase := 0.0
	var noise := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var progress := t / length
		# Quick fade-in, then a decay that falls away fast like a struck object.
		var envelope := minf(t / ATTACK, 1.0) * pow(1.0 - progress, 2.0)
		var sample := 0.0
		if wave == "noise":
			noise = lerpf(rng.randf_range(-1.0, 1.0), noise, smooth)
			sample = noise
		else:
			# Exponential glide sounds even to the ear, unlike a straight line in Hz.
			phase += from * pow(to / from, progress) / MIX_RATE
			var cycle := fmod(phase, 1.0)
			match wave:
				"square":
					sample = 0.6 if cycle < 0.5 else -0.6
				"triangle":
					sample = 4.0 * absf(cycle - 0.5) - 1.0
				_:
					sample = sin(cycle * TAU)
		mix[first + i] += sample * volume * envelope
