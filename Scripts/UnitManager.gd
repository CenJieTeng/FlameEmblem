extends Node

var default_stats=  {
	"max_hp": 10,
	"hp": 10,
	"atk": 12,
	"def": 2,
	"mov": 7  # 移动力
}

var unit_dict : Dictionary[String, UnitData] = {
	"角色1" : UnitData.new(default_stats),
	"角色2" : UnitData.new(default_stats),
	"角色3" : UnitData.new(default_stats),
	"角色4" : UnitData.new(default_stats),
	"敌人1" : UnitData.new(default_stats),
}

var deploy_item_list : Array[DeployUnitItem]

func _ready() -> void:
	SceneManager.connect("pre_scene_change", func():
		deploy_item_list.clear()
	)
	
func init_deploy_unit(deploy_count: int):
	var born_pos_index = 0
	for unit_name in unit_dict.keys():
		var deploy_unit_item = preload("res://Scenes/UI/DeployUnitItem.tscn").instantiate() as DeployUnitItem
		deploy_unit_item.unit_name = unit_name
		deploy_unit_item.born_pos_index = born_pos_index
		born_pos_index += 1
		if deploy_item_list.size() < deploy_count:
			deploy_unit_item.is_deploy = true
		deploy_item_list.append(deploy_unit_item)
