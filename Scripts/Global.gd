extends Node2D

var name_to_unit_sprite_frames_map := {
	"角色1" : ["res://Sprites/Characters/PlayerCharacters/EirikaPortrait.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF_move.png"],
	"角色2" : ["res://Sprites/Characters/PlayerCharacters/EirikaPortrait.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF_move.png"],
	"角色3" : ["res://Sprites/Characters/PlayerCharacters/EirikaPortrait.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF_move.png"],
	"角色4" : ["res://Sprites/Characters/PlayerCharacters/EirikaPortrait.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF_move.png"],
	"角色5" : ["res://Sprites/Characters/PlayerCharacters/EirikaPortrait.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF.png", "res://Sprites/Characters/MapSprites/Lord/playerEirika_LordF_move.png"],
	"敌人1" : ["res://Sprites/Characters/PlayerCharacters/FordePortrait.png", "res://Sprites/Characters/MapSprites/Hero/enemyHeroM.png", "res://Sprites/Characters/MapSprites/Hero/enemyHeroM_move.png"],
}

var sprite_frams_map : Dictionary[String, SpriteFrames]

func create_sprite_frames():
	for unit_name in name_to_unit_sprite_frames_map.keys():
		var sprite_frames = load("res://Sprites/Animation/UnitSpriteFrames/Lord.tres").duplicate(true) as SpriteFrames
		create_idle_anim(unit_name, sprite_frames)
		create_move_anim(unit_name, sprite_frames)
		sprite_frams_map[unit_name] = sprite_frames

func create_idle_anim(unit_name: String, sprite_frames: SpriteFrames):
	var tex = load(Global.name_to_unit_sprite_frames_map[unit_name][1])
	var atlas1 = AtlasTexture.new()
	atlas1.atlas = tex
	atlas1.region = Rect2(0, 0, 64, 48)
	atlas1.margin = Rect2(0, 0, 0, 0)
	sprite_frames.set_frame("idle", 0, atlas1)
	var atlas2 = AtlasTexture.new()
	atlas2.atlas = tex
	atlas2.region = Rect2(64, 0, 64, 48)
	atlas2.margin = Rect2(0, 0, 0, 0)
	sprite_frames.set_frame("idle", 1, atlas2)
	var atlas3 = AtlasTexture.new()
	atlas3.atlas = tex
	atlas3.region = Rect2(128, 0, 64, 48)
	atlas3.margin = Rect2(0, 0, 0, 0)
	sprite_frames.set_frame("idle", 2, atlas3)
	sprite_frames.set_frame("idle", 3, atlas2)
	sprite_frames.set_frame("idle", 4, atlas1)
	
func create_move_anim(unit_name: String, sprite_frames: SpriteFrames):
	var tex = load(Global.name_to_unit_sprite_frames_map[unit_name][2])
	var offsety = -3
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 0, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		sprite_frames.set_frame("move_down", i, atlas)
		
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 40, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		sprite_frames.set_frame("move_left", i, atlas)
		
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 80, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		sprite_frames.set_frame("move_right", i, atlas)
	
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 48, 122, 48, 40)
		atlas.margin = Rect2(0, offsety, 0, 0)
		sprite_frames.set_frame("move_up", i, atlas)

var terrain_type_to_name_map = {
	"plain" : "平原",
	"foest" : "森林",
	"mountain" : "山脉",
	"sea" : "海",
}

func _ready() -> void:
	create_sprite_frames()

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
