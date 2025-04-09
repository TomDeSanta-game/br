extends CharacterBody2D

@export var back: bool = true
@export var front: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	SignalBus.csaf.connect(csaf)

func _process(_delta: float) -> void:
	if back == true:
		animated_sprite.play("Up_Idle") # Will show back
	elif front == true:
		animated_sprite.play("Down_Idle") # Will show front

func csaf() -> void:
	Log.info("hello")
	animated_sprite.play("Attack")