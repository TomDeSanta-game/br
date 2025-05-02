extends StaticBody2D
@onready var sl: Sprite2D = $Sprite2D_left
@onready var sr: Sprite2D = $Sprite2D_right
@onready var button: Button = $Button
@export var dt: StringName
@export var fh: bool = false
var opened: bool = false
func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	if fh == false:
		sl.flip_h = false
		sr.flip_h = true
	else:
		sl.flip_h = true
		sr.flip_h = false
	
	if dt == "R":
		sl.frame = 0
		sr.frame = 0
	elif dt == "C":
		sl.frame = 2
		sr.frame = 2
func _process(_delta: float) -> void:
	if opened == false:
		process_mode = Node.PROCESS_MODE_INHERIT
		button.text = "Open"
	else:
		process_mode = Node.PROCESS_MODE_DISABLED
		button.text = "Close"
func _on_da_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		button.show()
func _on_button_pressed() -> void:
	if opened == true:
		opened = false
		if dt == "R":
			sl.frame = 0
			sr.frame = 0
		elif dt == "C":
			sl.frame = 2
			sr.frame = 2
	else:
		opened = true
		if dt == "R":
			sl.frame = 1
			sr.frame = 1
		elif dt == "C":
			sl.frame = 3
			sr.frame = 3
func _on_da_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		button.hide()