class_name IsoWorld
extends Node2D
## Owns the visual world: a non-sorted GroundLayer of LandTiles (drawn first) and a
## y-sorted EntityLayer holding structures + NPCs. Builds itself from GameState data
## and exposes confirm_* methods the PlacementController calls to commit actions.

signal structure_clicked(structure: Structure)

var ground_layer: Node2D
var entity_layer: Node2D

func _ready() -> void:
	ground_layer = Node2D.new()
	ground_layer.name = "GroundLayer"
	add_child(ground_layer)

	entity_layer = Node2D.new()
	entity_layer.name = "EntityLayer"
	entity_layer.y_sort_enabled = true
	add_child(entity_layer)

	build_ground()
	build_structures()
	_spawn_initial_npcs()

# --- Building from state ----------------------------------------------------

func build_ground() -> void:
	for c in ground_layer.get_children():
		c.queue_free()
	# Back-to-front so front tiles' grass tops cover the side faces behind them.
	var cells := GameState.owned_cells.keys()
	cells.sort_custom(func(a, b): return (a.x + a.y) < (b.x + b.y))
	for cell in cells:
		var tile := LandTile.new()
		ground_layer.add_child(tile)
		tile.setup(cell)

func build_structures() -> void:
	for c in entity_layer.get_children():
		if c is Structure:
			c.queue_free()
	for s in GameState.structures:
		_add_structure_node(s["type"], s["cell"])

func _add_structure_node(type: String, cell: Vector2i) -> Structure:
	var st := Structure.new()
	entity_layer.add_child(st)
	st.setup(type, cell, false)
	st.clicked.connect(_on_structure_clicked)
	return st

func _spawn_initial_npcs() -> void:
	# One starter farmer.
	_spawn_villager(GameState.first_free_cell())
	# NPCs implied by already-placed houses/stables.
	for s in GameState.structures:
		var def: Dictionary = Catalog.get_structure(s["type"])
		match def.get("spawns", ""):
			"villager": _spawn_villager(s["cell"])
			"animal": _spawn_animal(s["cell"])

func _spawn_villager(cell: Vector2i) -> void:
	var v := Villager.new()
	entity_layer.add_child(v)
	v.spawn_at(cell)

func _spawn_animal(cell: Vector2i) -> void:
	var a := Animal.new()
	entity_layer.add_child(a)
	a.spawn_at(cell)

# --- Commits (called by PlacementController) --------------------------------

func confirm_structure(type: String, cell: Vector2i) -> bool:
	if not GameState.place_structure(type, cell):
		return false
	_add_structure_node(type, cell)
	var def: Dictionary = Catalog.get_structure(type)
	match def.get("spawns", ""):
		"villager": _spawn_villager(cell)
		"animal": _spawn_animal(cell)
	return true

func confirm_move(struct: Structure, to_cell: Vector2i) -> bool:
	var from := struct.cell
	if not GameState.move_structure(from, to_cell):
		return false
	struct.move_to_cell(to_cell)
	return true

func confirm_land(origin: Vector2i) -> bool:
	if not GameState.add_land_block(origin):
		return false
	build_ground()
	return true

func _on_structure_clicked(struct: Structure) -> void:
	structure_clicked.emit(struct)
