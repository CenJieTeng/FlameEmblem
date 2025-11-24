extends UnitCommand
class_name UnitAttackCommand

var target : Unit

func _init(p_unit: Unit, p_target: Unit):
	unit = p_unit
	target = p_target
	
func do():
	unit.game_manager.fight(unit, target)
