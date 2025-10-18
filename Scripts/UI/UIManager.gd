extends Node2D

enum UI_NAME
{
	INVALID,
	CONSOLE,
	UNIT_MENU,
	LEVEL_PASS_UI,
	SELECT_DEPLOY_UNIT_UI,
}

var ui_dict : Dictionary[UI_NAME, BaseUI]
var ui_input_handlers : Array[BaseUI]

var ui_name_dict = {
	UI_NAME.CONSOLE : "Console",
	UI_NAME.UNIT_MENU : "UnitMenu",
	UI_NAME.LEVEL_PASS_UI: "LevelPassUI",
	UI_NAME.SELECT_DEPLOY_UNIT_UI: "SelectDeployUnitUI",
}

func _ready() -> void:
	SceneManager.connect("pre_scene_change", func():
		ui_dict.clear()
		ui_input_handlers.clear()
	)

func register_ui(ui_name: UI_NAME, ui: BaseUI):
	if ui_dict.has(ui_name):
		printerr("注册UI名称已经存在 ", ui_name)
	ui_dict[ui_name] = ui
	print("注册UI ", ui_name_dict[ui_name])
	
func register_ui_input_handler(ui: BaseUI):
	if not ui_input_handlers.has(ui):
		ui_input_handlers.append(ui)
		
func unregister_ui_input_handler(ui: BaseUI):
	if ui_input_handlers.has(ui):
		ui_input_handlers.erase(ui)

func open(ui_name: UI_NAME):
	if ui_dict.has(ui_name):
		ui_dict[ui_name].open_ui()
		
func close(ui_name: UI_NAME):
	if ui_dict.has(ui_name):
		ui_dict[ui_name].close_ui()

func handle_ui_input():
	for i in range(ui_input_handlers.size() - 1, -1, -1):
		if ui_input_handlers[i].handle_ui_input():
			return true
	return false
		
