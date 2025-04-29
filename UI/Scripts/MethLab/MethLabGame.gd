@tool
extends Control

# Game variables
var chemicals = []
var selected_method = ""
var heat_level = 100
var purity = 0
var result_created = false
var max_chemicals = 5
var current_view = 1  # 0=left, 1=center, 2=right

# View control
enum View {LEFT, CENTER, RIGHT}

# Optimal recipes
var optimal_recipes = {
	"Phosphorus Method": ["Pseudoephedrine", "Red Phosphorus", "Hydriodic Acid"],
	"Mercury Method": ["Pseudoephedrine", "Aluminum", "Mercury"],
	"Birch Reduction": ["Pseudoephedrine", "Lithium", "Ammonia"],
	"Blue Sky Method": ["Methylamine", "Phenylacetic Acid", "Aluminum"]
}

# Optimal heat levels
var optimal_heat = {
	"Phosphorus Method": 115,
	"Mercury Method": 110,
	"Birch Reduction": 90,
	"Blue Sky Method": 135
}

# Node references
@onready var console = $MainContainer/RightPanel/ConsolePanel/ConsoleText
@onready var method_buttons = $MainContainer/LeftPanel/MethodsPanel/Methods.get_children()
@onready var chemical_nodes = [] # Will be populated in fix_layout()
@onready var beaker = $MainContainer/MiddlePanel/BeakerPanel/Beaker
@onready var heat_slider = $MainContainer/MiddlePanel/HeatPanel/HeatSlider
@onready var heat_value = $MainContainer/MiddlePanel/HeatPanel/HeatValue
@onready var purity_label = $MainContainer/RightPanel/ResultPanel/PurityLabel
@onready var purity_bar = $MainContainer/RightPanel/ResultPanel/PurityBar
@onready var title_label = $MainContainer/Header/Title
@onready var chemical_list = $MainContainer/MiddlePanel/BeakerPanel/ChemicalList
@onready var main_container = $MainContainer
@onready var left_panel = $MainContainer/LeftPanel
@onready var middle_panel = $MainContainer/MiddlePanel
@onready var right_panel = $MainContainer/RightPanel
@onready var left_button = $NavButtons/LeftButton
@onready var right_button = $NavButtons/RightButton
@onready var view_indicator = $NavButtons/ViewIndicator
@onready var chemicals_container = $MainContainer/LeftPanel/ChemicalsPanel/ChemicalsContainer

# UI colors - Modern dark theme with blue accents
const COLOR_BG_DARK = Color("#0A0E14")
const COLOR_BG_PANEL = Color("#141A24")
const COLOR_PRIMARY = Color("#007AFF")
const COLOR_PRIMARY_DARK = Color("#0055CC")
const COLOR_SECONDARY = Color("#5AC8FA")
const COLOR_ACCENT = Color("#FF9500")
const COLOR_SUCCESS = Color("#34C759")
const COLOR_WARNING = Color("#FFCC00")
const COLOR_ERROR = Color("#FF3B30")
const COLOR_TEXT = Color("#FFFFFF")
const COLOR_TEXT_SECONDARY = Color("#AAAAAA")
const COLOR_BORDER = Color("#2C3E50")

# For animations
var time_elapsed = 0.0

# Swipe detector for mobile navigation
var swipe_detector = SwipeDetector.new()

# Dragging variables
var dragging = false
var drag_chemical = null
var drag_start_pos = Vector2()
var drag_original_pos = Vector2()
var drag_original_parent = null

func _ready():
	if Engine.is_editor_hint():
		return
		
	randomize()
	setup_navigation()
	fix_layout()
	enhance_ui()
	initialize_ui()
	heat_slider.value = heat_level
	update_heat_display()
	add_console_message("Welcome to the lab. Select a synthesis method and add chemicals.")
	add_console_message("Need at least three chemicals to synthesize.")
	animate_intro()
	
	# Start with the center view
	set_view(View.CENTER)

func _process(delta):
	time_elapsed += delta
	
	# Subtle breathing effect for title
	title_label.modulate = Color(1, 1, 1, 0.8 + sin(time_elapsed * 1.5) * 0.2)
	
	# Subtle effect for beaker when chemicals are present
	if chemicals.size() > 0:
		var beaker_color = beaker.get_node("ColorRect").color
		beaker_color.a = 0.7 + sin(time_elapsed * 2) * 0.1
		beaker.get_node("ColorRect").color = beaker_color

func setup_navigation():
	left_button.pressed.connect(navigate_left)
	right_button.pressed.connect(navigate_right)
	update_navigation_buttons()
	
	# Set up swipe detection
	swipe_detector.set_target(self)
	add_child(swipe_detector)

func navigate_left():
	if current_view > View.LEFT:
		set_view(current_view - 1)
	else:
		# Optionally wrap around
		set_view(View.RIGHT)

func navigate_right():
	if current_view < View.RIGHT:
		set_view(current_view + 1)
	else:
		# Optionally wrap around
		set_view(View.LEFT)

func set_view(view):
	current_view = view
	
	# Hide all panels first
	left_panel.visible = false
	middle_panel.visible = false
	right_panel.visible = false
	
	# Show only the current panel
	match view:
		View.LEFT:
			left_panel.visible = true
			view_indicator.text = "Methods & Chemicals (< >)"
		View.CENTER:
			middle_panel.visible = true
			view_indicator.text = "Synthesis Lab (< >)"
		View.RIGHT:
			right_panel.visible = true
			view_indicator.text = "Results & Console (< >)"
	
	update_navigation_buttons()

func update_navigation_buttons():
	# Update button states based on current view
	left_button.disabled = current_view == View.LEFT
	right_button.disabled = current_view == View.RIGHT
	
	# Visually indicate which panel is active
	left_button.modulate.a = 0.5 if current_view == View.LEFT else 1.0
	right_button.modulate.a = 0.5 if current_view == View.RIGHT else 1.0

func fix_layout():
	# Ensure main container has correct margins
	main_container.custom_minimum_size.y = get_viewport_rect().size.y - 150
	
	# Set up the chemicals in a grid
	var chemicals_panel = $MainContainer/LeftPanel/ChemicalsPanel
	var chemicals_container = $MainContainer/LeftPanel/ChemicalsPanel/ChemicalsContainer
	
	# Collect all chemical nodes
	for child in chemicals_panel.get_children():
		if child is ColorRect and child.name != "ChemicalsContainer" and child.name != "Label":
			chemical_nodes.append(child)
	
	# Make buttons more visible
	left_button.modulate.a = 0.8
	right_button.modulate.a = 0.8

func enhance_ui():
	# Apply modern styling to all UI elements
	apply_style_to_buttons()
	apply_style_to_panels()
	
	# Apply style to slider
	heat_slider.add_theme_color_override("slider_highlight_color", COLOR_ACCENT)
	
	# Apply style to beaker
	var beaker_rect = beaker.get_node("ColorRect")
	beaker_rect.color = COLOR_PRIMARY.darkened(0.7)
	beaker_rect.color.a = 0.5

func apply_style_to_buttons():
	# Get all buttons in the scene
	var buttons = find_all_nodes_of_type(self, Button)
	for button in buttons:
		apply_style_to_button(button)

func apply_style_to_panels():
	# Get all panels in the scene
	var panels = find_all_nodes_of_type(self, PanelContainer)
	for panel in panels:
		apply_style_to_panel(panel)

# Helper function to find all nodes of a specific type using class name
func find_all_nodes_of_type(node, node_class_name):
	var result = []
	if node.get_class() == node_class_name:
		result.append(node)
	
	for child in node.get_children():
		result.append_array(find_all_nodes_of_type(child, node_class_name))
	
	return result

func apply_style_to_button(button):
	# Create button styles
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = COLOR_PRIMARY
	normal_style.border_width_bottom = 4
	normal_style.border_color = COLOR_SECONDARY
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = COLOR_PRIMARY.lightened(0.1)
	hover_style.border_color = COLOR_ACCENT
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = COLOR_PRIMARY.darkened(0.1)
	pressed_style.border_width_bottom = 2
	pressed_style.border_width_top = 2
	
	# Apply styles
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_ACCENT)
	
	# Add hover animation
	button.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	)
	
	button.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	)

func apply_style_to_panel(panel):
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PRIMARY.darkened(0.1)
	panel_style.border_width_all = 1
	panel_style.border_color = COLOR_SECONDARY.darkened(0.3)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	
	panel.add_theme_stylebox_override("panel", panel_style)

func initialize_ui():
	# Initialize method buttons
	for button in method_buttons:
		if button is Button:
			button.pressed.connect(_on_method_selected.bind(button.text))
	
	# Initialize action buttons
	$MainContainer/MiddlePanel/ButtonsPanel/MixButton.pressed.connect(_on_mix_pressed)
	$MainContainer/MiddlePanel/ButtonsPanel/CookButton.pressed.connect(_on_cook_pressed)
	$MainContainer/MiddlePanel/ButtonsPanel/ClearButton.pressed.connect(_on_clear_pressed)
	
	# Initialize heat slider
	heat_slider.value_changed.connect(_on_heat_slider_changed)
	
	# Initialize chemical buttons
	setup_chemical_buttons()
	
	# Initialize quit button
	$MainContainer/RightPanel/ButtonsPanel/QuitButton.pressed.connect(_on_quit_pressed)

func animate_intro():
	# Fade in header
	title_label.modulate.a = 0
	var header_tween = create_tween()
	header_tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
	
	# Slide in panels
	left_panel.position.x = -left_panel.size.x
	right_panel.position.x = right_panel.size.x
	
	var left_tween = create_tween()
	left_tween.tween_property(left_panel, "position:x", 0, 0.5).set_ease(Tween.EASE_OUT)
	
	var right_tween = create_tween()
	right_tween.tween_property(right_panel, "position:x", 0, 0.5).set_ease(Tween.EASE_OUT)

func setup_chemical_buttons():
	# Find the chemicals container
	var chemicals_panel = $MainContainer/LeftPanel/ChemicalsPanel
	var chemical_container = chemicals_panel.get_node("ChemicalsContainer")
	
	# Setup each chemical
	for child in chemical_container.get_children():
		if child is ColorRect:
			var chemical = child
			
			# Store original position and size in metadata for dragging
			chemical.set_meta("original_pos", chemical.position)
			chemical.set_meta("original_size", chemical.size)
			
			# Make sure it has the right size and is visible
			chemical.custom_minimum_size = Vector2(80, 30)
			
			# Add hover effects
			chemical.mouse_entered.connect(func():
				var tween = create_tween()
				tween.tween_property(chemical, "scale", Vector2(1.1, 1.1), 0.2)
				tween.parallel().tween_property(chemical, "modulate", Color(1.2, 1.2, 1.2), 0.2)
			)
			
			chemical.mouse_exited.connect(func():
				var tween = create_tween()
				tween.tween_property(chemical, "scale", Vector2(1.0, 1.0), 0.2)
				tween.parallel().tween_property(chemical, "modulate", Color(1.0, 1.0, 1.0), 0.2)
			)
			
			# Make it clickable
			chemical.gui_input.connect(func(event):
				if event is InputEventMouseButton:
					if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
						# Scale effect when clicked
						var tween = create_tween()
						tween.tween_property(chemical, "scale", Vector2(0.9, 0.9), 0.1)
						tween.tween_property(chemical, "scale", Vector2(1.0, 1.0), 0.1)
						
						# Add the chemical
						_on_add_chemical_pressed(chemical.get_node("Label").text)
			)
			
			# Make sure the text is visible and centered
			var label = chemical.get_node("Label")
			if label:
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.add_theme_font_size_override("font_size", 14)
				label.add_theme_color_override("font_color", Color.BLACK)

func _on_method_selected(method_name):
	selected_method = method_name
	add_console_message("Selected method: " + method_name)
	
	# Update UI to show selected method
	for button in method_buttons:
		if button is Button:
			if button.text == method_name:
				button.add_theme_color_override("font_color", COLOR_ACCENT)
			else:
				button.add_theme_color_override("font_color", COLOR_TEXT)

func _on_add_chemical_pressed(chemical_name):
	if chemicals.size() < max_chemicals:
		chemicals.append(chemical_name)
		add_console_message("Added " + chemical_name)
		update_interface()
	else:
		add_console_message("Beaker full! Clear it first.")

func _on_mix_pressed():
	if chemicals.size() > 0:
		add_console_message("Mixing chemicals...")
		create_bubbles(5)
		update_interface()
	else:
		add_console_message("No chemicals to mix!")

func _on_cook_pressed():
	if chemicals.size() < 3:
		add_console_message("Need at least three chemicals!")
		return
	
	if selected_method == "":
		add_console_message("Select a synthesis method first!")
		return
	
	add_console_message("Cooking with " + selected_method + " method...")
	add_console_message("Heat level: " + str(heat_level) + "°C")
	
	# Start the synthesis process
	synthesize()

func _on_clear_pressed():
	chemicals.clear()
	result_created = false
	purity = 0
	update_interface()
	add_console_message("Beaker cleared.")

func _on_heat_slider_changed(value):
	heat_level = value
	update_heat_display()

func update_heat_display():
	heat_value.text = str(heat_level) + "°C"
	
	# Change color based on heat level
	if heat_level < 100:
		heat_value.add_theme_color_override("font_color", COLOR_SECONDARY)
	elif heat_level < 150:
		heat_value.add_theme_color_override("font_color", COLOR_ACCENT)
	else:
		heat_value.add_theme_color_override("font_color", COLOR_ERROR)

func update_interface():
	# Update chemical list
	if chemicals.size() > 0:
		chemical_list.text = ""
		for i in range(chemicals.size()):
			chemical_list.text += chemicals[i]
			if i < chemicals.size() - 1:
				chemical_list.text += "\n"
	else:
		chemical_list.text = "No chemicals added."
	
	# Update purity display if result was created
	if result_created:
		purity_label.text = "Purity: " + str(purity) + "%"
		purity_bar.value = purity
		
		# Set color based on purity
		if purity < 50:
			purity_bar.add_theme_color_override("gradient_foreground", COLOR_ERROR)
		elif purity < 80:
			purity_bar.add_theme_color_override("gradient_foreground", COLOR_WARNING)
		else:
			purity_bar.add_theme_color_override("gradient_foreground", COLOR_SUCCESS)
	else:
		purity_label.text = "Purity: --"
		purity_bar.value = 0

func add_console_message(message):
	var time_str = Time.get_time_string_from_system().substr(0, 5)
	console.text += "[" + time_str + "] " + message + "\n"
	
	# Auto scroll to bottom
	await get_tree().process_frame
	$MainContainer/RightPanel/ConsolePanel.scroll_vertical = $MainContainer/RightPanel/ConsolePanel.get_v_scroll_bar().max_value

func synthesize():
	# Create bubbling effect
	create_bubbles(15)
	
	# Calculate purity based on selected method and chemicals
	calculate_purity()
	
	# Update UI
	result_created = true
	update_interface()
	
	# Provide feedback
	if purity > 90:
		add_console_message("Excellent synthesis! " + str(purity) + "% purity achieved.")
	elif purity > 70:
		add_console_message("Good synthesis. " + str(purity) + "% purity achieved.")
	else:
		add_console_message("Poor synthesis. Only " + str(purity) + "% purity achieved.")

func calculate_purity():
	var base_purity = 0
	
	# Check if all required chemicals for the method are present
	var correct_reagents = 0
	var method_chemicals = optimal_recipes[selected_method]
	
	for chemical in method_chemicals:
		if chemicals.has(chemical):
			correct_reagents += 1
	
	# Base purity calculation
	if correct_reagents == 3:
		base_purity = 85
	elif correct_reagents == 2:
		base_purity = 60
	elif correct_reagents == 1:
		base_purity = 30
	
	# Adjust for heat level
	var optimal_temp = optimal_heat[selected_method]
	var temp_diff = abs(heat_level - optimal_temp)
	var temp_adjustment = 0
	
	if temp_diff <= 5:
		temp_adjustment = 10  # Perfect temperature
	elif temp_diff <= 15:
		temp_adjustment = 5   # Good temperature
	elif temp_diff <= 30:
		temp_adjustment = 0   # Acceptable temperature
	else:
		temp_adjustment = -15  # Poor temperature
	
	# Adjust for contaminants (extra chemicals not in recipe)
	var contaminants = chemicals.size() - correct_reagents
	var contaminant_penalty = contaminants * 5
	
	# Calculate final purity
	purity = base_purity + temp_adjustment - contaminant_penalty
	
	# Cap purity
	purity = clamp(purity, 0, 99.1)  # Famous Blue Sky limit
	
	# Round to one decimal place
	purity = round(purity * 10) / 10

func create_bubbles(count = 10):
	# Create bubbling effect for synthesis
	for i in range(count):
		var bubble = ColorRect.new()
		bubble.color = COLOR_PRIMARY
		bubble.color.a = randf_range(0.3, 0.7)
		
		# Random size (3-8 pixels)
		var size = randf_range(3, 8)
		bubble.custom_minimum_size = Vector2(size, size)
		
		# Random position in beaker
		var x_pos = randf_range(10, beaker.size.x - 10)
		var y_pos = randf_range(10, beaker.size.y - 10)
		bubble.position = Vector2(x_pos, y_pos)
		
		beaker.add_child(bubble)
		
		# Animate bubble rising and fading
		var tween = create_tween()
		tween.tween_property(bubble, "position:y", bubble.position.y - randf_range(30, 100), randf_range(1.0, 2.0))
		tween.parallel().tween_property(bubble, "color:a", 0, randf_range(0.8, 1.5))
		
		# Remove bubble when animation completes
		tween.tween_callback(bubble.queue_free)

func _on_quit_pressed():
	# Return to previous scene
	get_tree().change_scene_to_file("res://UI/Scenes/MethLab/MethLabEntry.tscn")

# Handle screen resize to be responsive
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		adjust_for_screen_size()

func adjust_for_screen_size():
	var window_size = get_viewport_rect().size
	
	# If narrow screen, automatically switch to vertical layout
	if window_size.x < 900:
		# Adjust container margins for smaller screens
		$MainContainer.add_theme_constant_override("margin_left", 5)
		$MainContainer.add_theme_constant_override("margin_right", 5)
		$MainContainer.add_theme_constant_override("margin_top", 5)
		$MainContainer.add_theme_constant_override("margin_bottom", 5)
	else:
		# Reset to original margins for larger screens
		$MainContainer.add_theme_constant_override("margin_left", 10)
		$MainContainer.add_theme_constant_override("margin_right", 10)
		$MainContainer.add_theme_constant_override("margin_top", 10)
		$MainContainer.add_theme_constant_override("margin_bottom", 10)

# SwipeDetector inner class for handling swipe gestures
class SwipeDetector extends Node:
	var start_pos = Vector2()
	var target = null
	var min_swipe_distance = 50
	
	func set_target(node):
		target = node
	
	func _input(event):
		if event is InputEventScreenTouch:
			if event.pressed:
				start_pos = event.position
			else:
				var swipe_direction = calculate_swipe_direction(event.position)
				if swipe_direction == "left":
					target.navigate_left()
				elif swipe_direction == "right":
					target.navigate_right()
		
	func calculate_swipe_direction(end_pos):
		var distance = end_pos - start_pos
		if abs(distance.x) > min_swipe_distance:
			if distance.x > 0:
				return "right"
			else:
				return "left"
		return "none" 