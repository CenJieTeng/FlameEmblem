class_name TerrainData extends RefCounted
var type : String
var move_cost : int

func _init(p_type: String, p_move_cost: int):
	type = p_type
	move_cost = p_move_cost

func print():
	print("type: %s, move_cost: %d" % [type, move_cost])
