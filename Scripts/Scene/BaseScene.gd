extends Node2D
class_name BaseScene

var first_frame := true
var game_manager : GameManager

var deploy_count := 1
var unit_born_pos : Array[Vector2i]

func _ready() -> void:
	SceneManager.set_scene(self)
	game_manager = get_node("/root/Node2D/GameManager")
	setup_level()
	
func _process(delta: float) -> void:
	if first_frame:
		first_frame = false
		first_frame_process()
	
func setup_level():
	pass
	
func first_frame_process():
	pass

func born_unit():
	for deploy_item in UnitManager.deploy_item_list:
		if deploy_item.is_deploy:
			game_manager.create_unit(deploy_item.unit_name, unit_born_pos[deploy_item.born_pos_index], Unit.UnitCamp.PLAYER)
