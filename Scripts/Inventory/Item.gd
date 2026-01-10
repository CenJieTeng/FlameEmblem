extends Resource
class_name Item

enum ItemType {
	WEAPON,			# 武器
	CONSUMABLE,		# 消耗品
	OTHER,			# 其他
}

@export var item_name : String			# 物品名称
@export var item_type : ItemType		# 物品类型
@export var icon_texture : Texture2D	# 物品图标
@export var description : String		# 物品描述
@export var uses: int = 0				# 剩余使用次数

func use(_unit: Unit) -> bool:
	if (uses <= 0):
		return false
	uses -= 1
	return true
