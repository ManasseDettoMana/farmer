class_name Villager
extends Node2D
## A villager NPC (the farmer / townsfolk) that wanders owned land on its own.
## Side-view 48x48 sprites; flips horizontally to face its travel direction.

# [folder, file-prefix] for the 6 available villager characters.
const CHARS := [
	["1 Old_man", "Old_man"], ["2 Old_woman", "Old_woman"], ["3 Man", "Man"],
	["4 Woman", "Woman"], ["5 Boy", "Boy"], ["6 Girl", "Girl"],
]
const BASE := "res://assets/craftpix-781111-free-villagers-sprite-sheets-pixel-art/"
const SPEED := 38.0

var _sprite: AnimatedSprite2D
var _target: Vector2
var _walking := false
var _wait := 0.0

func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.offset = Vector2(0, -24)   # feet at node origin (for y-sort)
	_sprite.scale = Vector2(1.1, 1.1)
	add_child(_sprite)
	z_index = 1
	_go_idle()

func spawn_at(cell: Vector2i) -> void:
	position = IsoUtils.grid_to_world(cell)

func _build_frames() -> SpriteFrames:
	var pick: Array = CHARS[randi() % CHARS.size()]
	var dir: String = BASE + String(pick[0]) + "/"
	var prefix: String = pick[1]
	var idle: Texture2D = load(dir + prefix + "_idle.png")
	var walk: Texture2D = load(dir + prefix + "_walk.png")
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	if idle:
		SpriteSheet.add_row_anim(frames, idle, "idle", 48, 48, 0, 4, 6.0)
	if walk:
		SpriteSheet.add_row_anim(frames, walk, "walk", 48, 48, 0, 6, 10.0)
	return frames

func _process(delta: float) -> void:
	if _walking:
		var to := _target - position
		if to.length() < 4.0:
			_go_idle()
		else:
			var dir := to.normalized()
			position += dir * SPEED * delta
			if absf(dir.x) > 0.05:
				_sprite.flip_h = dir.x < 0.0
	else:
		_wait -= delta
		if _wait <= 0.0:
			_pick_target()

func _go_idle() -> void:
	_walking = false
	_wait = randf_range(1.0, 3.0)
	if _sprite.sprite_frames.has_animation("idle"):
		_sprite.play("idle")

func _pick_target() -> void:
	var cells := GameState.owned_cells.keys()
	if cells.is_empty():
		return
	_target = IsoUtils.grid_to_world(cells[randi() % cells.size()])
	_walking = true
	if _sprite.sprite_frames.has_animation("walk"):
		_sprite.play("walk")
