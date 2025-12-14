extends BaseUI
class_name QuickAttackInfoUI

@onready var weapon_texture1 := $Panel/Weapon1
@onready var weapon_arrow1 : AnimatedSprite2D = $Panel/Weapon1/WeaponArrow1
@onready var name1 := $Panel/Name1
@onready var hp1 := $Panel/HP1
@onready var power1 := $Panel/Power1
@onready var hit1 := $Panel/Hit1
@onready var crit1 := $Panel/Crit1

@onready var weapon_texture2 := $Panel/Weapon2
@onready var weapon_arrow2 := $Panel/Weapon2/WeaponArrow2
@onready var name2 := $Panel/Name2
@onready var hp2 := $Panel/HP2
@onready var power2 := $Panel/Power2
@onready var hit2 := $Panel/Hit2
@onready var crit2 := $Panel/Crit2
@onready var weapon_name := $Panel/WeaponName

const ITEM_ARROW_UP = preload("res://SpriteFrames/ItemArrowUp.tres")
const ITEM_ARROW_DOWN = preload("res://SpriteFrames/ItemArrowDown.tres")

var arrow_dict = {
	"up" : ITEM_ARROW_UP,
	"down" : ITEM_ARROW_DOWN
}

func get_ui_name():
	return UIManager.UI_NAME.QUICK_ATTACK_INFO_UI

func update_info(unit1 : Unit, unit2 : Unit, quick_battle_info: Dictionary):
	
	weapon_arrow1.visible = false
	weapon_arrow2.visible = false

	if BattleSystem.is_triangle_weapon(unit1.weapon.weapon_type, unit2.weapon.weapon_type):
		weapon_arrow1.visible = true
		weapon_arrow1.frames = arrow_dict["up"]
		weapon_arrow1.play()
		weapon_arrow2.visible = true
		weapon_arrow2.frames = arrow_dict["down"]
		weapon_arrow2.play()
	elif BattleSystem.is_triangle_weapon(unit2.weapon.weapon_type, unit1.weapon.weapon_type):
		weapon_arrow1.visible = true
		weapon_arrow1.frames = arrow_dict["down"]
		weapon_arrow1.play()
		weapon_arrow2.visible = true
		weapon_arrow2.frames = arrow_dict["up"]
		weapon_arrow2.play()
	
	name1.text = unit1.unit_name
	hp1.text = str(unit1.get_stats().hp)
	power1.text = str(unit1.weapon.power)
	hit1.text = str(quick_battle_info[unit1.unit_name].get("hit_rate"))
	crit1.text = str(quick_battle_info[unit1.unit_name].get("critical_rate"))
	weapon_texture1.texture = unit1.weapon.icon_texture

	name2.text = unit2.unit_name
	hp2.text = str(unit2.get_stats().hp)
	power2.text = str(unit2.weapon.power)
	hit2.text = str(quick_battle_info[unit2.unit_name].get("hit_rate"))
	crit2.text = str(quick_battle_info[unit2.unit_name].get("critical_rate"))
	weapon_name.text = unit2.weapon.item_name
	weapon_texture2.texture = unit2.weapon.icon_texture
