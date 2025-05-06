extends Node
signal music_changed(music_name)
signal ambient_changed(ambient_name)
@export_category("Audio Settings")
@export var music_crossfade_time: float = 2.0
@export var ambient_crossfade_time: float = 3.0
@export var sound_bus: String = "Master"
@export_category("Music Tracks")
@export var normal_music: AudioStream
@export var tense_music: AudioStream
@export var chase_music: AudioStream
@export var stealth_music: AudioStream
@export_category("Ambient Sounds")
@export var normal_ambient: AudioStream
@export var tense_ambient: AudioStream
@export_category("Sound Effects")
@export var tension_stinger: AudioStream
@export var detection_stinger: AudioStream
@export var alert_stinger: AudioStream
var manager = null
var signal_bus = null
var effects = null
var current_music_player: AudioStreamPlayer = null
var next_music_player: AudioStreamPlayer = null
var ambient_player: AudioStreamPlayer = null
var sfx_player: AudioStreamPlayer = null
var current_music_name: String = ""
var current_ambient_name: String = ""
var last_tension_level = -1
var transitioning: bool = false
func _ready():
	current_music_player = AudioStreamPlayer.new()
	current_music_player.bus = sound_bus
	current_music_player.volume_db = 0.0
	add_child(current_music_player)
	next_music_player = AudioStreamPlayer.new()
	next_music_player.bus = sound_bus
	next_music_player.volume_db = -80.0
	add_child(next_music_player)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = sound_bus
	ambient_player.volume_db = 0.0
	add_child(ambient_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = sound_bus
	sfx_player.volume_db = 0.0
	add_child(sfx_player)
	manager = get_node_or_null("/root/TensionManager")
	signal_bus = get_node_or_null("/root/SignalBus")
	if signal_bus:
		signal_bus.threshold_crossed.connect(_on_tension_threshold_crossed)
	if manager:
		manager.player_detected.connect(_on_player_detected)
	effects = get_node_or_null("/root/TensionEffects")
	if normal_music:
		play_music("normal", normal_music)
	if normal_ambient:
		play_ambient("normal", normal_ambient)
func _process(delta):
	if !manager:
		return
	var current_level = manager.tension_engine.get_level_from_value(manager.tension_engine.current)
	if current_level != last_tension_level:
		last_tension_level = current_level
		_handle_tension_level_change(current_level)
func _handle_tension_level_change(level):
	match level:
		manager.tension_engine.LEVEL.MINIMAL:
			if current_music_name != "normal" && normal_music && !transitioning:
				play_music("normal", normal_music)
			if current_ambient_name != "normal" && normal_ambient:
				play_ambient("normal", normal_ambient)
		manager.tension_engine.LEVEL.LOW:
			if sfx_player && tension_stinger && last_tension_level < level:
				sfx_player.stream = tension_stinger
				sfx_player.play()
		manager.tension_engine.LEVEL.MEDIUM:
			if current_music_name != "tense" && tense_music && !transitioning:
				play_music("tense", tense_music)
			if current_ambient_name != "tense" && tense_ambient:
				play_ambient("tense", tense_ambient)
		manager.tension_engine.LEVEL.HIGH, manager.tension_engine.LEVEL.CRITICAL:
			if current_music_name != "chase" && chase_music && !transitioning:
				play_music("chase", chase_music)
func _on_tension_threshold_crossed(threshold_name, direction):
	if direction == "up" && tension_stinger && sfx_player:
		sfx_player.stream = tension_stinger
		sfx_player.play()
func _on_player_detected(is_detected):
	if is_detected && detection_stinger && sfx_player:
		sfx_player.stream = detection_stinger
		sfx_player.play()
		if chase_music && current_music_name != "chase" && !transitioning:
			play_music("chase", chase_music)
	elif !is_detected && stealth_music && current_music_name == "chase" && !transitioning:
		play_music("stealth", stealth_music)
func play_music(name: String, stream: AudioStream):
	if current_music_name == name || !stream:
		return
	transitioning = true
	next_music_player.stream = stream
	next_music_player.volume_db = -40.0
	next_music_player.play()
	var tween = create_tween()
	tween.parallel().tween_property(current_music_player, "volume_db", -40.0, music_crossfade_time)
	tween.parallel().tween_property(next_music_player, "volume_db", 0.0, music_crossfade_time)
	tween.tween_callback(func():
		current_music_player.stop()
		var temp = current_music_player
		current_music_player = next_music_player
		next_music_player = temp
		current_music_name = name
		transitioning = false
		music_changed.emit(name)
	)
func play_ambient(name: String, stream: AudioStream):
	if current_ambient_name == name || !stream || !ambient_player:
		return
	var tween = create_tween()
	if ambient_player.playing:
		tween.tween_property(ambient_player, "volume_db", -40.0, ambient_crossfade_time)
		tween.tween_callback(func():
			ambient_player.stream = stream
			ambient_player.volume_db = -40.0
			ambient_player.play()
		)
		tween.tween_property(ambient_player, "volume_db", 0.0, ambient_crossfade_time)
	else:
		ambient_player.stream = stream
		ambient_player.volume_db = -40.0
		ambient_player.play()
		tween.tween_property(ambient_player, "volume_db", 0.0, ambient_crossfade_time)
	current_ambient_name = name
	ambient_changed.emit(name)
func play_stinger(stinger_type: String):
	if !sfx_player:
		return
	match stinger_type:
		"tension":
			if tension_stinger:
				sfx_player.stream = tension_stinger
				sfx_player.play()
		"detection":
			if detection_stinger:
				sfx_player.stream = detection_stinger
				sfx_player.play()
		"alert":
			if alert_stinger:
				sfx_player.stream = alert_stinger
				sfx_player.play()
func stop_all_audio():
	transitioning = false
	if current_music_player:
		current_music_player.stop()
	if next_music_player:
		next_music_player.stop()
	if ambient_player:
		ambient_player.stop()
	current_music_name = ""
	current_ambient_name = ""