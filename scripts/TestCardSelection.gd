# TestCardSelection.gd
# 测试卡牌选择功能的简单脚本
extends SceneTree

func _init():
	print("[TestCardSelection] 开始测试卡牌选择功能...")
	
	# 加载主场景
	var main_scene = load("res://scenes/MainGame.tscn")
	var main_instance = main_scene.instantiate()
	
	# 添加到场景树
	root.add_child(main_instance)
	current_scene = main_instance
	
	print("[TestCardSelection] 主场景已加载")
	
	# 等待一帧让所有节点初始化
	await process_frame
	await process_frame
	
	print("[TestCardSelection] 开始查找CardSelectionWindow...")
	
	# 查找CardSelectionWindow
	var card_selection_window = main_instance.get_node_or_null("UI/CardSelectionWindow")
	if not card_selection_window:
		print("[TestCardSelection] 错误: 无法找到CardSelectionWindow")
		quit()
		return
	
	print("[TestCardSelection] 找到CardSelectionWindow，开始测试...")
	
	# 直接调用show_card_selection方法
	card_selection_window.show_card_selection(5)
	
	print("[TestCardSelection] 卡牌选择已触发，等待2秒后退出...")
	
	# 等待2秒让我们看到结果
	await create_timer(2.0).timeout
	
	print("[TestCardSelection] 测试完成，退出...")
	quit()