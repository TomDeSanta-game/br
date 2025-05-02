extends Node2D
@onready var label: Label = $CanvasLayer/Label
@onready var bg: Panel = $Meter/Background
@onready var indicator: Panel = $Meter/Indicator
@onready var gz: Panel = $Meter/GoodZone
@onready var meter_width := bg.size.x
@onready var indicator_width := indicator.size.x
@onready var bg_start_x := bg.position.x
@onready var gz_size := gz.size
@onready var progress_fill: ColorRect = $Meter/ProgressBar/ProgressFill
@onready var progress_bar_width: float = $Meter/ProgressBar.size.x - 2
@onready var title_label: Label = $TitleLabel
@onready var score_panel: Panel = $CanvasLayer/ScorePanel
@onready var tick_marks: Node2D = $Meter/TickMarks
var speed: float = 400.0
var current_dir: String = "RIGHT"
var points: int = 0
var can_press: bool = true
var original_indicator_color: Color
var original_gz_color: Color
var max_score: int = 50
var game_completed: bool = false
var cleanliness_percent: int = 0
func _ready() -> void:
	label.text = "Score: 0%"
	indicator.position.x = bg_start_x
	original_indicator_color = indicator.get_theme_stylebox("panel").bg_color
	original_gz_color = gz.get_theme_stylebox("panel").bg_color
	update_progress_bar()
	animate_meter()
func _physics_process(delta: float) -> void:
	if game_completed:
		return
		
	var left_bound = bg_start_x
	var right_bound = bg_start_x + meter_width - indicator_width
	if current_dir == "RIGHT":
		indicator.position.x += speed * delta
		if indicator.position.x >= right_bound:
			indicator.position.x = right_bound
			flip()
	elif current_dir == "LEFT":
		indicator.position.x -= speed * delta
		if indicator.position.x <= left_bound:
			indicator.position.x = left_bound
			flip()
			
	if Input.is_action_just_pressed("Zerostovik") and can_press:
		check_indicator_position()
func animate_meter() -> void:
	var gz_tween = create_tween().set_loops()
	gz_tween.tween_property(gz, "scale", Vector2(1.02, 1.02), 1.0).set_trans(Tween.TRANS_SINE)
	gz_tween.tween_property(gz, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)
	var tick_nodes = tick_marks.get_children()
	for i in range(tick_nodes.size()):
		var tick = tick_nodes[i]
		tick.modulate = Color(1, 1, 1, 0)
		var tick_tween = create_tween()
		tick_tween.tween_property(tick, "modulate", Color(1, 1, 1, 1), 0.2).set_delay(i * 0.05)
func flip() -> void:
	if current_dir == "RIGHT":
		current_dir = "LEFT"
	elif current_dir == "LEFT":
		current_dir = "RIGHT"
func check_indicator_position() -> void:
	var indicator_center = indicator.position.x + indicator_width / 2
	var gz_left = gz.position.x
	var gz_right = gz.position.x + gz_size.x
	
	can_press = false
	
	if indicator_center >= gz_left and indicator_center <= gz_right:
		add_points(5)
		success_feedback()
	else:
		failure_feedback()
	await get_tree().create_timer(0.5).timeout
	reset_visual_feedback()
	can_press = true
func add_points(amount: int) -> void:
	points += amount
	var original_scale = label.scale
	var original_color = label.modulate
	
	var color_tween = create_tween()
	color_tween.tween_property(label, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	color_tween.tween_property(label, "modulate", original_color, 0.2)
	
	var scale_tween = create_tween()
	scale_tween.tween_property(label, "scale", Vector2(1.15, 1.15), 0.1)
	scale_tween.tween_property(label, "scale", original_scale, 0.2)
	
	if points >= max_score:
		points = max_score
		cleanliness_percent = 100
		label.text = "Score: 100%"
		update_progress_bar()
		game_completed = true
		show_victory()
	else:
		cleanliness_percent = int((float(points) / max_score) * 100)
		label.text = "Score: " + str(cleanliness_percent) + "%"
		update_progress_bar()
	
func success_feedback() -> void:
	var style = gz.get_theme_stylebox("panel").duplicate()
	style.bg_color = Color(0.4, 0.9, 0.2, 1.0)
	gz.add_theme_stylebox_override("panel", style)
	var tween = create_tween()
	tween.tween_property(indicator, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(indicator, "scale", Vector2(0.9, 0.9), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(indicator, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(indicator, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE)
	var bg_tween = create_tween()
	bg_tween.tween_property(bg, "scale", Vector2(1.02, 1.02), 0.1)
	bg_tween.tween_property(bg, "scale", Vector2(1.0, 1.0), 0.2)
	var panel_tween = create_tween()
	panel_tween.tween_property(score_panel, "scale", Vector2(1.05, 1.05), 0.1)
	panel_tween.tween_property(score_panel, "scale", Vector2(1.0, 1.0), 0.2)
	
func failure_feedback() -> void:
	var style = indicator.get_theme_stylebox("panel").duplicate()
	style.bg_color = Color(0.9, 0.2, 0.2, 1)
	indicator.add_theme_stylebox_override("panel", style)
	var orig_pos = indicator.position
	var shake_tween = create_tween()
	shake_tween.tween_property(indicator, "position", orig_pos + Vector2(5, -3), 0.05)
	shake_tween.tween_property(indicator, "position", orig_pos + Vector2(-5, 2), 0.05)
	shake_tween.tween_property(indicator, "position", orig_pos + Vector2(3, -2), 0.05)
	shake_tween.tween_property(indicator, "position", orig_pos + Vector2(-2, 1), 0.05)
	shake_tween.tween_property(indicator, "position", orig_pos, 0.05)
func reset_visual_feedback() -> void:
	var gz_style = gz.get_theme_stylebox("panel").duplicate()
	gz_style.bg_color = original_gz_color
	gz.add_theme_stylebox_override("panel", gz_style)
	var ind_style = indicator.get_theme_stylebox("panel").duplicate()
	ind_style.bg_color = original_indicator_color
	indicator.add_theme_stylebox_override("panel", ind_style)
func update_progress_bar() -> void:
	var progress_percent = float(points) / max_score
	var new_width = progress_bar_width * progress_percent
	var tween = create_tween()
	tween.tween_property(progress_fill, "size:x", new_width, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var color_tween = create_tween()
	var progress_color = lerp(Color(0.2, 0.6, 0.2), Color(0.2, 0.9, 0.2), progress_percent)
	color_tween.tween_property(progress_fill, "color", progress_color, 0.3)
	for i in range(tick_marks.get_children().size()):
		var tick = tick_marks.get_children()[i]
		var tick_position = float(i) / (tick_marks.get_children().size() - 1)
		
		if tick_position <= progress_percent:
			var tick_tween = create_tween()
			tick_tween.tween_property(tick, "color", Color(0.3, 0.8, 0.3), 0.2)
		else:
			var tick_tween = create_tween()
			tick_tween.tween_property(tick, "color", Color(0.8, 0.8, 0.8), 0.2)
func show_victory() -> void:
	label.text = "Game Complete!"
	score_panel.size.x = 300
	var meter_tween = create_tween()
	meter_tween.tween_property($Meter, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_SINE)
	meter_tween.tween_property($Meter, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
	var title_tween = create_tween()
	title_tween.tween_property(title_label, "modulate", Color(0.3, 0.9, 0.3), 0.5)
	var score_tween = create_tween().set_loops(3)
	score_tween.tween_property(label, "modulate", Color(0.3, 0.9, 0.3), 0.3)
	score_tween.tween_property(label, "modulate", Color(1, 1, 1), 0.3)
