extends Control

func _ready():
	pass

func _on_start_button_pressed():
	# Try to use SceneManager if available
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").change_scene("res://UI/Scenes/MethLab/MethLabGame.tscn")
	else:
		get_tree().change_scene_to_file("res://UI/Scenes/MethLab/MethLabGame.tscn") 