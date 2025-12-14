extends Node2D
class_name GameManager

@onready var grid_map : CustomGridMap = $"../Map"
@onready var move_path_layer : TileMapLayer = $"../Map/MovePathLayer"
@onready var unit_menu : Control = $"../CanvasLayer/UnitMenu"
@onready var unit_info_ui : Control = $"../CanvasLayer/UnitInfoUI"
@onready var unit_fight_info_ui : Control = $"../CanvasLayer/UnitFightInfoUI"
@onready var terrain_info_ui : Control = $"../CanvasLayer/TerrainInfoUI"
@onready var wave_info_ui : Control = $"../CanvasLayer/WaveInfoUI"
@onready var cursor : Cursor = $"../Cursor"
@onready var battle_system : BattleSystem = $"../BattleSystem"
@onready var ai_manager : AIManager = $"../AIManager"

var cursor_dir : Vector2
var window_size
var is_processing_input := false
var is_wave_finish := false

# 单位相关
var unit_list : Array[Unit] = []
var pos_to_unit_map : Dictionary[Vector2i, Unit] = {}
var current_unit : Unit
var movement_arrow_tilest : TileSet
var move_path_gold_sprite : Sprite2D
var unit_command_list : Array[UnitCommand] = []
var select_unit_index = 0

var attackable_unit_list : Array[Unit] = []
var select_attack_index = 0

# 回合相关
var wave_count = 1
var max_wave = 3
var wave_camp : Array[Unit.UnitCamp] = [Unit.UnitCamp.PLAYER, Unit.UnitCamp.ENEMY]
var current_wave_camp : Unit.UnitCamp = Unit.UnitCamp.PLAYER

enum GameState{
	WAITING_FOR_PLAYER,
	WAITING_FOR_AI,
	GAME_RUNING,
	GAME_FINISH
}
var game_state := GameState.WAITING_FOR_PLAYER:
	set(value):
		game_state = value
		check_hud_state()

enum PlayState{
	NONE,
	SELECT_UNIT,
	SELECT_ACTION,
	SELECT_WEAPON,
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
	PlayState.SELECT_WEAPON: true,
	PlayState.SELECT_ATTACK_TARGET: true,
	PlayState.SELECT_USE_ITEM: true,
}

# 调试
var default_font = FontFile.new()
var default_font_size = ThemeDB.fallback_font_size

var enemy_unit : Unit
 
func _ready() -> void:
	InputManager.register_game_input_handlers(self)
	window_size = get_viewport().get_visible_rect().size / DisplayServer.screen_get_scale()
	movement_arrow_tilest = preload("res://Sprites/TileSet/MovementArrows.tres")
	default_font = load("res://Fonts/fusion-pixel-monospaced.ttf") as FontFile
	default_font_size = 10
	cursor.connect("pos_change", _on_cursor_pos_change)	
	check_hud_state()

	grid_map.init(self)
	ai_manager.init(self)
	
	SceneManager.connect("pre_scene_change", func():
		for unit in unit_list:
			unit.save_data()
	)

func _process(_delta: float) -> void:
	queue_redraw()
	
func handle_game_input():
	if Input.is_action_just_pressed("toggle_console"):
		UIManager.open(UIManager.UI_NAME.CONSOLE)
		return
		
	if is_processing_input || is_wave_finish:
		return
	is_processing_input = true

	var command : UnitCommand = null
	match game_state:
		GameState.WAITING_FOR_PLAYER:
			command = handle_input()
		GameState.WAITING_FOR_AI:
			await get_tree().create_timer(0.5).timeout
			command = ai_manager.process_ai_turn()
		GameState.GAME_RUNING:
			pass
	push_command(command)
	is_processing_input = false

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

	if action == "move_complate":
		update_unit_pos_map()
		show_menu()
	if action == "die":
		unit_list.erase(unit)
		update_unit_pos_map()
	if action == "standby" or action == "die":
		check_game_win_or_lose()
		if game_state == GameState.GAME_FINISH:
			return
		check_wave_finish()
		if current_wave_camp == Unit.UnitCamp.PLAYER:
			play_state = PlayState.NONE

func _on_cursor_pos_change():
	cursor_dir = grid_map.get_direction_to_center_from_grid(cursor.pos)
	#print(cursor.pos)
	#print("偏移向量: ", "左" if cursor_dir.x < 0 else "右", "上" if cursor_dir.y < 0 else "下");
	
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
			if Input.is_action_just_pressed("RB"):
				for i in range(unit_list.size()):
					var next_select_index = (select_unit_index + i + 1) % unit_list.size()
					var unit = unit_list[next_select_index]
					if unit.camp == Unit.UnitCamp.PLAYER and not unit.is_standby:
						cursor.set_pos2(unit.grid_position)
						select_unit_index = next_select_index
						break
		PlayState.SELECT_UNIT:
			if Input.is_action_just_pressed("mouse_left"):
				if cursor.pos == current_unit.grid_position:
					grid_map.clear_moveable_sprites()
					play_state = PlayState.SELECT_ACTION
					show_menu()
					return
				if move_path_gold_sprite and not pos_to_unit_map.has(cursor.pos):
					var gold_grid = grid_map.world_to_grid(move_path_gold_sprite.position)
					if cursor.pos == gold_grid and current_unit.move_path.size() >= 2:
						move_path_layer.clear()
						if move_path_gold_sprite: move_path_gold_sprite.queue_free()
						grid_map.clear_moveable_sprites()
						return UnitMoveCommand.new(current_unit, gold_grid)
		PlayState.SELECT_ATTACK_TARGET:
			if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("up"):
				select_attack_target(select_attack_index - 1)
			if Input.is_action_just_pressed("right") or Input.is_action_just_pressed("down"):
				select_attack_target(select_attack_index + 1)

			if Input.is_action_just_pressed("mouse_left"):
				if current_unit.is_in_attack_range(cursor.pos):
					var target = get_unit_by_grid(cursor.pos)
					if target:
						UIManager.close(UIManager.UI_NAME.QUICK_ATTACK_INFO_UI)
						grid_map.clear_moveable_sprites()
						return UnitAttackCommand.new(current_unit, target)

	
	if Input.is_action_just_pressed("mouse_right"):
		if not _skip_rollback_states.get(play_state, false) and not unit_command_list.is_empty():
			var command = unit_command_list.back() as UnitCommand
			if command.unit == current_unit and command.wave == wave_count:
				if command.can_undo:
					unit_command_list.pop_back()
					command.undo()
					if command is UnitMoveCommand:
						UIManager.close(UIManager.UI_NAME.UNIT_MENU)
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
					UIManager.close(UIManager.UI_NAME.UNIT_MENU)
					play_state = PlayState.NONE
			PlayState.SELECT_ACTION:
				grid_map.clear_moveable_sprites()
				UIManager.close(UIManager.UI_NAME.UNIT_MENU)
				play_state = PlayState.SELECT_UNIT
				select_unit(current_unit)
			PlayState.SELECT_WEAPON:
				cursor.set_pos2(current_unit.grid_position)
				grid_map.clear_moveable_sprites()
				UIManager.close(UIManager.UI_NAME.SELECT_WEAPON_UI)
				UIManager.open(UIManager.UI_NAME.UNIT_MENU)
				play_state = PlayState.SELECT_ACTION
			PlayState.SELECT_ATTACK_TARGET:
				cursor.set_pos2(current_unit.grid_position)
				grid_map.clear_moveable_sprites()
				UIManager.close(UIManager.UI_NAME.QUICK_ATTACK_INFO_UI)
				UIManager.open(UIManager.UI_NAME.SELECT_WEAPON_UI)
				play_state = PlayState.SELECT_WEAPON
	
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

func create_unit(p_name: String, grid: Vector2i, camp: Unit.UnitCamp, strategy := AIBrain.AIStrategy.NONE) -> Unit:
	if pos_to_unit_map.has(grid):
		return pos_to_unit_map[grid]
	var unit = preload("res://Scenes/Unit/Unit.tscn").instantiate() as Unit
	grid_map.unit_layer.add_child(unit)
	unit.init(p_name, grid, camp)
	unit_list.append(unit)
	unit.connect("unit_signal", _on_unit_signal)
	pos_to_unit_map[grid] = unit
	if unit.camp != Unit.UnitCamp.PLAYER:
		ai_manager.register_ai_unit(unit, strategy)
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

func check_game_win_or_lose():
	if wave_count > max_wave * wave_camp.size():
		print("玩家失败")
		game_state = GameState.GAME_FINISH
		return

	var player_count = 0
	var enemy_count = 0
	for unit in unit_list:
		if unit.camp == Unit.UnitCamp.PLAYER:
			player_count += 1
		else:
			enemy_count += 1
	if player_count == 0:
		print("玩家失败")
		game_state = GameState.GAME_FINISH
		SceneManager.restart_scene()
		return
	if enemy_count == 0:
		print("玩家胜利")
		game_state = GameState.GAME_FINISH
		UIManager.open(UIManager.UI_NAME.LEVEL_PASS_UI)
		return

func check_wave_finish():
	if is_wave_finish:
		return

	for unit in unit_list:
		if unit.camp == current_wave_camp and not unit.is_standby:
			return

	wave_finish()

func wave_finish():
	print(Unit.UnitCamp.keys()[current_wave_camp], " 回合结束")

	is_wave_finish = true
	await get_tree().create_timer(1).timeout

	current_unit = null
	current_wave_camp = wave_camp[(current_wave_camp + 1) % wave_camp.size()]
	wave_count += 1
	wave_info_ui.set_wave(int(ceil(float(wave_count) / wave_camp.size())))

	check_game_win_or_lose()
	if game_state == GameState.GAME_FINISH:
		return

	if current_wave_camp == Unit.UnitCamp.PLAYER:
		game_state = GameState.WAITING_FOR_PLAYER
		play_state = PlayState.NONE
	else:
		game_state = GameState.WAITING_FOR_AI
		enemy_state = EnemyState.NONE
	
	for unit in unit_list:
		unit.is_standby = false
		unit.animator.material = null

	is_wave_finish = false
	
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
	UIManager.open(UIManager.UI_NAME.UNIT_MENU)
	if current_unit.position.x < window_size.x / 2:
		unit_menu.position = Vector2(window_size.x * 4 / 5, window_size.y / 3)
	else:
		unit_menu.position = Vector2(window_size.x / 5 - 23, window_size.y / 3)

func check_hud_state():
	unit_info_ui.visible = false
	terrain_info_ui.visible = false
	wave_info_ui.visible = false
	var ui_slot_list : Array[int]
	if game_state == GameState.WAITING_FOR_PLAYER:	
		if play_state == PlayState.NONE:
			var unit = get_unit_by_grid(cursor.pos)
			if unit:
				unit_info_ui.visible = true
				unit_info_ui.update_info(unit)
				if cursor_dir.y < 0:
					unit_info_ui.set_position(Vector2(5, window_size.y - 35))
					ui_slot_list.append(3)
				else:
					unit_info_ui.set_position(Vector2(5, 5))
					ui_slot_list.append(1)
					
			var terrain_data = grid_map.get_terrain_data(cursor.pos)
			if terrain_data:
				terrain_info_ui.visible = true
				terrain_info_ui.update_info(terrain_data)
				if cursor_dir.x < 0 or ui_slot_list.has(3):
					terrain_info_ui.set_position(Vector2(window_size.x - 40, window_size.y - 40))
					ui_slot_list.append(4)
				else:
					terrain_info_ui.set_position(Vector2(5, window_size.y - 40))
					ui_slot_list.append(3)
					
			wave_info_ui.visible = true
			var wave_info_scale = 0.8
			if cursor_dir.y > 0 or ui_slot_list.has(4):
				wave_info_ui.set_position(Vector2(window_size.x - 85  * wave_info_scale, 5 * wave_info_scale))
			else:
				wave_info_ui.set_position(Vector2(window_size.x - 85 * wave_info_scale, window_size.y - 45 * wave_info_scale))
		
func select_menu_item(index: int):
	match index:
		1:
			play_state = PlayState.SELECT_WEAPON
			UIManager.open(UIManager.UI_NAME.SELECT_WEAPON_UI)
		3:
			push_command(UnitStandbyCommand.new(current_unit))
			current_unit = null
			play_state = PlayState.NONE
			UIManager.close(UIManager.UI_NAME.UNIT_MENU)
			
func select_weapon_item(weapon: Weapon):
	current_unit.weapon = weapon
	play_state = PlayState.SELECT_ATTACK_TARGET
	UIManager.close(UIManager.UI_NAME.SELECT_WEAPON_UI)
	UIManager.close(UIManager.UI_NAME.UNIT_MENU)

	current_unit.clac_attckable2()
	attackable_unit_list.clear()
	for grid in current_unit.attackable_grids:
		var unit = get_unit_by_grid(grid)
		if unit:
			attackable_unit_list.append(unit)

	var center_pos = current_unit.grid_position
	attackable_unit_list.sort_custom(func(a: Unit, b: Unit) -> int:
		var angle_a = (Vector2)(a.grid_position - center_pos).angle()
		var angle_b = (Vector2)(b.grid_position - center_pos).angle()
		print("unita: ", a.grid_position, "unitb: ", b.grid_position, "angle_a: ", angle_a, " angle_b: ", angle_b)
		if angle_a < angle_b:
			return true
		elif angle_a > angle_b:
			return false
		else:
			return sign((a - center_pos).length_squared() - (b - center_pos).length_squared())
	)
	select_attack_index = 0
	select_attack_target(0)
	UIManager.open(UIManager.UI_NAME.QUICK_ATTACK_INFO_UI)

func select_attack_target(index: int):
	if attackable_unit_list.size() == 0:
		return
	select_attack_index = index % attackable_unit_list.size()
	var target_unit = attackable_unit_list[select_attack_index]
	cursor.set_pos2(target_unit.grid_position)
	var attack_info_ui = UIManager.get_ui(UIManager.UI_NAME.QUICK_ATTACK_INFO_UI)
	var quick_battle_info = battle_system.quick_battle_info(current_unit, target_unit)
	attack_info_ui.update_info(current_unit, target_unit, quick_battle_info)
	if current_unit.position.x < window_size.x / 2:
		attack_info_ui.position = Vector2(window_size.x - 69 - window_size.x / 20, window_size.y / 20)
	else:
		attack_info_ui.position = Vector2(window_size.x / 20, window_size.y / 20)

func fight(attack_unit: Unit, target_unit: Unit):
	game_state = GameState.GAME_RUNING
	
	await battle_system.battle(attack_unit, target_unit)

	UIManager.close(UIManager.UI_NAME.UNIT_MENU)
	current_unit = null
	target_unit = null
		
	if attack_unit:
		push_command(UnitStandbyCommand.new(attack_unit))
