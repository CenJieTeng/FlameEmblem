extends Node2D

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("mouse_left"):
		SceneManager.go_to_level(1)
