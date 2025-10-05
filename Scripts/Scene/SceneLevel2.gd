extends BaseScene

var game_manager : GameManager

func setup_level():
	super()
	game_manager = get_node("/root/Node2D/GameManager")
	game_manager.create_unit("角色1", Vector2i(3, 12), Unit.UnitCamp.PLAYER)
	game_manager.create_unit("角色1", Vector2i(4, 4), Unit.UnitCamp.PLAYER)
	game_manager.create_unit("敌人1", Vector2i(2, 4), Unit.UnitCamp.ENEMY)
	game_manager.cursor.set_pos2(Vector2i(3, 12))
	game_manager.max_wave = 5
	game_manager.wave_info_ui.init(game_manager.max_wave, "胜利")
