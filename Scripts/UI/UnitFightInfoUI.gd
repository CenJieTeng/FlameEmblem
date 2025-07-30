extends Control

@onready var name_node1 = $Panel1/Name1
@onready var hp_label1 = $Panel1/HP1
@onready var hp_progress1 = $Panel1/HealthBackground/ProgressBar1

@onready var name_node2 = $Panel2/Name2
@onready var hp_label2 = $Panel2/HP2
@onready var hp_progress2 = $Panel2/HealthBackground/ProgressBar2

func update_info(unit1: Unit, unit2: Unit):
	name_node1.text = unit1.unit_name
	var max_hp1 = unit1.stats["max_hp"];
	var hp1 = unit1.stats["hp"];
	hp_label1.text = str(hp1) + "/" + str(max_hp1);
	hp_progress1.max_value = max_hp1;
	hp_progress1.value = hp1;
	
	name_node2.text = unit2.unit_name
	var max_hp2 = unit2.stats["max_hp"];
	var hp2 = unit2.stats["hp"];
	hp_label2.text = str(hp2) + "/" + str(max_hp2);
	hp_progress2.max_value = max_hp2;
	hp_progress2.value = hp2;
