class_name UnitData extends Resource
@export var stats : Dictionary
@export var exp : int
@export var level : int

func _init(p_stats: Dictionary):
	stats = p_stats
