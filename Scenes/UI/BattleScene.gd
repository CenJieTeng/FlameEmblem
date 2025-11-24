extends BaseUI
class_name BattleSceneUI

@onready var left_unit_name_label := $LeftControl/NamePanel/Label
@onready var left_unit_hit_label := $LeftControl/InfoPanel/HitLabel
@onready var left_unit_dmg_label := $LeftControl/InfoPanel/DmgLabel
@onready var left_unit_crt_label := $LeftControl/InfoPanel/CrtLabel
@onready var left_unit_hp_label := $LeftControl/InfoPanel/HpLabel
@onready var left_unit_hp_bar := $LeftControl/InfoPanel/HpProgressBar
@onready var left_unit_sprite := $LeftControl/Node2D/Sprite2D
@onready var left_unit_anim_player := $LeftControl/Node2D/AnimationPlayer

@onready var right_unit_name_label := $RightControl/NamePanel/Label
@onready var right_unit_hit_label := $RightControl/InfoPanel/HitLabel
@onready var right_unit_dmg_label := $RightControl/InfoPanel/DmgLabel
@onready var right_unit_crt_label := $RightControl/InfoPanel/CrtLabel
@onready var right_unit_hp_label := $RightControl/InfoPanel/HpLabel
@onready var right_unit_hp_bar := $RightControl/InfoPanel/HpProgressBar
@onready var right_unit_sprite := $RightControl/Node2D/Sprite2D
@onready var right_unit_anim_player := $RightControl/Node2D/AnimationPlayer

@onready var hit_flash_color_rect := $HitFlashColorRect

enum SIDE
{
	LEFT,
	RIGHT
}
var node_side_dict = {}

var camera

# 临时变量存储战斗双方节点信息
var battle_system : BattleSystem
var attacker_unit : Unit
var defender_unit : Unit
var attack_side : SIDE
var defend_side : SIDE
var round_result : BattleSystem.RoundResult

func get_ui_name():
	return UIManager.UI_NAME.BATTLE_SCENE_UI

func _ready():
	super()
	camera = self

func init(p_battle_system: BattleSystem, p_attacker_unit: Unit, p_defender_unit: Unit, battle_result: BattleSystem.BattleResult):
	battle_system = p_battle_system
	attacker_unit = p_attacker_unit
	defender_unit = p_defender_unit

	var play_unit = attacker_unit if attacker_unit.camp == Unit.UnitCamp.PLAYER else defender_unit
	var enemy_unit = defender_unit if attacker_unit.camp == Unit.UnitCamp.PLAYER else attacker_unit

	node_side_dict[SIDE.LEFT] = {
		"unit": enemy_unit,
		"name_label": left_unit_name_label,
		"hit_label": left_unit_hit_label,
		"dmg_label": left_unit_dmg_label,
		"crt_label": left_unit_crt_label,
		"hp_label": left_unit_hp_label,
		"hp_bar": left_unit_hp_bar,
		"sprite": left_unit_sprite,
		"anim_player": left_unit_anim_player
	}

	node_side_dict[SIDE.RIGHT] = {
		"unit": play_unit,
		"name_label": right_unit_name_label,
		"hit_label": right_unit_hit_label,
		"dmg_label": right_unit_dmg_label,
		"crt_label": right_unit_crt_label,
		"hp_label": right_unit_hp_label,
		"hp_bar": right_unit_hp_bar,
		"sprite": right_unit_sprite,
		"anim_player": right_unit_anim_player
	}

	left_unit_name_label.text = enemy_unit.unit_name
	left_unit_hit_label.text = str(battle_result.show_attr_dict[enemy_unit.unit_name]["hit_rate"])
	left_unit_dmg_label.text = str(battle_result.show_attr_dict[enemy_unit.unit_name]["damage"])
	left_unit_crt_label.text = str(battle_result.show_attr_dict[enemy_unit.unit_name]["critical_rate"])
	update_hp_bar(SIDE.LEFT, enemy_unit.get_stats().hp, enemy_unit.get_stats().max_hp)
	left_unit_anim_player.remove_animation_library("")
	left_unit_anim_player.clear_caches()
	left_unit_anim_player.add_animation_library("",enemy_unit.unit_data.animation_library)
	left_unit_anim_player.play("RESET")

	right_unit_name_label.text = play_unit.unit_name
	right_unit_hit_label.text = str(battle_result.show_attr_dict[play_unit.unit_name]["hit_rate"])
	right_unit_dmg_label.text = str(battle_result.show_attr_dict[play_unit.unit_name]["damage"])
	right_unit_crt_label.text = str(battle_result.show_attr_dict[play_unit.unit_name]["critical_rate"])
	update_hp_bar(SIDE.RIGHT, play_unit.get_stats().hp, play_unit.get_stats().max_hp)
	right_unit_anim_player.remove_animation_library("")
	right_unit_anim_player.clear_caches()
	right_unit_anim_player.add_animation_library("",play_unit.unit_data.animation_library)
	right_unit_anim_player.play("RESET")

func update_hp_bar(side, hp, max_hp):
	var node_dict = node_side_dict[side]
	var hp_label = node_dict["hp_label"] as Label
	hp_label.text = str(hp)

	var hp_bar = node_dict["hp_bar"] as TextureProgressBar
	var tile_scale = max_hp/6.0
	hp_bar.set_scale(Vector2(tile_scale, 1))
	hp_bar.material.set_shader_parameter("tile_count", tile_scale)
	hp_bar.material.set_shader_parameter("progress", float(hp) / float(max_hp))

func opposite_side(side):
	return SIDE.LEFT if side == SIDE.RIGHT else SIDE.RIGHT

func play_battle_animation(p_round_result: BattleSystem.RoundResult, attacker: Unit):
	attack_side = SIDE.RIGHT if attacker.camp == Unit.UnitCamp.PLAYER else SIDE.LEFT
	defend_side = opposite_side(attack_side)
	round_result = p_round_result

	var node_dict = node_side_dict[attack_side]
	var anim_player = node_dict["anim_player"] as AnimationPlayer
	anim_player.play("Attack")

	await anim_player.animation_finished

func play_defend_hurt_animation():
	if round_result.is_miss:
		return

	var node_dict = node_side_dict[defend_side]
	update_hp_bar(defend_side, round_result.hp, node_dict["unit"].get_stats().max_hp)
	
	#屏幕震动
	var shake_time = 0.6
	var shake_dir = Vector2(1, 0)
	if attack_side == SIDE.RIGHT:
		shake_dir = Vector2(-1, 0)
	shake_impact(shake_dir, 15.0, shake_time)
	shake_random(shake_time, 8.0)

	hit_flash_color_rect.visible = true
	#await get_tree().create_timer(0.03).timeout
	await Global.wait_frames(5)
	hit_flash_color_rect.visible = false

	# 闪烁
	var sprite = node_dict["sprite"] as Sprite2D
	var tween_time = 0.1
	var tween = sprite.create_tween()
	tween.tween_property(sprite, "modulate", Color(5, 5, 5), tween_time)
	await tween.finished
	tween = sprite.create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), tween_time)
	await tween.finished


func play_defend_miss_animation():
	if round_result.is_miss:
		var node_dict = node_side_dict[defend_side]
		var anim_player = node_dict["anim_player"] as AnimationPlayer
		anim_player.play("Miss")
		await anim_player.animation_finished

func shake_impact(direction: Vector2, strength: float = 15.0, duration: float = 0.4):
	var tween = camera.create_tween()
	var original_position = position

	# 先向反方向冲击，然后弹回
	var impact_offset = -direction.normalized() * strength * 0.3
	var rebound_offset = direction.normalized() * strength * 0.1

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(camera, "position", original_position + impact_offset, duration * 0.2)
	tween.tween_property(camera, "position", original_position + rebound_offset, duration * 0.3)
	tween.tween_property(camera, "position", original_position, duration * 0.5)

func shake_random(duration: float = 0.3, strength: float = 8.0, loop: int = 1):
	var tween = create_tween()
	var original_position = position

	# 设置循环和缓动
	tween.set_loops(loop)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)

	for i in range(loop):
		var random_offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		tween.tween_property(camera, "position", 
			original_position + random_offset, duration * 0.25)

	# 最后回到原位
	tween.tween_property(camera, "position", original_position, duration * 0.25)
