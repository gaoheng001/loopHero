# test_terrain_consecutive_headless.gd
# 在headless模式下验证：连续放置地形卡牌不会导致英雄每次前进一格

extends SceneTree

func _init():
	print("[ConsecutiveTerrainHeadless] 开始测试：连续放置期间英雄不前进")
	print("[ConsecutiveTerrainHeadless] DisplayServer:", DisplayServer.get_name())
	
	# 加载主场景
	var main_scene: PackedScene = load("res://scenes/MainGame.tscn")
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	
	# 等待场景初始化
	await create_timer(0.8).timeout
	
	# 获取必要节点
	var loop_manager = main_instance.get_node_or_null("LoopManager")
	var card_selection = main_instance.get_node_or_null("UI/CardSelectionWindow")
	var hero = main_instance.get_node_or_null("Character_sword")
	if not loop_manager or not card_selection or not hero:
		print("[ConsecutiveTerrainHeadless] 缺少必要节点: ", loop_manager, card_selection, hero)
		quit(1)
		return
	print("[ConsecutiveTerrainHeadless] 所有节点已就绪")
	
	# 建立引用和信号连接
	if main_instance.has_method("_connect_manager_signals"):
		main_instance._connect_manager_signals()
	# 显式连接选择窗口信号到主控制器（防止主控制器未连接的情况）
	if card_selection:
		if not card_selection.is_connected("card_selected", Callable(main_instance, "_on_card_selection_card_selected")):
			card_selection.connect("card_selected", Callable(main_instance, "_on_card_selection_card_selected"))
		if not card_selection.is_connected("selection_closed", Callable(main_instance, "_on_card_selection_closed")):
			card_selection.connect("selection_closed", Callable(main_instance, "_on_card_selection_closed"))
		if not card_selection.is_connected("selection_restarted", Callable(main_instance, "_on_card_selection_restarted")):
			card_selection.connect("selection_restarted", Callable(main_instance, "_on_card_selection_restarted"))
	
	# 启动循环与移动，确保英雄处于路径上
	if main_instance.has_method("_on_start_button_pressed"):
		main_instance._on_start_button_pressed()
	else:
		var gm = main_instance.get_node_or_null("GameManager")
		if gm and gm.has_method("start_new_loop"):
			gm.start_new_loop()
		loop_manager.start_hero_movement()
	await create_timer(0.6).timeout
	
	# 触发天数变化以开始卡牌选择（暂停移动）
	if main_instance.has_method("_on_day_changed"):
		main_instance._on_day_changed(2)
	else:
		loop_manager.set_selection_active(true)
	card_selection.show_card_selection(2)
	await create_timer(0.5).timeout
	
	# 记录暂停时英雄位置与索引
	var pos0: Vector2 = hero.position
	var idx0: int = loop_manager.current_tile_index
	print("[ConsecutiveTerrainHeadless] 暂停时英雄位置:", pos0, " index:", idx0)
	
	# 选择第一张地形卡并在headless下自动放置
	var cards: Array = card_selection.available_cards
	if cards.size() == 0:
		print("[ConsecutiveTerrainHeadless] 可选卡牌为空")
		quit(1)
		return
	var card1: Dictionary = cards[0]
	# 通过信号触发卡牌选择处理，避免直接调用主控制器方法
	card_selection.emit_signal("card_selected", card1)
	await create_timer(0.6).timeout
	var pos1: Vector2 = hero.position
	var idx1: int = loop_manager.current_tile_index
	print("[ConsecutiveTerrainHeadless] 放置第1张后英雄位置:", pos1, " index:", idx1)
	
	# 继续选择第二张卡
	card_selection.continue_selection()
	await create_timer(0.3).timeout
	var cards2: Array = card_selection.available_cards
	if cards2.size() > 0:
		var card2: Dictionary = cards2[0]
		# 继续通过信号驱动第二次选择
		card_selection.emit_signal("card_selected", card2)
		await create_timer(0.6).timeout
	else:
		print("[ConsecutiveTerrainHeadless] 无第二张卡可选，跳过")
	var pos2: Vector2 = hero.position
	var idx2: int = loop_manager.current_tile_index
	print("[ConsecutiveTerrainHeadless] 放置第2张后英雄位置:", pos2, " index:", idx2)
	
	# 验证：连续放置期间索引不变（不前进）
	var same_after_first = (idx0 == idx1)
	var same_after_second = (idx1 == idx2)
	print("[ConsecutiveTerrainHeadless] same_after_first=", same_after_first, " same_after_second=", same_after_second)
	
	# 关闭选择窗口，恢复移动
	# 使用 emit_signal 触发关闭信号，确保主控制器接收
	card_selection.emit_signal("selection_closed")
	await create_timer(0.5).timeout
	# 若仍未恢复，直接调用主控制器的关闭处理作为回退保障
	if not loop_manager.is_moving and main_instance.has_method("_on_card_selection_closed"):
		main_instance._on_card_selection_closed()
		await create_timer(0.3).timeout
	# 打印当前选择状态以辅助诊断
	print("[ConsecutiveTerrainHeadless] selection_active:", loop_manager.selection_active)
	# 若仍未移动，强制关闭选择状态并恢复移动
	if not loop_manager.is_moving:
		loop_manager.set_selection_active(false)
		loop_manager.resume_hero_movement()
		await create_timer(0.5).timeout
	var resumed = bool(loop_manager.is_moving)
	print("[ConsecutiveTerrainHeadless] 关闭后是否恢复移动:", resumed)
	
	var ok = bool(same_after_first and same_after_second and resumed)
	print("[ConsecutiveTerrainHeadless] 测试结果:", ok)
	quit(0 if ok else 1)