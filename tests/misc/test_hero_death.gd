extends SceneTree

func _init():
	print("=== 英雄死亡测试开始 ===")
	
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn")
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	
	# 等待场景初始化
	await process_frame
	await create_timer(1.0).timeout
	
	# 获取关键组件
	var loop_manager = main_instance.get_node_or_null("LoopManager")
	var game_manager = main_instance.get_node_or_null("GameManager")
	
	if not loop_manager:
		print("✗ 未找到LoopManager")
		quit(1)
		return
		
	if not game_manager:
		print("✗ 未找到GameManager")
		quit(1)
		return
	
	print("✓ 找到所有关键组件")
	
	# 记录初始状态
	var initial_state = game_manager.current_state
	print("初始游戏状态: %d" % initial_state)
	
	# 调用英雄死亡
	print("调用hero_death()...")
	game_manager.hero_death()
	
	# 等待状态更新
	await process_frame
	await create_timer(0.5).timeout
	
	# 检查结果
	var current_state = game_manager.current_state
	print("当前游戏状态: %d" % current_state)
	print("GAME_OVER枚举值: %d" % GameManager.GameState.GAME_OVER)
	
	# 测试LoopManager中的GameManager访问
	print("\n=== 测试LoopManager中的GameManager访问 ===")
	var gm_from_loop = loop_manager.get_node_or_null("../GameManager")
	print("从LoopManager访问GameManager (相对路径): %s" % gm_from_loop)
	if gm_from_loop:
		print("从LoopManager看到的游戏状态 (相对路径): %d" % gm_from_loop.current_state)
	
	# 测试移动阻止
	print("\n=== 测试移动阻止 ===")
	var initial_moving = loop_manager.get("is_moving")
	print("初始移动状态: %s" % initial_moving)
	
	# 停止当前移动（如果有的话）
	if initial_moving:
		loop_manager.set("is_moving", false)
		print("停止当前移动")
	
	if loop_manager.has_method("start_hero_movement"):
		print("调用start_hero_movement()...")
		loop_manager.start_hero_movement()
		await process_frame
		var after_start = loop_manager.get("is_moving")
		print("尝试开始移动后: %s" % after_start)
		
		# 验证移动是否被阻止
		if after_start:
			print("✗ 移动未被阻止")
		else:
			print("✓ 移动被正确阻止")
	
	# 验证结果
	var success = true
	if current_state != GameManager.GameState.GAME_OVER:
		print("✗ 游戏状态不是GAME_OVER")
		success = false
	else:
		print("✓ 游戏状态正确设置为GAME_OVER")
	
	if gm_from_loop and gm_from_loop.current_state == GameManager.GameState.GAME_OVER:
		print("✓ LoopManager可以正确访问GAME_OVER状态")
	else:
		print("✗ LoopManager无法正确访问GAME_OVER状态")
		success = false
	
	# 检查移动是否被阻止
	var final_moving = loop_manager.get("is_moving")
	if not final_moving:
		print("✓ 移动被正确阻止")
	else:
		print("✗ 移动未被阻止")
		success = false
	
	print("=== 测试结果: %s ===" % ("通过" if success else "失败"))
	quit(0 if success else 1)