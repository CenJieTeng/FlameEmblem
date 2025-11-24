extends AIStrategyBase
class_name StaticAI

func evaluate_decision() -> UnitCommand:

	# 情况1: 如果可以攻击敌人，优先攻击
	if brain.can_act():
		var target = find_best_attack_target()
		if target != null:
			print("范围内有敌人，执行攻击")
			brain.mark_acted()
			return UnitAttackCommand.new(brain.current_unit, target)

	# 静态AI只会待机
	brain.mark_acted()
	return UnitStandbyCommand.new(brain.current_unit)
