extends Node2D

var game_input_handlers : Array[Node]

func _ready() -> void:
	SceneManager.connect("pre_scene_change", func():
		game_input_handlers.clear()
	)

func register_game_input_handlers(obj: Node):
	if not game_input_handlers.has(obj):
		game_input_handlers.append(obj)
		print("注册GameInput ", obj.name)

func _process(delta: float) -> void:
	if UIManager.handle_ui_input() and not Input.is_action_just_pressed("mouse_right"):
		return
	handle_game_input()
		
func handle_game_input():
	for obj in game_input_handlers:
		obj.handle_game_input()
