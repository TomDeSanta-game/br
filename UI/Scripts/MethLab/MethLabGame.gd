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
const COLOR_BG_DARK = Color("#151515")
const COLOR_BG_PANEL = Color("#202020")
const COLOR_PRIMARY = Color("#0066cc")
const COLOR_ACCENT = Color("#ff6600")
const COLOR_TEXT = Color("#ffffff")
const COLOR_TEXT_DIM = Color("#aaaaaa")
const COLOR_SUCCESS = Color("#34C759")
const COLOR_WARNING = Color("#FFCC00")
const COLOR_ERROR = Color("#FF3B30")
const COLOR_BLUE_SKY = Color("#4F9FE3")

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

func _ready():
	if Engine.is_editor_hint():
		return
		
	randomize()
	
	# Initialize node references
	beaker = $LabLayout/MainContent/MidPanel/ReactionPanel/VBoxContainer/ReactionContainer/ReactionDisplay
	recipe_text = $LabLayout/MainContent/RightPanel/RecipePanel/VBoxContainer/RecipeText
	log_text = $LabLayout/LogPanel/VBoxContainer/LogText
	quality_label = $LabLayout/TitleBar/QualityLabel
	profit_label = $LabLayout/TitleBar/ProfitLabel
	timer_label = $LabLayout/TitleBar/TimerLabel
	score_label = $LabLayout/TitleBar/ScoreLabel
	combo_label = $LabLayout/TitleBar/ComboLabel
	
	# Improve UI spacing to prevent overlapping
	adjust_ui_layout()
	
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

func adjust_ui_layout():
	# Make sure title bar has proper spacing
	var title_bar = $LabLayout/TitleBar
	if title_bar:
		title_bar.add_theme_constant_override("separation", 30)
		title_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Organize title bar elements
		var labels = []
		for child in title_bar.get_children():
			if child is Label:
				labels.append(child)
				
		# Set consistent sizes for labels
		for label in labels:
			label.custom_minimum_size.x = 140
	
	# Make chemical buttons more uniform and visually pleasing
	var chemical_buttons_container = $LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons
	if chemical_buttons_container:
		chemical_buttons_container.add_theme_constant_override("separation", 10)
		
		for child in chemical_buttons_container.get_children():
			if child is Button:
				child.custom_minimum_size.y = 50
	
	# Improve beaker display area
	var reaction_display = $LabLayout/MainContent/MidPanel/ReactionPanel/VBoxContainer/ReactionContainer/ReactionDisplay
	if reaction_display:
		reaction_display.custom_minimum_size = Vector2(250, 250)
		
	# Make the recipe panel more readable
	var recipe_panel = $LabLayout/MainContent/RightPanel/RecipePanel
	if recipe_panel:
		recipe_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var recipe_text = $LabLayout/MainContent/RightPanel/RecipePanel/VBoxContainer/RecipeText
		if recipe_text:
			recipe_text.add_theme_constant_override("line_separation", 10)
	
	# Create better bottom controls layout
	var control_panel = $LabLayout/ControlPanel
	if control_panel:
		control_panel.add_theme_constant_override("separation", 30)
		control_panel.alignment = BoxContainer.ALIGNMENT_CENTER

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
	var chemical_buttons = [
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons/PseudoephedrineButton,
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons/PhosphorusButton,
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons/IodineButton,
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons/MethylamineButton,
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons/AluminumButton
	]
	
	# Chemical icons and colors - using more distinct textures for different chemicals
	var chemical_icons = {
		"Pseudoephedrine": preload("res://assets/early_methaphetamine_batch.png"),
		"Red Phosphorus": preload("res://assets/early_methaphetamine_batch.png"),
		"Iodine": preload("res://assets/early_methaphetamine_batch.png"),
		"Methylamine": preload("res://assets/early_methaphetamine_batch.png"),
		"Aluminum": preload("res://assets/early_methaphetamine_batch.png")
	}
	
	for button in chemical_buttons:
		if button:
			# Style the button
			button.add_theme_stylebox_override("normal", create_button_style(get_chemical_color(button.text.replace("Add ", ""))))
			button.add_theme_stylebox_override("hover", create_button_style(get_chemical_color(button.text.replace("Add ", "")).lightened(0.2)))
			button.add_theme_stylebox_override("pressed", create_button_style(get_chemical_color(button.text.replace("Add ", "")).darkened(0.2)))
			
			# Add icon to button
			var chemical_name = button.text.replace("Add ", "")
			var icon = TextureRect.new()
			icon.texture = chemical_icons[chemical_name]
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(32, 32)
			
			# Create horizontal container for icon and text
			var hbox = HBoxContainer.new()
			button.add_child(hbox)
			
			# Add icon
			hbox.add_child(icon)
			
			# Add label for chemical name
			var label = Label.new()
			label.text = chemical_name
			label.add_theme_font_size_override("font_size", 16)
			hbox.add_child(label)
			
			# Set button text to empty since we're using our custom layout
			button.text = ""
			
			# Center the container
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_theme_constant_override("separation", 10)
			
			# Connect signals
			button.gui_input.connect(_on_chemical_gui_input.bind(button))
			# Add hover effect
			button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
			button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
			
			# Apply color tint based on the chemical
			icon.modulate = get_chemical_color(chemical_name)

func _on_button_mouse_entered(button):
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2), 0.2)

func _on_button_mouse_exited(button):
	var tween = create_tween()
	tween.tween_property(button, "modulate", Color(1, 1, 1), 0.2)

func _on_chemical_gui_input(event, chemical_button):
	# Determine chemical name from button's child label
	var chemical_name = ""
	if chemical_button.get_child_count() > 0 and chemical_button.get_child(0) is HBoxContainer:
		var hbox = chemical_button.get_child(0)
		for child in hbox.get_children():
			if child is Label:
				chemical_name = child.text
				break
	
	if chemical_name == "":
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drag
				dragging_chemical = true
				dragged_chemical_name = chemical_name
				drag_start_position = event.global_position
				create_drag_ghost(chemical_button)
				apply_pulse_effect(chemical_button)
			elif dragging_chemical and dragged_chemical_name == chemical_name:
				# End drag
				if can_drop and chemicals_in_beaker.size() < max_chemicals and not recipe_complete and timer_running:
					add_chemical_to_beaker(chemical_name)
				clean_up_drag()
	
	elif event is InputEventMouseMotion and dragging_chemical and dragged_chemical_name == chemical_name:
		update_drag_position(event.global_position)

func create_drag_ghost(source_button):
	drag_ghost = ColorRect.new()
	drag_ghost.size = Vector2(120, 40)
	drag_ghost.color = Color(0.15, 0.15, 0.15, 0.9)
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Get chemical name from button
	var chemical_name = ""
	if source_button.get_child_count() > 0 and source_button.get_child(0) is HBoxContainer:
		var hbox = source_button.get_child(0)
		for child in hbox.get_children():
			if child is Label:
				chemical_name = child.text
				break
	
	if chemical_name == "":
		return
	
	# Create container for icon and text
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.custom_minimum_size = Vector2(120, 40)
	hbox.position = Vector2(0, 0)
	drag_ghost.add_child(hbox)
	
	# Get icon texture
	var icon_texture = null
	if source_button.get_child_count() > 0 and source_button.get_child(0) is HBoxContainer:
		var source_hbox = source_button.get_child(0)
		for child in source_hbox.get_children():
			if child is TextureRect:
				icon_texture = child.texture
				break
	
	# Add icon if we found one
	if icon_texture:
		var icon = TextureRect.new()
		icon.texture = icon_texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(30, 30)
		icon.modulate = get_chemical_color(chemical_name)
		hbox.add_child(icon)
	
	# Add label
	var label = Label.new()
	label.text = chemical_name
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(label)
	
	add_child(drag_ghost)
	
	# Position at cursor
	drag_ghost.global_position = drag_start_position - drag_ghost.size / 2

func update_drag_position(position):
	if not drag_ghost:
		return
	
	drag_ghost.global_position = position - drag_ghost.size / 2
	
	# Check if we're over the beaker
	if beaker:
		var beaker_rect = Rect2(beaker.global_position, beaker.size)
		can_drop = beaker_rect.has_point(position)
		
		if can_drop:
			drag_ghost.color = Color(0.3, 0.8, 0.5, 0.8)
		else:
			drag_ghost.color = Color(0.2, 0.6, 0.9, 0.7)

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
	
	# Visual feedback
	flash_beaker_color(get_chemical_color(chemical_name))
	spawn_particles(beaker.global_position + Vector2(beaker.size.x/2, beaker.size.y/2), 5)
	
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
		"Red Phosphorus": return Color(0.8, 0.0, 0.0)
		"Iodine": return Color(0.6, 0.3, 0.7)
		"Methylamine": return Color(0.2, 0.5, 0.9)
		"Aluminum": return Color(0.7, 0.7, 0.8)
		_: return Color(0.5, 0.5, 0.5)

func flash_beaker_color(color):
	if not beaker:
		return
	
	var flash = ColorRect.new()
	flash.color = color.lightened(0.3)
	flash.color.a = 0.7
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.size = beaker.size
	
	beaker.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

func update_recipe_display():
	if recipe_text:
		var text = "[font_size=18][color=#aaaaaa]CORRECT RECIPE ORDER:[/color][/font_size]\n\n"
		
		for i in range(correct_recipe.size()):
			var chemical = correct_recipe[i]
			var checked = ""
			var color_hex = get_chemical_color(chemical).to_html(false)
			
			if i < chemicals_in_beaker.size():
				if chemicals_in_beaker[i] == chemical:
					checked = " [color=#34C759][font_size=16]✓[/font_size][/color]"
				else:
					checked = " [color=#FF3B30][font_size=16]✗[/font_size][/color]"
			
			text += "[color=#" + color_hex + "]■[/color] [color=#dddddd][font_size=16]" + str(i+1) + ". " + chemical + checked + "[/font_size][/color]\n"
		
		recipe_text.text = text

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
		
		# Random size
		var bubble_size = randf_range(3, 7)
		bubble.scale = Vector2(bubble_size, bubble_size)

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
		show_success_animation()
		unlock_next_difficulty()
	elif quality >= 0.5:
		log_message("Mixed results. The product is mediocre quality.")
		log_message("Score: " + str(score) + " (Profit: $" + str(profit) + " + Time Bonus: " + str(time_bonus) + " x" + str(combo_multiplier) + " Combo)")
		show_partial_success_animation()
	else:
		log_message("FAILURE! The chemicals were mixed incorrectly.")
		show_failure_animation()
	
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

func apply_pulse_effect(button):
	var original_scale = button.scale
	var tween = create_tween()
	tween.tween_property(button, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(button, "scale", original_scale, 0.1)

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
	achievement_popup.add_theme_stylebox_override("panel", get_stylebox_from_theme("panel"))
	achievement_popup.size = Vector2(300, 80)
	achievement_popup.position = Vector2(size.x - 320, 20)
	achievement_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vbox = VBoxContainer.new()
	achievement_popup.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = "Achievement: " + title
	title_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	vbox.add_child(title_label)
	
	var desc_label = Label.new()
	desc_label.text = description
	vbox.add_child(desc_label)
	
	add_child(achievement_popup)
	
	var tween = create_tween()
	tween.tween_property(achievement_popup, "position:x", size.x, 0).set_delay(3.0)
	tween.tween_callback(achievement_popup.queue_free)

func get_stylebox_from_theme(name):
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_PANEL
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_PRIMARY
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	return style

func log_message(msg):
	if log_text:
		log_text.text += "\n[color=#888888]> %s[/color]" % msg

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

func create_button_style(color):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style
