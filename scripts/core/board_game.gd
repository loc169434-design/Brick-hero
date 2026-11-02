class_name BoardGame
extends RefCounted
## One board in play: the piece in hand, hold, preview queue and combo counter.
## Pieces don't fall on their own. The piece hovers at the top while the player
## moves and turns it, then drops it.

signal piece_changed
signal dropped(result: DropResult)
signal topped_out

## Sideways nudges tried, in order, when a turn would hit a wall or another square.
const KICKS := [0, -1, 1, -2, 2]

var rules: BoardRules
var board: BoardModel
var bag: PieceBag
var current: Piece
var origin := Vector2i.ZERO
var held: Piece
## Consecutive drops that cleared something.
var combo := 0
var is_over := false

var _can_hold := true


## A negative seed picks a random one.
func _init(p_rules: BoardRules = null, seed_value: int = -1) -> void:
	rules = p_rules if p_rules else BoardRules.new()
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	board = BoardModel.new(rules.columns, rules.rows)
	bag = PieceBag.new(rules, rng)


func start() -> void:
	_spawn(bag.next())


func move(dx: int) -> bool:
	if is_over:
		return false
	var to := origin + Vector2i(dx, 0)
	if not board.can_place(current, to):
		return false
	origin = to
	piece_changed.emit()
	return true


func rotate(clockwise := true) -> bool:
	if is_over:
		return false
	var turned := current.rotated(clockwise)
	var y := -turned.bounds().position.y
	for dx in KICKS:
		var at := Vector2i(origin.x + dx, y)
		if board.can_place(turned, at):
			current = turned
			origin = at
			piece_changed.emit()
			return true
	return false


## Swaps the piece in hand with the held one. Allowed once per drop.
func hold() -> bool:
	if is_over or not _can_hold:
		return false
	var swap := held
	held = current
	_can_hold = false
	_spawn(swap if swap else bag.next())
	return true


func landing_origin() -> Vector2i:
	return board.landing(current, origin)


func drop() -> DropResult:
	if is_over:
		return null
	var result := DropResult.new()
	result.placed = board.lock(current, landing_origin())
	result.steps = Resolver.resolve(board, rules, result.placed)
	combo = combo + 1 if result.cleared_anything() else 0
	result.combo = combo
	_can_hold = true
	dropped.emit(result)
	_spawn(bag.next())
	return result


## Centered, with the piece's top row against the top edge.
func spawn_origin(piece: Piece) -> Vector2i:
	var b := piece.bounds()
	return Vector2i(floori((board.columns - b.size.x) / 2.0) - b.position.x, -b.position.y)


func _spawn(piece: Piece) -> void:
	current = piece
	origin = spawn_origin(piece)
	if not board.can_place(current, origin):
		is_over = true
		topped_out.emit()
	piece_changed.emit()
