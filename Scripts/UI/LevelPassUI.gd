extends Node

@onready var button : Button = $NinePatchRect/Button

func _ready() -> void:
	if SceneManager.is_final_level():
		button.text = "返回标题"
	
	button.connect("visibility_changed", func():
		if button.visible:
			button.grab_focus()
	)
	button.connect("pressed", _button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_mouse_left"):
		var focued_control = get_viewport().gui_get_focus_owner()
		if focued_control is BaseButton:
			focued_control.emit_signal("pressed")
			#get_viewport().set_input_as_handled()

func _button_pressed():
	if SceneManager.is_final_level():
		SceneManager.go_to_game_start_scene()
	else:
		SceneManager.go_to_next_level()
	
