class_name Structure
extends Node2D
## A placed building/object. Uses a real sprite when the catalog entry provides one
## (currently only trees), otherwise draws a colorful labeled placeholder "card".
## Anchored at the tile-center; sits in the y-sorted EntityLayer for correct depth.

signal clicked(structure: Structure)

const TREE_PATHS := [
	"res://assets/green_pine_tree_with_grass_at/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (1)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (2)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (3)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (4)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (5)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (6)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (7)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (8)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (9)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (10)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (11)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (12)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (13)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (14)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
	"res://assets/green_pine_tree_with_grass_at (15)/green_pine_tree_with_grass_at_base/rotations/unknown.png",
]

var type: String
var cell: Vector2i
var ghost: bool = false
var _def: Dictionary
var _area: Area2D

func setup(p_type: String, p_cell: Vector2i, p_ghost: bool = false) -> void:
	type = p_type
	cell = p_cell
	ghost = p_ghost
	_def = Catalog.get_structure(type)
	position = IsoUtils.grid_to_world(cell)
	z_index = 1

	if _def.get("sprite", "") == "tree":
		_build_tree()
	else:
		_build_placeholder()

	if ghost:
		modulate = Color(1, 1, 1, 0.6)
	else:
		_add_click_area()

func _build_tree() -> void:
	var idx: int = absi(cell.x * 3 + cell.y * 7) % TREE_PATHS.size()
	var tex: Texture2D = load(TREE_PATHS[idx])
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.scale = Vector2(1.4, 1.4)
	# Anchor the trunk base near the tile center.
	if tex:
		spr.offset = Vector2(0, -tex.get_height() * 0.5 + 6)
	add_child(spr)

func _build_placeholder() -> void:
	# Footprint highlight + building box are drawn in _draw(); add the text label here.
	var label := Label.new()
	label.text = _def.get("label", type.to_upper())
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(80, 16)
	label.position = Vector2(-40, -42)
	add_child(label)
	queue_redraw()

func _draw() -> void:
	if _def.get("sprite", "") == "tree":
		return
	var color: Color = _def.get("color", Color.GRAY)
	# Footprint diamond (so occupancy is obvious).
	var hw := IsoUtils.TILE_W / 2.0
	var hh := IsoUtils.TILE_H / 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -hh), Vector2(hw, 0), Vector2(0, hh), Vector2(-hw, 0)]),
		Color(color.r, color.g, color.b, 0.35))
	# Building box rising from the tile.
	var box := Rect2(-30, -50, 60, 46)
	draw_rect(box, color)
	draw_rect(box, color.darkened(0.4), false, 2.0)
	# Simple roof.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-34, -50), Vector2(0, -66), Vector2(34, -50)]), color.darkened(0.25))

func _add_click_area() -> void:
	_area = Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(IsoUtils.TILE_W * 0.6, IsoUtils.TILE_H + 40)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	_area.add_child(shape)
	_area.input_pickable = true
	_area.input_event.connect(_on_area_input)
	add_child(_area)

func _on_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)

## Recolor while acting as a placement ghost.
func set_valid_tint(valid: bool) -> void:
	modulate = Color(0.5, 1.0, 0.5, 0.7) if valid else Color(1.0, 0.4, 0.4, 0.7)

func move_to_cell(c: Vector2i) -> void:
	cell = c
	position = IsoUtils.grid_to_world(c)
