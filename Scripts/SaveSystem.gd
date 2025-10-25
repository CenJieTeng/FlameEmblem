extends Node

const SAVE_PATH = "user://savedata/game_save.tres"

var save_data : GameSaveData = GameSaveData.new()

func _ready() -> void:
	# 确保目录存在
	var dir = DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("savedata")
	else:
		print("错误：无法访问 user:// 目录")

	load_game()

func save_game():
	return
	save_data.timestamp = Time.get_date_string_from_system()
	var error = ResourceSaver.save(save_data, SAVE_PATH)
	if error != OK:
		print("错误：无法保存游戏数据，错误代码：%d" % error)
	else:
		print("游戏数据已保存至 %s" % SAVE_PATH)

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		save_data = load(SAVE_PATH)
		print("游戏数据已从 %s 加载" % SAVE_PATH)

func save_unit(unit_data: UnitData):
	save_data.unit_dict[unit_data.unit_name] = unit_data

	
