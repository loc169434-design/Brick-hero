class_name DropResult
extends RefCounted
## Everything one drop caused, from the squares it landed on to the end of its chain.

var placed: Array[Vector2i] = []
var steps: Array[ClearStep] = []
## Consecutive drops that cleared something, this one included; 0 if it cleared nothing.
var combo := 0


func cleared_anything() -> bool:
	return not steps.is_empty()


func chain_length() -> int:
	return steps.size()


func total_cleared() -> int:
	var total := 0
	for step in steps:
		total += step.cleared.size()
	return total
