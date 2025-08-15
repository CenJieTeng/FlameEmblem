class_name TerrainData extends RefCounted
var type : String
var move_cost : int
var def : int
var avo : int

func _init(p_type: String, p_move_cost: int, p_def: int, p_avo: int):
	type = p_type
	move_cost = p_move_cost
	def = p_def
	avo = p_avo

func print():
	print("type: %s, move_cost: %d" % [type, move_cost])
