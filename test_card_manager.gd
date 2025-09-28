# test_card_manager.gd
# 简单的CardManager测试脚本

extends SceneTree

func _init():
	print("开始测试CardManager...")
	
	# 创建根节点
	var root = Node.new()
	current_scene = root
	
	# 创建CardManager实例
	var card_manager = preload("res://scripts/CardManager.gd").new()
	root.add_child(card_manager)
	
	# 等待CardManager初始化
	await process_frame
	
	print("CardManager初始化完成")
	print("数据库大小: ", card_manager.card_database.size())
	print("数据库键: ", card_manager.card_database.keys())
	
	# 测试获取卡牌
	var test_cards = ["bamboo_forest", "mountain_peak", "river"]
	for card_id in test_cards:
		print("测试获取卡牌: ", card_id)
		var card_data = card_manager.get_card_by_id(card_id)
		print("结果: ", card_data)
	
	print("测试完成")
	quit()