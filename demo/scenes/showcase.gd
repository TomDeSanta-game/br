extends Node2D

@onready var behavior_tree_view: BehaviorTreeView = %BehaviorTreeView
@onready var camera: Camera2D = $Camera2D
@onready var agent_selection: MenuButton = %AgentSelection
@onready var previous: Button = %Previous
@onready var next: Button = %Next
@onready var minimize_description: Button = %MinimizeDescription
@onready var description: RichTextLabel = %Description
@onready var begin_tutorial: Button = %BeginTutorial
@onready var navigation_hint: Label = %NavigationHint
@onready var scene_title: Label = %SceneTitle
@onready var code_popup = %CodePopup
@onready var code_edit = %CodeEdit

var bt_player: BTPlayer
var selected_tree_index: int = -1
var agent_files: Array[String]
var agents_dir: String
var is_tutorial: bool = false

func _ready() -> void:
	code_popup.hide()
	agent_selection.get_popup().id_pressed.connect(_on_agent_selection_id_pressed)
	previous.pressed.connect(func(): _on_agent_selection_id_pressed(selected_tree_index - 1))
	next.pressed.connect(func(): _on_agent_selection_id_pressed(selected_tree_index + 1))
	_initialize()

func _physics_process(_delta: float) -> void:
	var inst: BTInstance = bt_player.get_bt_instance()
	var bt_data: BehaviorTreeData = BehaviorTreeData.create_from_bt_instance(inst)
	behavior_tree_view.update_tree(bt_data)

func _initialize() -> void:
	if is_tutorial:
		_populate_agent_files("res://demo/agents/tutorial/")
		begin_tutorial.text = "End Tutorial"
		navigation_hint.text = "Tutorial Mode"
		_on_agent_selection_id_pressed(0)
	else:
		_populate_agent_files("res://demo/ai/trees/")
		begin_tutorial.text = "Begin Tutorial"
		navigation_hint.text = "Use arrow buttons to navigate"
		_on_agent_selection_id_pressed(0)

func _attach_camera(agent: CharacterBody2D) -> void:
	await get_tree().process_frame
	camera.get_parent().remove_child(camera)
	agent.add_child(camera)
	camera.position = Vector2.ZERO

func _populate_agent_files(p_path: String) -> void:
	var popup: PopupMenu = agent_selection.get_popup()
	popup.clear()
	popup.reset_size()
	agent_files.clear()
	agents_dir = p_path
	
	var dir := DirAccess.open(p_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				agent_files.append(p_path + file_name)
				popup.add_item(file_name.get_basename())
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	agent_files.sort()
	for i in agent_files.size():
		popup.set_item_id(i, i)

func _load_agent(file_name: String) -> void:
	var agent_res := load(file_name)
	
	# Remove existing agent if any
	for child in get_children():
		if child is CharacterBody2D:
			child.queue_free()
	
	# Wait for removal to complete
	await get_tree().process_frame
	
	# Load new agent
	if agent_res:
		var agent = agent_res.instantiate()
		if agent:
			add_child(agent)
			
			if is_instance_of(agent, CharacterBody2D):
				_attach_camera(agent)
				
				# Set up the behavior tree player
				bt_player = agent.get_node_or_null("BTPlayer")
				if bt_player:
					behavior_tree_view.play_icon_texture = preload("res://addons/limboai/icons/BTPlayer.svg")
				else:
					bt_player = BTPlayer.new()
					bt_player.name = "BTPlayer"
					agent.add_child(bt_player)
					
				var tree_path = agent_files[selected_tree_index]
				if tree_path.ends_with(".tres"):
					bt_player.behavior_tree = load(tree_path)
					
					# Update scene title
					var display_name = tree_path.get_file().get_basename()
					scene_title.text = display_name
					
					# Update description
					if is_tutorial and bt_player.behavior_tree:
						description.text = bt_player.behavior_tree.description
					else:
						description.text = ""

func _on_agent_selection_id_pressed(id: int) -> void:
	if id < 0 or id >= agent_files.size():
		return
		
	selected_tree_index = id
	previous.disabled = (id == 0)
	next.disabled = (id == agent_files.size() - 1)
	
	_load_agent(agent_files[id])

func _on_behavior_tree_view_task_selected(_type_name: String, p_script_path: String) -> void:
	if not p_script_path.is_empty():
		var sc: Script = load(p_script_path)
		if sc:
			code_edit.set_source_code(sc.source_code)
			code_popup.popup_centered()

func _on_minimize_description_button_down() -> void:
	description.visible = not description.visible
	if description.visible:
		minimize_description.text = "▲"
	else:
		minimize_description.text = "▼"

func _on_begin_tutorial_pressed() -> void:
	is_tutorial = not is_tutorial
	_initialize()
