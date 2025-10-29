extends Control

@onready var name_node1 = $Panel1/Name1
@onready var hp_label1 = $Panel1/HP1
@onready var hp_progress1 = $Panel1/HealthBackground/ProgressBar1

@onready var name_node2 = $Panel2/Name2
@onready var hp_label2 = $Panel2/HP2
@onready var hp_progress2 = $Panel2/HealthBackground/ProgressBar2

var unit_ui_dict = {}

func init(battle_system: BattleSystem, unit1: Unit, unit2: Unit):
	unit_ui_dict[unit1.unit_name] = {
		"name_node": name_node1,
		"hp_label": hp_label1,
		"hp_progress": hp_progress1
	}
	unit_ui_dict[unit2.unit_name] = {
		"name_node": name_node2,
		"hp_label": hp_label2,
		"hp_progress": hp_progress2
	}
	update_info(unit1.unit_name, unit1.get_stats().hp, unit1.get_stats().max_hp)
	update_info(unit2.unit_name, unit2.get_stats().hp, unit2.get_stats().max_hp)

	if not battle_system.is_connected("hp_changed", update_info):
		battle_system.connect("hp_changed", update_info)

func update_info(unit_name: String, hp: int, max_hp: int):
	unit_ui_dict[unit_name]["name_node"].text = unit_name
	unit_ui_dict[unit_name]["hp_label"].text = str(hp) + "/" + str(max_hp);
	unit_ui_dict[unit_name]["hp_progress"].max_value = max_hp;
	unit_ui_dict[unit_name]["hp_progress"].value = hp;
	print("更新单位信息 %s 生命值 %d/%d" % [unit_name, hp, max_hp])
