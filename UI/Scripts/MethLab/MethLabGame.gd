@tool
extends Control

# Game variables
var chemicals_in_beaker = []
var max_chemicals = 5
var dragging_chemical = false
var dragged_chemical_name = ""
var drag_start_position = Vector2()
var drag_ghost = null
var can_drop = false
var recipe_complete = false
var time_elapsed = 0.0
var timer_running = false
var time_remaining = 90.0
var score = 0
var combo_multiplier = 1.0
var streak = 0
var difficulty_level = 1
var achievements = {
	"first_attempt": false,
	"perfect_batch": false,
	"speed_cook": false
}
var visual_effects = []
var shake_amount = 0.0

# The correct recipe order - will change with difficulty
var correct_recipe = ["Pseudoephedrine", "Red Phosphorus", "Iodine", "Methylamine", "Aluminum"]

# Colors
const COLOR_BG = Color("#121212")
const COLOR_PANEL = Color("#1E1E1E")
const COLOR_PRIMARY = Color("#0088FF")
const COLOR_ACCENT = Color("#FF6600")
const COLOR_TEXT = Color("#FFFFFF")
const COLOR_SUCCESS = Color("#00CC66")
const COLOR_WARNING = Color("#FFCC00")
const COLOR_ERROR = Color("#FF3333")
const COLOR_BLUE_SKY = Color("#4F9FE3")
const COLOR_GREEN = Color(0, 0.8, 0.4, 1)
const COLOR_RED = Color(0.8, 0.2, 0.2, 1)
const COLOR_GOLD = Color(1, 0.85, 0, 1)
const COLOR_CYAN = Color(0, 0.8, 0.8, 1)
const COLOR_ORANGE = Color(1, 0.65, 0, 1)

# Node references
var beaker
var recipe_text
var log_text
var quality_label
var profit_label
var chemical_list
var timer_label
var score_label
var combo_label
var sound_effects = {}
var temperature_bar: ProgressBar
var purity_bar: ProgressBar
var yield_bar: ProgressBar

func _ready():
	if Engine.is_editor_hint():
		return
		
	# Initialize node references
	beaker = $LabLayout/MainContent/MidPanel/ReactionPanel/VBoxContainer/ReactionContainer/ReactionDisplay
	recipe_text = $LabLayout/MainContent/RightPanel/RecipePanel/VBoxContainer/RecipeText
	log_text = $LabLayout/LogPanel/VBoxContainer/LogText
	quality_label = $LabLayout/TitleBar/QualityLabel
	profit_label = $LabLayout/TitleBar/ProfitLabel
	timer_label = $LabLayout/TitleBar/TimerLabel
	score_label = $LabLayout/TitleBar/ScoreLabel
	combo_label = $LabLayout/TitleBar/ComboLabel
	temperature_bar = $LabLayout/MainContent/RightPanel/MetricsPanel/VBoxContainer/TemperatureContainer/TemperatureBar
	purity_bar = $LabLayout/MainContent/RightPanel/MetricsPanel/VBoxContainer/PurityContainer/PurityBar
	yield_bar = $LabLayout/MainContent/RightPanel/MetricsPanel/VBoxContainer/YieldContainer/YieldBar
	
	# Apply basic styling
	apply_basic_styling()
	
	# Set up chemical buttons
	setup_chemical_buttons()
	
	# Update the recipe text
	update_recipe_display()
	
	# Initial setup
	setup_game()
	
	# Initial log message
	log_message("Welcome to the lab. Add chemicals in the correct order.")
	log_message("Drag chemicals to the beaker in the middle.")
	
	# Start game timer
	timer_running = true
	
	# Randomize for gameplay variation
	randomize()

func apply_basic_styling():
	# Create beautiful UI styling
	apply_beautiful_ui_theme()
	
	# Improve UI spacing to prevent overlapping
	adjust_ui_layout()

func animate_intro():
	# Fade in main sections one by one
	var sections = [
		$LabLayout/TitleBar,
		$LabLayout/MainContent/LeftPanel,
		$LabLayout/MainContent/MidPanel,
		$LabLayout/MainContent/RightPanel,
		$LabLayout/LogPanel,
		$LabLayout/ControlPanel
	]
	
	for section in sections:
		if section:
			section.modulate = Color(1, 1, 1, 0)
	
	var delay = 0.0
	for section in sections:
		if section:
			var tween = create_tween()
			tween.tween_property(section, "modulate", Color(1, 1, 1, 1), 0.5).set_delay(delay)
			delay += 0.15 # Faster animation
			
	# Pulse title with Breaking Bad style
	var title = $LabLayout/TitleBar/Title
	if title:
		var tween = create_tween()
		tween.tween_property(title, "modulate", Color(0.2, 1.0, 0.3), 0.5).set_delay(1.2)
		tween.tween_property(title, "modulate", Color(1, 1, 1), 0.5)

func apply_beautiful_ui_theme():
	# Apply themed background with Breaking Bad green tint
	var background = $Background
	if background:
		# Create gradient background
		background.color = Color(0.05, 0.05, 0.05, 1)
		
		# Add texture overlay for lab aesthetic
		var texture_rect = TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_TILE
		texture_rect.modulate = Color(0.2, 0.5, 0.3, 0.1)  # Subtle green tint
		background.add_child(texture_rect)
		
		# Add vignette effect
		var vignette = ColorRect.new()
		vignette.color = Color(0, 0, 0, 0)
		vignette.material = create_vignette_material()
		vignette.anchor_right = 1.0
		vignette.anchor_bottom = 1.0
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.add_child(vignette)
		
		# Add subtle scanlines effect
		var scanlines = create_scanlines()
		background.add_child(scanlines)
		
		# Add noise filter for TV/film grain effect
		var noise = create_noise_filter()
		background.add_child(noise)
	
	# Style title bar with "Breaking Bad" theme
	var title = $LabLayout/TitleBar/Title
	if title:
		title.text = "HEISENBERG'S LAB"
		title.add_theme_font_size_override("font_size", 32)
		title.add_theme_color_override("font_color", Color(0.1, 0.9, 0.3))
		title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		title.add_theme_constant_override("outline_size", 2)
		title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		title.add_theme_constant_override("shadow_offset_x", 2)
		title.add_theme_constant_override("shadow_offset_y", 2)
	
	# Style all panels
	style_panels()
	
	# Style buttons
	style_control_buttons()
	
	# Add crystal icon to score display
	var crystal_icon = create_crystal_icon()
	$LabLayout/TitleBar.add_child(crystal_icon)
	crystal_icon.global_position = score_label.global_position - Vector2(24, -2)

func create_crystal_icon():
	var icon = TextureRect.new()
	icon.texture = preload("res://assets/early_methaphetamine_batch.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(20, 20)
	icon.modulate = COLOR_BLUE_SKY
	
	# Add subtle rotation animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(icon, "rotation_degrees", 5, 2)
	tween.tween_property(icon, "rotation_degrees", -5, 2)
	
	return icon

func create_scanlines():
	var scanlines = ColorRect.new()
	scanlines.color = Color(1, 1, 1, 0.03)
	scanlines.material = create_scanlines_material()
	scanlines.anchor_right = 1.0
	scanlines.anchor_bottom = 1.0
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return scanlines

func create_scanlines_material():
	var shader_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	
	uniform float line_thickness : hint_range(0.0, 1.0) = 0.002;
	uniform float line_frequency : hint_range(0.0, 100.0) = 100.0;
	uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 0.3);
	
	void fragment() {
		float lines = abs(sin(UV.y * line_frequency)) < line_thickness ? 1.0 : 0.0;
		COLOR = mix(vec4(0.0), line_color, lines);
	}
	"""
	shader_material.shader = shader
	return shader_material

func style_panels():
	var panels = [
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel,
		$LabLayout/MainContent/LeftPanel/EquipmentPanel,
		$LabLayout/MainContent/MidPanel/ReactionPanel,
		$LabLayout/MainContent/MidPanel/ControlsPanel,
		$LabLayout/MainContent/RightPanel/MetricsPanel,
		$LabLayout/MainContent/RightPanel/RecipePanel,
		$LabLayout/LogPanel
	]
	
	for panel in panels:
		if panel:
			var style = StyleBoxFlat.new()
			style.bg_color = COLOR_PANEL
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = COLOR_PRIMARY
			style.corner_radius_top_left = 4
			style.corner_radius_top_right = 4
			style.corner_radius_bottom_right = 4
			style.corner_radius_bottom_left = 4
			panel.add_theme_stylebox_override("panel", style)

func style_control_buttons():
	var control_panel = $LabLayout/ControlPanel
	if control_panel:
		for child in control_panel.get_children():
			if child is Button:
				# Create button style
				var normal_style = StyleBoxFlat.new()
				normal_style.bg_color = COLOR_PANEL
				normal_style.border_width_left = 1
				normal_style.border_width_top = 1
				normal_style.border_width_right = 1
				normal_style.border_width_bottom = 1
				normal_style.border_color = COLOR_PRIMARY
				normal_style.corner_radius_top_left = 4
				normal_style.corner_radius_top_right = 4
				normal_style.corner_radius_bottom_right = 4
				normal_style.corner_radius_bottom_left = 4
				child.add_theme_stylebox_override("normal", normal_style)
				
				# Hover style
				var hover_style = normal_style.duplicate()
				hover_style.bg_color = COLOR_PANEL.lightened(0.1)
				child.add_theme_stylebox_override("hover", hover_style)
				
				# Pressed style
				var pressed_style = normal_style.duplicate()
				pressed_style.bg_color = COLOR_PANEL.darkened(0.1)
				child.add_theme_stylebox_override("pressed", pressed_style)
				
				# Text color
				child.add_theme_color_override("font_color", COLOR_TEXT)
				child.add_theme_color_override("font_hover_color", COLOR_TEXT.lightened(0.2))
				child.add_theme_font_size_override("font_size", 16)
				
				# Add glow effect
				var glow = ColorRect.new()
				glow.color = Color(0.0, 0.8, 0.3, 0.0)
				glow.size = child.size + Vector2(10, 10)
				glow.position = Vector2(-5, -5)
				glow.z_index = -1
				glow.name = "ButtonGlow"
				child.add_child(glow)
				
				# Add hover effect
				child.mouse_entered.connect(_on_control_button_mouse_entered.bind(child))
				child.mouse_exited.connect(_on_control_button_mouse_exited.bind(child))

func _on_control_button_mouse_entered(button):
	var tween = create_tween()
	tween.tween_property(button, "custom_minimum_size:y", 44, 0.2)
	
	if button.has_node("ButtonGlow"):
		var glow = button.get_node("ButtonGlow")
		tween.parallel().tween_property(glow, "modulate:a", 0.8, 0.3)

func _on_control_button_mouse_exited(button):
	var tween = create_tween()
	tween.tween_property(button, "custom_minimum_size:y", 40, 0.2)
	
	if button.has_node("ButtonGlow"):
		var glow = button.get_node("ButtonGlow")
		tween.parallel().tween_property(glow, "modulate:a", 0.0, 0.3)

func create_vignette_material():
	var shader_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	
	uniform float vignette_intensity = 0.4;
	uniform float vignette_opacity = 0.5;
	uniform vec4 vignette_rgb : source_color = vec4(0.0, 0.0, 0.0, 1.0);
	
	float vignette(vec2 uv){
		uv *= 1.0 - uv.xy;
		float vig = uv.x * uv.y * 15.0;
		return pow(vig, vignette_intensity);
	}
	
	void fragment() {
		vec4 color = vignette_rgb;
		color.a = 1.0 - vignette(UV);
		COLOR = vec4(color.rgb, color.a * vignette_opacity);
	}
	"""
	shader_material.shader = shader
	return shader_material

func adjust_ui_layout():
	# Make everything more compact
	var lab_layout = $LabLayout
	if lab_layout:
		lab_layout.add_theme_constant_override("separation", 10) # Reduced from 20
	
	# Make sure title bar has proper spacing but compact
	var title_bar = $LabLayout/TitleBar
	if title_bar:
		title_bar.add_theme_constant_override("separation", 20) # Reduced from 30
		title_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Organize title bar elements
		var labels = []
		for child in title_bar.get_children():
			if child is Label:
				labels.append(child)
				
		# Set consistent sizes for labels (reduced size)
		for label in labels:
			label.custom_minimum_size.x = 120 # Reduced from 140
			
	# Make chemical buttons more compact and pixel-art like
	var chemical_buttons_container = $LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons
	if chemical_buttons_container:
		chemical_buttons_container.add_theme_constant_override("separation", 4) # Reduced from 10
		
		for child in chemical_buttons_container.get_children():
			if child is Button:
				child.custom_minimum_size.y = 38 # Reduced from 50
	
	# Improve beaker display area - keep it large as focal point
	var reaction_display = $LabLayout/MainContent/MidPanel/ReactionPanel/VBoxContainer/ReactionContainer/ReactionDisplay
	if reaction_display:
		reaction_display.custom_minimum_size = Vector2(230, 230) # Slightly reduced
		
	# Make the recipe panel more compact
	var recipe_panel = $LabLayout/MainContent/RightPanel/RecipePanel
	if recipe_panel:
		recipe_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var recipe_text = $LabLayout/MainContent/RightPanel/RecipePanel/VBoxContainer/RecipeText
		if recipe_text:
			recipe_text.add_theme_constant_override("line_separation", 6) # Reduced from 10
	
	# Create better bottom controls layout
	var control_panel = $LabLayout/ControlPanel
	if control_panel:
		control_panel.add_theme_constant_override("separation", 20) # Reduced from 30
		control_panel.alignment = BoxContainer.ALIGNMENT_CENTER
		for child in control_panel.get_children():
			if child is Button:
				child.custom_minimum_size = Vector2(130, 36) # Smaller buttons
				
	# Make log panel smaller to save space
	var log_panel = $LabLayout/LogPanel
	if log_panel:
		log_panel.custom_minimum_size.y = 80 # Reduced from 100

func setup_game():
	# Reset game state
	chemicals_in_beaker.clear()
	recipe_complete = false
	time_remaining = 90.0 - (difficulty_level * 10)
	score = 0
	combo_multiplier = 1.0
	streak = 0
	shake_amount = 0.0
	
	# Update UI
	quality_label.text = "Quality: 0%"
	profit_label.text = "Profit: $0"
	score_label.text = "Score: 0"
	combo_label.text = "Combo: x1.0"
	
	# Set difficulty variations
	if difficulty_level > 1:
		# Shuffle the recipe for higher difficulties
		correct_recipe.shuffle()
		max_chemicals = 5 + difficulty_level
	
	update_recipe_display()

func _process(delta):
	time_elapsed += delta
	
	# Handle timer
	if timer_running:
		time_remaining -= delta
		if time_remaining <= 0:
			timer_running = false
			time_remaining = 0
			if not recipe_complete:
				fail_from_timeout()
		update_timer_display()
	
	# Make the beaker content bubble when chemicals are added
	if chemicals_in_beaker.size() > 0 and beaker:
		animate_beaker(delta)
	
	# Apply screen shake if active
	if shake_amount > 0:
		apply_screen_shake(delta)
	
	# Process visual effects
	process_visual_effects(delta)

func setup_chemical_buttons():
	# Find the container for our chemical buttons
	var buttons_container = $LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons
	
	if buttons_container:
		# Clear any existing buttons
		for child in buttons_container.get_children():
			child.queue_free()
			
		# Add a button for each chemical
		for chemical in get_all_chemicals():
			var button = Button.new()
			button.text = chemical
			button.custom_minimum_size.y = 38
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			# Set up dragging
			button.gui_input.connect(_on_chemical_gui_input.bind(chemical))
			
			# Style the button
			style_chemical_button(button, chemical)
			
			buttons_container.add_child(button)

func get_all_chemicals():
	return ["Pseudoephedrine", "Red Phosphorus", "Iodine", "Methylamine", "Aluminum"]

func style_chemical_button(button, chemical):
	var color = get_chemical_color(chemical)
	
	# Create stylebox
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = COLOR_PANEL
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = color
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.shadow_color = Color(0, 0, 0, 0.3)
	normal_style.shadow_size = 3
	normal_style.shadow_offset = Vector2(1, 1)
	button.add_theme_stylebox_override("normal", normal_style)
	
	# Hover style
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = COLOR_PANEL.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = COLOR_PANEL.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Font overrides
	var font = load("res://assets/Fonts/Oswald-Regular.ttf")
	
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_SUCCESS)

func create_chemical_icon(chemical_name, color):
	# Create custom 8-bit style icon
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Fill background transparent
	image.fill(Color(0, 0, 0, 0))
	
	# Choose the right icon pattern based on chemical name
	match chemical_name:
		"Pseudoephedrine":
			draw_pill_icon(image, color)
		"Red Phosphorus":
			draw_powder_icon(image, Color.RED)
		"Iodine":
			draw_crystal_icon(image, Color(0.5, 0.0, 0.5))
		"Methylamine":
			draw_liquid_icon(image, Color(0.0, 0.5, 0.5))
		"Aluminum":
			draw_metal_icon(image, Color(0.7, 0.7, 0.7))
		_:
			# Default to a simple square if no pattern matches
			for y in range(8, 24):
				for x in range(8, 24):
					image.set_pixel(x, y, color)
	
	# Create texture from image
	var texture = ImageTexture.create_from_image(image)
	return texture

func draw_pill_icon(image, color):
	# Draw a pill capsule shape
	var center_x = 16
	var center_y = 16
	var width = 12
	var height = 20
	
	# Draw oval pill
	for y in range(center_y - height/2, center_y + height/2):
		for x in range(center_x - width/2, center_x + width/2):
			var dx = (x - center_x) / float(width/2)
			var dy = (y - center_y) / float(height/2)
			if dx*dx + dy*dy <= 1.0:
				image.set_pixel(x, y, color)
	
	# Add line across middle in darker color
	var line_color = color.darkened(0.3)
	for y in range(center_y - 2, center_y + 2):
		for x in range(center_x - width/2, center_x + width/2):
			var dx = (x - center_x) / float(width/2)
			var dy = (y - center_y) / float(height/2)
			if dx*dx + dy*dy <= 1.0:
				image.set_pixel(x, y, line_color)

func draw_powder_icon(image, color):
	# Draw powder as small particles
	for i in range(40):
		var x = randi() % 24 + 4
		var y = randi() % 24 + 4
		image.set_pixel(x, y, color)
		
		# Some pixels have a small cluster
		if randf() < 0.5:
			if x < 31: image.set_pixel(x+1, y, color)
			if x > 0: image.set_pixel(x-1, y, color)
			if y < 31: image.set_pixel(x, y+1, color)
			if y > 0: image.set_pixel(x, y-1, color)

func draw_crystal_icon(image, color):
	# Draw crystal shape
	var center_x = 16
	var center_y = 16
	
	# Main crystal body
	for y in range(8, 24):
		var width = 16 - abs(y - 16)
		for x in range(center_x - width, center_x + width):
			image.set_pixel(x, y, color)
	
	# Highlight
	var highlight = color.lightened(0.3)
	for y in range(8, 20):
		var width = 3
		for x in range(center_x - width, center_x):
			if x >= center_x - (16 - abs(y - 16)):
				image.set_pixel(x, y, highlight)

func draw_liquid_icon(image, color):
	# Draw a flask with liquid
	var center_x = 16
	var center_y = 16
	
	# Flask shape
	var flask_color = Color(0.8, 0.8, 0.8, 0.5)
	for y in range(10, 24):
		var width = 5 + int((y - 10) / 2.0)
		if width > 10: width = 10
		for x in range(center_x - width, center_x + width):
			image.set_pixel(x, y, flask_color)
	
	# Liquid inside
	for y in range(16, 24):
		var width = 5 + int((y - 10) / 2.0) - 1
		if width > 9: width = 9
		for x in range(center_x - width, center_x + width):
			image.set_pixel(x, y, color)
	
	# Flask neck
	for y in range(5, 10):
		for x in range(center_x - 2, center_x + 3):
			image.set_pixel(x, y, flask_color)

func draw_metal_icon(image, color):
	# Draw metal foil or sheet
	for y in range(8, 24):
		for x in range(8, 24):
			image.set_pixel(x, y, color)
	
	# Add shine lines
	var shine = color.lightened(0.3)
	for i in range(4):
		var y = 10 + i * 3
		for x in range(10, 22):
			image.set_pixel(x, y, shine)

func create_drag_ghost(chemical_name):
	if drag_ghost != null:
		drag_ghost.queue_free()
		
	drag_ghost = Panel.new()
	
	# Create a style for the ghost
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.09, 0.09, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = get_chemical_color(chemical_name)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 2)
	drag_ghost.add_theme_stylebox_override("panel", style)
	
	# Set size
	drag_ghost.custom_minimum_size = Vector2(150, 45)
	
	# Add label
	var label = Label.new()
	label.text = chemical_name
	label.position = Vector2(10, 10)
	
	# Set Oswald font
	var font = load("res://assets/Fonts/Oswald-Regular.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	
	drag_ghost.add_child(label)
	
	# Add to scene and position at cursor
	add_child(drag_ghost)
	drag_ghost.global_position = drag_start_position - drag_ghost.size / 2
	
	# Store reference to the drag ghost
	
	return drag_ghost

func _on_chemical_gui_input(event, chemical):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drag
				dragging_chemical = true
				dragged_chemical_name = chemical
				drag_start_position = event.global_position
				create_drag_ghost(chemical)
			elif dragging_chemical and dragged_chemical_name == chemical:
				# End drag
				if can_drop and chemicals_in_beaker.size() < max_chemicals and not recipe_complete and timer_running:
					add_chemical_to_beaker(chemical)
				clean_up_drag()
	
	elif event is InputEventMouseMotion and dragging_chemical and dragged_chemical_name == chemical:
		update_drag_position(event.global_position)

func update_drag_position(position):
	if not drag_ghost:
		return
	
	drag_ghost.global_position = position - drag_ghost.size / 2
	
	# Check if we're over the beaker
	if beaker:
		var beaker_rect = Rect2(beaker.global_position, beaker.size)
		can_drop = beaker_rect.has_point(position)

func clean_up_drag():
	dragging_chemical = false
	dragged_chemical_name = ""
	can_drop = false
	
	if drag_ghost:
		drag_ghost.queue_free()
		drag_ghost = null

func add_chemical_to_beaker(chemical_name):
	chemicals_in_beaker.append(chemical_name)
	log_message("Added " + chemical_name + " to the beaker.")
	update_recipe_display()
	
	# Visual feedback with enhanced particle effects
	flash_beaker_color(get_chemical_color(chemical_name))
	spawn_particles(beaker.global_position + Vector2(beaker.size.x/2, beaker.size.y/2), 10)
	spawn_chemical_splash_effect(get_chemical_color(chemical_name))
	
	# Update streak and combo
	if chemicals_in_beaker.size() <= correct_recipe.size() and chemicals_in_beaker[chemicals_in_beaker.size() - 1] == correct_recipe[chemicals_in_beaker.size() - 1]:
		streak += 1
		combo_multiplier = min(3.0, 1.0 + (streak * 0.2))
		update_combo_display()
	else:
		streak = 0
		combo_multiplier = 1.0
		update_combo_display()
		shake_screen(0.5)
	
	# Check if we've added all chemicals
	if chemicals_in_beaker.size() == correct_recipe.size():
		check_recipe()

func get_chemical_color(chemical_name):
	match chemical_name:
		"Pseudoephedrine": return Color(0.9, 0.2, 0.2)
		"Red Phosphorus": return Color(0.8, 0.1, 0.1)
		"Iodine": return Color(0.5, 0.2, 0.5)
		"Methylamine": return Color(0.2, 0.4, 0.8)
		"Aluminum": return Color(0.7, 0.7, 0.7)
		_: return Color(0.5, 0.5, 0.5)

func flash_beaker_color(color):
	if not beaker:
		return
	
	var flash = ColorRect.new()
	flash.color = color
	flash.color.a = 0.5
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.size = beaker.size
	
	beaker.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

func update_recipe_display():
	if recipe_text:
		var text = "CORRECT RECIPE:\n"
		
		for i in range(correct_recipe.size()):
			var chemical = correct_recipe[i]
			var checked = ""
			
			if i < chemicals_in_beaker.size():
				if chemicals_in_beaker[i] == chemical:
					checked = " ✓"
				else:
					checked = " ✗"
			
			text += str(i+1) + ". " + chemical + checked + "\n"
		
		recipe_text.text = text
		
		# Indicate current step in log
		var current_step = chemicals_in_beaker.size()
		if current_step < correct_recipe.size() and not recipe_complete:
			if current_step == 0:
				log_message("Start with " + correct_recipe[0])
			else:
				log_message("Next: Add " + correct_recipe[current_step])

func animate_beaker(delta):
	var blue_intensity = min(1.0, float(chemicals_in_beaker.size()) / correct_recipe.size())
	var color = Color(0.1, 0.3 + blue_intensity * 0.5, 0.8, 0.8)
	
	# Create bubbles randomly
	if randf() < 0.05 * chemicals_in_beaker.size():
		create_bubble()

func create_bubble():
	var bubble_scene = load("res://UI/Scenes/MethLab/Bubble.tscn")
	if bubble_scene and beaker:
		var bubble = bubble_scene.instantiate()
		beaker.add_child(bubble)
		
		# Position randomly within beaker
		var x_pos = randf_range(10, beaker.size.x - 10)
		var y_pos = randf_range(beaker.size.y - 20, beaker.size.y - 5)
		bubble.position = Vector2(x_pos, y_pos)
		
		# Random size and color variation for more realistic effect
		var bubble_size = randf_range(3, 7)
		bubble.scale = Vector2(bubble_size, bubble_size)
		
		# Vary bubble color based on chemicals
		var blue_intensity = min(1.0, float(chemicals_in_beaker.size()) / correct_recipe.size())
		var color_variation = randf_range(-0.1, 0.1)
		var bubble_color = Color(
			0.1 + color_variation,
			0.3 + blue_intensity * 0.5 + color_variation,
			0.8 + color_variation,
			0.7
		)
		bubble.modulate = bubble_color

func check_recipe():
	var correct_count = 0
	var quality = 0.0
	
	for i in range(correct_recipe.size()):
		if i < chemicals_in_beaker.size() and chemicals_in_beaker[i] == correct_recipe[i]:
			correct_count += 1
	
	quality = float(correct_count) / correct_recipe.size()
	var profit = int(quality * 10000)
	
	# Calculate score with time bonus and combo multiplier
	var time_bonus = int(time_remaining * 10)
	score = int((profit + time_bonus) * combo_multiplier)
	
	recipe_complete = true
	timer_running = false
	
	# Check achievements
	if not achievements["first_attempt"]:
		achievements["first_attempt"] = true
		show_achievement("First Attempt", "Completed your first batch")
	
	if quality >= 1.0:
		achievements["perfect_batch"] = true
		show_achievement("Perfect Batch", "Created a 100% pure batch")
	
	if time_remaining > 60:
		achievements["speed_cook"] = true
		show_achievement("Speed Cook", "Finished with more than 60 seconds left")
	
	if quality >= 0.8:
		log_message("SUCCESS! You made high-quality Blue Sky.")
		log_message("Score: " + str(score) + " (Profit: $" + str(profit) + " + Time Bonus: " + str(time_bonus) + " x" + str(combo_multiplier) + " Combo)")
		unlock_next_difficulty()
	elif quality >= 0.5:
		log_message("Mixed results. The product is mediocre quality.")
		log_message("Score: " + str(score) + " (Profit: $" + str(profit) + " + Time Bonus: " + str(time_bonus) + " x" + str(combo_multiplier) + " Combo)")
	else:
		log_message("FAILURE! The chemicals were mixed incorrectly.")
	
	quality_label.text = "Quality: %d%%" % int(quality * 100)
	profit_label.text = "Profit: $%d" % profit
	score_label.text = "Score: %d" % score
	
	SignalBus.emit_signal("meth_lab_completed", quality, profit)

func fail_from_timeout():
	recipe_complete = true
	log_message("OUT OF TIME! The batch is ruined.")
	show_failure_animation()
	shake_screen(1.0)

func shake_screen(intensity):
	shake_amount = intensity

func apply_screen_shake(delta):
	if shake_amount <= 0:
		position = Vector2.ZERO
		return
		
	var shake_offset = Vector2(
		randf_range(-shake_amount, shake_amount) * 10, 
		randf_range(-shake_amount, shake_amount) * 10
	)
	
	position = shake_offset
	shake_amount = max(0, shake_amount - delta * 2)
	
	if shake_amount <= 0:
		position = Vector2.ZERO

func unlock_next_difficulty():
	difficulty_level = min(3, difficulty_level + 1)
	log_message("New difficulty level unlocked! Level " + str(difficulty_level))

func show_success_animation():
	# Create pulsing highlight around beaker
	var highlight = ColorRect.new()
	highlight.color = Color(0.3, 0.9, 0.5, 0.0)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if beaker:
		beaker.add_child(highlight)
		highlight.size = beaker.size + Vector2(20, 20)
		highlight.position = Vector2(-10, -10)
		
		var tween = create_tween()
		tween.tween_property(highlight, "color", Color(0.3, 0.9, 0.5, 0.3), 0.5)
		tween.tween_property(highlight, "color", Color(0.3, 0.9, 0.5, 0.0), 0.5)
		tween.tween_property(highlight, "color", Color(0.3, 0.9, 0.5, 0.3), 0.5)
		tween.tween_property(highlight, "color", Color(0.3, 0.9, 0.5, 0.0), 0.5)
	
	# Create floating blue crystals
	spawn_crystals(10)

func show_partial_success_animation():
	var highlight = ColorRect.new()
	highlight.color = Color(0.9, 0.9, 0.2, 0.0)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if beaker:
		beaker.add_child(highlight)
		highlight.size = beaker.size + Vector2(20, 20)
		highlight.position = Vector2(-10, -10)
		
		var tween = create_tween()
		tween.tween_property(highlight, "color", Color(0.9, 0.9, 0.2, 0.3), 0.5)
		tween.tween_property(highlight, "color", Color(0.9, 0.9, 0.2, 0.0), 0.5)
	
	# Create some crystal particles
	spawn_crystals(5)

func show_failure_animation():
	# Red flash for failed reaction
	var flash = ColorRect.new()
	flash.color = Color(0.9, 0.3, 0.2, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.size = size
	
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color", Color(0.9, 0.3, 0.2, 0.3), 0.2)
	tween.tween_property(flash, "color", Color(0.9, 0.3, 0.2, 0.0), 0.5)
	
	await tween.finished
	flash.queue_free()

func spawn_particles(position, count):
	for i in range(count):
		var particle = ColorRect.new()
		particle.color = Color(0.9, 0.9, 0.9, 0.8)
		particle.size = Vector2(3, 3)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.position = position
		
		add_child(particle)
		
		var lifetime = randf_range(0.5, 1.5)
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 0))
		var speed = randf_range(20, 50)
		
		visual_effects.append({
			"node": particle,
			"type": "particle",
			"velocity": direction.normalized() * speed,
			"lifetime": lifetime,
			"current_time": 0
		})

func spawn_crystals(count):
	var crystal_texture = load("res://assets/early_methaphetamine_batch.png")
	if not crystal_texture:
		return
		
	for i in range(count):
		var crystal = TextureRect.new()
		crystal.texture = crystal_texture
		crystal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crystal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crystal.size = Vector2(20, 20)
		crystal.modulate = COLOR_BLUE_SKY
		crystal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if beaker:
			crystal.position = beaker.global_position + Vector2(randf_range(0, beaker.size.x), beaker.size.y / 2)
		else:
			crystal.position = Vector2(size.x / 2, size.y / 2)
			
		add_child(crystal)
		
		var lifetime = randf_range(1.5, 3.0)
		var direction = Vector2(randf_range(-1, 1), randf_range(-2, -1))
		var rotation_speed = randf_range(-2, 2)
		
		visual_effects.append({
			"node": crystal,
			"type": "crystal",
			"velocity": direction.normalized() * randf_range(50, 100),
			"lifetime": lifetime,
			"current_time": 0,
			"rotation_speed": rotation_speed
		})

func process_visual_effects(delta):
	var i = 0
	while i < visual_effects.size():
		var effect = visual_effects[i]
		effect.current_time += delta
		
		if effect.current_time >= effect.lifetime:
			effect.node.queue_free()
			visual_effects.remove_at(i)
			continue
			
		# Update position
		effect.node.position += effect.velocity * delta
		
		# Update alpha for fade out
		var alpha = 1.0 - (effect.current_time / effect.lifetime)
		effect.node.modulate.a = alpha
		
		# For crystal effects, also rotate them
		if effect.type == "crystal":
			effect.node.rotation += effect.rotation_speed * delta
			effect.velocity.y += 50 * delta  # Add gravity
		
		i += 1

func apply_pulse_effect(chemical):
	var button = null
	
	# Find the button for this chemical
	var buttons_container = $LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons
	for child in buttons_container.get_children():
		if child is Button and child.text == chemical:
			button = child
			break
	
	if button:
		var tween = create_tween()
		tween.tween_property(button, "modulate", Color(1.5, 1.5, 1.5), 0.1)
		tween.tween_property(button, "modulate", Color(1, 1, 1), 0.1)

func update_timer_display():
	if timer_label:
		var minutes = floor(time_remaining / 60)
		var seconds = int(time_remaining) % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]
		
		# Change color when time is running low
		if time_remaining <= 10:
			timer_label.add_theme_color_override("font_color", COLOR_ERROR)
		elif time_remaining <= 30:
			timer_label.add_theme_color_override("font_color", COLOR_WARNING)
		else:
			timer_label.add_theme_color_override("font_color", COLOR_TEXT)

func update_combo_display():
	if combo_label:
		combo_label.text = "Combo: x%.1f" % combo_multiplier
		
		if combo_multiplier > 2.0:
			combo_label.add_theme_color_override("font_color", COLOR_SUCCESS)
		elif combo_multiplier > 1.0:
			combo_label.add_theme_color_override("font_color", COLOR_WARNING)
		else:
			combo_label.add_theme_color_override("font_color", COLOR_TEXT)

func show_achievement(title, description):
	var achievement_popup = PanelContainer.new()
	
	# Create a pixelated, Breaking Bad styled panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.7, 0.3, 0.8)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 6
	style.shadow_offset = Vector2(3, 3)
	
	achievement_popup.add_theme_stylebox_override("panel", style)
	achievement_popup.size = Vector2(280, 70) # More compact
	achievement_popup.position = Vector2(size.x, 20)
	achievement_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4) # More compact spacing
	achievement_popup.add_child(vbox)
	
	# Add achievement icon
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8) # More compact
	vbox.add_child(hbox)
	
	var icon = TextureRect.new()
	icon.texture = preload("res://assets/early_methaphetamine_batch.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 32) # Smaller icon
	icon.modulate = COLOR_BLUE_SKY
	hbox.add_child(icon)
	
	# Create a spinning animation for the crystal
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(icon, "rotation_degrees", 360, 3)
	
	# Title and description in vertical layout
	var text_vbox = VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 2) # More compact
	hbox.add_child(text_vbox)
	
	var title_label = Label.new()
	title_label.text = title.to_upper()
	title_label.add_theme_color_override("font_color", Color(0.0, 0.9, 0.4))
	title_label.add_theme_font_size_override("font_size", 14) # Smaller font
	text_vbox.add_child(title_label)
	
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 12) # Smaller font
	text_vbox.add_child(desc_label)
	
	add_child(achievement_popup)
	
	# Slide in from right with bounce effect
	var slide_tween = create_tween()
	slide_tween.tween_property(achievement_popup, "position:x", size.x - achievement_popup.size.x - 20, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Add glow effect that pulses
	var glow = ColorRect.new()
	glow.color = Color(0.0, 0.7, 0.3, 0.0)
	glow.size = achievement_popup.size + Vector2(10, 10)
	glow.position = Vector2(-5, -5)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	achievement_popup.add_child(glow)
	
	var glow_tween = create_tween()
	glow_tween.set_loops(2)
	glow_tween.tween_property(glow, "color:a", 0.2, 0.5)
	glow_tween.tween_property(glow, "color:a", 0.0, 0.5)
	
	# Wait then slide out
	slide_tween.tween_interval(2.5) # Shorter display time
	slide_tween.tween_property(achievement_popup, "position:x", size.x + 50, 0.5).set_ease(Tween.EASE_IN)
	slide_tween.tween_callback(achievement_popup.queue_free)
	
	# Add particles for flair - more compact
	var particles = create_particle_effect(achievement_popup.position + Vector2(140, 35), COLOR_SUCCESS)
	add_child(particles)
	particles.emitting = true

func create_particle_effect(pos, color):
	var particles = CPUParticles2D.new()
	particles.position = pos
	particles.amount = 20
	particles.lifetime = 1.0
	particles.explosiveness = 0.8
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.gravity = Vector2(0, 80)
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	particles.color = color
	return particles

func get_stylebox_from_theme(name):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.6, 0.3, 0.6)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	style.shadow_offset = Vector2(2, 2)
	return style

func log_message(msg):
	if log_text:
		log_text.text += "\n> " + msg

func _on_reset_button_pressed():
	setup_game()
	log_message("Beaker cleared. Start again.")

func _on_quit_button_pressed():
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").change_scene("res://Levels/RideWithHank/ride_with_hank.tscn")
	else:
		get_tree().change_scene_to_file("res://Levels/RideWithHank/ride_with_hank.tscn")

func _on_next_level_button_pressed():
	setup_game()
	log_message("Starting difficulty level " + str(difficulty_level))
	timer_running = true

func _on_beaker_button_pressed():
	log_message("Using beaker...")

func _on_hot_plate_button_pressed():
	log_message("Adjusting hot plate...")

func _on_filter_button_pressed():
	log_message("Using filter...")

func _on_centrifuge_button_pressed():
	log_message("Using centrifuge...")

func _on_start_button_pressed():
	if not timer_running and not recipe_complete:
		timer_running = true
		log_message("Process started!")

func _on_stop_button_pressed():
	if timer_running:
		timer_running = false
		log_message("Process stopped!")

func create_noise_filter():
	var noise = ColorRect.new()
	noise.color = Color(1, 1, 1, 1)
	noise.material = create_noise_material()
	noise.anchor_right = 1.0
	noise.anchor_bottom = 1.0
	noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return noise

func create_noise_material():
	var shader_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	
	uniform float noise_amount : hint_range(0.0, 1.0) = 0.04;
	uniform float flicker_speed : hint_range(0.0, 10.0) = 5.0;
	
	float random(vec2 uv) {
		return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
	}
	
	void fragment() {
		float noise = random(UV + vec2(TIME * flicker_speed, 0.0));
		vec4 noise_color = vec4(noise, noise, noise, 1.0) * noise_amount;
		COLOR = noise_color;
	}
	"""
	shader_material.shader = shader
	return shader_material

func spawn_chemical_splash_effect(color):
	if not beaker:
		return
		
	# Create parent node for all particles
	var splash_container = Node2D.new()
	beaker.add_child(splash_container)
	splash_container.position = Vector2(beaker.size.x/2, beaker.size.y/2)
	
	# Create multiple particles
	for i in range(15):
		var particle = ColorRect.new()
		particle.color = color
		particle.color.a = 0.8
		
		# Random size for particles
		var size = randf_range(2, 6)
		particle.size = Vector2(size, size)
		
		# Random initial position within beaker
		var pos_x = randf_range(-beaker.size.x/3, beaker.size.x/3)
		var pos_y = randf_range(-10, 10)
		particle.position = Vector2(pos_x, pos_y)
		
		splash_container.add_child(particle)
		
		# Create animation
		var tween = create_tween()
		
		# Initial upward motion
		var target_y = randf_range(-30, -10)
		var target_x = particle.position.x + randf_range(-20, 20)
		tween.tween_property(particle, "position", Vector2(target_x, target_y), 0.3)
		
		# Then fall back down
		target_y = randf_range(20, 40)
		target_x = particle.position.x + randf_range(-15, 15)
		tween.tween_property(particle, "position", Vector2(target_x, target_y), 0.5)
		
		# Fade out
		tween.parallel().tween_property(particle, "color:a", 0.0, 0.5)
		
		# Cleanup when done
		tween.tween_callback(particle.queue_free)
	
	# Remove container after all particles are done
	var container_tween = create_tween()
	container_tween.tween_interval(1.0)
	container_tween.tween_callback(splash_container.queue_free)
