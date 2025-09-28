extends SceneTree

func _init():
	print("[TestCardManager] 开始测试CardManager...")
	_run_test()

func _run_test():
	# 直接创建CardManager实例
	var card_manager_script = load("res://scripts/CardManager.gd")
	if not card_manager_script:
		print("[TestCardManager] 错误: 无法加载CardManager.gd")
		quit(1)
		return
	
	var card_manager = card_manager_script.new()
	if not card_manager:
		print("[TestCardManager] 错误: 无法创建CardManager实例")
		quit(1)
		return
	
	print("[TestCardManager] CardManager实例已创建")
	
	# 等待一帧让CardManager初始化
	await process_frame
	
	# 手动调用_ready方法来初始化CardManager
	card_manager._ready()
	
	print("[TestCardManager] CardManager._ready()已调用")
	
	# 等待一段时间确保初始化完成
	await create_timer(1.0).timeout
	
	# 测试get_card_by_id方法
	print("[TestCardManager] 开始测试get_card_by_id方法...")
	
	var test_cards = ["bamboo_forest", "mountain_peak", "river"]
	for card_id in test_cards:
		print("[TestCardManager] 测试获取卡牌: ", card_id)
		var card_data = card_manager.get_card_by_id(card_id)
		print("[TestCardManager] 获取到的卡牌数据: ", card_data)
		
		if card_data.is_empty():
			print("[TestCardManager] 警告: 卡牌数据为空!")
		else:
			print("[TestCardManager] 成功获取卡牌: ", card_data.get("name", "未知"))
	
	print("[TestCardManager] 测试完成，退出...")
	quit(0)