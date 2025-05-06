
class_name Hurtbox
extends Area2D
@export var health: Health
var last_attack_vector: Vector2
func take_damage(amount: float, knockback: Vector2, source: Hitbox) -> void:
	last_attack_vector = owner.global_position - source.owner.global_position
	health.take_damage(amount, knockback)