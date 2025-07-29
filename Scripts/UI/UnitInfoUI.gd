extends Control

@onready var name_node = $Panel/Name
@onready var hp_label = $Panel/HP
@onready var hp_progress = $Panel/HealthBackground/ProgressBar

func update_info(unit: Unit):
	name_node.text = unit.unit_name
	var max_hp = unit.stats["max_hp"];
	var hp = unit.stats["hp"];
	hp_label.text = str(hp) + "/" + str(max_hp);
	hp_progress.max_value = max_hp;
	hp_progress.value = hp;
