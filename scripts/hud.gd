extends CanvasLayer
class_name RunnerHUD

# UI References
var speed_label: Label
var nitro_gauge_label: Label
var distance_label: Label
var score_label: Label
var tier_label: Label
var cores_label: Label
var status_label: Label
var controls_label: Label

# Power-Up Badges
var powerup_container: HBoxContainer
var shield_panel: PanelContainer
var shield_label: Label
var overdrive_panel: PanelContainer
var overdrive_label: Label
var magnet_panel: PanelContainer
var magnet_label: Label

# Tier Notification Banner
var tier_banner: Label
var tier_banner_timer: float = 0.0

# Game Over Dialog
var game_over_panel: PanelContainer
var game_over_dist_label: Label
var game_over_tier_label: Label
var game_over_cores_label: Label
var game_over_score_label: Label

# Nitro Radial Screen Overlay
var nitro_overlay: ColorRect
var nitro_material: ShaderMaterial

# Cached States & Timers
var is_boosting: bool = false
var cached_speed: float = 24.0
var target_nitro_intensity: float = 0.0
var current_nitro_intensity: float = 0.0

var has_shield: bool = false
var overdrive_remaining: float = 0.0
var magnet_remaining: float = 0.0
var cached_tier: int = 0

func _ready() -> void:
	layer = 10
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# 1. Full-Screen Nitrous Radial Speed Lines & Warp Vignette Overlay (50% visibility)
	nitro_overlay = ColorRect.new()
	nitro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	nitro_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float nitro_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 nitro_color : source_color = vec4(0.0, 0.88, 1.0, 1.0);

float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

void fragment() {
	if (nitro_intensity <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		vec2 uv = UV - vec2(0.5, 0.5);
		uv.x *= 1.777;
		float dist = length(uv);
		float angle = atan(uv.y, uv.x);
		
		float ray_count = 72.0;
		float ray_id = floor((angle + 3.14159265) / 6.2831853 * ray_count);
		float rand_val = hash(ray_id + floor(TIME * 28.0));
		
		float is_ray = step(0.68, rand_val);
		float streak = smoothstep(0.38, 0.88, dist) * is_ray;
		float vignette = smoothstep(0.42, 0.95, dist) * 0.22;
		
		float total_alpha = clamp((streak * 0.40 + vignette) * nitro_intensity * 0.50, 0.0, 0.38);
		vec3 col = mix(nitro_color.rgb, vec3(0.92, 0.98, 1.0), streak * 0.50);
		COLOR = vec4(col, total_alpha);
	}
}
"""
	nitro_material = ShaderMaterial.new()
	nitro_material.shader = shader
	nitro_material.set_shader_parameter("nitro_intensity", 0.0)
	nitro_overlay.material = nitro_material
	root.add_child(nitro_overlay)

	# 2. Top Header Bar (3 Columns: Speed/N2O | Score/Distance | Tier/Cores)
	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_top = 16.0
	top_bar.offset_bottom = 85.0
	top_bar.offset_left = 32.0
	top_bar.offset_right = -32.0
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(top_bar)

	# --- Column 1 (Left): Speed & Nitrous Gauge ---
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(left_vbox)

	speed_label = Label.new()
	speed_label.text = "SPEED: 086 KM/H"
	speed_label.add_theme_font_size_override("font_size", 22)
	speed_label.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	speed_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.3, 0.5, 0.8))
	speed_label.add_theme_constant_override("shadow_offset_x", 2)
	speed_label.add_theme_constant_override("shadow_offset_y", 2)
	left_vbox.add_child(speed_label)

	nitro_gauge_label = Label.new()
	nitro_gauge_label.text = "N₂O: [READY]"
	nitro_gauge_label.add_theme_font_size_override("font_size", 16)
	nitro_gauge_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0, 0.7))
	nitro_gauge_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.2, 0.4, 0.8))
	nitro_gauge_label.add_theme_constant_override("shadow_offset_x", 1)
	nitro_gauge_label.add_theme_constant_override("shadow_offset_y", 1)
	left_vbox.add_child(nitro_gauge_label)

	# --- Column 2 (Center): Score & Distance ---
	var center_vbox := VBoxContainer.new()
	center_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(center_vbox)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.text = "SCORE: 000000"
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
	score_label.add_theme_color_override("font_shadow_color", Color(0.8, 0.3, 0.0, 0.9))
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	center_vbox.add_child(score_label)

	distance_label = Label.new()
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label.text = "DIST: 00000 M"
	distance_label.add_theme_font_size_override("font_size", 18)
	distance_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	distance_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.1, 0.0, 0.8))
	distance_label.add_theme_constant_override("shadow_offset_x", 1)
	distance_label.add_theme_constant_override("shadow_offset_y", 1)
	center_vbox.add_child(distance_label)

	# --- Column 3 (Right): Tier & Data Cores ---
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(right_vbox)

	tier_label = Label.new()
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tier_label.text = "TIER 0 [1.0x MULT]"
	tier_label.add_theme_font_size_override("font_size", 22)
	tier_label.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0))
	tier_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.3, 0.5, 0.8))
	tier_label.add_theme_constant_override("shadow_offset_x", 2)
	tier_label.add_theme_constant_override("shadow_offset_y", 2)
	right_vbox.add_child(tier_label)

	var cores_status_hbox := HBoxContainer.new()
	cores_status_hbox.alignment = BoxContainer.ALIGNMENT_END
	right_vbox.add_child(cores_status_hbox)

	cores_label = Label.new()
	cores_label.text = "◆ CORES: 00   "
	cores_label.add_theme_font_size_override("font_size", 16)
	cores_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	cores_status_hbox.add_child(cores_label)

	status_label = Label.new()
	status_label.text = "SYS: ONLINE"
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	cores_status_hbox.add_child(status_label)

	# 3. Active Power-Up Badges Container (Below Top Bar)
	powerup_container = HBoxContainer.new()
	powerup_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	powerup_container.offset_top = 92.0
	powerup_container.offset_bottom = 132.0
	powerup_container.alignment = BoxContainer.ALIGNMENT_CENTER
	powerup_container.add_theme_constant_override("separation", 16)
	powerup_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(powerup_container)

	# Shield Badge (Cyan)
	var shield_data = _build_powerup_pill("🛡️ SHIELD: ONLINE", Color(0.0, 0.95, 1.0), Color(0.02, 0.18, 0.25, 0.85))
	shield_panel = shield_data["panel"]
	shield_label = shield_data["label"]
	powerup_container.add_child(shield_panel)

	# Overdrive Badge (Gold)
	var od_data = _build_powerup_pill("⚡ OVERDRIVE: 6.0s", Color(1.0, 0.8, 0.15), Color(0.25, 0.15, 0.02, 0.85))
	overdrive_panel = od_data["panel"]
	overdrive_label = od_data["label"]
	powerup_container.add_child(overdrive_panel)

	# Magnet Badge (Magenta)
	var mag_data = _build_powerup_pill("🧲 MAGNET: 8.0s", Color(0.9, 0.25, 1.0), Color(0.22, 0.03, 0.28, 0.85))
	magnet_panel = mag_data["panel"]
	magnet_label = mag_data["label"]
	powerup_container.add_child(magnet_panel)

	# 4. Tier Milestone Announcement Banner
	tier_banner = Label.new()
	tier_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tier_banner.offset_top = 142.0
	tier_banner.offset_bottom = 182.0
	tier_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_banner.text = ""
	tier_banner.add_theme_font_size_override("font_size", 22)
	tier_banner.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	tier_banner.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	tier_banner.add_theme_constant_override("shadow_offset_x", 2)
	tier_banner.add_theme_constant_override("shadow_offset_y", 2)
	tier_banner.visible = false
	root.add_child(tier_banner)

	# 5. Bottom Controls Hint
	controls_label = Label.new()
	controls_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	controls_label.offset_bottom = -16.0
	controls_label.offset_top = -54.0
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_label.text = "[A / D] SWITCH LANE    |    [W] NITRO BOOST    |    [SPACE] JUMP    |    [S] SLIDE    |    [R] RESTART"
	controls_label.add_theme_font_size_override("font_size", 15)
	controls_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.85))
	controls_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.1, 0.3, 0.9))
	controls_label.add_theme_constant_override("shadow_offset_x", 1)
	controls_label.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(controls_label)

	# 6. Game Over Overlay Panel
	_build_game_over_panel(root)

func _build_powerup_pill(default_text: String, border_color: Color, bg_color: Color) -> Dictionary:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", style)
	panel.visible = false

	var lbl := Label.new()
	lbl.text = default_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", border_color)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	panel.add_child(lbl)

	return {"panel": panel, "label": lbl}

func _build_game_over_panel(root: Control) -> void:
	game_over_panel = PanelContainer.new()
	game_over_panel.set_anchors_preset(Control.PRESET_CENTER)
	game_over_panel.custom_minimum_size = Vector2(520, 310)
	game_over_panel.offset_left = -260.0
	game_over_panel.offset_top = -155.0
	game_over_panel.offset_right = 260.0
	game_over_panel.offset_bottom = 155.0
	game_over_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.07, 0.94)
	style.border_color = Color(1.0, 0.15, 0.45)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	game_over_panel.add_theme_stylebox_override("panel", style)

	var go_vbox := VBoxContainer.new()
	go_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	go_vbox.add_theme_constant_override("separation", 10)
	game_over_panel.add_child(go_vbox)

	var title := Label.new()
	title.text = "SYSTEM DISCONNECTED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.18, 0.45))
	go_vbox.add_child(title)

	var hs := HSeparator.new()
	go_vbox.add_child(hs)

	game_over_dist_label = Label.new()
	game_over_dist_label.text = "DISTANCE: 0 METERS"
	game_over_dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_dist_label.add_theme_font_size_override("font_size", 18)
	game_over_dist_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	go_vbox.add_child(game_over_dist_label)

	game_over_tier_label = Label.new()
	game_over_tier_label.text = "DIFFICULTY TIER: TIER 0 [1.0x]"
	game_over_tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_tier_label.add_theme_font_size_override("font_size", 18)
	game_over_tier_label.add_theme_color_override("font_color", Color(0.2, 0.95, 1.0))
	go_vbox.add_child(game_over_tier_label)

	game_over_cores_label = Label.new()
	game_over_cores_label.text = "DATA CORES SALVAGED: 0 ◆"
	game_over_cores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_cores_label.add_theme_font_size_override("font_size", 18)
	game_over_cores_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	go_vbox.add_child(game_over_cores_label)

	game_over_score_label = Label.new()
	game_over_score_label.text = "FINAL SCORE: 0 PTS"
	game_over_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_score_label.add_theme_font_size_override("font_size", 24)
	game_over_score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	go_vbox.add_child(game_over_score_label)

	var hs2 := HSeparator.new()
	go_vbox.add_child(hs2)

	var prompt := Label.new()
	prompt.text = "PRESS [R] OR [SPACE] TO RE-INITIALIZE"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
	go_vbox.add_child(prompt)

	root.add_child(game_over_panel)

func _process(delta: float) -> void:
	# 1. Nitro Screen Effect Lerp
	current_nitro_intensity = lerp(current_nitro_intensity, target_nitro_intensity, delta * 14.0)
	if nitro_material:
		nitro_material.set_shader_parameter("nitro_intensity", current_nitro_intensity)

	if nitro_gauge_label:
		if current_nitro_intensity > 0.05:
			var bars: int = clampi(int(round(current_nitro_intensity * 10.0)), 1, 10)
			var bar_str: String = "N₂O: [" + "=".repeat(bars) + " ".repeat(10 - bars) + "]"
			nitro_gauge_label.text = bar_str
			nitro_gauge_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))
		else:
			nitro_gauge_label.text = "N₂O: [READY]"
			nitro_gauge_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0, 0.65))

	# 2. Power-Up Timers Countdown & Badge Updating
	if shield_panel:
		shield_panel.visible = has_shield

	if overdrive_remaining > 0.0:
		overdrive_remaining = maxf(0.0, overdrive_remaining - delta)
		if overdrive_panel:
			overdrive_panel.visible = true
		if overdrive_label:
			overdrive_label.text = "⚡ OVERDRIVE: %.1fs" % overdrive_remaining
	else:
		if overdrive_panel:
			overdrive_panel.visible = false

	if magnet_remaining > 0.0:
		magnet_remaining = maxf(0.0, magnet_remaining - delta)
		if magnet_panel:
			magnet_panel.visible = true
		if magnet_label:
			magnet_label.text = "🧲 MAGNET: %.1fs" % magnet_remaining
	else:
		if magnet_panel:
			magnet_panel.visible = false

	# 3. Tier Notification Banner Timer
	if tier_banner_timer > 0.0:
		tier_banner_timer -= delta
		if tier_banner:
			tier_banner.visible = true
			var alpha: float = clampf(tier_banner_timer / 0.8, 0.0, 1.0)
			tier_banner.modulate = Color(1.0, 1.0, 1.0, alpha)
		if tier_banner_timer <= 0.0:
			if tier_banner:
				tier_banner.visible = false

# --- Public API / Callbacks ---

func set_nitro_intensity(factor: float) -> void:
	target_nitro_intensity = factor

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
		speed_label.text = "SPEED: %03d KM/H  [NITRO]" % kmh
		speed_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		if status_label:
			status_label.text = "SYS: NITRO [W]"
			status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	else:
		speed_label.text = "SPEED: %03d KM/H" % kmh
		speed_label.add_theme_color_override("font_color", Color(0.1, 0.9, 1.0))
		if status_label:
			status_label.text = "SYS: ONLINE"
			status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))

func update_distance(meters: float) -> void:
	if distance_label:
		distance_label.text = "DIST: %05d M" % int(meters)

func update_score(new_score: int) -> void:
	if score_label:
		score_label.text = "SCORE: %06d" % new_score

func update_cores(new_cores: int) -> void:
	if cores_label:
		cores_label.text = "◆ CORES: %02d   " % new_cores

func update_tier(new_tier: int, multiplier: float) -> void:
	if tier_label:
		var tier_name = _get_tier_name(new_tier)
		tier_label.text = "TIER %d [%.1fx %s]" % [new_tier, multiplier, tier_name]
		var col = _get_tier_color(new_tier)
		tier_label.add_theme_color_override("font_color", col)

	if new_tier > cached_tier:
		cached_tier = new_tier
		tier_banner_timer = 3.6
		if tier_banner:
			tier_banner.text = "⚠️ LEVEL UP: TIER %d REACHED! (%.1fx SCORE / INCREASED HAZARDS) ⚠️" % [new_tier, multiplier]
			tier_banner.add_theme_color_override("font_color", _get_tier_color(new_tier))
			tier_banner.visible = true

func update_powerups(shield: bool, overdrive_time: float, magnet_time: float) -> void:
	has_shield = shield
	overdrive_remaining = overdrive_time
	magnet_remaining = magnet_time

func show_game_over(final_distance: float, final_score: int = 0, final_cores: int = 0, final_tier: int = 0) -> void:
	if game_over_panel:
		game_over_panel.visible = true
	if game_over_dist_label:
		game_over_dist_label.text = "DISTANCE REACHED: %s METERS" % _format_number(int(final_distance))
	if game_over_tier_label:
		game_over_tier_label.text = "HIGHEST TIER: TIER %d (%s)" % [final_tier, _get_tier_name(final_tier)]
		game_over_tier_label.add_theme_color_override("font_color", _get_tier_color(final_tier))
	if game_over_cores_label:
		game_over_cores_label.text = "DATA CORES SALVAGED: %d ◆" % final_cores
	if game_over_score_label:
		game_over_score_label.text = "TOTAL SCORE: %s PTS" % _format_number(final_score)
	if status_label:
		status_label.text = "SYS: TERMINATED"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.3))

func hide_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	if status_label:
		status_label.text = "SYS: ONLINE"
		status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))

func _get_tier_name(tier: int) -> String:
	match tier:
		0: return "NORMAL"
		1: return "HYPER-SURGE"
		2: return "OVERCLOCK"
		_: return "OVERDRIVE"

func _get_tier_color(tier: int) -> Color:
	match tier:
		0: return Color(0.2, 0.95, 1.0)
		1: return Color(1.0, 0.8, 0.15)
		2: return Color(1.0, 0.2, 0.7)
		_: return Color(1.0, 0.2, 0.25)

func _format_number(n: int) -> String:
	var s: String = str(n)
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	return result
