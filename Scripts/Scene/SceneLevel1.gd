extends BaseScene

func setup_level():
	super()
	
	deploy_count =  2
	unit_born_pos = [
		Vector2i(3, 4),
		Vector2i(4, 4)
	]

	
	game_manager.create_unit("敌人1", Vector2i(2, 4), Unit.UnitCamp.ENEMY)
	#game_manager.create_unit("敌人1", Vector2i(4, 4), Unit.UnitCamp.ENEMY)
	game_manager.cursor.set_pos2(Vector2i(3, 4))
	game_manager.max_wave = 3
	game_manager.wave_info_ui.init(game_manager.max_wave, "胜利")

func first_frame_process():
	UnitManager.init_deploy_unit(deploy_count)
	born_unit()
