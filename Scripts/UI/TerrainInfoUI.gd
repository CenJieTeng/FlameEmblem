extends Control

@onready var terrain = $Panel/Terrain
@onready var def = $Panel/Def
@onready var avo = $Panel/Avo

func update_info(terrain_data : TerrainData):
	terrain.text = Global.terrain_type_to_name_map[terrain_data.type]
	def.text = str(terrain_data.def)
	avo.text = str(terrain_data.avo)
