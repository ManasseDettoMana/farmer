class_name Animal
extends Node2D
## A farm animal NPC that wanders owned land. Top-down multi-directional sheets.
##
## NOTE: the row->direction order in these Craftpix sheets can't be derived from the
## image dimensions alone. The DIR_ROWS mapping below is a sensible default; if an
## animal faces the wrong way in-editor, tweak the row indices here (see todo.md).

const BASE := "res://assets/craftpix-net-291971-free-top-down-animals-farm-pixel-art-sprites/PNG/With_shadow/"

# name -> { file, frame, cols, rows }
const ANIMALS := {
	"chick":   { "file": "Chick_animation_with_shadow.png",   "frame": 32, "cols": 3, "rows": 4 },
	"rooster": { "file": "Rooster_animation_with_shadow.png", "frame": 32, "cols": 6, "rows": 8 },
	"sheep":   { "file": "Sheep_animation_with_shadow.png",   "frame": 32, "cols": 6, "rows": 8 },
	"lamb":    { "file": "Lamb_animation_with_shadow.png",    "frame": 32, "cols": 6, "rows": 8 },
	"piglet":  { "file": "Piglet_animation_with_shadow.png",  "frame": 32, "cols": 6, "rows": 8 },
	"turkey":  { "file": "Turkey_animation_with_shadow.png",  "frame": 32, "cols": 6, "rows": 8 },
	"calf":    { "file": "Calf_animation_with_shadow.png",    "frame": 64, "cols": 6, "rows": 8 },
	"bull":    { "file": "Bull_animation_with_shadow.png",    "frame": 64, "cols": 6, "rows": 8 },
}
# Direction -> offset within the walk row band. Order assumed: down, up, left, right.
const DIR_ROWS := { "down": 0, "up": 1, "left": 2, "right": 3 }
const SPEED := 26.0

var _sprite: AnimatedSprite2D
var _target: Vector2
var _walking := false
var _wait := 0.0
var _dir := "down"

func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.scale = Vector2(1.2, 1.2)
	add_child(_sprite)
	z_index = 1
	_go_idle()

func spawn_at(cell: Vector2i) -> void:
	position = IsoUtils.grid_to_world(cell)

func _build_frames() -> SpriteFrames:
	var key: String = ANIMALS.keys()[randi() % ANIMALS.size()]
	var cfg: Dictionary = ANIMALS[key]
	var tex: Texture2D = load(BASE + cfg["file"])
	var f: int = cfg["frame"]
	var cols: int = cfg["cols"]
	var rows: int = cfg["rows"]
	# Center the (frame-sized) sprite so its feet sit near the node origin.
	_sprite_offset = Vector2(0, -f * 0.4)
	var walk_base := 4 if rows >= 8 else 0   # 8-row sheets: lower half = walking
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for d in DIR_ROWS.keys():
		var row: int = walk_base + DIR_ROWS[d]
		if row < rows:
			SpriteSheet.add_row_anim(frames, tex, "walk_" + d, f, f, row, cols, 8.0)
	# Idle = first frame of the down-facing row.
	SpriteSheet.add_row_anim(frames, tex, "idle", f, f, 0, 1, 1.0)
	return frames

var _sprite_offset := Vector2.ZERO

func _process(delta: float) -> void:
	if _sprite.offset != _sprite_offset:
		_sprite.offset = _sprite_offset
	if _walking:
		var to := _target - position
		if to.length() < 4.0:
			_go_idle()
		else:
			var dir := to.normalized()
			position += dir * SPEED * delta
			_update_dir(dir)
	else:
		_wait -= delta
		if _wait <= 0.0:
			_pick_target()

func _update_dir(dir: Vector2) -> void:
	var d: String
	if absf(dir.x) > absf(dir.y):
		d = "left" if dir.x < 0.0 else "right"
	else:
		d = "up" if dir.y < 0.0 else "down"
	if d != _dir:
		_dir = d
	var anim := "walk_" + _dir
	if _sprite.sprite_frames.has_animation(anim) and _sprite.animation != anim:
		_sprite.play(anim)

func _go_idle() -> void:
	_walking = false
	_wait = randf_range(1.5, 4.0)
	if _sprite.sprite_frames.has_animation("idle"):
		_sprite.play("idle")

func _pick_target() -> void:
	var cells := GameState.owned_cells.keys()
	if cells.is_empty():
		return
	_target = IsoUtils.grid_to_world(cells[randi() % cells.size()])
	_walking = true
