extends Node2D

var terrain_type_to_name_map = {
	"plain" : "平原",
	"foest" : "森林",
	"mountain" : "山脉",
	"sea" : "海",
}

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

# 判断三点A-B-C是否形成直角（B为顶点）
func is_perpendicular_2d(a: Vector2, b: Vector2, c: Vector2, epsilon: float = 0.0001) -> bool:
	var ba := a - b
	var bc := c - b
	ba = ba.normalized()
	bc = bc.normalized()
	return abs(ba.dot(bc)) < epsilon

# 从图块集（TileSet）中创建一个Sprite2D对象
func create_sprite_from_tile(atlas_source: TileSetAtlasSource, tile_coords: Vector2i) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = atlas_source.texture
	sprite.region_enabled = true
	sprite.region_rect = atlas_source.get_tile_texture_region(tile_coords)
	return sprite

# 遍历获取文件夹所有文件
func list_files_in_directory(path: String) -> Array[String]:
	var dir = DirAccess.open(path)
	var files: Array[String] = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("目录不存在: " + path)
	return files
