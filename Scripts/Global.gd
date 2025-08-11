extends Node2D

var name_to_unit_sprite_frames_map = {
	"角色1" : ["res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF_move.png"],
	"敌人1" : ["res://Sprites/Characters/MapSprites/Knight/enemyKnightM.png", "res://Sprites/Characters/MapSprites/Knight/enemyKnightM_move.png"],
}

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

# 判断三点A-B-C是否形成直角（B为顶点）
func is_perpendicular_2d(a: Vector2, b: Vector2, c: Vector2, epsilon: float = 0.0001) -> bool:
	var ba := a - b
	var bc := c - b
	ba = ba.normalized()
	bc = bc.normalized()
	return abs(ba.dot(bc)) < epsilon

# 从图块集（TileSet）中创建一个Sprite2D对象
func create_sprite_from_tile(atlas_source: TileSetAtlasSource, tile_coords: Vector2i) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = atlas_source.texture
	sprite.region_enabled = true
	sprite.region_rect = atlas_source.get_tile_texture_region(tile_coords)
	return sprite
