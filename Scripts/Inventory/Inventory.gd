extends Resource
class_name Inventory

signal item_removed(item: Item)

@export var capacity = 5
var items: Array[Item] = []

func add_item(item: Item) -> bool:
	if items.size() >= capacity:
		return false
	items.append(item)
	return true

func remove_item(index: int) -> void:
	if index >= 0 and index < items.size():
		item_removed.emit(items[index])
		items.remove_at(index)

func get_item(index: int) -> Item:
	if index >= 0 and index < items.size():
		return items[index]
	return null

func get_all_items() -> Array[Item]:
	return items

func get_weapon_items() -> Array[Weapon]:
	var weapons: Array[Weapon] = []
	for item in items:
		if item.item_type == Item.ItemType.WEAPON:
			weapons.append(item as Weapon)
	return weapons

func use_item(index: int, unit: Unit) -> void:
	if index >= 0 and index < items.size():
		items[index].use(unit)
		if items[index].uses <= 0:
			item_removed.emit(items[index])
			items.remove_at(index)
			

func use_item_by_reference(item: Item, unit: Unit) -> void:
	if item in items:
		item.use(unit)
		if item.uses <= 0:
			item_removed.emit(item)
			items.erase(item)
			print("物品 %s 已经用完并从库存中移除" % item.item_name)
