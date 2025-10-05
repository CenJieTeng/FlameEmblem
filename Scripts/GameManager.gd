extends Node2D
class_name GameManager

@onready var grid_map : CustomGridMap = $"../Map"
@onready var move_path_layer : TileMapLayer = $"../Map/MovePathLayer"
@onready var unit_menu : Control = $"../CanvasLayer/UnitMenu"
@onready var unit_info_ui : Control = $"../CanvasLayer/UnitInfoUI"
@onready var unit_fight_info_ui : Control = $"../CanvasLayer/UnitFightInfoUI"
@onready var terrain_info_ui : Control = $"../CanvasLayer/TerrainInfoUI"
@onready var wave_info_ui : Control = $"../CanvasLayer/WaveInfoUI"
@onready var console_ui : Control = $"../CanvasLayer/Console"
@onready var cursor : Cursor = $"../Cursor"

var cursor_dir : Vector2
var window_size = DisplayServer.window_get_size() / 3.2

# 单位相关
var unit_list : Array[Unit] = []
var pos_to_unit_map : Dictionary[Vector2i, Unit] = {}
var current_unit : Unit
var movement_arrow_tilest : TileSet
var move_path_gold_sprite : Sprite2D
var unit_command_list : Array[UnitCommand] = []
var select_unit_index = 0

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
	default_font = load("res://Fonts/fusion-pixel-monospaced.ttf") as FontFile
	default_font_size = 10
	cursor.connect("pos_change", _on_cursor_pos_change)	
	check_hud_state()

func _process(_delta: float) -> void:
	queue_redraw()
	
	if console_ui.visible:
		return
		
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

	if action == "move_complate":
		update_unit_pos_map()
		show_menu()
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
	var unit = preload("res://Scenes/Unit/Unit.tscn").instantiate() as Unit
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
		SceneManager.go_to_next_level()
		return

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

func shake_target(target: Node, strength: float = 10.0, duration: float = 0.15, loops: int = 3):
	var shake = create_tween().set_loops(loops)

	# 向左震动
	shake.tween_property(target, "rotation", deg_to_rad(-strength), duration * 0.33).set_trans(Tween.TRANS_SINE)

	# 向右震动
	shake.tween_property(target, "rotation", deg_to_rad(strength), duration * 0.33).set_trans(Tween.TRANS_SINE)

	# 回正
	shake.tween_property(target, "rotation", 0, duration * 0.33).set_trans(Tween.TRANS_SINE)
	await shake.finished

func attack_anim(attack_unit: Unit, target_unit: Unit):
	var attack_z_index = attack_unit.z_index
	var target_z_index = target_unit.z_index
	attack_unit.z_index = 100 * attack_unit.grid_position.y + 1
	target_unit.z_index = 100 * target_unit.grid_position.y

	var anim : String
	if target_unit.grid_position.x > attack_unit.grid_position.x: anim = "move_right"
	if target_unit.grid_position.x < attack_unit.grid_position.x: anim = "move_left"
	if target_unit.grid_position.y > attack_unit.grid_position.y: anim = "move_down"
	if target_unit.grid_position.y < attack_unit.grid_position.y: anim = "move_up"
	attack_unit.animator.play(anim)
	attack_unit.animator.stop()

	await get_tree().create_timer(0.3).timeout
	attack_unit.animator.play()

	var tween = create_tween()
	var origin = attack_unit.position
	var tween_time = 0.2
	tween.tween_property(attack_unit, "position", origin.lerp(target_unit.position, 0.6), tween_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	#tween.tween_property(attack_unit, "position", origin.lerp(target_unit.position, 0.55), tween_time/2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	#tween.tween_property(attack_unit, "position", origin.lerp(target_unit.position, 0.6), tween_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

	attack_unit.animator.speed_scale = 2.0

	# 被攻击单位加上闪烁效果，使用tween实现
	var tween_time2 = 0.08
	tween =	create_tween()
	await tween.tween_property(target_unit, "modulate", Color(2, 2, 2, 1), tween_time2).finished

	attack(attack_unit, target_unit)

	# 震动
	await shake_target(target_unit, 3.0, 0.1, 1)

	tween =	create_tween()
	await tween.tween_property(target_unit, "modulate", Color(1, 1, 1, 1), tween_time2).finished

	attack_unit.animator.speed_scale = 1.0
	attack_unit.animator.stop()

	tween = create_tween()
	tween.tween_property(attack_unit, "position", origin, tween_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

	attack_unit.animator.play("idle")
	
	if target_unit.stats["hp"] <= 0:
		print(target_unit.unit_name, " 死亡")
		tween = create_tween()
		tween.tween_property(target_unit, "modulate", Color(1, 1, 1, 0), tween_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		get_tree().create_timer(1).timeout.connect(func():
			target_unit.emit_signal("unit_signal", target_unit, "die")
			unit_list.erase(target_unit)
			target_unit.queue_free()
			update_unit_pos_map()
		)

	attack_unit.z_index = attack_z_index
	target_unit.z_index = target_z_index


func fight(attack_unit: Unit, target_unit: Unit):
	game_state = GameState.GAME_RUNING

	unit_fight_info_ui.visible = true
	unit_fight_info_ui.update_info(attack_unit, target_unit)
	
	if attack_unit.position.y < window_size.y / 2:
		unit_fight_info_ui.position = Vector2(window_size.x/2, window_size.y * 4 / 5)
	else:
		unit_fight_info_ui.position = Vector2(window_size.x/2, window_size.y / 5)

	# 等待攻击动画播放结束
	await attack_anim(attack_unit, target_unit)
	unit_fight_info_ui.update_info(attack_unit, target_unit)
	if target_unit.is_alive():
		await attack_anim(target_unit, attack_unit)
		unit_fight_info_ui.update_info(attack_unit, target_unit)

	unit_menu.visible = false
	current_unit = null
	target_unit = null

	await get_tree().create_timer(1).timeout
	unit_fight_info_ui.visible = false
	
	if attack_unit:
		push_command(UnitStandbyCommand.new(attack_unit))
