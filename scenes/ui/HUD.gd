class_name HUD
extends CanvasLayer
## Screen-space UI: a top points/income bar, a bottom-center action dashboard
## (Build / Move / Fish / Expand Land), and a toggleable Build market panel.
## Icons are text placeholders for now.

signal request_build_structure(type: String)
signal request_move()
signal request_expand_land()
signal request_fish()

var _points_label: Label
var _market: Panel
var _market_buttons: Array[Button] = []
var _expand_btn: Button

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_top_bar(root)
	_build_dashboard(root)
	_build_market(root)

	GameState.points_changed.connect(_on_points_changed)
	GameState.economy_changed.connect(_refresh_costs)
	_on_points_changed(GameState.points, GameState.points_per_second)

# --- Top bar ----------------------------------------------------------------

func _build_top_bar(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -170
	panel.offset_right = 170
	panel.offset_top = 10
	panel.offset_bottom = 56
	root.add_child(panel)
	_points_label = Label.new()
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_points_label.add_theme_font_size_override("font_size", 20)
	panel.add_child(_points_label)

# --- Bottom dashboard -------------------------------------------------------

func _build_dashboard(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -280
	panel.offset_right = 280
	panel.offset_top = -92
	panel.offset_bottom = -14
	root.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	hbox.add_child(_action_button("🔨\nBuild", func(): _toggle_market(true)))
	hbox.add_child(_action_button("✋\nMove", func(): request_move.emit()))
	hbox.add_child(_action_button("🐟\nFish", func(): request_fish.emit()))
	_expand_btn = _action_button("🗺\nExpand", func(): request_expand_land.emit())
	hbox.add_child(_expand_btn)

func _action_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(96, 64)
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(cb)
	return b

# --- Market panel -----------------------------------------------------------

func _build_market(root: Control) -> void:
	_market = Panel.new()
	_market.anchor_left = 0.5
	_market.anchor_right = 0.5
	_market.anchor_top = 0.5
	_market.anchor_bottom = 0.5
	_market.offset_left = -190
	_market.offset_right = 190
	_market.offset_top = -220
	_market.offset_bottom = 220
	_market.visible = false
	root.add_child(_market)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12
	vbox.offset_right = -12
	vbox.offset_top = 12
	vbox.offset_bottom = -12
	vbox.add_theme_constant_override("separation", 8)
	_market.add_child(vbox)

	var title := Label.new()
	title.text = "BUILD MARKET"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	for id in Catalog.MARKET_ORDER:
		var def: Dictionary = Catalog.get_structure(id)
		var b := Button.new()
		b.set_meta("id", id)
		b.set_meta("cost", int(def["cost"]))
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(func():
			_toggle_market(false)
			request_build_structure.emit(id))
		vbox.add_child(b)
		_market_buttons.append(b)

	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(func(): _toggle_market(false))
	vbox.add_child(close)

	_refresh_costs()

func _toggle_market(show_it: bool) -> void:
	if show_it:
		_refresh_costs()
	_market.visible = show_it

# --- Refresh ----------------------------------------------------------------

func _on_points_changed(points: float, pps: float) -> void:
	_points_label.text = "%d pts   (+%.1f/s)" % [int(points), pps]

func _refresh_costs() -> void:
	for b in _market_buttons:
		var id: String = b.get_meta("id")
		var def: Dictionary = Catalog.get_structure(id)
		var cost: int = b.get_meta("cost")
		b.text = "%s   $%d   +%.0f/s" % [def["name"], cost, float(def["income"])]
		b.disabled = not GameState.can_afford(cost)
	if _expand_btn:
		_expand_btn.text = "🗺\n$%d" % GameState.next_land_block_cost()
