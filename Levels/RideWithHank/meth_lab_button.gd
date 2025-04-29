extends Button

func _ready():
	pressed.connect(open_meth_lab)
	
func open_meth_lab():
	get_tree().change_scene_to_file("res://UI/Scenes/MethLab/MethLabGame.tscn")
	
func show_button():
	visible = true
	
func hide_button():
	visible = false 