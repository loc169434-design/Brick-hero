class_name ClearStep
extends RefCounted
## One round of a chain: what cleared, why, what got created, and how the rest fell.
## The battle reads the counts; the board view replays it as animation.

## 1 for the round set off by the drop itself, 2 for the next, and so on.
var chain := 0
## Every position cleared this round.
var cleared: Array[Vector2i] = []
## The cells that stood at `cleared`, in the same order.
var cleared_cells: Array[Cell] = []
var full_rows: Array[int] = []
## { "color": int, "cells": Array[Vector2i] }
var clusters: Array[Dictionary] = []
## Specials that went off, including ones set off by other specials.
var triggered: Array[Vector2i] = []
## { "at": Vector2i, "with": Vector2i, "kinds": [Cell.Special, Cell.Special] }
var fusions: Array[Dictionary] = []
## { "at": Vector2i, "special": Cell.Special, "color": int }
var spawned: Array[Dictionary] = []
## { "from": Vector2i, "to": Vector2i }
var falls: Array[Dictionary] = []


func is_empty() -> bool:
	return cleared.is_empty()


## Cleared squares per Cell.BlockColor. Rainbows have no color and aren't counted.
func count_by_color() -> Dictionary:
	var counts := {}
	for cell in cleared_cells:
		if cell.color != Cell.NO_COLOR:
			counts[cell.color] = counts.get(cell.color, 0) + 1
	return counts
