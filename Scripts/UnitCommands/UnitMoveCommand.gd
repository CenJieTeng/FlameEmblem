extends UnitCommand
class_name UnitMoveCommand

var pos : Vector2i
var old_pos : Vector2i

func _init(p_unit: Unit, p_pos: Vector2i):
	can_undo = true
	unit = p_unit
	pos = p_pos

func do():
	old_pos = unit.grid_position
	unit.move_to(pos)
	
func undo():
	unit.set_pos(old_pos)
