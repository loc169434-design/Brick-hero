class_name Boosters
extends RefCounted
## Help the hero carries into fights: bought at the forge with gold and now and then won. Each
## is used up when used and none costs a move. Pure rules, no Node.
##
## hammer: smashes one square (a tile, or a layer off an obstacle; a special goes off).
## shuffle: deals the tiles again, keeping the specials.
## potion: POTION_HEAL health back.
## opening_bombs: before the first move only, a bomb and a lightning appear on the board.
## Prices and drop chances are proposals, to be checked when playing.

const ORDER := ["hammer", "shuffle", "potion", "opening_bombs"]
const ITEMS := {
	"hammer": {"name": "Búa", "price": 25},
	"shuffle": {"name": "Xáo bảng", "price": 15},
	"potion": {"name": "Bình máu", "price": 30},
	"opening_bombs": {"name": "Bom mở màn", "price": 40},
}
const POTION_HEAL := 30
## No more than this many of one booster in the bag.
const MAX_CARRIED := 9
## Each one's uses in a single fight.
const PER_FIGHT := 3
## A first clear of a boss or hard level always drops one; a three-star win sometimes does.
const STAR_DROP_CHANCE := 0.3


static func is_known(id: String) -> bool:
	return ITEMS.has(id)


## What winning drops, or "" for nothing: a booster for a first clear of a boss or hard stop,
## a chance of one for three stars.
static func reward(first_clear: bool, special_stop: bool, star_count: int, rng: RandomNumberGenerator) -> String:
	if (first_clear and special_stop) or (star_count >= 3 and rng.randf() < STAR_DROP_CHANCE):
		return ORDER[rng.randi_range(0, ORDER.size() - 1)]
	return ""
