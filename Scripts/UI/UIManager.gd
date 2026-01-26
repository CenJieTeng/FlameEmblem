extends Node2D

enum UI_NAME
{
	INVALID,
	CONSOLE,
	UNIT_MENU,
	LEVEL_PASS_UI,
	SELECT_DEPLOY_UNIT_UI,
	UNIT_FIGHT_INFO_UI,
	BATTLE_SCENE_UI,
	SELECT_WEAPON_UI,
	QUICK_ATTACK_INFO_UI,
	SELECT_ITEM_UI
}

var window_size : Vector2
var ui_dict : Dictionary[UI_NAME, BaseUI]
var ui_input_handlers : Array[BaseUI]

var ui_name_dict = {
	UI_NAME.CONSOLE : "Console",
	UI_NAME.UNIT_MENU : "UnitMenu",
	UI_NAME.LEVEL_PASS_UI: "LevelPassUI",
	UI_NAME.SELECT_DEPLOY_UNIT_UI: "SelectDeployUnitUI",
	UI_NAME.UNIT_FIGHT_INFO_UI: "UnitFightInfoUI",
	UI_NAME.BATTLE_SCENE_UI: "BattleSceneUI",
	UI_NAME.SELECT_WEAPON_UI: "SelectWeaponUI",
	UI_NAME.QUICK_ATTACK_INFO_UI: "QuickAttackInfoUI",
	UI_NAME.SELECT_ITEM_UI: "SelectItemUI"
}

func _ready() -> void:
	SceneManager.connect("pre_scene_change", func():
		ui_dict.clear()
		ui_input_handlers.clear()
	)
	window_size = get_viewport().get_visible_rect().size / DisplayServer.screen_get_scale()

func get_ui(ui_name: UI_NAME) -> BaseUI:
	if ui_dict.has(ui_name):
		return ui_dict[ui_name]
	return null

func get_window_size() -> Vector2:
	return window_size

func register_ui(ui_name: UI_NAME, ui: BaseUI):
	if ui_dict.has(ui_name):
		printerr("注册UI名称已经存在 ", ui_name)
		return
	ui_dict[ui_name] = ui
	print("注册UI ", ui_name_dict[ui_name])
	
func is_handle_ui_input() -> bool:
	return not ui_input_handlers.is_empty()

func register_ui_input_handler(ui: BaseUI):
	if not ui_input_handlers.has(ui):
		ui_input_handlers.append(ui)
		ui.focus_mode = Control.FOCUS_ALL
		ui.grab_focus()
		
func unregister_ui_input_handler(ui: BaseUI):
	if ui_input_handlers.has(ui):
		ui_input_handlers.erase(ui)
		ui.focus_mode = Control.FOCUS_NONE
		ui.release_focus()
		if not ui_input_handlers.is_empty():
			ui_input_handlers.back().grab_focus()

func open(ui_name: UI_NAME):
	if ui_dict.has(ui_name):
		ui_dict[ui_name].open_ui()
		
func close(ui_name: UI_NAME):
	if ui_dict.has(ui_name):
		ui_dict[ui_name].close_ui()
