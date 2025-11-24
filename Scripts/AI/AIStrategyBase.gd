extends RefCounted
class_name AIStrategyBase

var brain: AIBrain
var last_target: Unit = null

func _init(_brain: AIBrain):
	brain = _brain

func reset_turn():
	last_target = null

func evaluate_decision() -> UnitCommand:
	return null

# 寻找最佳攻击目标（不考虑移动）
func find_best_attack_target() -> Unit:
	if last_target and last_target.is_alive():
		return last_target

	var best_target = null
	var best_score = -1000.0

	for enemy in brain.enemy_units:
		if brain.can_attack_target(enemy):
			var score = calculate_attack_score(enemy)
			if score > best_score:
				best_score = score
				best_target = enemy

	return best_target

# 寻找最佳目标（考虑移动）
func find_best_attack_after_move() -> Dictionary:
	var best_score = -1000
	var best_target = null
	var best_position = null

	if not brain.can_move():
		return {}

	var move_range = brain.current_unit.get_move_range()
	var moveable_grids = brain.grid_map.calc_moveable(brain.current_unit.grid_position, move_range, brain.current_unit.camp, true)
	moveable_grids.append(brain.current_unit.grid_position) # 也考虑当前位置

	for grid in moveable_grids:
		for enemy in brain.enemy_units:
			if not enemy.is_alive():
				continue

			var dist = brain.grid_map.get_tile_distance(grid, enemy.grid_position)
			if dist <= brain.current_unit.get_attack_range():
				var score = calc_attack_sorce_from_grid(grid, enemy)
				if score > best_score:
					best_score = score
					best_target = enemy
					best_position = grid

	if best_target:
		return {
			"target": best_target,
			"position": best_position
		}

	return {}

func calc_attack_sorce_from_grid(grid: Vector2, enemy: Unit) -> int:
	return 100 # 暂时先写死

func calculate_attack_score(enemy: Unit) -> float:
	return 100 # 暂时先写死
