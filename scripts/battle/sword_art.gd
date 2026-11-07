class_name SwordArt
## The hero's swords drawn in his hand: the forge's icons (assets/ui/items/<sword>.png, 256
## canvas) held by the middle of the handle, blade up, all the same length.

## How each icon is held: "grip", the middle of its handle, goes in the fist; "turn" (degrees)
## stands its blade straight up (the wooden one is drawn slanting); "size" evens out their
## lengths (the slanting one spans more of its canvas). Measured along each icon's long axis,
## between the guard and the pommel. A sword not listed is held as HOLD.
const HOLDS := {
	"wood_sword": {"grip": Vector2(68, 197), "turn": -40.9, "size": 0.77},
	"iron_sword": {"grip": Vector2(127, 200), "turn": -0.2, "size": 1.0},
	"tempered_sword": {"grip": Vector2(128, 203), "turn": -0.3, "size": 1.0},
}
const HOLD := {"grip": Vector2(128, 200), "turn": 0.0, "size": 1.0}
## A straight sword's length held, in canvas pixels (512 canvas) per 256 of icon.
const SIZE := 210.0

static var _icons := {}


static func hold(id: String) -> Dictionary:
	return HOLDS.get(id, HOLD)


static func icon(id: String) -> Texture2D:
	if not _icons.has(id):
		var path := "res://assets/ui/items/%s.png" % id
		_icons[id] = load(path) if ResourceLoader.exists(path) else null
	return _icons[id]


## Draws sword `id` on `canvas` with its grip at `at`, its blade turned `angle` radians from
## straight up (clockwise), `scale` screen pixels per canvas pixel.
static func draw(canvas: CanvasItem, id: String, at: Vector2, angle: float, scale: float) -> void:
	var texture := icon(id)
	if texture == null:
		return
	var h := hold(id)
	canvas.draw_set_transform(at, angle + deg_to_rad(h["turn"]), Vector2.ONE * scale * SIZE / 256.0 * h["size"])
	canvas.draw_texture(texture, -h["grip"])
	canvas.draw_set_transform(Vector2.ZERO)
