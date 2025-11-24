extends Node2D
class_name AIManager

var game_manager : GameManager
var ai_brains : Array = []
var current_brain_index : int = 0
var current_brain : AIBrain = null
var is_turning : bool = false

func init(_game_manager: GameManager):
	game_manager = _game_manager

func register_ai_unit(unit: Unit, strategy: AIBrain.AIStrategy) -> void:
	var brain = AIBrain.new(unit, strategy)
	ai_brains.append(brain)
	print("注册AI单位: %s" % unit.unit_name)

func process_ai_turn() -> UnitCommand:
	if is_turning:
		return process_current_ai_unit()

	current_brain_index = 0
	current_brain = null
	is_turning = true
	ai_brains = ai_brains.filter(func(brain):
		if is_instance_valid(brain.current_unit):
			return brain.current_unit.is_alive()
		else:
			return false
	)

	print("AI开始行动，共有 %d 个AI单位" % ai_brains.size())         
	for brain in ai_brains:
		brain.reset_turn()           

	return process_next_ai_turn()

func process_next_ai_turn() -> UnitCommand:
	if current_brain_index >= ai_brains.size():
		print("process_ai_turn end")         
		current_brain_index = 0
		current_brain = null
		is_turning = false
		return null

	current_brain = ai_brains[current_brain_index]
	current_brain_index += 1

	print("AI单位行动: %s" % current_brain.current_unit.unit_name)
	return process_current_ai_unit()

func process_current_ai_unit() -> UnitCommand:
	if current_brain == null:
		return process_next_ai_turn()

	if current_brain.is_turn_complete():
		print("AI单位行动结束: %s" % current_brain.current_unit.unit_name)
		return process_next_ai_turn()

	var command = current_brain.make_decision()
	if command != null:
		#command.execute().connect("completed", callable(self, "process_current_ai_unit"))
		#game_manager.push_command(command)
		return command
	else:
		print("AI单位无可执行命令，结束行动: %s" % current_brain.current_unit.unit_name)
		return process_next_ai_turn()

func _on_unit_die(unit: Unit) -> void:
	if is_turning and current_brain != null and current_brain.current_unit == unit:
		print("AI单位死亡，结束行动: %s" % current_brain.current_unit.unit_name)
		current_brain = null
