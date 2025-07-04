extends Node2D
class_name GameManager

@export var grid_map : CustomGridMap
@export var move_path_layer : TileMapLayer

var unit1 : Unit
var unit2 : Unit
var unit_list : Array[Unit] = []
var pos_to_unit_map : Dictionary[Vector2i, Unit] = {}
var current_unit : Unit
var cursor_pos : Vector2i
var cursor_anim = AnimatedSprite2D.new()
var movement_arrow_tilest : TileSet
var move_path_goal_sprite : Sprite2D

enum GameState{
	WAITING_FOR_PLAYER,
	SELECTING_TILE,
	GAME_RUNING
}
var game_state = GameState.WAITING_FOR_PLAYER

func _ready() -> void:
	movement_arrow_tilest = preload("res://Sprites/TileSet/MovementArrows.tres")
	
	unit1 = create_unit("角色1", Vector2i(4, 4))
	unit2 = create_unit("角色2", Vector2i(6, 4))
	cursor_pos =  unit1.grid_position
	create_cursor_sprite(cursor_pos)

func _on_unit_signal(unit: Unit, action: String):
	if current_unit == unit:
		if action == "move_complate":
			pos_to_unit_map[current_unit.grid_position] = current_unit
			pos_to_unit_map.erase(current_unit.old_grid_position)
			current_unit = null
			game_state = GameState.WAITING_FOR_PLAYER

func _process(_delta: float) -> void:
	match game_state:
		GameState.WAITING_FOR_PLAYER:
			if Input.is_action_just_pressed("moouse_left"):
				var grid = grid_map.world_to_grid(get_global_mouse_position())
				var unit = get_unit_by_grid(grid)
				if unit:
					current_unit = unit
					current_unit.show_moveable()
					print("选中单位 ", current_unit.unit_name)
					game_state = GameState.SELECTING_TILE
		GameState.SELECTING_TILE:
			if Input.is_action_just_pressed("moouse_left"):
				var grid = grid_map.world_to_grid(get_global_mouse_position())
				if grid == cursor_pos and current_unit.move_path.size() >= 2:
					move_path_layer.clear()
					if move_path_goal_sprite: move_path_goal_sprite.queue_free()
					grid_map.clear_moveable_sprites()
					current_unit.move_to()
					game_state = GameState.GAME_RUNING
				else:
					current_unit.cal_move_path(grid)
					if current_unit.move_path.size() < 2:
						return
					if move_path_goal_sprite: move_path_goal_sprite.queue_free()
					create_move_path_sprite(current_unit.move_path)
		GameState.GAME_RUNING:
			pass
	
	match game_state:
		GameState.WAITING_FOR_PLAYER, GameState.SELECTING_TILE:
			if Input.is_action_just_pressed("moouse_left"):
				var grid = grid_map.world_to_grid(get_global_mouse_position())
				cursor_pos = grid
				cursor_anim.position = grid_map.grid_to_world(grid)
			
			if Input.is_action_just_pressed("mouse_right"):
				if current_unit:
					current_unit.move_path.clear()
					cursor_pos = current_unit.grid_position
					cursor_anim.position = grid_map.grid_to_world(cursor_pos)
					current_unit = null
					move_path_layer.clear()
					if move_path_goal_sprite: move_path_goal_sprite.queue_free()
					grid_map.clear_moveable_sprites()
				game_state = GameState.WAITING_FOR_PLAYER
			
func create_unit(p_name: String, grid: Vector2i) -> Unit:
	if pos_to_unit_map.has(grid):
		return pos_to_unit_map[grid]
	var unit = preload("res://Scenes/Unit/Lord.tscn").instantiate() as Unit
	grid_map.unit_layer.add_child(unit)
	unit.init(p_name, grid)
	unit_list.append(unit)
	unit.connect("unit_signal", _on_unit_signal)
	pos_to_unit_map[grid] = unit
	return unit
	
func get_unit_by_grid(grid: Vector2i) -> Unit:
	if pos_to_unit_map.has(grid):
		return pos_to_unit_map[grid]
	return null

func create_cursor_sprite(grid: Vector2i):
	cursor_anim.sprite_frames = preload("res://Sprites/Animation/Cursor1.tres")
	cursor_anim.play("default")
	cursor_anim.position = grid_map.grid_to_world(grid)
	cursor_anim.offset = Vector2(-0.5, 1)
	get_tree().current_scene.add_child(cursor_anim)
	
func create_move_path_sprite(path: Array[Vector2i]):
	move_path_layer.clear()
	move_path_layer.set_cells_terrain_path(path, 0, 0)
	move_path_layer.set_cell(path.back())
	
	var dir = path[-1] - path[-2]
	var tile_coords
	match dir:
		Vector2i.RIGHT:
			tile_coords = Vector2i(0, 0)
		Vector2i.DOWN:
			tile_coords = Vector2i(1, 0)
		Vector2i.LEFT:
			tile_coords = Vector2i(1, 1)
		Vector2i.UP:
			tile_coords = Vector2i(0, 1)
	move_path_goal_sprite =  Global.create_sprite_from_tile(movement_arrow_tilest.get_source(3), tile_coords)
	move_path_goal_sprite.position = grid_map.grid_to_world(path.back())
	move_path_layer.add_child(move_path_goal_sprite)
