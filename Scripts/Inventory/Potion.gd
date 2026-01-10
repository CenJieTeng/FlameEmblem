extends Item

@export var recover_hp: int = 0

func use(unit: Unit) -> bool:
	if super(unit):
		unit.heal(recover_hp)
		return true
	return false
