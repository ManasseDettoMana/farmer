class_name PlacementController
extends Node
## Drives Clash-of-Clans-style placement for three flows that share one ghost UI:
##   - buying a structure   (snap to one free owned cell)
##   - moving a structure   (no cost; snap to a free cell)
##   - buying a 4x4 land block (snap a block adjacent to existing land)
## A floating green check / red cross follows the ghost to confirm or cancel.

signal finished()

enum Mode { NONE, BUY_STRUCTURE, MOVE_STRUCTURE, BUY_LAND }

var world: IsoWorld
var camera: Camera2D

var _mode: int = Mode.NONE
var _type: String = ""
var _ghost: Structure = null
var _move_target: Structure = null
var _land_preview: Node2D = null
var _land_origin: Vector2i = Vector2i.ZERO
var _cur_cell: Vector2i = Vector2i.ZERO
var _valid: bool = false
var _dragging: bool = false

var _ui: CanvasLayer
var _ok_btn: Button
var _no_btn: Button

func setup(p_world: IsoWorld, p_camera: Camera2D) -> void:
	world = p_world
	camera = p_camera
	_build_ui()

func is_active() -> bool:
	return _mode != Mode.NONE

# --- Public entry points ----------------------------------------------------

func start_buy_structure(type: String) -> void:
	_cancel_silent()
	_mode = Mode.BUY_STRUCTURE
	_type = type
	_cur_cell = GameState.first_free_cell()
	_ghost = Structure.new()
	world.entity_layer.add_child(_ghost)
	_ghost.setup(type, _cur_cell, true)
	_show_ui()
	_refresh()

func start_move(struct: Structure) -> void:
	_cancel_silent()
	_mode = Mode.MOVE_STRUCTURE
	_move_target = struct
	_type = struct.type
	_cur_cell = struct.cell
	struct.visible = false
	_ghost = Structure.new()
	world.entity_layer.add_child(_ghost)
	_ghost.setup(_type, _cur_cell, true)
	_show_ui()
	_refresh()

func start_buy_land() -> void:
	_cancel_silent()
	_mode = Mode.BUY_LAND
	_land_origin = _suggest_land_origin()
	_land_preview = Node2D.new()
	world.add_child(_land_preview)
	for i in range(Catalog.LAND_BLOCK_SIZE * Catalog.LAND_BLOCK_SIZE):
		var poly := Polygon2D.new()
		poly.polygon = IsoUtils.diamond_points()
		_land_preview.add_child(poly)
	_show_ui()
	_refresh()

# --- Per-frame update -------------------------------------------------------

func _process(_delta: float) -> void:
	if _mode == Mode.NONE:
		return
	# Keep the confirm/cancel buttons pinned to the ghost (e.g. if zoom changes).
	# The ghost itself only moves while the user is actively dragging it (see
	# _unhandled_input) so it stays put while you reach for the ✓ button.
	_position_buttons()

# Snap the ghost / land block to the cell under the mouse. Only called while dragging.
func _follow_mouse() -> void:
	var mouse := world.get_global_mouse_position()
	var cell := IsoUtils.world_to_grid(mouse)
	if _mode == Mode.BUY_LAND:
		if cell != _land_origin:
			_land_origin = cell
			_refresh()
	elif cell != _cur_cell:
		_cur_cell = cell
		if _ghost:
			_ghost.move_to_cell(cell)
		_refresh()
	_position_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if _mode == Mode.NONE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Press in the world starts dragging the ghost; release drops it in place.
		# Presses on the ✓/✗ buttons are consumed by them and never reach here.
		_dragging = event.pressed
		if _dragging:
			_follow_mouse()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		_follow_mouse()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	match _mode:
		Mode.BUY_STRUCTURE:
			var cost := int(Catalog.get_structure(_type).get("cost", 0))
			_valid = GameState.is_cell_free(_cur_cell) and GameState.can_afford(cost)
			if _ghost: _ghost.set_valid_tint(_valid)
		Mode.MOVE_STRUCTURE:
			_valid = GameState.is_cell_free(_cur_cell) or _cur_cell == _move_target.cell
			if _ghost: _ghost.set_valid_tint(_valid)
		Mode.BUY_LAND:
			_valid = _land_valid(_land_origin)
			_update_land_preview()
	_ok_btn.disabled = not _valid
	_ok_btn.modulate = Color.WHITE if _valid else Color(1, 1, 1, 0.4)

# --- Confirm / cancel -------------------------------------------------------

func _confirm() -> void:
	if not _valid:
		return
	var ok := false
	match _mode:
		Mode.BUY_STRUCTURE: ok = world.confirm_structure(_type, _cur_cell)
		Mode.MOVE_STRUCTURE: ok = world.confirm_move(_move_target, _cur_cell)
		Mode.BUY_LAND: ok = world.confirm_land(_land_origin)
	if _move_target:
		_move_target.visible = true
	_teardown()
	if ok:
		finished.emit()

func _cancel() -> void:
	_cancel_silent()
	finished.emit()

func _cancel_silent() -> void:
	if _move_target:
		_move_target.visible = true
	_teardown()

func _teardown() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	if _land_preview:
		_land_preview.queue_free()
		_land_preview = null
	_move_target = null
	_mode = Mode.NONE
	if _ui:
		_ui.visible = false

# --- Land helpers -----------------------------------------------------------

func _land_valid(origin: Vector2i) -> bool:
	if not GameState.can_afford(GameState.next_land_block_cost()):
		return false
	var n := Catalog.LAND_BLOCK_SIZE
	var touches := false
	for x in range(n):
		for y in range(n):
			var c := origin + Vector2i(x, y)
			if GameState.owned_cells.has(c):
				return false   # overlaps existing land
			for nb in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				if GameState.owned_cells.has(c + nb):
					touches = true
	return touches

func _suggest_land_origin() -> Vector2i:
	# Default the new block just to the +x side of the current land.
	var max_x := 0
	for c in GameState.owned_cells.keys():
		max_x = max(max_x, c.x)
	return Vector2i(max_x + 1, 0)

func _update_land_preview() -> void:
	var n := Catalog.LAND_BLOCK_SIZE
	var col := Color(0.4, 1.0, 0.4, 0.55) if _valid else Color(1.0, 0.4, 0.4, 0.55)
	var i := 0
	for x in range(n):
		for y in range(n):
			var poly: Polygon2D = _land_preview.get_child(i)
			poly.position = IsoUtils.grid_to_world(_land_origin + Vector2i(x, y))
			poly.color = col
			i += 1

# --- Confirm/cancel button UI ----------------------------------------------

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)
	_ok_btn = _make_button("✓", Color(0.3, 0.8, 0.3))
	_no_btn = _make_button("✗", Color(0.85, 0.3, 0.3))
	_ok_btn.pressed.connect(_confirm)
	_no_btn.pressed.connect(_cancel)
	_ui.add_child(_no_btn)
	_ui.add_child(_ok_btn)
	_ui.visible = false

func _make_button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(48, 48)
	b.add_theme_font_size_override("font_size", 24)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(24)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	return b

func _show_ui() -> void:
	_ui.visible = true
	_position_buttons()

func _position_buttons() -> void:
	if not _ui.visible:
		return
	var world_pos: Vector2
	if _mode == Mode.BUY_LAND:
		var c := float(Catalog.LAND_BLOCK_SIZE - 1) / 2.0
		world_pos = IsoUtils.grid_to_world(_land_origin) + Vector2(0, IsoUtils.TILE_H * c)
	else:
		world_pos = IsoUtils.grid_to_world(_cur_cell)
	var screen := world.get_viewport().get_canvas_transform() * world_pos
	_ok_btn.position = screen + Vector2(12, 30)
	_no_btn.position = screen + Vector2(-60, 30)
