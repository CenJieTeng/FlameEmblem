extends Node
class_name BattleSystem

class BattleUnit:
	var unit_name : String
	var max_hp : int
	var strength : int
	var magic : int
	var skill : int
	var speed : int
	var luck : int
	var defense : int
	var resistance : int
	var hp : int
	var weapon : Weapon

func create_battle_unit(unit: Unit) -> BattleUnit:
	var battle_unit = BattleUnit.new()
	var stats = unit.get_stats()
	battle_unit.unit_name = unit.unit_name
	battle_unit.max_hp = stats.max_hp
	battle_unit.strength = stats.strength
	battle_unit.magic = stats.magic
	battle_unit.skill = stats.skill	
	battle_unit.speed = stats.speed
	battle_unit.luck = stats.luck
	battle_unit.defense = stats.defense
	battle_unit.resistance = stats.resistance
	battle_unit.hp = stats.hp

	battle_unit.weapon = unit.weapon
	if battle_unit.weapon == null:
		var weapon_items = unit.inventory.get_weapon_items()
		if weapon_items.size() > 0:
			unit.weapon = weapon_items[0]
			battle_unit.weapon = unit.weapon
			print("警告：单位 %s 自动装备武器 %s" % [unit.unit_name, battle_unit.weapon.item_name])
		else:
			print("警告：单位 %s 没有装备武器，使用默认武器" % unit.unit_name)
			battle_unit.weapon = ItemManager.create_item_instance("空手") as Weapon

	return battle_unit

class BattleResult:
	var attacker : BattleUnit
	var defender : BattleUnit
	var show_attr_dict : Dictionary
	var round_results : Array[RoundResult]


class RoundResult:
	var attacker : BattleUnit
	var defender : BattleUnit
	var damage : int
	var origin_hp : int
	var hp : int
	var is_miss : bool
	var is_critical : bool
	var is_skill : bool


var skip_battle_anim : bool = false
var preare_data : Dictionary
var battle_scene : BattleSceneUI

# 武器克制关系，剑克制斧，斧克制枪，枪克制剑
const weapon_triangle : Dictionary = {
	Weapon.WeaponType.NONE : Weapon.WeaponType.NONE,
	Weapon.WeaponType.SWORD : Weapon.WeaponType.AXE,
	Weapon.WeaponType.AXE : Weapon.WeaponType.LANCE,
	Weapon.WeaponType.LANCE : Weapon.WeaponType.SWORD
}

func _ready() -> void:
	add_user_signal("hp_changed", [TYPE_STRING, TYPE_INT, TYPE_INT])

func is_skip_battle_anim() -> bool:
	return skip_battle_anim

func quick_battle_info(attacker: Unit, defender: Unit) -> Dictionary:
	var attacker_battle_unit = create_battle_unit(attacker)
	var defender_battle_unit = create_battle_unit(defender)
	return _quick_battle_info(attacker_battle_unit, defender_battle_unit)
	

func _quick_battle_info(attacker: BattleUnit, defender: BattleUnit) -> Dictionary:
	return  {
		attacker.unit_name : {
			"hit_rate" : calc_hit_rate(attacker, defender),
			"damage" : calc_damage(attacker, defender),
			"critical_rate" : calc_critical_rate(attacker, defender)
		},
		defender.unit_name : {
			"hit_rate" : calc_hit_rate(defender, attacker),
			"damage" : calc_damage(defender, attacker),
			"critical_rate" : calc_critical_rate(defender, attacker)
		}
	}

func battle(attacker: Unit, defender: Unit):
	# 准备数据
	preare_data = preare_battle_data(attacker, defender)
	
	# 战斗计算
	var battle_result = simulate_battle(preare_data["attacker"], preare_data["defender"])

	# 战斗表现
	present_battle_result(battle_result)
	if skip_battle_anim:
		var unit_fight_info_ui = UIManager.get_ui(UIManager.UI_NAME.UNIT_FIGHT_INFO_UI) as UnitFightInfoUI
		unit_fight_info_ui.init(self, attacker, defender)
		unit_fight_info_ui.open_ui()
		await present_battle_result_skip_anim(battle_result)
		await get_tree().create_timer(1).timeout
		unit_fight_info_ui.close_ui()
	else:
		battle_scene = UIManager.get_ui(UIManager.UI_NAME.BATTLE_SCENE_UI) as BattleSceneUI
		battle_scene.init(self, attacker, defender, battle_result)
		battle_scene.open_ui()
		await present_battle_result_anim(battle_result)
		battle_scene.close_ui()

	# 应用结果
	apply_battle_result(battle_result)
	
func preare_battle_data(attacker: Unit, defender: Unit) -> Dictionary:
	var attacker_battle_unit = create_battle_unit(attacker)
	var defender_battle_unit = create_battle_unit(defender)
	return {
		"attacker_real_unit" : attacker,
		"defender_real_unit" : defender,
		"attacker": attacker_battle_unit,
		"defender": defender_battle_unit
	}

static func is_triangle_weapon(attacker_weapon_type: Weapon.WeaponType, defender_weapon_type: Weapon.WeaponType) -> bool:
	if weapon_triangle[attacker_weapon_type] == defender_weapon_type:
		return true
	return false

func calc_damage(attacker: BattleUnit, defender: BattleUnit) -> int:
	var damage = (attacker.weapon.power / 10.0) * (attacker.strength - defender.defense)
	print("计算伤害: 武器威:%d 力量:%d 防:%d 计算结果 (%d / 10) * (%d - %d) = %d" % [attacker.weapon.power, attacker.strength, defender.defense, attacker.weapon.power, attacker.strength, defender.defense, damage])
	#根据克制关系最终伤害调整
	if is_triangle_weapon(attacker.weapon.weapon_type, defender.weapon.weapon_type):
		damage = damage * 1.5
		print("克制加成，最终伤害 %d" % damage)
	if damage < 0:
		damage = 0
	return damage

func calc_hit_rate(attacker: BattleUnit, defender: BattleUnit) -> int:
	var hit_rate = 80 + (attacker.skill * 2) + (attacker.luck / 2) - (defender.speed * 2) - (defender.luck / 2)
	return clamp(hit_rate, 0, 100)

func calc_critical_rate(attacker: BattleUnit, defender: BattleUnit) -> int:
	var critical_rate = 10 + (attacker.luck * 2) - (defender.luck * 2)
	print("critical_rate %d" % critical_rate)
	return clamp(critical_rate, 0, 100)

func simulate_battle(attacker: BattleUnit, defender: BattleUnit) -> BattleResult:
	var battle_result = BattleResult.new()
	battle_result.attacker = attacker
	battle_result.defender = defender
	battle_result.show_attr_dict = _quick_battle_info(attacker, defender)

	var attaacker_round_result = simulate_round(attacker, defender)
	battle_result.round_results.append(attaacker_round_result)

	if defender.hp > 0:
		var defender_round_result = simulate_round(defender, attacker)
		battle_result.round_results.append(defender_round_result)

	return battle_result

func simulate_round(attacker: BattleUnit, defender: BattleUnit) -> RoundResult:
	var round_result = RoundResult.new()
	round_result.attacker = attacker
	round_result.defender = defender
	round_result.origin_hp = defender.hp

	var hit_rate = calc_hit_rate(attacker, defender)
	var roll = randi() % 100
	if roll >= hit_rate:
		round_result.is_miss = true
		round_result.damage = 0
	else:
		round_result.is_miss = false
		var damage = calc_damage(attacker, defender)
		round_result.damage = damage
		defender.hp -= damage
		if defender.hp < 0:
			defender.hp = 0
			
	round_result.hp = defender.hp
	return round_result

func present_battle_result(battle_result: BattleResult):
	var attacker_unit = preare_data["attacker_real_unit"]
	var defender_unit = preare_data["defender_real_unit"]

	print("战斗开始 攻击者 %s 防御者 %s" % [attacker_unit.unit_name, defender_unit.unit_name])
	print("战斗开始")
	var cur_round = 0
	for round_result in battle_result.round_results:
		var attacker = round_result.attacker
		var defender = round_result.defender
		cur_round += 1
		print("第 %d 回合：" % cur_round)
		if round_result.is_miss:
			print("%s 攻击未命中！" % attacker_unit.unit_name)
		else:
			print("%s 对 %s 造成 %d 点伤害！" % [attacker.unit_name, defender.unit_name, round_result.damage])
			print("%s 当前生命值 %d/%d" % [defender.unit_name, defender.hp, defender.max_hp])
		print("--------------------------")
	print("战斗结束")


func apply_battle_result(battle_result: BattleResult):
	var attacker_unit = preare_data["attacker_real_unit"] as Unit
	var defender_unit = preare_data["defender_real_unit"] as Unit
	attacker_unit.inventory.use_item_by_reference(battle_result.attacker.weapon, attacker_unit)
	defender_unit.inventory.use_item_by_reference(battle_result.defender.weapon, defender_unit)
	attacker_unit.unit_stats.hp = battle_result.attacker.hp
	defender_unit.unit_stats.hp = battle_result.defender.hp
	check_unit_alive(defender_unit, attacker_unit)
	check_unit_alive(attacker_unit, defender_unit)

	

func check_unit_alive(defender_real_unit: Unit, attacker_real_unit: Unit):
	if not defender_real_unit.is_alive():
		print(defender_real_unit.unit_name, " 死亡")
		attacker_real_unit.level_manager.add_exp(100)
		var tween = create_tween()
		tween.tween_property(defender_real_unit, "modulate", Color(1, 1, 1, 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		get_tree().create_timer(1).timeout.connect(func():
			#unit_list.erase(defender_real_unit)
			#update_unit_pos_map()
			defender_real_unit.die()
		)

##------------------------------无动画表现

func present_battle_result_skip_anim(battle_result: BattleResult):
	var attacker_real_unit = preare_data["attacker_real_unit"]
	var defender_real_unit = preare_data["defender_real_unit"]

	for round_result in battle_result.round_results:
		var attacker = round_result.attacker
		#var defender = round_result.defender
		if attacker.unit_name == attacker_real_unit.unit_name:
			await attack_skip_anim(round_result, attacker_real_unit, defender_real_unit)
		else:
			await attack_skip_anim(round_result, defender_real_unit, attacker_real_unit)

func shake_target(target: Node, strength: float = 10.0, duration: float = 0.15, loops: int = 3):
	var shake = create_tween().set_loops(loops)

	# 向左震动
	shake.tween_property(target, "rotation", deg_to_rad(-strength), duration * 0.33).set_trans(Tween.TRANS_SINE)

	# 向右震动
	shake.tween_property(target, "rotation", deg_to_rad(strength), duration * 0.33).set_trans(Tween.TRANS_SINE)

	# 回正
	shake.tween_property(target, "rotation", 0, duration * 0.33).set_trans(Tween.TRANS_SINE)
	await shake.finished

func attack_skip_anim(round_result: RoundResult, attacker_real_unit: Unit, defender_real_unit: Unit):
	var attack_z_index = attacker_real_unit.z_index
	var target_z_index = defender_real_unit.z_index
	attacker_real_unit.z_index = 100 * attacker_real_unit.grid_position.y + 1
	defender_real_unit.z_index = 100 * defender_real_unit.grid_position.y

	var anim : String
	var miss_move_dir : Vector2 = Vector2(5, 0)
	if defender_real_unit.grid_position.x > attacker_real_unit.grid_position.x:
		anim = "move_right"
	if defender_real_unit.grid_position.x < attacker_real_unit.grid_position.x:
		anim = "move_left"
		miss_move_dir = Vector2(-5, 0)
	if defender_real_unit.grid_position.y > attacker_real_unit.grid_position.y:
		anim = "move_down"
	if defender_real_unit.grid_position.y < attacker_real_unit.grid_position.y:
		anim = "move_up"
	attacker_real_unit.animator.play(anim)
	attacker_real_unit.animator.stop()

	await get_tree().create_timer(0.3).timeout
	attacker_real_unit.animator.play()

	var tween = create_tween()
	var origin = attacker_real_unit.position
	var tween_time = 0.2
	tween.tween_property(attacker_real_unit, "position", origin.lerp(defender_real_unit.position, 0.6), tween_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.1).timeout

	attacker_real_unit.animator.speed_scale = 2.0

	if round_result.is_miss:
		# 在单位上方显示“未命中”文字
		var miss_label = Label.new()
		miss_label.text = "miss"
		miss_label.modulate = Color(1, 1, 1)

		# 设置字体大小
		var font = load("res://Fonts/fusion-pixel-monospaced.ttf") as FontFile
		miss_label.add_theme_font_override("font", font)
		miss_label.add_theme_font_size_override("font_size", 8)

		defender_real_unit.add_child(miss_label)
		miss_label.position = Vector2(-10, -10)  # 调整 y 值，确保文字在角色上方
		miss_label.z_index = 1000

		# 被攻击方y上移动一点然后回落
		var defender_tween_time = 0.1
		var miss_tween = create_tween()
		miss_tween.tween_property(defender_real_unit, "position", defender_real_unit.position + miss_move_dir, defender_tween_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await miss_tween.finished

		# 文字上浮并淡出
		var miss_tween_time = 0.2
		var text_tween = create_tween()
		text_tween.tween_property(miss_label, "position", miss_label.position + Vector2(0, -10), miss_tween_time)
		text_tween.tween_property(miss_label, "modulate:a", 0, miss_tween_time)

		miss_tween = create_tween()
		miss_tween.tween_property(defender_real_unit, "position", defender_real_unit.position - miss_move_dir, defender_tween_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await miss_tween.finished

		await text_tween.finished
		miss_label.queue_free()
	else:
		# 被攻击单位加上闪烁效果，使用tween实现
		var tween_time2 = 0.08
		tween =	create_tween()
		await tween.tween_property(defender_real_unit, "modulate", Color(2, 2, 2, 1), tween_time2).finished

		emit_signal("hp_changed", defender_real_unit.unit_name, round_result.hp, defender_real_unit.get_stats().max_hp)

		# 震动
		await shake_target(defender_real_unit, 3.0, 0.1, 1)

		tween =	create_tween()
		await tween.tween_property(defender_real_unit, "modulate", Color(1, 1, 1, 1), tween_time2).finished

	attacker_real_unit.animator.speed_scale = 1.0
	attacker_real_unit.animator.stop()

	tween = create_tween()
	tween.tween_property(attacker_real_unit, "position", origin, tween_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

	attacker_real_unit.animator.play("idle")

	attacker_real_unit.z_index = attack_z_index
	defender_real_unit.z_index = target_z_index


#------------------------------有动画表现

func present_battle_result_anim(battle_result: BattleResult):
	var attacker_real_unit = preare_data["attacker_real_unit"]
	var defender_real_unit = preare_data["defender_real_unit"]

	for round_result in battle_result.round_results:
		var attacker = round_result.attacker
		#var defender = round_result.defender
		if attacker.unit_name == attacker_real_unit.unit_name:
			await attack_anim(round_result, attacker_real_unit, defender_real_unit)
		else:
			await attack_anim(round_result, defender_real_unit, attacker_real_unit)

func attack_anim(round_result: RoundResult, attacker_real_unit: Unit, defender_real_unit: Unit):
	await battle_scene.play_battle_animation(round_result, attacker_real_unit)
	await get_tree().create_timer(0.5).timeout
