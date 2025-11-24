extends AIStrategyBase
class_name AggressiveAI

func evaluate_decision() -> UnitCommand:
	
	# 情况1：如果可以攻击敌人，优先攻击
	if brain.can_act():
		var target = find_best_attack_target()
		if target != null:
			print("范围内有敌人，执行攻击")
			brain.mark_acted()
			return UnitAttackCommand.new(brain.current_unit, target)

	# 情况2：如果不能攻击敌人，尝试移动到可以攻击的位置
	if brain.can_move() and brain.can_act():
		var attack_info = find_best_attack_after_move()
		if attack_info.size() > 0:
			var move_position = attack_info["position"]
			last_target = attack_info["target"]
			print("移动到可以攻击的位置")
			brain.mark_moved()
			return UnitMoveCommand.new(brain.current_unit, move_position)

	# 情况3：待机
	brain.mark_acted()
	return UnitStandbyCommand.new(brain.current_unit)
