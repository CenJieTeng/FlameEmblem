extends Node2D

var cur_level = 0

var level_path = [
	"res://Scenes/Map/Level1.tscn",
	"res://Scenes/Map/Level2.tscn",
]

func go_to_game_start_scene():
	simple_fade_transition("res://Scenes/Map/GameStartScene.tscn")

func go_to_level(level: int):
	if level >= 1 && level <= level_path.size():
		cur_level = level
		simple_fade_transition(level_path[cur_level-1])

func go_to_next_level():
	if cur_level + 1 <= level_path.size():
		cur_level += 1
		simple_fade_transition(level_path[cur_level-1], 0.5)

func restart_scene():
	simple_fade_transition(level_path[cur_level-1])

func is_final_level():
	return cur_level == level_path.size()
	
func simple_fade_transition(scene_path: String, fade_duration: float = 1.0):
	# 创建临时ColorRect
	var fade_rect = ColorRect.new()
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.color = Color(0, 0, 0, 0)

	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(fade_rect)
	get_tree().root.add_child(canvas_layer)

	# 淡入
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, fade_duration)
	await tween.finished

	# 切换场景
	get_tree().change_scene_to_file(scene_path)

	# 淡出
	tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, fade_duration)
	await tween.finished

	canvas_layer.queue_free()
