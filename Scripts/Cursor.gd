extends Node2D
class_name Cursor

var pos : Vector2i
var move_dir : Vector2i
var anim : AnimatedSprite2D
var timer : Timer
var grid_map : CustomGridMap
var game_manager : GameManager

func _ready() -> void:
	game_manager = get_node("/root/Node2D")
	grid_map = get_node("/root/Node2D/Map")
	anim = get_node("AnimatedSprite2D")
	timer = get_node("Timer")
	anim.play()
	
	add_user_signal("pos_change")

func _process(_delta: float) -> void:
	if (game_manager.game_state != GameManager.GameState.WAITING_FOR_PLAYER
		or game_manager.play_state == GameManager.PlayState.SELECT_ACTION):
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
	emit_signal("pos_change")

func set_pos2(p_pos : Vector2i):
	pos = p_pos
	position = grid_map.grid_to_world(pos)
	emit_signal("pos_change")


func _on_timer_timeout() -> void:
	if not grid_map.is_grid_in_map(pos + move_dir):
		timer.stop()
		return
	set_pos(pos + move_dir)
