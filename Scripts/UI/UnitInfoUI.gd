extends Control

@onready var name_node = $Panel/Name
@onready var hp_label = $Panel/HP
@onready var hp_progress = $Panel/HealthBackground/ProgressBar
@onready var head_image = $Panel/TextureRect

func update_info(unit: Unit):
	var atlas = head_image.texture as AtlasTexture
	atlas.atlas = unit.head_texture
	name_node.text = unit.unit_name
	var max_hp = unit.get_stats().max_hp;
	var hp = unit.get_stats().hp;
	hp_label.text = str(hp) + "/" + str(max_hp);
	hp_progress.max_value = max_hp;
	hp_progress.value = hp;
