extends Node2D
class_name Cursor

var pos : Vector2i
var move_dir : Vector2i
var anim : AnimatedSprite2D
var timer : Timer
var grid_map : CustomGridMap
var game_manager : GameManager
var console_ui : Control
var camera : Camera2D
var camera_bounds : Rect2i

func _ready() -> void:
	game_manager = get_node("/root/Node2D/GameManager")
	grid_map = get_node("/root/Node2D/Map")
	anim = get_node("AnimatedSprite2D")
	timer = get_node("Timer")
	console_ui = get_node("/root/Node2D/CanvasLayer/Console")
	camera = get_node("/root/Node2D/Camera2D")
	anim.play()
	
	camera_bounds.position = Vector2(0, 0)
	camera_bounds.size = Vector2i(15, 10)
	add_user_signal("pos_change")

func _process(_delta: float) -> void:
	if UIManager.is_handle_ui_input():
		return

	if (game_manager.game_state != GameManager.GameState.WAITING_FOR_PLAYER
		or game_manager.play_state == GameManager.PlayState.SELECT_ACTION
		or game_manager.play_state == GameManager.PlayState.SELECT_ATTACK_TARGET):
		if move_dir != Vector2i.ZERO:
			move_dir = Vector2i.ZERO
		if not timer.is_stopped():
			timer.stop()
		return
	
	move_dir = Vector2i.ZERO
	if Input.is_action_pressed("up"):
		move_dir += Vector2i.UP
	if Input.is_action_pressed("down"):
		move_dir += Vector2i.DOWN
	if Input.is_action_pressed("left"):
		move_dir += Vector2i.LEFT
	if Input.is_action_pressed("right"):
		move_dir += Vector2i.RIGHT
	
	if timer.is_stopped():
		if (Input.is_action_just_pressed("up")
			or Input.is_action_just_pressed("down")
			or Input.is_action_just_pressed("left")
			or Input.is_action_just_pressed("right")
			or Input.is_action_just_released("up")
			or Input.is_action_just_released("down")
			or Input.is_action_just_released("left")
			or Input.is_action_just_released("right")):
			if not grid_map.is_grid_in_map(pos + move_dir):
				return
			set_pos(pos + move_dir)
			await get_tree().create_timer(0.1).timeout
			timer.start()
	
	if move_dir == Vector2i.ZERO:
		timer.stop()

func set_pos(p_pos : Vector2i):
	var new_position = grid_map.grid_to_world(p_pos)
	var tween = create_tween()
	tween.tween_property(self, "position", new_position, 0.08)
	pos = p_pos
	if not camera_bounds.has_point(pos):
		var bounds_move = move_dir
		if camera_bounds.position.x + move_dir.x < 0 || camera_bounds.position.x + camera_bounds.size.x + move_dir.x > grid_map.map_size.x:
			bounds_move.x = 0
		if camera_bounds.position.y + move_dir.y < 0 || camera_bounds.position.y  + camera_bounds.size.y + move_dir.y > grid_map.map_size.y:
			bounds_move.y = 0
		#print(camera_bounds, bounds_move, move_dir)
		camera_bounds.position += bounds_move
		set_camera_offset()
	emit_signal("pos_change")

func set_pos2(p_pos : Vector2i):
	pos = p_pos
	position = grid_map.grid_to_world(pos)
	if not camera_bounds.has_point(pos):
		camera_bounds.position.x = clamp(pos.x, 0, grid_map.map_size.x - camera_bounds.size.x)
		camera_bounds.position.y = clamp(pos.y, 0, grid_map.map_size.y - camera_bounds.size.y)
		#camera.offset = calc_camera_offset()
		set_camera_offset()
	emit_signal("pos_change")

func _on_timer_timeout() -> void:
	if not grid_map.is_grid_in_map(pos + move_dir):
		timer.stop()
		return
	set_pos(pos + move_dir)

func calc_camera_offset():
	var offsetX = 120 + (camera_bounds.position.x + camera_bounds.size.x - 15) * 16
	var offsetY = 80 + (camera_bounds.position.y + camera_bounds.size.y - 10) * 16
	return Vector2(offsetX, offsetY)
	

func set_camera_offset():
	var target_offset = calc_camera_offset()
	var tween = create_tween()
	tween.tween_method(_update_offset, camera.offset, target_offset, 0.1)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
func _update_offset(value: Vector2):
	camera.offset = value
