extends Control
class_name DeployUnitItem

@onready var sprite_anim := $Panel/SpriteAnimation
@onready var name_lable := $Panel/NameLabel
var unit_name : String
var is_deploy := false
var born_pos_index := 0

func update_info():
	sprite_anim.sprite_frames = Global.sprite_frams_map[unit_name]
	sprite_anim.play("idle")
	if is_deploy:
		sprite_anim.material = null
		name_lable.text = unit_name
	else:
		sprite_anim.material = preload("res://Shader/SpriteGray.tres")
		name_lable.text = "[color=gray]" + unit_name + "[/color]";

func deploy():
	is_deploy = !is_deploy
	
	var born_pos_arr : Array[int]
	for deploy_item in UnitManager.deploy_item_list:
		if deploy_item.is_deploy:
			born_pos_arr.append(deploy_item.born_pos_index)
			
	for i in range(SceneManager.get_scene().unit_born_pos.size()):
		if not born_pos_arr.has(i):
			born_pos_index = i
			break
	
	update_info()
	

#[color=#00ff00]绿色文字[/color]
#[color=red]红色[/color]
#[color=blue]蓝色[/color] 
#[color=green]绿色[/color]
#[color=yellow]黄色[/color]
#[color=purple]紫色[/color]
#[color=orange]橙色[/color]
#[color=gray]灰色[/color]
#[color=white]白色[/color]
#[color=black]
