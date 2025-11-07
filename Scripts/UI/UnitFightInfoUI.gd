extends BaseUI
class_name UnitFightInfoUI

@onready var name_node1 = $Panel1/Name1
@onready var hp_label1 = $Panel1/HP1
@onready var hp_progress1 = $Panel1/HealthBackground/ProgressBar1

@onready var name_node2 = $Panel2/Name2
@onready var hp_label2 = $Panel2/HP2
@onready var hp_progress2 = $Panel2/HealthBackground/ProgressBar2

var unit_ui_dict = {}

func get_ui_name():
	return UIManager.UI_NAME.UNIT_FIGHT_INFO_UI

func init(battle_system: BattleSystem, attack_unit: Unit, defend_unit: Unit):
	unit_ui_dict[attack_unit.unit_name] = {
		"name_node": name_node1,
		"hp_label": hp_label1,
		"hp_progress": hp_progress1
	}
	unit_ui_dict[defend_unit.unit_name] = {
		"name_node": name_node2,
		"hp_label": hp_label2,
		"hp_progress": hp_progress2
	}
	update_info(attack_unit.unit_name, attack_unit.get_stats().hp, attack_unit.get_stats().max_hp)
	update_info(defend_unit.unit_name, defend_unit.get_stats().hp, defend_unit.get_stats().max_hp)

	if not battle_system.is_connected("hp_changed", update_info):
		battle_system.connect("hp_changed", update_info)

	var window_size = UIManager.get_window_size()
	if attack_unit.position.y < window_size.y / 2:
		position = Vector2(window_size.x/2, window_size.y * 4 / 5)
	else:
		position = Vector2(window_size.x/2, window_size.y / 5)

func open_ui():
	super()
	

func update_info(unit_name: String, hp: int, max_hp: int):
	unit_ui_dict[unit_name]["name_node"].text = unit_name
	unit_ui_dict[unit_name]["hp_label"].text = str(hp) + "/" + str(max_hp);
	unit_ui_dict[unit_name]["hp_progress"].max_value = max_hp;
	unit_ui_dict[unit_name]["hp_progress"].value = hp;
	print("更新单位信息 %s 生命值 %d/%d" % [unit_name, hp, max_hp])
