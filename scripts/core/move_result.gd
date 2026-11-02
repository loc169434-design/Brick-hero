class_name MoveResult
extends RefCounted
## Everything one move caused: the link the player traced and every round it set off.

var path: Array[Vector2i] = []
var steps: Array[ClearStep] = []
## True if no link was left afterwards and the board was dealt again.
var reshuffled := false


func chain_length() -> int:
	return steps.size()


func total_cleared() -> int:
	var total := 0
	for step in steps:
		total += step.cleared.size()
	return total
