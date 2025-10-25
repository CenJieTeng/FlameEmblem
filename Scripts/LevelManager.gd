extends Node
class_name LevelManager

var unit : Unit

#等级
var level : int = 0
var experience : int = 0

#属性成长
var GROW_POINT_PER_LEVEL : int = 500
var grow_data : UnitStats # 累计属性成长
var grow_stats_cache : UnitStats # 缓存属性成长
var grow_pre_point : UnitStats = UnitStats.new({
	"max_hp" : 100,
	"strength" : 100,
	"magic" : 100,
	"skill" : 100,
	"speed" : 100,
	"luck" : 100,
	"defense" : 100,
	"resistance" : 100,		
})
var grow_keys : Array = [
	"max_hp",
	"strength",
	"magic",
	"skill",
	"speed",
	"luck",
	"defense",
	"resistance",
]

func _init(p_unit, p_level : int, p_experience : int) -> void:
	unit = p_unit
	level = p_level
	experience = p_experience
	grow_data = UnitStats.new()
	update_grow_stats_cache()

func save_data(unit_data: UnitData):
	unit_data.level = level
	unit_data.experience = experience

func add_exp(amount : int) -> void:
	experience += amount
	print("当前经验 %d" % experience)
	while experience >= exp_to_next_level():
		level += 1
		experience -= exp_to_next_level()
		print("升级 %d" % level)

		var old_grow_cache = grow_stats_cache.duplicate()

		# 计算成长点
		calc_grow_point()
		# 更新缓存
		update_grow_stats_cache()
		print("grow_data: %s" % grow_data)
		print("grow_stats_cache: %s" % grow_stats_cache)

		# 如果hp增加了，则恢复hp
		if grow_stats_cache.get("max_hp") > old_grow_cache.get("max_hp"):
			unit.heal(grow_stats_cache.get("max_hp") - old_grow_cache.get("max_hp"))

func exp_to_next_level() -> int:
	return 100

func get_stats() -> UnitStats:
	return grow_stats_cache

# 改进的成长点分配算法
func calc_grow_point():
	var left_grouth_point = GROW_POINT_PER_LEVEL
	var stats_to_grow = get_stats_to_grow_count()  # 确定这次要升级几个属性
	
	# 先确保选中的属性获得基础成长点
	var selected_stats = select_random_stats(stats_to_grow)
	for stat_key in selected_stats:
		var base_growth = randi_range(100, 120)
		grow_data.set(stat_key, grow_data.get(stat_key) + base_growth)
		left_grouth_point -= base_growth
	
	# 剩余点数随机分配
	while left_grouth_point > 0:
		var group_point = get_random_group_point()
		group_point = min(group_point, left_grouth_point)
		
		if group_point <= 0:
			break
			
		var stat_index = randi() % grow_keys.size()
		var stat_key = grow_keys[stat_index]
		grow_data.set(stat_key, grow_data.get(stat_key) + group_point)
		left_grouth_point -= group_point

# 确定这次升级要增长几个属性 (3-4个)
func get_stats_to_grow_count() -> int:
	# 70%概率3个属性，30%概率4个属性
	if randf() < 0.7:
		return 3
	else:
		return 4

# 随机选择要成长的属性
func select_random_stats(count: int) -> Array:
	var available_stats = grow_keys.duplicate()
	var selected = []

	if level > 2:
		# 排除两个成长值最大的属性
		var sorted_stats = grow_data.get_key_value_array()
		sorted_stats.sort_custom(func(a, b):
			return a.values()[0] > b.values()[0]
		)
	
		for i in range(2):
			available_stats.erase(sorted_stats[i].keys()[0])
	
	for i in range(count):
		if available_stats.size() == 0:
			break
		var random_index = randi() % available_stats.size()
		selected.append(available_stats[random_index])
		available_stats.remove_at(random_index)
	
	return selected

func get_random_group_point() -> int:
	var random_value = randf() * 100

	if random_value < 40:      # 40%概率获得中等点数
		return randi_range(15, 25)
	elif random_value < 80:    # 40%概率获得较少点数
		return randi_range(10, 15)
	else:                      # 20%概率获得较多点数
		return randi_range(25, 35)

# 更新成长属性缓存
func update_grow_stats_cache():
	grow_stats_cache = UnitStats.new()
	for key in grow_keys:
		var grow_value = grow_data.get(key)
		var pre_point = grow_pre_point.get(key)
		# 计算实际增加的属性点 (整除)
		var stat_increase = int(grow_value / pre_point)
		grow_stats_cache.set(key, stat_increase)
