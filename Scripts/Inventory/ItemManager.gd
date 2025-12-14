extends Node

var items: Dictionary = {}

func _ready() -> void:
	var path = "res://Resource/Item/"
	var files = Global.list_files_in_directory(path)
	for file in files:
		var item = load(path + file) as Item
		items[item.item_name] = item

func get_item(id: String) -> Item:
	return items.get(id)

func create_item_instance(id: String) -> Item:
	var item = items.get(id) as Item
	if item:
		return item.duplicate()
	return null
