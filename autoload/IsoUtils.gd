extends Node
## Isometric grid math and shared tile constants.
## Autoloaded as the `IsoUtils` singleton.
##
## The world uses a 2:1 isometric ("diamond") projection: a tile's corners point
## up / down / left / right, exactly like the reference image. Grid cell (0,0) maps
## to world origin; +x goes down-right, +y goes down-left.

const TILE_W: int = 128       # full width of a diamond tile, in pixels
const TILE_H: int = 64        # full height of a diamond tile, in pixels
const SIDE_H: int = 24        # how tall the brown "block" side faces are drawn

## Grid cell -> world position (center-top of the diamond's top face).
func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		(cell.x - cell.y) * (TILE_W / 2.0),
		(cell.x + cell.y) * (TILE_H / 2.0)
	)

## World position -> nearest grid cell (inverse of grid_to_world).
func world_to_grid(world: Vector2) -> Vector2i:
	var hw := TILE_W / 2.0
	var hh := TILE_H / 2.0
	var fx := (world.x / hw + world.y / hh) / 2.0
	var fy := (world.y / hh - world.x / hw) / 2.0
	return Vector2i(int(round(fx)), int(round(fy)))

## The four corner offsets of a diamond's top face, relative to its center.
func diamond_points() -> PackedVector2Array:
	var hw := TILE_W / 2.0
	var hh := TILE_H / 2.0
	return PackedVector2Array([
		Vector2(0, -hh),   # top
		Vector2(hw, 0),    # right
		Vector2(0, hh),    # bottom
		Vector2(-hw, 0),   # left
	])
