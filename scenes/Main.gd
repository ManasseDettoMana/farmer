extends Node2D
## Root scene. Builds the camera, sky background, world, HUD and placement controller,
## then handles camera pan/zoom, land click-bonus, the move tool and the fish action.

const SKY := "res://assets/bg-sky.jpg"
const FISH_REWARD := 5.0
const DRAG_THRESHOLD := 6.0

var camera: Camera2D
var world: IsoWorld
var hud: HUD
var placement: PlacementController

var _panning := false
var _drag_moved := 0.0
var _await_move := false

func _ready() -> void:
	_build_background()

	camera = Camera2D.new()
	camera.position = Vector2(0, 96)
	add_child(camera)
	camera.make_current()

	world = IsoWorld.new()
	add_child(world)
	world.structure_clicked.connect(_on_structure_clicked)

	hud = HUD.new()
	add_child(hud)
	hud.request_build_structure.connect(_on_request_build)
	hud.request_move.connect(_on_request_move)
	hud.request_expand_land.connect(_on_request_expand)
	hud.request_fish.connect(_on_request_fish)

	placement = PlacementController.new()
	add_child(placement)
	placement.setup(world, camera)
	placement.finished.connect(func(): _await_move = false)

	_update_camera_limits()
	GameState.economy_changed.connect(_update_camera_limits)

func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -100
	add_child(layer)
	var rect := TextureRect.new()
	rect.texture = load(SKY)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)

# --- Input: pan / zoom / click ---------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if placement.is_active():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_panning = true
				_drag_moved = 0.0
			else:
				_panning = false
				if _drag_moved < DRAG_THRESHOLD and not _await_move:
					_try_click_bonus()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / 1.1)
	elif event is InputEventMouseMotion and _panning:
		camera.position -= event.relative / camera.zoom
		_drag_moved += event.relative.length()

func _zoom(factor: float) -> void:
	var z: float = clampf(camera.zoom.x * factor, 0.5, 2.5)
	camera.zoom = Vector2(z, z)

func _try_click_bonus() -> void:
	var cell := IsoUtils.world_to_grid(get_global_mouse_position())
	if GameState.is_land_owned(cell):
		var gained := GameState.add_click_points()
		_floating_text("+%d" % int(gained), IsoUtils.grid_to_world(cell), Color.YELLOW)

# --- HUD actions ------------------------------------------------------------

func _on_request_build(type: String) -> void:
	placement.start_buy_structure(type)

func _on_request_move() -> void:
	_await_move = true
	_floating_text("Tap a building to move", camera.position + Vector2(0, -120), Color.WHITE)

func _on_request_expand() -> void:
	placement.start_buy_land()

func _on_request_fish() -> void:
	GameState.points += FISH_REWARD
	GameState.points_changed.emit(GameState.points, GameState.points_per_second)
	GameState.save_game()
	_floating_text("+%d fish!" % int(FISH_REWARD), camera.position + Vector2(0, -80), Color.AQUA)

func _on_structure_clicked(struct: Structure) -> void:
	if _await_move:
		_await_move = false
		placement.start_move(struct)

# --- Helpers ----------------------------------------------------------------

func _floating_text(text: String, world_pos: Vector2, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.z_index = 100
	lbl.position = world_pos
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	world.add_child(lbl)
	var t := create_tween()
	t.tween_property(lbl, "position", world_pos + Vector2(0, -34), 0.8)
	t.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8)
	t.tween_callback(lbl.queue_free)

func _update_camera_limits() -> void:
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for c in GameState.owned_cells.keys():
		var w: Vector2 = IsoUtils.grid_to_world(c)
		min_p = min_p.min(w)
		max_p = max_p.max(w)
	var margin := 400.0
	camera.limit_left = int(min_p.x - margin)
	camera.limit_right = int(max_p.x + margin)
	camera.limit_top = int(min_p.y - margin)
	camera.limit_bottom = int(max_p.y + margin)
