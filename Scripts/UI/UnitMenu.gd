extends Control

var init_offset := 5
var offset := 13
var index := 1
var item_count := 3

var game_manager : GameManager

func _ready() -> void:
	game_manager = get_node("/root/Node2D")

func show_ui():
	await get_tree().process_frame
	visible = true
	index = 1
	$TextureRect.position.y = init_offset

func _process(_delta: float) -> void:
	if not visible or game_manager.play_state != GameManager.PlayState.SELECT_ACTION:
		return
	
	if Input.is_action_just_pressed("up"):
		index -= 1
		index = clamp(index, 1, item_count)
		$TextureRect.position.y = init_offset + offset * (index - 1)
	if Input.is_action_just_pressed("down"):
		index += 1
		index = clamp(index, 1, item_count)
		$TextureRect.position.y = init_offset + offset * (index - 1)
	if Input.is_action_just_pressed("mouse_left"):
		game_manager.select_menu_item(index)
