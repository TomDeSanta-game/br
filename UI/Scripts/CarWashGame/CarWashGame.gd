extends Node

var car_ui
var car_model

func _ready():
	car_ui = $CarWashUI
	car_model = $CarViewport/SubViewport/CarModel
	
	connect_signals()
	
func connect_signals():
	car_ui.connect("wash_car", Callable(self, "_on_wash_car"))
	car_ui.connect("polish_car", Callable(self, "_on_polish_car"))
	car_ui.connect("wax_car", Callable(self, "_on_wax_car"))
	
func _on_wash_car():
	car_model.play_wash_effect()
	
func _on_polish_car():
	car_model.play_polish_effect()
	
func _on_wax_car():
	car_model.play_wax_effect() 