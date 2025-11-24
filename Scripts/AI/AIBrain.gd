extends RefCounted
class_name AIBrain

enum AIStrategy {
	NONE,
	AGGRESSIVE, # 进攻型
	STATIC,  # 静态型
}

var strategy: AIStrategyBase
var has_moved: bool = false
var current_unit : Unit
var has_acted: bool = false

var game_manager: GameManager
var grid_map : CustomGridMap
var enemy_units: Array[Unit] = []

func _init(_unit: Unit, stragatey_type: AIStrategy) -> void:
	current_unit = _unit
	game_manager = current_unit.game_manager
	grid_map = current_unit.grid_map
	strategy = AIFactory.create_ai(self, stragatey_type)

func reset_turn() -> void:
	has_acted = false
	has_moved = false
	strategy.reset_turn()

	enemy_units.clear()
	for unit in game_manager.unit_list:
		if unit.camp != current_unit.camp:
			enemy_units.append(unit)

func make_decision() -> UnitCommand:
	return strategy.evaluate_decision()

func mark_moved() -> void:
	has_moved = true

func mark_acted() -> void:
	has_acted = true

func can_move() -> bool:
	return not has_moved

func can_act() -> bool:
	return not has_acted

func is_turn_complete() -> bool:
	return has_acted || (!can_move() && !can_attack_anyone())

func can_attack_anyone() -> bool:
	for enemy in enemy_units:
		if enemy.is_alive() && can_attack_target(enemy):
			return true
	return false

func can_attack_target(unit: Unit) -> bool:
	if has_acted:
		return false

	var distance = grid_map.get_tile_distance(current_unit.grid_position, unit.grid_position)
	return distance <= current_unit.get_attack_range()
