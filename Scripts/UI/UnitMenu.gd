extends BaseUI

var init_offset := 11
var offset := 13
var index := 1
var item_count := 3

var game_manager : GameManager
@onready var finger_ui := $FingerUI

func _ready() -> void:
	super._ready()
	game_manager = get_node("/root/Node2D/GameManager")
	
func get_ui_name():
	return UIManager.UI_NAME.UNIT_MENU
	
func is_handle_input():
	return true

func open_ui():
	super.open_ui()
	index = 1
	finger_ui.position.y = init_offset

func handle_ui_input() -> bool:
	if game_manager.play_state != GameManager.PlayState.SELECT_ACTION:
		return false
	
	if Input.is_action_just_pressed("up"):
		index -= 1
		index = clamp(index, 1, item_count)
		finger_ui.position.y = init_offset + offset * (index - 1)
	if Input.is_action_just_pressed("down"):
		index += 1
		index = clamp(index, 1, item_count)
		finger_ui.position.y = init_offset + offset * (index - 1)
	if Input.is_action_just_pressed("mouse_left"):
		game_manager.select_menu_item(index)
		
	return true
