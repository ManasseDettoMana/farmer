extends Node
## Authoritative game data + idle economy. Autoloaded as `GameState`.
##
## Holds points, owned land cells, and placed-structure records (pure data — the
## visual nodes are created by IsoWorld from this data). Persists to user://save.json.

signal points_changed(points: float, per_second: float)
signal economy_changed()   # structures/land changed: rebuild visuals + income

const SAVE_PATH := "user://save.json"

var points: float = 0.0
var click_value: float = 1.0
var points_per_second: float = 0.0
var blocks_owned: int = 1

var owned_cells: Dictionary = {}      # Vector2i -> true
var structures: Array = []            # [{ "type": String, "cell": Vector2i }]

var _occupied: Dictionary = {}        # Vector2i -> true (derived from structures)
var _emit_accum: float = 0.0

func _ready() -> void:
	if not load_game():
		_seed_new_game()
	recompute_income()

func _process(delta: float) -> void:
	if points_per_second > 0.0:
		points += points_per_second * delta
	# Throttle the points signal to ~10 Hz so the HUD updates smoothly but cheaply.
	_emit_accum += delta
	if _emit_accum >= 0.1:
		_emit_accum = 0.0
		points_changed.emit(points, points_per_second)

# --- Setup ------------------------------------------------------------------

func _seed_new_game() -> void:
	owned_cells.clear()
	structures.clear()
	blocks_owned = 1
	points = 0.0
	for x in range(Catalog.LAND_BLOCK_SIZE):
		for y in range(Catalog.LAND_BLOCK_SIZE):
			owned_cells[Vector2i(x, y)] = true
	_rebuild_occupied()

func _rebuild_occupied() -> void:
	_occupied.clear()
	for s in structures:
		_occupied[s["cell"]] = true

# --- Queries ----------------------------------------------------------------

func is_land_owned(cell: Vector2i) -> bool:
	return owned_cells.has(cell)

func is_cell_free(cell: Vector2i) -> bool:
	return owned_cells.has(cell) and not _occupied.has(cell)

func can_afford(cost: int) -> bool:
	return points >= float(cost)

func first_free_cell() -> Vector2i:
	var cells := owned_cells.keys()
	cells.sort_custom(func(a, b): return (a.x + a.y) < (b.x + b.y) or (a.x + a.y == b.x + b.y and a.x < b.x))
	for c in cells:
		if not _occupied.has(c):
			return c
	return cells[0] if cells.size() > 0 else Vector2i.ZERO

func next_land_block_cost() -> int:
	return Catalog.land_block_cost(blocks_owned + 1)

# --- Mutations --------------------------------------------------------------

func recompute_income() -> void:
	var total := 0.0
	for s in structures:
		var def: Dictionary = Catalog.get_structure(s["type"])
		total += float(def.get("income", 0.0))
	points_per_second = total
	points_changed.emit(points, points_per_second)

func add_click_points() -> float:
	points += click_value
	points_changed.emit(points, points_per_second)
	return click_value

## Spend points for a structure and record it. Returns true on success.
func place_structure(type: String, cell: Vector2i) -> bool:
	var def: Dictionary = Catalog.get_structure(type)
	if def.is_empty() or not is_cell_free(cell) or not can_afford(int(def["cost"])):
		return false
	points -= float(def["cost"])
	structures.append({ "type": type, "cell": cell })
	_occupied[cell] = true
	recompute_income()
	economy_changed.emit()
	save_game()
	return true

## Move an already-placed structure to a new free cell (no cost).
func move_structure(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if not is_cell_free(to_cell):
		return false
	for s in structures:
		if s["cell"] == from_cell:
			_occupied.erase(from_cell)
			s["cell"] = to_cell
			_occupied[to_cell] = true
			economy_changed.emit()
			save_game()
			return true
	return false

## Buy a 4x4 land block whose top corner is `origin`. Caller validates placement.
func add_land_block(origin: Vector2i) -> bool:
	var cost := next_land_block_cost()
	if not can_afford(cost):
		return false
	points -= float(cost)
	blocks_owned += 1
	for x in range(Catalog.LAND_BLOCK_SIZE):
		for y in range(Catalog.LAND_BLOCK_SIZE):
			owned_cells[origin + Vector2i(x, y)] = true
	economy_changed.emit()
	save_game()
	return true

# --- Persistence ------------------------------------------------------------

func save_game() -> void:
	var data := {
		"points": points,
		"blocks_owned": blocks_owned,
		"owned_cells": owned_cells.keys().map(func(c): return [c.x, c.y]),
		"structures": structures.map(func(s): return { "type": s["type"], "cell": [s["cell"].x, s["cell"].y] }),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	points = float(data.get("points", 0.0))
	blocks_owned = int(data.get("blocks_owned", 1))
	owned_cells.clear()
	for c in data.get("owned_cells", []):
		owned_cells[Vector2i(int(c[0]), int(c[1]))] = true
	structures.clear()
	for s in data.get("structures", []):
		var cell = s["cell"]
		structures.append({ "type": String(s["type"]), "cell": Vector2i(int(cell[0]), int(cell[1])) })
	if owned_cells.is_empty():
		_seed_new_game()
	_rebuild_occupied()
	return true

func reset_game() -> void:
	_seed_new_game()
	recompute_income()
	economy_changed.emit()
	save_game()
