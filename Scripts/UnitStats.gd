extends Resource
class_name UnitStats
@export var max_hp : int		# 最大生命值
@export var strength : int		# 力量 - 物理攻击力
@export var magic : int			# 魔力 - 魔法攻击力
@export var skill : int			# 技巧 - 影响命中率和必杀率
@export var speed : int			# 速度 - 影响回避率和追击
@export var luck : int			# 幸运 - 影响回避
@export var defense : int		# 防御 - 物理防御力
@export var resistance : int	# 魔防 - 魔法防御力
@export var mov : int			# 移动力

#当前状态
@export var hp : int

func _init(base_stats : Dictionary = {}) -> void:
	if base_stats:
		max_hp = base_stats.get("max_hp", max_hp)
		strength = base_stats.get("strength", strength)
		magic = base_stats.get("magic", magic)
		skill = base_stats.get("skill", skill)
		speed = base_stats.get("speed", speed)
		luck = base_stats.get("luck", luck)
		defense = base_stats.get("defense", defense)
		resistance = base_stats.get("resistance", resistance)
		mov = base_stats.get("mov", mov)

	hp = max_hp

func get_key_value_array() -> Array[Dictionary]:
	return [
		{ "max_hp": max_hp },
		{ "strength": strength },
		{ "magic": magic },
		{ "skill": skill },
		{ "speed": speed },
		{ "luck": luck },
		{ "defense": defense },
		{ "resistance": resistance },
		{ "mov": mov }
	]

func add(other : UnitStats) -> UnitStats:
	var new_stats = self.duplicate()
	new_stats.max_hp = max_hp + other.max_hp
	new_stats.strength = strength + other.strength
	new_stats.magic = magic + other.magic
	new_stats.skill = skill + other.skill
	new_stats.speed = speed + other.speed
	new_stats.luck = luck + other.luck
	new_stats.defense = defense + other.defense
	new_stats.resistance = resistance + other.resistance
	new_stats.mov = mov + other.mov
	
	return new_stats


func _to_string() -> String:
	return "HP: %d, STR: %d, MAG: %d, SKL: %d, SPD: %d, LUK: %d, DEF: %d, RES: %d, MOV: %d" % [
		max_hp,
		strength,
		magic,
		skill,
		speed,
		luck,
		defense,
		resistance,
		mov
	]
