class_name ClearStep
extends RefCounted
## One round of a chain: what cleared, why, what got created, and how the rest fell.
## The battle reads the counts; the board view replays it as animation.

## 1 for the link itself, 2 for the first line it set off, and so on.
var chain := 0
## Every position cleared this round.
var cleared: Array[Vector2i] = []
## The cells that stood at `cleared`, in the same order.
var cleared_cells: Array[Cell] = []
## The link or lines that cleared: { "color": int, "cells": Array[Vector2i] }
var clusters: Array[Dictionary] = []
## Specials that went off, including ones set off by other specials.
var triggered: Array[Vector2i] = []
## { "at": Vector2i, "with": Vector2i, "kinds": [Cell.Special, Cell.Special] }
var fusions: Array[Dictionary] = []
## { "at": Vector2i, "special": Cell.Special, "color": int }
var spawned: Array[Dictionary] = []
## Crates and rocks that lost a layer and still stand: { "at": Vector2i, "layers": int left }.
var hit: Array[Dictionary] = []
## Crates and rocks that broke this round (also in `cleared`): { "at": Vector2i, "kind": String }.
## Ice melted all the way and webs torn away are here too, with kind "ice" or "web"; their
## tile stays.
var broken: Array[Dictionary] = []
## Items that reached the bottom row and were taken off (also in `cleared`):
## { "at": Vector2i, "kind": String }. A round of rescues only, with no tiles, keeps the chain
## number of the round before it.
var rescued: Array[Dictionary] = []
## Iced tiles that lost a layer and stayed: { "at": Vector2i, "ice": int left }.
var thawed: Array[Dictionary] = []
## { "from": Vector2i, "to": Vector2i }, plus "cell" for a new square dropped in from above
## (its "from" is above the board).
var falls: Array[Dictionary] = []


func is_empty() -> bool:
	return cleared.is_empty()


## Cleared squares per Cell.BlockColor. Stars have no color and aren't counted.
func count_by_color() -> Dictionary:
	var counts := {}
	for cell in cleared_cells:
		if cell.color != Cell.NO_COLOR:
			counts[cell.color] = counts.get(cell.color, 0) + 1
	return counts
