class_name LandTile
extends Node2D
## A single isometric ground cell, drawn procedurally (placeholder art): a green grass
## "top" diamond plus brown "side" faces below it to give the block-of-earth look from
## the reference image. Purely visual — clicks are handled by Main via world_to_grid.

var cell: Vector2i

const GRASS := Color("5fa64a")
const GRASS_EDGE := Color("4d8a3c")
const SIDE_RIGHT := Color("6e4326")
const SIDE_LEFT := Color("5a3620")

func setup(c: Vector2i) -> void:
	cell = c
	position = IsoUtils.grid_to_world(c)
	z_index = 0
	queue_redraw()

func _draw() -> void:
	var hw := IsoUtils.TILE_W / 2.0
	var hh := IsoUtils.TILE_H / 2.0
	var s := float(IsoUtils.SIDE_H)
	var top := Vector2(0, -hh)
	var right := Vector2(hw, 0)
	var bottom := Vector2(0, hh)
	var left := Vector2(-hw, 0)

	# Side faces (drawn first, behind the grass top).
	draw_colored_polygon(PackedVector2Array([
		right, bottom, bottom + Vector2(0, s), right + Vector2(0, s)]), SIDE_RIGHT)
	draw_colored_polygon(PackedVector2Array([
		left, bottom, bottom + Vector2(0, s), left + Vector2(0, s)]), SIDE_LEFT)

	# Grass top.
	var diamond := PackedVector2Array([top, right, bottom, left])
	draw_colored_polygon(diamond, GRASS)
	# Subtle outline so individual cells read clearly.
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), GRASS_EDGE, 1.0, true)
