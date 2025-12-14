extends Item
class_name Weapon

enum WeaponType {
	NONE,
	SWORD,
	AXE,
	LANCE,
}

@export var weapon_type : WeaponType = WeaponType.NONE	# 武器类型
@export var power : int = 0			# 武器威力
@export var hit : int = 0			# 命中率
@export var crit : int = 0			# 必杀率
@export var miss : int = 0			# 回避率
@export var atk_range : int = 1		# 攻击范围

func _init():
	item_type = ItemType.WEAPON

func use(_unit: Unit) -> bool:
	if (uses <= 0):
		return false
	uses -= 1
	return true
