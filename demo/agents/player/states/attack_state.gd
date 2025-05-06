
extends LimboState
@export var animation_player: AnimationPlayer
@export var animations: Array[StringName]
@export var hitbox: Hitbox
@export var combo_cooldown: float = 0.1
var anim_index: int = 0
var last_attack_msec: int = -10000
var _can_enter: bool = true
func can_enter() -> bool:
	return _can_enter
func _enter() -> void:
	if (Time.get_ticks_msec() - last_attack_msec) < 200:
		anim_index = (anim_index + 1) % 3
	else:
		anim_index = 0
	var horizontal_move: float = Input.get_axis(&"move_left", &"move_right")
	if not is_zero_approx(horizontal_move):
		agent.face_dir(horizontal_move)
	hitbox.damage = 2 if anim_index == 2 else 1
	animation_player.play(animations[anim_index])
	await animation_player.animation_finished
	if is_active():
		get_root().dispatch(EVENT_FINISHED)
func _exit() -> void:
	hitbox.damage = 1
	last_attack_msec = Time.get_ticks_msec()
	if anim_index == 2 and _can_enter:
		_can_enter = false
		await get_tree().create_timer(combo_cooldown).timeout
		_can_enter = true