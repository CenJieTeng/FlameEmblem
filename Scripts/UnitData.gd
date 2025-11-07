extends Resource
class_name UnitData 

@export var unit_name : String

#资源
@export var head_texture : Texture2D	# 角色头像
@export var idea_texture : Texture2D	# 待机图
@export var move_texture : Texture2D	# 移动图
@export var animation_library : AnimationLibrary	# 角色动画库

#基础属性
@export var stats : UnitStats

#当前状态
@export var hp : int
@export var level : int = 1
@export var experience : int = 0

func init(base_stats: Dictionary = {}) -> void:
	stats._init(base_stats)
	
