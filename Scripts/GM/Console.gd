extends BaseUI

@onready var input_field : LineEdit = $Panel/VBoxContainer/LineEdit
@onready var output_text : RichTextLabel = $Panel/VBoxContainer/RichTextLabel

var game_manager : GameManager

func _ready() -> void:
	super._ready()
	input_field.text_submitted.connect(_on_command_submitted)
	game_manager = get_node("/root/Node2D/GameManager")

func get_ui_name():
	return UIManager.UI_NAME.CONSOLE
	
func is_handle_input():
	return true
	
func open_ui():
	super.open_ui()
	input_field.grab_focus()
	
func handle_ui_input() -> bool:
	if Input.is_action_just_pressed("toggle_console"):
		close_ui()
	return true
	
func _on_command_submitted(command: String):
	if command.strip_edges() != "":
		excute_command(command)
	input_field.clear()
	
func excute_command(command: String):
	var parts = command.split(" ")
	var cmd = parts[0].to_lower()
	var args = parts.slice(1)
	
	var output = execute_command2(cmd, args)
	output_text.append_text("> " + command + "\n" + output)

func execute_command2(command: String, args: Array = []) -> String:
	var cmd = command.to_lower()
	match cmd:
		"addunit":
			var x = args[0].to_int()
			var y = args[1].to_int()
			var unit_name = args[2]
			var camp = args.get(3).to_int() if args.size() > 3 else 0
			game_manager.create_unit(unit_name, Vector2i(x, y), camp)
			return "addunit suc"
		_:
			return "Unknown command: " + command + "\nType 'help' for available commands"
