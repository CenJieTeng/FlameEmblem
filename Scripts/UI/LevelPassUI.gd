extends BaseUI

@onready var button : Button = $NinePatchRect/Button

func _ready() -> void:
	super._ready()
	
	if SceneManager.is_final_level():
		button.text = "返回标题"
	
	button.connect("visibility_changed", func():
		if button.visible:
			button.grab_focus()
	)
	button.connect("pressed", _button_pressed)
	
func get_ui_name():
	return UIManager.UI_NAME.LEVEL_PASS_UI
	
func is_handle_input():
	return true

func handle_ui_input() -> bool:
	if Input.is_action_just_pressed("ui_mouse_left"):
		var focued_control = get_viewport().gui_get_focus_owner()
		if focued_control is BaseButton:
			focued_control.emit_signal("pressed")
	return true

func _button_pressed():
	if SceneManager.is_final_level():
		SceneManager.go_to_game_start_scene()
	else:
		SceneManager.go_to_next_level()
	
