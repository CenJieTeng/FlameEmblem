extends Node2D
class_name Unit

enum UnitCamp
{
	PLAYER,
	ENEMY
}

var unit_name : String = "名称"
var stats=  {
	"max_hp": 20,
	"hp": 20,
	"atk": 8,
	"def": 4,
	"mov": 7  # 移动力
}
var camp = UnitCamp.PLAYER
var old_grid_position = Vector2i.ZERO
var grid_position = Vector2i.ZERO
var is_move := false
var is_standby := false
var moveable_grids : Array[Vector2i] = []
var move_path : Array[Vector2i] = []
var simple_move_path : Array[Vector2i] = []
var attackable_grids : Array[Vector2i] = []

var game_manager : GameManager
var grid_map : CustomGridMap
var animator : AnimatedSprite2D

func _ready() -> void:
	game_manager = get_node("/root/Node2D")
	grid_map = get_node("/root/Node2D/Map")
	animator = get_node("AnimatedSprite2D")
	
	add_user_signal("unit_signal", [
		{ "unit": Unit, "action": TYPE_STRING }
	])

func init(p_name: String, pos: Vector2i, p_camp: UnitCamp) -> void:
	unit_name = p_name
	grid_position = pos
	camp = p_camp
	position = grid_map.grid_to_world(grid_position)
	animator.sprite_frames = load("res://Sprites/Animation/UnitSpriteFrames/Lord.tres").duplicate(true)
	
	# 创建待机动画
	create_idle_anim()

	# 创建移动动画
	create_move_anim()
	
	animator.play("idle")
	
func create_idle_anim():
	var tex = load(Global.name_to_unit_sprite_frames_map[unit_name][0])
	var atlas1 = AtlasTexture.new()
	atlas1.atlas = tex
	atlas1.region = Rect2(0, 0, 64, 48)
	atlas1.margin = Rect2(0, -8, 0, 0)
	animator.sprite_frames.set_frame("idle", 0, atlas1)
	var atlas2 = AtlasTexture.new()
	atlas2.atlas = tex
	atlas2.region = Rect2(64, 0, 64, 48)
	atlas2.margin = Rect2(0, -8, 0, 0)
	animator.sprite_frames.set_frame("idle", 1, atlas2)
	var atlas3 = AtlasTexture.new()
	atlas3.atlas = tex
	atlas3.region = Rect2(128, 0, 64, 48)
	atlas3.margin = Rect2(0, -8, 0, 0)
	animator.sprite_frames.set_frame("idle", 2, atlas3)
	animator.sprite_frames.set_frame("idle", 3, atlas2)
	animator.sprite_frames.set_frame("idle", 4, atlas1)
	
func create_move_anim():
	var tex = load(Global.name_to_unit_sprite_frames_map[unit_name][1])
	var offsety = -11
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 0, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		animator.sprite_frames.set_frame("move_down", i, atlas)
		
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 40, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		animator.sprite_frames.set_frame("move_left", i, atlas)
		
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 80, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		animator.sprite_frames.set_frame("move_right", i, atlas)
	
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 122, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		animator.sprite_frames.set_frame("move_up", i, atlas)
	
func set_pos(grid: Vector2i):
	old_grid_position = grid_position
	grid_position = grid
	position = grid_map.grid_to_world(grid)
	game_manager.update_unit_pos_map()

func get_move_path(walkable_cells: Array[Vector2i], start: Vector2i, end: Vector2i) -> PackedVector2Array:
	var astar = AStar2D.new()
	
	for cell in walkable_cells:
		var point_id = astar.get_available_point_id()  # 获取唯一 ID
		astar.add_point(point_id, Vector2(cell.x, cell.y), 1.0)  # 权重设为 1
		
	for cell in walkable_cells:
		var point_id = astar.get_closest_point(Vector2(cell.x, cell.y))
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var neighbor = cell + dir
			if neighbor in walkable_cells:
				var neighbor_id = astar.get_closest_point(Vector2(neighbor.x, neighbor.y))
				astar.connect_points(point_id, neighbor_id, false)  # 无向连接
	
	var start_id = astar.get_closest_point(Vector2(start.x, start.y))
	var end_id = astar.get_closest_point(Vector2(end.x, end.y))
	
	if start_id == -1 or end_id == -1:
		return PackedVector2Array()  # 起点或终点不可达
	
	var path = astar.get_point_path(start_id, end_id)
	return path
	
func calc_moveable():
	moveable_grids.clear()
	var queue = []
	var visited = {}
	queue.push_back({"pos": grid_position, "move_cost": 0})
	while not queue.is_empty():
		var current = queue.pop_front()
		
		if current.move_cost < stats["mov"]:
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next_pos = current.pos + dir
				
				if visited.has(next_pos):
					continue
					
				var terrain_data = grid_map.get_terrain_data(next_pos)
				if not terrain_data or current.move_cost + terrain_data.move_cost > stats["mov"]:
					continue

				if next_pos != grid_position and game_manager.pos_to_unit_map.has(next_pos):
					continue
					
				visited[next_pos] = true
				moveable_grids.append(next_pos)
				queue.push_back({"pos": next_pos, "move_cost": current.move_cost + terrain_data.move_cost})

func show_moveable():
	grid_map.create_moveable_sprites(moveable_grids)
	
func clac_attckable():
	attackable_grids.clear()
	var attack_range = 1
	var queue = []
	var visited = {}
	for pos in moveable_grids:
		queue.push_back({"pos": pos, "move_cost": 0})
		visited[pos] = true
		
	while not queue.is_empty():
		var current = queue.pop_front()
		
		if current.move_cost < stats["mov"]:
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next_pos = current.pos + dir
				
				if visited.has(next_pos):
					continue
					
				var terrain_data = grid_map.get_terrain_data(next_pos)
				if not terrain_data:
					continue
					
				if current["move_cost"] + 1 > attack_range:
					continue
					
				visited[next_pos] = true
				attackable_grids.append(next_pos)
				queue.push_back({"pos": next_pos, "move_cost": current.move_cost + 1})
	
	grid_map.create_attackable_sprites(attackable_grids)
	
func clac_attckable2():
	attackable_grids.clear()
	var attack_range = 1
	var queue = []
	var visited = {}
	visited[grid_position] = true
	queue.push_back({"pos": grid_position, "move_cost": 0})
		
	while not queue.is_empty():
		var current = queue.pop_front()
		
		if current.move_cost < stats["mov"]:
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next_pos = current.pos + dir
				
				if visited.has(next_pos):
					continue
					
				var terrain_data = grid_map.get_terrain_data(next_pos)
				if not terrain_data:
					continue
					
				if current["move_cost"] + 1 > attack_range:
					continue
					
				visited[next_pos] = true
				attackable_grids.append(next_pos)
				queue.push_back({"pos": next_pos, "move_cost": current.move_cost + 1})
	
	grid_map.create_attackable_sprites(attackable_grids)

func is_in_attack_range(target_grid: Vector2i):
	if attackable_grids.has(target_grid):
		return true
	return false

func calc_move_path(target_grid: Vector2i):
	if moveable_grids.has(target_grid):
		var path = get_move_path(moveable_grids, grid_position, target_grid)
		move_path.clear()
		simple_move_path.clear()
		for pos in path:
			move_path.append(Vector2i(pos))
		simple_move_path = move_path.duplicate(true)
		var i := 0
		while i <= simple_move_path.size() - 3:
			var current_slice := simple_move_path.slice(i, i+3)
			if current_slice.size() < 3:
				break
			if not Global.is_perpendicular_2d(current_slice[0], current_slice[1], current_slice[2]):
				simple_move_path.remove_at(i + 1)
			else:
				i += 1
		#print("path", move_path)
		#print("simple_path", simple_move_path)

func move_to(target_grid: Vector2i = Vector2i(-1, -1)):
	if target_grid != Vector2i(-1, -1):
		calc_moveable()
		calc_move_path(target_grid)
	
	if is_move or simple_move_path.is_empty():
		printerr("move path is empty")
		return
	is_move = true
	old_grid_position = grid_position
	
	for pos in simple_move_path:
		var move_anim : String
		if pos.x > grid_position.x: move_anim = "move_right"
		if pos.x < grid_position.x: move_anim = "move_left"
		if pos.y > grid_position.y: move_anim = "move_down"
		if pos.y < grid_position.y: move_anim = "move_up"
		animator.play(move_anim)
		
		var new_position = grid_map.grid_to_world(pos)
		var tween = create_tween()
		var move_time = pos.distance_to(grid_position) * 0.15
		tween.tween_property(self, "position", new_position, move_time)
		await get_tree().create_timer(move_time).timeout
		grid_position = Vector2i(pos)

	is_move = false
	move_path.clear()
	simple_move_path.clear()
	animator.play("idle")
	emit_signal("unit_signal", self, "move_complate")
	
func standby():
	is_standby = true
	animator.material = preload("res://Shader/SpriteGray.tres")
	emit_signal("unit_signal", self, "standby")
	
