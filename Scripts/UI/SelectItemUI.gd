extends BaseUI

var init_offset := 23
var offset := 16
var index := 1
var item_count := 1

var game_manager : GameManager
@onready var finger_ui := $FingerUI
@onready var item_ui_template := $ItemTemplate
@onready var item_container := $MarginContainer/MarginContainer/VBoxContainer
@onready var unit_texture: TextureRect = $Control/UnitTexture
@onready var hp_title: Label = $Control/MarginContainer/NinePatchRect/HpTitle
@onready var hp_value: Label = $Control/MarginContainer/NinePatchRect/HpTitle/HpValue
@onready var max_hp_title: Label = $Control/MarginContainer/NinePatchRect/MaxHpTitle
@onready var max_hp_value: Label = $Control/MarginContainer/NinePatchRect/MaxHpTitle/MaxHpValue
@onready var recover_title: Label = $Control/MarginContainer/NinePatchRect/RecoverTitle
@onready var recover_value: Label = $Control/MarginContainer/NinePatchRect/RecoverTitle/RecoverValue

var items : Array[Item] = []

func _ready() -> void:
	super._ready()
	game_manager = get_node("/root/Node2D/GameManager")

func get_ui_name():
	return UIManager.UI_NAME.SELECT_ITEM_UI

func is_handle_input():
	return true

func open_ui():
	super.open_ui()
	index = 1
	finger_ui.position.y = init_offset

	for child in item_container.get_children():
		child.queue_free()

	items = game_manager.current_unit.inventory.get_all_items()
	var usable_items: Array[Item] = []
	for item in items:
		if item.item_type == Item.ItemType.CONSUMABLE and item.uses > 0:
			usable_items.append(item)

	item_count = usable_items.size()

	for item in usable_items:
		var item_ui = item_ui_template.duplicate() as Control
		item_ui.get_node("Control/ItemName").text = item.item_name
		item_ui.get_node("Control/Uses").text = str(item.uses)
		item_ui.get_node("Control/TextureRect").texture = item.icon_texture
		item_ui.visible = true
		item_container.add_child(item_ui)

	var atlas = unit_texture.texture as AtlasTexture
	atlas.atlas = game_manager.current_unit.head_texture
	update_item_info()

func update_item_info():
	var stats = game_manager.current_unit.get_stats()
	hp_value.text = str(stats.hp)
	max_hp_value.text = str(stats.max_hp)

	if item_count > 0:
		var usable_items: Array[Item] = []
		for item in items:
			if item.item_type == Item.ItemType.CONSUMABLE and item.uses > 0:
				usable_items.append(item)

		var current_item = usable_items[index - 1]
		recover_value.text = str(current_item.recover_hp)

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("up"):
		index -= 1
		index = clamp(index, 1, item_count)
		finger_ui.position.y = init_offset + offset * (index - 1)
		update_item_info()
	if event.is_action_pressed("down"):
		index += 1
		index = clamp(index, 1, item_count)
		finger_ui.position.y = init_offset + offset * (index - 1)
		update_item_info()
	if event.is_action_pressed("mouse_left"):
		if item_count > 0:
			var usable_items: Array[Item] = []
			for item in items:
				if item.item_type == Item.ItemType.CONSUMABLE and item.uses > 0:
					usable_items.append(item)
			game_manager.select_use_item(usable_items[index - 1])
			get_viewport().set_input_as_handled()
