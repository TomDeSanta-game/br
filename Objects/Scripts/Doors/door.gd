extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var button: Button = $Button

@export var dt: StringName
@export var fh: bool = false

var opened: bool = false

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout

	if fh == false:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
	# ;;;;
	if dt == "R":
		sprite.frame = 0
	elif dt == "C":
		sprite.frame = 2

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
			sprite.frame = 0
		elif dt == "C":
			sprite.frame = 2
	else:
		opened = true
		if dt == "R":
			sprite.frame = 1
		elif dt == "C":
			sprite.frame = 3

func _on_da_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		button.hide()