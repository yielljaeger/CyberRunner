extends CanvasLayer
class_name RunnerHUD

var distance_label: Label
var speed_label: Label
var status_label: Label
var controls_label: Label
var game_over_panel: PanelContainer
var game_over_stats_label: Label

func _ready() -> void:
	layer = 10
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- TOP HEADER BAR ---
	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_top = 20.0
	top_bar.offset_bottom = 80.0
	top_bar.offset_left = 30.0
	top_bar.offset_right = -30.0
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(top_bar)

	# 1. Speed display (Left)
	speed_label = Label.new()
	speed_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_label.text = "SPEED: 086 KM/H"
	speed_label.add_theme_font_size_override("font_size", 22)
	speed_label.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	speed_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.4, 0.6, 0.8))
	speed_label.add_theme_constant_override("shadow_offset_x", 2)
	speed_label.add_theme_constant_override("shadow_offset_y", 2)
	top_bar.add_child(speed_label)

	# 2. Distance display (Center)
	distance_label = Label.new()
	distance_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label.text = "DISTANCE: 00000 M"
	distance_label.add_theme_font_size_override("font_size", 28)
	distance_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
	distance_label.add_theme_color_override("font_shadow_color", Color(0.8, 0.3, 0.0, 0.8))
	distance_label.add_theme_constant_override("shadow_offset_x", 2)
	distance_label.add_theme_constant_override("shadow_offset_y", 2)
	top_bar.add_child(distance_label)

	# 3. Status display (Right)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.text = "SYS: ONLINE [P1]"
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	top_bar.add_child(status_label)

	# --- BOTTOM CONTROLS HINT ---
	controls_label = Label.new()
	controls_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	controls_label.offset_bottom = -20.0
	controls_label.offset_top = -60.0
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_label.text = "[A / D] SWITCH LANE    |    [W] BOOST SPEED    |    [SPACE] JUMP    |    [S] SLIDE / DIVE    |    [R] RESTART"
	controls_label.add_theme_font_size_override("font_size", 16)
	controls_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.85))
	controls_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.1, 0.3, 0.9))
	controls_label.add_theme_constant_override("shadow_offset_x", 1)
	controls_label.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(controls_label)

	# --- GAME OVER OVERLAY ---
	game_over_panel = PanelContainer.new()
	game_over_panel.set_anchors_preset(Control.PRESET_CENTER)
	game_over_panel.custom_minimum_size = Vector2(480, 240)
	game_over_panel.offset_left = -240.0
	game_over_panel.offset_top = -120.0
	game_over_panel.offset_right = 240.0
	game_over_panel.offset_bottom = 120.0
	game_over_panel.visible = false

	# Cyber style panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.92)
	style.border_color = Color(1.0, 0.1, 0.5)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	game_over_panel.add_theme_stylebox_override("panel", style)

	var go_vbox := VBoxContainer.new()
	go_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_panel.add_child(go_vbox)

	var title := Label.new()
	title.text = "SYSTEM DISCONNECTED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.15, 0.45))
	go_vbox.add_child(title)

	game_over_stats_label = Label.new()
	game_over_stats_label.text = "DISTANCE: 0 M"
	game_over_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_stats_label.add_theme_font_size_override("font_size", 22)
	game_over_stats_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	go_vbox.add_child(game_over_stats_label)

	var prompt := Label.new()
	prompt.text = "PRESS [R] OR [SPACE] TO RE-INITIALIZE"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	go_vbox.add_child(prompt)

	root.add_child(game_over_panel)

var is_boosting: bool = false
var cached_speed: float = 24.0

func set_boosting(boosting: bool) -> void:
	is_boosting = boosting
	_refresh_speed_display()

func update_speed(speed: float) -> void:
	cached_speed = speed
	_refresh_speed_display()

func _refresh_speed_display() -> void:
	if speed_label == null:
		return
	var kmh: int = int(cached_speed * 3.6)
	if is_boosting:
		speed_label.text = "SPEED: %03d KM/H  [BOOST]" % kmh
		speed_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		if status_label:
			status_label.text = "SYS: OVERDRIVE [W]"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	else:
		speed_label.text = "SPEED: %03d KM/H" % kmh
		speed_label.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
		if status_label:
			status_label.text = "SYS: ONLINE [P1]"
			status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))

func update_distance(meters: float) -> void:
	if distance_label:
		distance_label.text = "DISTANCE: %05d M" % int(meters)

func show_game_over(final_distance: float) -> void:
	if game_over_panel:
		game_over_panel.visible = true
	if game_over_stats_label:
		game_over_stats_label.text = "FINAL DISTANCE: %d METERS" % int(final_distance)
	if status_label:
		status_label.text = "SYS: TERMINATED"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.3))

func hide_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	if status_label:
		status_label.text = "SYS: ONLINE [P1]"
		status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
