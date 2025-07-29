extends Node2D
class_name GameManager

@export var grid_map : CustomGridMap
@export var move_path_layer : TileMapLayer
@export var unit_menu : Control
@onready var unit_info_ui := $CanvasLayer/UnitInfo
@export var cursor : Cursor

# 单位相关
var unit_list : Array[Unit] = []
var pos_to_unit_map : Dictionary[Vector2i, Unit] = {}
var current_unit : Unit
var movement_arrow_tilest : TileSet
var move_path_gold_sprite : Sprite2D
var unit_command_list : Array[UnitCommand] = []

# 回合相关
var wave_count = 0
var wave_camp : Array[Unit.UnitCamp] = [Unit.UnitCamp.PLAYER, Unit.UnitCamp.ENEMY]
var current_wave_camp : Unit.UnitCamp = Unit.UnitCamp.PLAYER

enum GameState{
	WAITING_FOR_PLAYER,
	WAITING_FOR_AI,
	GAME_RUNING
}
var game_state := GameState.WAITING_FOR_PLAYER

enum PlayState{
	NONE,
	SELECT_UNIT,
	SELECT_ACTION,
	SELECT_ATTACK_TARGET,
	SELECT_USE_ITEM,
}
var play_state := PlayState.NONE:
	set(value):
		play_state = value
		check_hud_state()

enum EnemyState{
	NONE,
	MOVE,
}
var enemy_state := EnemyState.NONE

var _skip_rollback_states = {
	PlayState.SELECT_ATTACK_TARGET: true,
	PlayState.SELECT_USE_ITEM: true,
}

# 调试
var default_font = FontFile.new()
var default_font_size = ThemeDB.fallback_font_size

var enemy_unit : Unit

func _ready() -> void:
	movement_arrow_tilest = preload("res://Sprites/TileSet/MovementArrows.tres")
	create_unit("角色1", Vector2i(4, 4), Unit.UnitCamp.PLAYER)
	enemy_unit = create_unit("敌人1", Vector2i(6, 4), Unit.UnitCamp.ENEMY)
	cursor.set_pos2(Vector2i(4, 4))
	cursor.connect("pos_change", _on_cursor_pos_change)
	
	default_font = load("res://Fonts/fusion-pixel-monospaced.ttf") as FontFile
	default_font_size = 10

	check_hud_state()

func _process(_delta: float) -> void:
	queue_redraw()
	
	var command : UnitCommand = null
	match game_state:
		GameState.WAITING_FOR_PLAYER:
			command = handle_input()
		GameState.WAITING_FOR_AI:
			#command = handle_ai_input()
			wave_finish()
		GameState.GAME_RUNING:
			pass
	push_command(command)

func _draw():
	var color = Color.NAVY_BLUE
	draw_string(default_font, Vector2(0, 10), "game_state: %d" % [game_state], HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size, color)
	draw_string(default_font, Vector2(0, 20), "play_state: %d" % [play_state], HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size, color)
	draw_string(default_font, Vector2(0, 30), "select_unit: %s" % [current_unit.unit_name if current_unit else "null"], HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size, color)

func push_command(command: UnitCommand):
	if command:
		command.wave = wave_count
		game_state = GameState.GAME_RUNING
		unit_command_list.append(command)
		command.do()
		check_hud_state()

func _on_unit_signal(unit: Unit, action: String):
	if current_wave_camp == Unit.UnitCamp.PLAYER:
		game_state = GameState.WAITING_FOR_PLAYER
		play_state = PlayState.SELECT_ACTION
	else:
		game_state = GameState.WAITING_FOR_AI

	if unit:
		if action == "move_complate":
			update_unit_pos_map()
			show_menu()
		if action == "standby":
			check_wave_finish()

func _on_cursor_pos_change():
	if current_unit and play_state == PlayState.SELECT_UNIT:
		current_unit.calc_move_path(cursor.pos)
		if current_unit.move_path.size() < 2:
			move_path_layer.clear()
			if move_path_gold_sprite: move_path_gold_sprite.queue_free()
			return
		if move_path_gold_sprite: move_path_gold_sprite.queue_free()
		create_move_path_sprite(current_unit.move_path)

	check_hud_state()
	

func handle_input() -> UnitCommand:
	match play_state:
		PlayState.NONE:
			if Input.is_action_just_pressed("mouse_left"):
				var unit = get_unit_by_grid(cursor.pos)
				select_unit(unit)
		PlayState.SELECT_UNIT:
			if Input.is_action_just_pressed("mouse_left"):
				if not move_path_gold_sprite:
					grid_map.clear_moveable_sprites()
					play_state = PlayState.SELECT_ACTION
					show_menu()
					return
				var gold_grid = grid_map.world_to_grid(move_path_gold_sprite.position)
				if cursor.pos == gold_grid and current_unit.move_path.size() >= 2:
					move_path_layer.clear()
					if move_path_gold_sprite: move_path_gold_sprite.queue_free()
					grid_map.clear_moveable_sprites()
					return UnitMoveCommand.new(current_unit, gold_grid)
		PlayState.SELECT_ATTACK_TARGET:
			if Input.is_action_just_pressed("mouse_left"):
				if current_unit.is_in_attack_range(cursor.pos):
					var target = get_unit_by_grid(cursor.pos)
					if target:
						grid_map.clear_moveable_sprites()
						fight(current_unit, target)	

	
	if Input.is_action_just_pressed("mouse_right"):
		if not _skip_rollback_states.get(play_state, false) and not unit_command_list.is_empty():
			var command = unit_command_list.back() as UnitCommand
			if command.unit == current_unit and command.wave == wave_count:
				if command.can_undo:
					unit_command_list.pop_back()
					command.undo()
					if command is UnitMoveCommand:
						unit_menu.visible = false
						play_state = PlayState.SELECT_UNIT
						select_unit(command.unit)
						_on_cursor_pos_change()
				return null
		
		match play_state:
			PlayState.SELECT_UNIT:
				if current_unit:
					cursor.set_pos2(current_unit.grid_position)
					current_unit.move_path.clear()
					current_unit = null
					move_path_layer.clear()
					if move_path_gold_sprite: move_path_gold_sprite.queue_free()
					grid_map.clear_moveable_sprites()
					unit_menu.visible = false
					play_state = PlayState.NONE
			PlayState.SELECT_ACTION:
				grid_map.clear_moveable_sprites()
				unit_menu.visible = false
				play_state = PlayState.SELECT_UNIT
				select_unit(current_unit)
			PlayState.SELECT_ATTACK_TARGET:
				cursor.set_pos2(current_unit.grid_position)
				grid_map.clear_moveable_sprites()
				play_state = PlayState.SELECT_ACTION
	
	return null
	
func handle_ai_input():
	match enemy_state:
		EnemyState.NONE:
			select_unit(enemy_unit)
			enemy_state = EnemyState.MOVE
			return UnitMoveCommand.new(enemy_unit, Vector2i(enemy_unit.grid_position.x - 1, 4))
		EnemyState.MOVE:
			return UnitStandbyCommand.new(enemy_unit)
	return null

func create_unit(p_name: String, grid: Vector2i, camp: Unit.UnitCamp) -> Unit:
	if pos_to_unit_map.has(grid):
		return pos_to_unit_map[grid]
	var unit = preload("res://Scenes/Unit/Lord.tscn").instantiate() as Unit
	grid_map.unit_layer.add_child(unit)
	unit.init(p_name, grid, camp)
	unit_list.append(unit)
	unit.connect("unit_signal", _on_unit_signal)
	pos_to_unit_map[grid] = unit
	return unit
	
func select_unit(unit: Unit):
	if unit and not unit.is_standby and unit.camp == current_wave_camp:
		current_unit = unit
		current_unit.calc_moveable()
		if unit.camp == Unit.UnitCamp.PLAYER:
			current_unit.show_moveable()
			current_unit.clac_attckable()
		print("选中单位 ", current_unit.unit_name, " ", current_unit.position)
		cursor.set_pos2(unit.grid_position)
		play_state = PlayState.SELECT_UNIT
	
func update_unit_pos_map():
	pos_to_unit_map.clear()
	for unit in unit_list:
		pos_to_unit_map[unit.grid_position] = unit
	
func get_unit_by_grid(grid: Vector2i) -> Unit:
	if pos_to_unit_map.has(grid):
		return pos_to_unit_map[grid]
	return null
	
func check_wave_finish():
	for unit in unit_list:
		if unit.camp == current_wave_camp and not unit.is_standby:
			return
	wave_finish()

func wave_finish():
	print(Unit.UnitCamp.keys()[current_wave_camp], " 回合结束")
	current_unit = null
	current_wave_camp = wave_camp[(current_wave_camp + 1) % wave_camp.size()]
	wave_count += 1

	if current_wave_camp == Unit.UnitCamp.PLAYER:
		game_state = GameState.WAITING_FOR_PLAYER
		play_state = PlayState.NONE
	else:
		game_state = GameState.WAITING_FOR_AI
		enemy_state = EnemyState.NONE
	
	for unit in unit_list:
		unit.is_standby = false
		unit.animator.material = null
	
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
	move_path_gold_sprite =  Global.create_sprite_from_tile(movement_arrow_tilest.get_source(3), tile_coords)
	move_path_gold_sprite.position = grid_map.grid_to_world(path.back())
	move_path_layer.add_child(move_path_gold_sprite)

func show_menu():
	if game_state != GameState.WAITING_FOR_PLAYER:
		return
	unit_menu.show_ui()
	var window_size = DisplayServer.window_get_size() / 3.2
	if current_unit.position.x < window_size.x / 2:
		unit_menu.position = Vector2(window_size.x * 4 / 5, window_size.y / 3)
	else:
		unit_menu.position = Vector2(window_size.x / 5 - 23, window_size.y / 3)

func check_hud_state():
	unit_info_ui.visible = false
	if play_state == PlayState.NONE:
		var unit = get_unit_by_grid(cursor.pos)
		if unit:
			unit_info_ui.visible = true
			unit_info_ui.update_info(unit)
		
func select_menu_item(index: int):
	match index:
		1:
			play_state = PlayState.SELECT_ATTACK_TARGET
			current_unit.clac_attckable2()
		3:
			push_command(UnitStandbyCommand.new(current_unit))
			current_unit = null
			play_state = PlayState.NONE
			unit_menu.visible = false

func attack(attack_unit: Unit, target_unit: Unit):
	var damage = attack_unit.stats["atk"] - target_unit.stats["def"]
	if damage > 0:
		target_unit.stats["hp"] -= damage
		print(attack_unit.unit_name, " 攻击 ", target_unit.unit_name, " 造成 ", damage, " 伤害")
		print(target_unit.unit_name, " 剩余 ", target_unit.stats["hp"], " 生命值")

func fight(attack_unit: Unit, target_unit: Unit):
	attack(attack_unit, target_unit)
	unit_menu.visible = false
	current_unit = null
	target_unit = null
	push_command(UnitStandbyCommand.new(attack_unit))
