extends Node2D

var cur_level = 0

var level_path = [
	"res://Scenes/Map/Level1.tscn",
	"res://Scenes/Map/Level2.tscn",
]

func go_to_next_level():
	if cur_level + 1 < level_path.size():
		cur_level += 1
		get_tree().change_scene_to_file(level_path[cur_level])

func restart_scene():
	get_tree().change_scene_to_file(level_path[cur_level])
