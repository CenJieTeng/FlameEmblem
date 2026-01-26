extends BaseUI

var init_offset := 23
var offset := 16
var index := 1
var item_count := 1

var game_manager : GameManager
@onready var finger_ui := $FingerUI
@onready var weapon_ui_template := $WeaponItemTemplate
@onready var weapon_container := $MarginContainer/MarginContainer/VBoxContainer
@onready var unit_texture: TextureRect = $Control/UnitTexture
@onready var attack_value: Label = $Control/MarginContainer/NinePatchRect/AttackTitle/AttackValue
@onready var hit_value: Label = $Control/MarginContainer/NinePatchRect/HitTitle/HitValue
@onready var crit_value: Label = $Control/MarginContainer/NinePatchRect/CritTitle/CritValue
@onready var miss_value: Label = $Control/MarginContainer/NinePatchRect/MissTitle/MissValue

var weapon_items : Array[Weapon] = []

func _ready() -> void:
	super._ready()
	game_manager = get_node("/root/Node2D/GameManager")
	
func get_ui_name():
	return UIManager.UI_NAME.SELECT_WEAPON_UI
	
func is_handle_input():
	return true

func open_ui():
	super.open_ui()
	index = 1
	finger_ui.position.y = init_offset
	
	for child in weapon_container.get_children():
		child.queue_free()

	weapon_items = game_manager.current_unit.inventory.get_weapon_items()
	if weapon_items.size() == 0:
		var unarmed_weapon = ItemManager.create_item_instance("空手") as Weapon
		weapon_items.append(unarmed_weapon)
	item_count = weapon_items.size()
	for weapon in weapon_items:
		var weapon_ui = weapon_ui_template.duplicate() as Control
		weapon_ui.get_node("Control/WeaponName").text = weapon.item_name
		weapon_ui.get_node("Control/Uses").text = str(weapon.uses)
		weapon_ui.get_node("Control/TextureRect").texture = weapon.icon_texture
		weapon_ui.visible = true
		weapon_container.add_child(weapon_ui)

	var atlas = unit_texture.texture as AtlasTexture
	atlas.atlas = game_manager.current_unit.head_texture
	update_weapon_info()

func update_weapon_info():
	var weapon = weapon_items[index - 1]
	attack_value.text = str(weapon.power)
	hit_value.text = str(weapon.hit)
	crit_value.text = str(weapon.crit)
	miss_value.text = str(weapon.miss)
	

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("up"):
		index -= 1
		index = clamp(index, 1, item_count)
		finger_ui.position.y = init_offset + offset * (index - 1)
		update_weapon_info()
	if event.is_action_pressed("down"):
		index += 1
		index = clamp(index, 1, item_count)
		finger_ui.position.y = init_offset + offset * (index - 1)
		update_weapon_info()
	if event.is_action_pressed("mouse_left"):
		game_manager.select_weapon_item(weapon_items[index - 1])
		get_viewport().set_input_as_handled()
