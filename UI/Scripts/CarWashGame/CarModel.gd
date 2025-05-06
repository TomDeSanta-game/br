extends Node2D
func play_wash_effect():
	$WaterParticles.emitting = true
	await get_tree().create_timer(2.0).timeout
	$WaterParticles.emitting = false
func play_polish_effect():
	$PolishParticles.emitting = true
	await get_tree().create_timer(1.5).timeout
	$PolishParticles.emitting = false
func play_wax_effect():
	$WaxParticles.emitting = true
	await get_tree().create_timer(2.0).timeout
	$WaxParticles.emitting = false
func set_car_texture(texture_path):
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		$CarSprite.texture = texture