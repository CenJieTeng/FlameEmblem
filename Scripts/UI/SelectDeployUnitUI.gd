extends BaseUI

@onready var left_num_balel := $DeployNumPanel/LeftNum
@onready var deploy_num_label := $DeployNumPanel/DeployNum
@onready var scroll_container := $UnitListPanel/ScrollContainer
@onready var unit_list_container := $UnitListPanel/ScrollContainer/HFlowContainer
@onready var arrow := $UnitListPanel/Arrow
@onready var head_texture := $UnitInfoPanel/NinePatchRect2/HeadTexture
@onready var name_label := $UnitInfoPanel/NinePatchRect2/NameLabel
@onready var level_label := $UnitInfoPanel/NinePatchRect2/Level
@onready var exp_label := $UnitInfoPanel/NinePatchRect2/Exp

var init_offset := 5
var offset := 20
var index := 1
var unit_count := 0
var cur_deploy_count := 0
var scene_deploy_count := 0
var index_bound_min := 1
var index_bound_max := 7
var bound_size := index_bound_max - index_bound_min
var index_y := 1
var scroll_max_value := 0

func _ready() -> void:
	super()

func get_ui_name():
	return UIManager.UI_NAME.SELECT_DEPLOY_UNIT_UI
	
func is_handle_input():
	return true

func open_ui():
	super()
	scene_deploy_count = SceneManager.get_scene().deploy_count
	unit_count = UnitManager.unit_dict.size()
	
	for deploy_unit_item in UnitManager.deploy_item_list:
		unit_list_container.add_child(deploy_unit_item)
		deploy_unit_item.update_info()
		
	if unit_list_container.get_child_count() > 10:
		scroll_max_value = ceil((unit_list_container.get_child_count() - 10) / 2.0) * 20
		
	cur_deploy_count = 0
	for deploy_unit_item in UnitManager.deploy_item_list:
		if deploy_unit_item.is_deploy:
			cur_deploy_count += 1
	update_deploy_unit_info(UnitManager.deploy_item_list[0])
	update_deploy_num()
	
func close_ui():
	super()
	
	for child in unit_list_container.get_children():
		child.queue_free()

func handle_ui_input() -> bool:
	
	if Input.is_action_just_pressed("start"):
		close_ui()
		SceneManager.get_scene().born_unit()
		return true
	
	if Input.is_action_just_pressed("mouse_left"):
		if UnitManager.deploy_item_list[index-1].is_deploy:
			UnitManager.deploy_item_list[index-1].deploy()
			cur_deploy_count -= 1
		elif  cur_deploy_count < scene_deploy_count:
			UnitManager.deploy_item_list[index-1].deploy()
			cur_deploy_count += 1
		update_deploy_num()
		return true
	
	var old_index = index
	if Input.is_action_just_pressed("up"):
		if (index - 1 >= 1):
			index -= 2
	if Input.is_action_just_pressed("down"):
		if (index + 1 <= unit_count):
			index += 2
	if Input.is_action_just_pressed("left"):
		if (index % 2 == 0):
			index -= 1
	if Input.is_action_just_pressed("right"):
		if (index % 2 != 0):
			index += 1
			
	index = clamp(index, 1, unit_count)
	if old_index == index:	
		return true
		
	update_deploy_unit_info(UnitManager.deploy_item_list[index-1])
		
	arrow.position.x = 0 if (index % 2 != 0) else 50
	
	if (index-1) / 2 != (old_index-1) / 2:
		if index > old_index:
			index_y += 1
		else:
			index_y -= 1
		
		var new_offset = offset * (index_y - 1)
		if new_offset >= 80 and scroll_container.scroll_vertical < scroll_max_value:
			index_y -= 1
			scroll_container.scroll_vertical += 20
		elif new_offset <= 0 and scroll_container.scroll_vertical > 0:
			index_y += 1
			scroll_container.scroll_vertical -= 20
		arrow.position.y = offset * (index_y - 1)
			
	
	return true
	
func update_deploy_unit_info(deploy_item: DeployUnitItem):
	name_label.text = deploy_item.unit_name
	var texture = load(Global.name_to_unit_sprite_frames_map[deploy_item.unit_name][0])
	var atlas = head_texture.texture as AtlasTexture
	atlas.atlas = texture
	level_label.text = str(UnitManager.unit_dict[deploy_item.unit_name].level)
	exp_label.text = str(UnitManager.unit_dict[deploy_item.unit_name].exp)

func update_deploy_num():
	left_num_balel.text = str(scene_deploy_count - cur_deploy_count)
	deploy_num_label.text = str(cur_deploy_count) + "/" + str(scene_deploy_count)
	
	
