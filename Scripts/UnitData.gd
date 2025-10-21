class_name UnitData extends Resource

#资源
@export var head_texture : Texture2D	# 角色头像
@export var idea_texture : Texture2D	# 待机图
@export var move_texture : Texture2D	# 移动图

#基础属性
@export var max_hp : int = 1		# 最大生命值
@export var strength : int = 1		# 力量 - 物理攻击力
@export var magic : int = 1			# 魔力 - 魔法攻击力
@export var skill : int = 1			# 技巧 - 影响命中率和必杀率
@export var speed : int = 1			# 速度 - 影响回避率和追击
@export var luck : int = 1			# 幸运 - 影响回避
@export var defense : int = 1		# 防御 - 物理防御力
@export var resistance : int = 1	# 魔防 - 魔法防御力
@export var mov : int = 1			# 移动力

#当前状态
@export var hp : int
@export var level : int = 1
@export var experience : int = 0

@export var unit_name : String

func _init(base_stats: Dictionary = {}) -> void:
	if base_stats:
		max_hp = base_stats.get("max_hp", 1)
		strength = base_stats.get("strength", 1)
		magic = base_stats.get("magic", 1)
		skill = base_stats.get("skill", 1)
		speed = base_stats.get("speed", 1)
		luck = base_stats.get("luck", 1)
		defense = base_stats.get("defense", 1)
		resistance = base_stats.get("resistance", 1)
		mov = base_stats.get("mov", 1)
	
	hp = max_hp
	
