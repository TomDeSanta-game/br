extends Control

func _ready():
	pass

func _on_start_button_pressed():
	SceneManager.change_scene("res://Levels/House/House.tscn")

func _on_options_button_pressed():
	SceneManager.change_scene("res://UI/Scenes/OptionsMenu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()