extends Node

var unit_dict : Dictionary[String, UnitData] = {}

var unit_list : Array[String] = [
	"角色1",
	"角色2",
	"角色3",
	"角色4",
]

var deploy_item_list : Array[DeployUnitItem]

var sprite_frams_map : Dictionary[String, SpriteFrames]

func create_sprite_frames():
	for unit_name in UnitManager.unit_dict.keys():
		var sprite_frames = load("res://Sprites/Animation/UnitSpriteFrames/Lord.tres").duplicate(true) as SpriteFrames
		create_idle_anim(unit_name, sprite_frames)
		create_move_anim(unit_name, sprite_frames)
		sprite_frams_map[unit_name] = sprite_frames

func _ready() -> void:
	SceneManager.connect("end_scene_change", func():
		deploy_item_list.clear()
		for unit in SaveSystem.save_data.unit_dict.values():
			unit_dict[unit.unit_name] = unit
	)
	
	var path = "res://Resource/Unit/"
	var files = Global.list_files_in_directory(path)
	for file in files:
		var data = load(path + file) as UnitData
		data.init()
		unit_dict[data.unit_name] = data

	create_sprite_frames()

	
func init_deploy_unit(deploy_count: int):
	var born_pos_index = 0
	for unit_name in unit_list:
		var deploy_unit_item = preload("res://Scenes/UI/DeployUnitItem.tscn").instantiate() as DeployUnitItem
		deploy_unit_item.unit_name = unit_name
		deploy_unit_item.born_pos_index = born_pos_index
		born_pos_index += 1
		if deploy_item_list.size() < deploy_count:
			deploy_unit_item.is_deploy = true
		deploy_item_list.append(deploy_unit_item)

func create_idle_anim(unit_name: String, sprite_frames: SpriteFrames):
	var tex = UnitManager.unit_dict[unit_name].idea_texture
	var atlas1 = AtlasTexture.new()
	atlas1.atlas = tex
	atlas1.region = Rect2(0, 0, 64, 48)
	atlas1.margin = Rect2(0, 0, 0, 0)
	sprite_frames.set_frame("idle", 0, atlas1)
	var atlas2 = AtlasTexture.new()
	atlas2.atlas = tex
	atlas2.region = Rect2(64, 0, 64, 48)
	atlas2.margin = Rect2(0, 0, 0, 0)
	sprite_frames.set_frame("idle", 1, atlas2)
	var atlas3 = AtlasTexture.new()
	atlas3.atlas = tex
	atlas3.region = Rect2(128, 0, 64, 48)
	atlas3.margin = Rect2(0, 0, 0, 0)
	sprite_frames.set_frame("idle", 2, atlas3)
	sprite_frames.set_frame("idle", 3, atlas2)
	sprite_frames.set_frame("idle", 4, atlas1)
	
func create_move_anim(unit_name: String, sprite_frames: SpriteFrames):
	var tex = UnitManager.unit_dict[unit_name].move_texture
	var offsety = -3
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 0, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		sprite_frames.set_frame("move_down", i, atlas)
		
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 40, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		sprite_frames.set_frame("move_left", i, atlas)
		
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 80, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		sprite_frames.set_frame("move_right", i, atlas)
	
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 122, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		sprite_frames.set_frame("move_up", i, atlas)
