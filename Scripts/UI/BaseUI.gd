extends Control
class_name BaseUI

func _ready() -> void:
	UIManager.register_ui(get_ui_name(), self)

func get_ui_name():
	return UIManager.UI_NAME.INVALID
	
func is_handle_input():
	return false

func open_ui():
	visible = true
	if is_handle_input():
		UIManager.register_ui_input_handler(self)
	#print("打开UI ", UIManager.ui_name_dict[get_ui_name()])
	
func close_ui():
	visible = false
	if is_handle_input():
		UIManager.unregister_ui_input_handler(self)
	#print("关闭UI ", UIManager.ui_name_dict[get_ui_name()])

func handle_ui_input() -> bool:
	return false
