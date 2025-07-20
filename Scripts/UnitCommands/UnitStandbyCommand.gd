extends UnitCommand
class_name UnitStandbyCommand

func _init(p_unit: Unit):
	unit = p_unit

func do():
	unit.standby()
