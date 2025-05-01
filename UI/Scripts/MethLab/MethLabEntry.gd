extends Control

@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var bg_panel = $BGPanel
@onready var center_panel = $CenterContainer/Panel

# Modern color scheme
const COLOR_BG_DARK = Color("#0A0E14")
const COLOR_PRIMARY = Color("#007AFF")
const COLOR_PRIMARY_DARK = Color("#0055CC")
const COLOR_SECONDARY = Color("#5AC8FA")
const COLOR_ACCENT = Color("#FF9500")
const COLOR_TEXT = Color("#FFFFFF")
const COLOR_TEXT_SECONDARY = Color("#AAAAAA")

var time_elapsed = 0.0

func _ready():
	enhance_visuals()
	animate_title_entrance()

func _process(delta):
	time_elapsed += delta
	
	# Dynamic title effect
	title_label.modulate = Color(
		1.0, 
		0.9 + sin(time_elapsed * 1.2) * 0.1, 
		0.9 + cos(time_elapsed * 1.5) * 0.1, 
		1.0
	)
	
	# Subtle button pulse
	start_button.modulate = Color(
		1.0,
		1.0, 
		1.0,
		0.9 + sin(time_elapsed * 2) * 0.1
	)

func enhance_visuals():
	# Setup title with a nice color
	title_label.add_theme_font_size_override("font_size", 52)
	title_label.add_theme_color_override("font_outline_color", COLOR_PRIMARY_DARK)
	title_label.add_theme_constant_override("outline_size", 4)
	
	# Setup subtitle
	subtitle_label.add_theme_color_override("font_color", COLOR_SECONDARY)
	subtitle_label.add_theme_font_size_override("font_size", 24)
	
	# Setup button
	style_button(start_button)
	
	# Center container styling
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.07, 0.12, 0.8)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = COLOR_PRIMARY.darkened(0.3)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0, 4)
	center_panel.add_theme_stylebox_override("panel", panel_style)

func style_button(button):
	# Create a new style for the button
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("#1a1a1a")
	normal_style.border_width_all = 2
	normal_style.border_color = Color("#3498db")
	
	# Use individual corner radius properties instead of corner_radius_all
	normal_style.corner_radius_top_left = 10
	normal_style.corner_radius_top_right = 10
	normal_style.corner_radius_bottom_left = 10
	normal_style.corner_radius_bottom_right = 10
	
	# Improve text appearance
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_color_override("font_color", Color("#ffffff"))
	button.add_theme_font_size_override("font_size", 24)

func animate_button_hover(button, is_hovering):
	var tween = create_tween()
	
	if is_hovering:
		tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2), 0.2)
	else:
		tween.tween_property(button, "modulate", Color(1, 1, 1), 0.2)

func animate_title_entrance():
	var title_label = $CenterContainer/VBoxContainer/TitleLabel
	
	# Set initial state
	title_label.scale = Vector2(0.5, 0.5)
	title_label.modulate.a = 0
	
	# Create animation
	var tween = create_tween()
	tween.tween_property(title_label, "scale", Vector2(1, 1), 0.5).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(title_label, "modulate:a", 1.0, 0.5)

func _on_start_button_pressed():
	# Check if the SceneManager is available
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").change_scene("res://UI/Scenes/MethLab/MethLabGame.tscn")
	else:
		# Fallback to direct scene change
		get_tree().change_scene_to_file("res://UI/Scenes/MethLab/MethLabGame.tscn") 
