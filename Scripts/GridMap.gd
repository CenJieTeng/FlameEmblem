extends Node2D
class_name CustomGridMap

@export var terrain_layer : TileMapLayer;
@export var move_layer : TileMapLayer;
@export var unit_layer : TileMapLayer;
@export var map_size : Vector2i

var terrain_data : Dictionary[Vector2i, TerrainData]

func _ready():
	load_terrain_data()

func load_terrain_data():
	for cell in terrain_layer.get_used_cells():
		var data = terrain_layer.get_cell_tile_data(cell)
		if data:
			var type = data.get_custom_data("type")
			var move_cost = data.get_custom_data("move_cost")
			var def = data.get_custom_data("def")
			var avo = data.get_custom_data("avo")
			terrain_data[cell] = TerrainData.new(type, move_cost, def, avo)
		else:
			print("找不到地图自定义数据 ", cell)
	print("地形数据加载完成")

# 获取地形数据
func get_terrain_data(grid: Vector2i) -> TerrainData:
	return terrain_data.get(grid)

# 世界坐标转网格坐标
func world_to_grid(pos: Vector2) -> Vector2i:
	return terrain_layer.local_to_map(pos)

# 网格坐标转世界坐标
func grid_to_world(grid: Vector2i) -> Vector2:
	return terrain_layer.map_to_local(grid)

func is_grid_in_map(grid: Vector2i) -> bool:
	if grid.x < 0 || grid.y < 0 || grid.x >= map_size.x || grid.y >= map_size.y :
		return false
	return true
	
# 网格坐标相对于地图中心点的偏移单位向量
func get_direction_to_center_from_grid(grid: Vector2i) -> Vector2:
	var center := map_size / 2
	var offset: Vector2 = grid - center
	return offset.normalized()


func create_moveable_sprites(grid_list: Array[Vector2i]):
	for grid in grid_list:
		_create_moveable_sprite(grid)

func _create_moveable_sprite(grid: Vector2i):
	var anim = AnimatedSprite2D.new()
	anim.sprite_frames = preload("res://SpriteFrames/BlueHightLight.tres")
	anim.play("default")
	anim.position = grid_to_world(grid)
	move_layer.add_child(anim)
	
func create_attackable_sprites(grid_list: Array[Vector2i]):
	for grid in grid_list:
		_create_attackable_sprite(grid)
	
func _create_attackable_sprite(grid: Vector2i):
	var anim = AnimatedSprite2D.new()
	anim.sprite_frames = preload("res://SpriteFrames/RedHightLight.tres")
	anim.play("default")
	anim.position = grid_to_world(grid)
	move_layer.add_child(anim)

func clear_moveable_sprites():
	for child in move_layer.get_children():
		child.queue_free()
		
		
