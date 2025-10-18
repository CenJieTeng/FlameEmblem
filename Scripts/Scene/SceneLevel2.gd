extends BaseScene

func setup_level():
	super()
	
	deploy_count =  2
	unit_born_pos = [
		Vector2i(2, 13),
		Vector2i(3, 13),
		Vector2i(3, 14)
	]

	
	#game_manager.create_unit("角色1", Vector2i(3, 12), Unit.UnitCamp.PLAYER)
	#game_manager.create_unit("角色1", Vector2i(4, 4), Unit.UnitCamp.PLAYER)
	game_manager.create_unit("敌人1", Vector2i(2, 4), Unit.UnitCamp.ENEMY)
	game_manager.cursor.set_pos2(Vector2i(3, 13))
	game_manager.max_wave = 5
	game_manager.wave_info_ui.init(game_manager.max_wave, "胜利")

func first_frame_process():
	UnitManager.init_deploy_unit(deploy_count)
	UIManager.open(UIManager.UI_NAME.SELECT_DEPLOY_UNIT_UI)
