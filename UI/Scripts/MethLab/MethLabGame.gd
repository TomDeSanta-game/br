@tool
extends Control

# Simple game variables
var chemicals_in_beaker = []
var max_chemicals = 5
var dragging_chemical = false
var dragged_chemical_name = ""
var drag_start_position = Vector2()
var drag_ghost = null
var can_drop = false
var recipe_complete = false
var time_elapsed = 0.0

# The correct recipe order
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

# Node references
var beaker
var recipe_text
var log_text
var quality_label
var profit_label
var chemical_list

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
	chemical_list = $LabLayout/MainContent/RightPanel/RecipePanel/VBoxContainer/RecipeList
	
	# Set up chemical buttons
	setup_chemical_buttons()
	
	# Update the recipe text
	update_recipe_display()
	
	# Initial log message
	log_message("Welcome to the lab. Add chemicals in the correct order.")
	log_message("Drag chemicals to the beaker in the middle.")

func _process(delta):
	time_elapsed += delta
	
	# Make the beaker content bubble when chemicals are added
	if chemicals_in_beaker.size() > 0 and beaker:
		animate_beaker(delta)

func setup_chemical_buttons():
	var chemical_buttons = [
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons/PseudoephedrineButton,
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons/PhosphorusButton,
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons/IodineButton,
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons/MethylamineButton,
		$LabLayout/MainContent/LeftPanel/ChemicalsPanel/VBoxContainer/ChemicalButtons/AluminumButton
	]
	
	for button in chemical_buttons:
		if button:
			button.gui_input.connect(_on_chemical_gui_input.bind(button))

func _on_chemical_gui_input(event, chemical_button):
	var chemical_name = chemical_button.text.replace("Add ", "")
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drag
				dragging_chemical = true
				dragged_chemical_name = chemical_name
				drag_start_position = event.global_position
				create_drag_ghost(chemical_button)
			elif dragging_chemical and dragged_chemical_name == chemical_name:
				# End drag
				if can_drop and chemicals_in_beaker.size() < max_chemicals and not recipe_complete:
					add_chemical_to_beaker(chemical_name)
				clean_up_drag()
	
	elif event is InputEventMouseMotion and dragging_chemical and dragged_chemical_name == chemical_name:
		update_drag_position(event.global_position)

func create_drag_ghost(source_button):
	drag_ghost = ColorRect.new()
	drag_ghost.size = Vector2(60, 30)
	drag_ghost.color = Color(0.2, 0.6, 0.9, 0.7)
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var label = Label.new()
	label.text = source_button.text.replace("Add ", "")
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.size = drag_ghost.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	drag_ghost.add_child(label)
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
	
	# Check if we've added all chemicals
	if chemicals_in_beaker.size() == correct_recipe.size():
		check_recipe()

func update_recipe_display():
	if recipe_text:
		var text = "[color=#aaaaaa]Correct recipe order:[/color]\n"
		
		for i in range(correct_recipe.size()):
			var chemical = correct_recipe[i]
			var checked = ""
			
			if i < chemicals_in_beaker.size():
				if chemicals_in_beaker[i] == chemical:
					checked = " [color=#34C759]✓[/color]"
				else:
					checked = " [color=#FF3B30]✗[/color]"
			
			text += "\n[color=#aaaaaa]" + str(i+1) + ". " + chemical + checked + "[/color]"
		
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
	
	recipe_complete = true
	
	if quality >= 0.8:
		log_message("SUCCESS! You made high-quality Blue Sky.")
		show_success_animation()
	elif quality >= 0.5:
		log_message("Mixed results. The product is mediocre quality.")
		show_partial_success_animation()
	else:
		log_message("FAILURE! The chemicals were mixed incorrectly.")
		show_failure_animation()
	
	quality_label.text = "Quality: %d%%" % int(quality * 100)
	profit_label.text = "Profit: $%d" % profit
	
	SignalBus.emit_signal("meth_lab_completed", quality, profit)

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

func log_message(msg):
	if log_text:
		log_text.text += "\n[color=#888888]> %s[/color]" % msg

func _on_reset_button_pressed():
	chemicals_in_beaker.clear()
	recipe_complete = false
	update_recipe_display()
	log_message("Beaker cleared. Start again.")
	quality_label.text = "Quality: 0%"
	profit_label.text = "Profit: $0"

func _on_quit_button_pressed():
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").change_scene("res://Levels/RideWithHank/ride_with_hank.tscn")
	else:
		get_tree().change_scene_to_file("res://Levels/RideWithHank/ride_with_hank.tscn")
